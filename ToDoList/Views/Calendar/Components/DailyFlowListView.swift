import SwiftUI

/// Takvim ekranının alt yarısında yer alan, seçili günün görevlerini
/// zaman çizelgesi (timeline) formatında gösteren bileşen.
/// Senior Notu: Glassmorphism efektleri ve oyunlaştırma rozetleriyle zenginleştirilmiştir.
struct DailyFlowListView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: CalendarViewModel
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    @State private var showingAddTask = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. ÜST BAŞLIK (Header)
            headerView
            
            // 2. GÖREVLER ZAMAN ÇİZELGESİ
            ScrollView(.vertical, showsIndicators: false) {
                let dailyTasks = viewModel.getDailyFlow(for: viewModel.selectedDate)
                
                if dailyTasks.isEmpty {
                    // Boş Durum (Empty State)
                    VStack(spacing: 16) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                            .padding(.top, 40)
                        
                        Text("Bu gün için planlanmış bir görev yok.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Button(action: { showingAddTask = true }) {
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
        .sheet(isPresented: $showingAddTask) {
            // Takvimden görev eklendiğinde seçili günü varsayılan yapmak için
            // AddTaskView'a tarih parametresi eklenebilir ancak mevcut yapıyı bozmamak için standart çağırıyoruz.
            AddTaskView(viewModel: taskVM, isPrivateDefault: false)
        }
    }
}

// MARK: - Sub-Views
private extension DailyFlowListView {
    
    /// "Today's Flow" Başlığı ve Ekleme Butonu
    var headerView: some View {
        HStack {
            HStack(spacing: 10) {
                Text(isToday ? "Bugünün Akışı" : "Günlük Akış")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Oyunlaştırma Rozeti (Level)
                Text("LVL \(taskVM.userXP / 50 + 1)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(appearance.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(appearance.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.triggerLightImpact()
                showingAddTask = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Görev Ekle")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(appearance.accentColor)
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
                    .foregroundColor(task.isCompleted ? .white.opacity(0.4) : .white.opacity(0.8))
                
                Text(formatAmPm(date: task.createdAt))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(width: 60)
            
            // AYRAÇ ÇİZGİSİ
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 10)
            
            // SAĞ SÜTUN: GÖREV DETAYLARI
            VStack(alignment: .leading, spacing: 8) {
                
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .white.opacity(0.4) : .white)
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
                        .foregroundColor(.white.opacity(0.5))
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
                        .foregroundColor(task.isCompleted ? .green.opacity(0.8) : .white.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(.leading, 16)
            .padding(.vertical, 14)
            .padding(.trailing, 16)
        }
        // ✨ GLASSMORPHISM EFEKTİ
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(task.isCompleted ? 0.01 : 0.03))
                .background(.ultraThinMaterial.opacity(task.isCompleted ? 0.4 : 0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(task.isCompleted ? 0.02 : 0.08), lineWidth: 1)
        )
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }
    
    // MARK: - Date Formatters
    func formatHour(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm" // 24 saatlik format için "HH", 12 saatlik için "hh"
        return formatter.string(from: date)
    }
    
    func formatAmPm(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a" // AM / PM
        return formatter.string(from: date)
    }
}
