import SwiftUI

/// Takvim ekranının alt yarısında yer alan, seçili günün görevlerini
/// zaman çizelgesi (timeline) formatında gösteren bileşen.
/// Senior Notu: Glassmorphism efektleriyle zenginleştirilmiş, statik beyazlar temizlenerek
/// aydınlık/karanlık mod uyumu (Adaptive UI) sağlanmıştır.
struct DailyFlowListView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: CalendarViewModel
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // Dışarıdan (CalendarView'dan) gönderilecek görev ekleme tetikleyicisi
    var onAddTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. ÜST BAŞLIK VE AKILLI BUTON (Header)
            headerView
            
            // 2. GÖREVLER ZAMAN ÇİZELGESİ
            ScrollView(.vertical, showsIndicators: false) {
                let dailyTasks = viewModel.getDailyFlow(for: viewModel.selectedDate)
                
                if dailyTasks.isEmpty {
                    // Boş Durum (Empty State)
                    VStack(spacing: 16) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 40))
                            // ✨ SENIOR FIX: .white yerine .primary kullanıldı
                            .foregroundColor(.primary.opacity(0.2))
                            .padding(.top, 40)
                        
                        Text("Bu gün için planlanmış bir görev yok.")
                            .font(.system(size: 14, weight: .medium))
                            // ✨ SENIOR FIX: .white yerine .secondary kullanıldı
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            HapticManager.shared.triggerLightImpact()
                            onAddTap() // Boş durumdayken de ana takvime ekleme komutu gönderir
                        }) {
                            Text("Dinlen veya Yeni Görev Ekle")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(appearance.accentColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(appearance.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 100) // Scroll rahatlığı için
                } else {
                    // Görev Listesi
                    VStack(spacing: 16) {
                        ForEach(dailyTasks) { task in
                            // Her bir görev için zaman çizelgesi satırı
                            TaskTimelineRow(task: task, taskVM: taskVM)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 120) // Alt navigasyon barı için boşluk
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Sub-Views
private extension DailyFlowListView {
    
    /// "Bugünün Akışı" Başlığı ve Minimalist Ekleme Butonu
    var headerView: some View {
        HStack {
            Text(isToday ? "Bugünün Akışı" : "Günlük Akış")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                // ✨ SENIOR FIX: Aydınlık/Karanlık mod duyarlı
                .foregroundColor(.primary)
            
            Spacer()
            
            // YENİ AKILLI VE MİNİMALİST BUTON
            Button(action: {
                HapticManager.shared.triggerLightImpact()
                onAddTap() // Dışarıya haber veriyor
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    // ✨ SENIOR FIX: İkon rengi .primary yapıldı
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    // ✨ SENIOR FIX: Arka plan .primary.opacity ile zenginleştirildi
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    
    /// Seçili günün bugün olup olmadığını kontrol eder
    var isToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }
}

// MARK: - Tekil Zaman Çizelgesi Satırı (TaskTimelineRow)
struct TaskTimelineRow: View {
    let task: TaskModel
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        HStack(spacing: 0) {
            
            // SOL SÜTUN: SAAT (Time Column)
            VStack(spacing: 2) {
                Text(formatHour(date: task.createdAt))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    // ✨ SENIOR FIX: Saatler aydınlık modda okunur hale geldi
                    .foregroundColor(task.isCompleted ? .primary.opacity(0.4) : .primary.opacity(0.8))
                
                Text(formatAmPm(date: task.createdAt))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.4))
            }
            .frame(width: 60)
            
            // AYRAÇ ÇİZGİSİ
            Rectangle()
                .fill(Color.primary.opacity(0.1)) // ✨ SENIOR FIX
                .frame(width: 1)
                .padding(.vertical, 10)
            
            // SAĞ SÜTUN: GÖREV DETAYLARI
            VStack(alignment: .leading, spacing: 8) {
                
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .strikethrough(task.isCompleted)
                        // ✨ SENIOR FIX: Beyaz yerine Primary
                        .foregroundColor(task.isCompleted ? .primary.opacity(0.4) : .primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Tamamlama / AI İkonu
                    Button(action: {
                        HapticManager.shared.triggerSelection()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            taskVM.toggleCompletion(task: task)
                        }
                    }) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(task.isCompleted ? .green : appearance.accentColor.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                
                // Görev Notu / Alt Başlık (Varsa)
                if !task.note.isEmpty {
                    Text(task.note)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary) // ✨ SENIOR FIX
                        .lineLimit(1)
                }
                
                // Etiketler (Kategori, XP)
                HStack(spacing: 8) {
                    if let category = task.category {
                        Text(category.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    // Gizli görev ikonu
                    if task.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    // Oyunlaştırma: Potansiyel veya Kazanılan XP
                    Text(task.isCompleted ? "TAMAMLANDI" : "+10 XP")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        // ✨ SENIOR FIX: Gelişmiş kontrast
                        .foregroundColor(task.isCompleted ? .green.opacity(0.8) : .primary.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(.leading, 16)
            .padding(.vertical, 14)
            .padding(.trailing, 16)
        }
        // ✨ GLASSMORPHISM EFEKTİ (Adaptive)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                // ✨ SENIOR FIX: .white yerine .primary kullanılarak Aydınlık Moda uyum sağlandı
                .fill(Color.primary.opacity(task.isCompleted ? 0.01 : 0.03))
                .background(.ultraThinMaterial.opacity(task.isCompleted ? 0.4 : 0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(task.isCompleted ? 0.02 : 0.08), lineWidth: 1)
        )
        .opacity(task.isCompleted ? 0.6 : 1.0)
        // Zaman Yolculuğu için görevi sürüklenebilir yapıyoruz
        .onDrag {
            NSItemProvider(object: task.id as NSString)
        }
    }
    
    // MARK: - Date Formatters
    func formatHour(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func formatAmPm(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: date)
    }
}
