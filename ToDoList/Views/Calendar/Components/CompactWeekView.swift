import SwiftUI
import UniformTypeIdentifiers

/// Takvimin üst kısmında yer alan, 2 haftalık (14 günlük) görünümü sunan akıllı bileşen.
/// Senior Notu: DragGesture ve LongPressGesture entegrasyonu sağlandı.
/// Sabit beyaz renkler kaldırılarak Aydınlık Mod (Adaptive UI) kusursuzlaştırıldı.
struct CompactWeekView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: CalendarViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // Ana ekrandan gelen bağımlılıklar ve basılı tutma köprüsü
    @ObservedObject var taskVM: TaskViewModel
    var onLongPress: (Date) -> Void
    
    // Grid yapısı: Haftanın 7 günü için 7 eşit sütun
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    // Haftanın günleri (Pazartesi'den Pazara)
    private let weekdays = ["PZT", "SAL", "ÇAR", "PER", "CUM", "CMT", "PAZ"]
    
    // MARK: - Body
    var body: some View {
        let currentDays = viewModel.generateCompactWeeks()
        
        VStack(spacing: 16) {
            // 1. ÜST BAŞLIK VE YÖN OKLARI (YENİ BUGÜN BUTONU BURADA)
            headerRow(days: currentDays)
            
            // 2. HAFTANIN GÜNLERİ (PZT, SAL...)
            weekdaysRow
            
            // 3. 14 GÜNLÜK IZGARA (DAY CELLS)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(currentDays, id: \.self) { date in
                    DayCellView(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        heatmapLevel: viewModel.getHeatmapLevel(for: date),
                        hasHiddenTasks: viewModel.hasHiddenTasks(on: date),
                        action: {
                            // NORMAL TIKLAMA (Sadece günü seçer)
                            HapticManager.shared.triggerSelection()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.selectedDate = date
                            }
                        },
                        onLongPress: {
                            // Basılı tutunca tetiklenir (DayCellView'dan gelir)
                            HapticManager.shared.triggerHeavyImpact()
                            // Önce o günü seçili yapıyoruz ki UI'da da güncellensin
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.selectedDate = date
                            }
                            // Sonra dışarıya (CalendarView'a) form açması için sinyal gönderiyoruz
                            onLongPress(date)
                        }
                    )
                    // Zaman Yolculuğu (Drag & Drop) Hedefi
                    .onDrop(of: [.plainText], isTargeted: nil) { providers in
                        if let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) {
                            provider.loadObject(ofClass: NSString.self) { object, _ in
                                if let taskID = object as? String {
                                    // ✨ SENIOR FIX: MainActor izolesi hatasını çözmek için arama işlemini Ana İş Parçacığına (Main Thread) alıyoruz.
                                    Task { @MainActor in
                                        if let draggedTask = taskVM.tasks.first(where: { $0.id == taskID }) {
                                            viewModel.moveTask(draggedTask, to: date)
                                        }
                                    }
                                }
                            }
                            return true
                        }
                        return false
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        // ✨ GLASSMORPHISM EFEKTİ (Adaptive)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                // ✨ SENIOR FIX: Aydınlık mod uyumu için .white yerine .primary kullanıldı
                .fill(Color.primary.opacity(0.03))
                .background(.ultraThinMaterial.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        // SAĞA-SOLA KAYDIRMA (SWIPE GESTURE)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        viewModel.changeWeek(by: -1)
                    } else if value.translation.width < -50 {
                        viewModel.changeWeek(by: 1)
                    }
                }
        )
    }
}

// MARK: - Sub-Views & Helpers
private extension CompactWeekView {
    
    /// Aralığı ("14 Eki - 27 Eki") ve ok butonlarını çizer
    @ViewBuilder
    func headerRow(days: [Date]) -> some View {
        HStack {
            Text(dateRangeText(for: days))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                // ✨ SENIOR FIX: .primary ile aydınlık mod desteklendi
                .foregroundColor(.primary.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 16) {
                if !Calendar.current.isDateInToday(viewModel.selectedDate) || viewModel.currentWeekOffset != 0 {
                    Button(action: {
                        viewModel.jumpToToday()
                    }) {
                        Text("Bugün")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(appearance.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(appearance.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Button(action: { viewModel.changeWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary.opacity(0.6)) // ✨ SENIOR FIX
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button(action: { viewModel.changeWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary.opacity(0.6)) // ✨ SENIOR FIX
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedDate)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentWeekOffset)
    }
    
    /// Haftanın gün başlıklarını (PZT, SAL...) çizer
    var weekdaysRow: some View {
        HStack {
            ForEach(0..<7, id: \.self) { index in
                Text(weekdays[index])
                    .font(.system(size: 10, weight: .bold))
                    // ✨ SENIOR FIX: .primary ile aydınlık mod desteklendi
                    .foregroundColor(index >= 5 ? appearance.accentColor.opacity(0.8) : .primary.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    /// İlk ve son tarihe bakarak şık bir aralık metni oluşturur
    func dateRangeText(for days: [Date]) -> String {
        guard let first = days.first, let last = days.last else { return "" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        
        let firstStr = formatter.string(from: first)
        let lastStr = formatter.string(from: last)
        
        return "\(firstStr) — \(lastStr)"
    }
}
