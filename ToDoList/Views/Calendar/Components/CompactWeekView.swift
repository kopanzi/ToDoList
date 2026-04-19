import SwiftUI

/// Takvimin üst kısmında yer alan, 2 haftalık (14 günlük) görünümü sunan akıllı bileşen.
/// Senior Notu: DragGesture (Sürükleme) entegrasyonu ile kusursuz bir mobil deneyim sağlar.
struct CompactWeekView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: CalendarViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // Grid yapısı: Haftanın 7 günü için 7 eşit sütun
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    // Haftanın günleri (Pazartesi'den Pazara)
    private let weekdays = ["PZT", "SAL", "ÇAR", "PER", "CUM", "CMT", "PAZ"]
    
    // MARK: - Body
    var body: some View {
        let currentDays = viewModel.generateCompactWeeks()
        
        VStack(spacing: 16) {
            // 1. ÜST BAŞLIK VE YÖN OKLARI
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
                            HapticManager.shared.triggerSelection()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.selectedDate = date
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        // ✨ GLASSMORPHISM EFEKTİ
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .background(.ultraThinMaterial.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        // ✨ SAĞA-SOLA KAYDIRMA (SWIPE GESTURE)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Sağa kaydırma -> Önceki haftaya git
                        viewModel.changeWeek(by: -1)
                    } else if value.translation.width < -50 {
                        // Sola kaydırma -> Sonraki haftaya git
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
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: { viewModel.changeWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button(action: { viewModel.changeWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
    
    /// Haftanın gün başlıklarını (PZT, SAL...) çizer
    var weekdaysRow: some View {
        HStack {
            ForEach(0..<7, id: \.self) { index in
                Text(weekdays[index])
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(index >= 5 ? appearance.accentColor.opacity(0.8) : .white.opacity(0.4))
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

// MARK: - Preview
#Preview {
    ZStack {
        // Arkada Mesh efekti simülasyonu
        Color(hex: "050a09").ignoresSafeArea()
        
        CompactWeekView(viewModel: CalendarViewModel(taskVM: TaskViewModel()))
            .padding()
    }
    .environmentObject(AppearanceManager.shared)
}
