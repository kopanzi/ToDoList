import SwiftUI

/// Takvim modülünün ana ekranı. Üstteki 14 günlük şeridi ve alttaki zaman çizelgesini birleştirir.
/// Senior Notu: AddTaskView ile tam entegrasyon sağlanmış, statik beyaz (.white) renkler kaldırılarak
/// Aydınlık/Karanlık moda tam uyumlu (Adaptive) hale getirilmiştir.
struct CalendarView: View {
    // MARK: - Properties
    @ObservedObject var taskVM: TaskViewModel
    @StateObject private var viewModel: CalendarViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // Sidebar'ı tetiklemek için
    var onMenuTap: () -> Void
    
    // Görev ekleme durumu
    @State private var showingAddTask = false
    @State private var isAIPulsing = false
    
    // MARK: - Initialization
    init(taskVM: TaskViewModel, onMenuTap: @escaping () -> Void) {
        self.taskVM = taskVM
        self.onMenuTap = onMenuTap
        // ViewModel'i doğrudan TaskViewModel bağımlılığı ile başlatıyoruz
        _viewModel = StateObject(wrappedValue: CalendarViewModel(taskVM: taskVM))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Arka Plan (Mesh Gradient'in görünmesi için tamamen şeffaf)
            Color.clear.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. ÜST HEADER (Tamamen sadeleştirildi ve Adaptive yapıldı)
                headerView
                
                // 2. KOMPAKT HAFTALIK TAKVİM (Üst Yarı)
                CompactWeekView(viewModel: viewModel, taskVM: taskVM) { date in
                    taskVM.defaultAdditionDate = date
                    showingAddTask = true
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .zIndex(2)
                
                // 3. GÜNLÜK AKIŞ LİSTESİ (Alt Yarı)
                DailyFlowListView(viewModel: viewModel, taskVM: taskVM) {
                    taskVM.defaultAdditionDate = viewModel.selectedDate
                    showingAddTask = true
                }
                .zIndex(1)
            }
            
            // 4. YÜZEN AI BALONU
            floatingAIBubble
        }
        // Görev ekleme ekranını ana ekrandan yönetiyoruz
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: taskVM, isPrivateDefault: false)
        }
        // Sayfa kapandığında seçili tarihi temizle (Global state güvenliği)
        .onDisappear {
            taskVM.defaultAdditionDate = nil
        }
    }
}

// MARK: - Sub-Views & Helpers
private extension CalendarView {
    
    /// Ekranın en üstünde yer alan, Menü, Tarih ve Avatar'ı içeren başlık.
    var headerView: some View {
        HStack {
            // SOL: Menü + Tarih Bilgisi
            HStack(spacing: 16) {
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    onMenuTap()
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 24, weight: .medium))
                        // ✨ SENIOR FIX: .white yerine .primary kullanıldı (Aydınlık mod uyumu)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentMonthName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        // ✨ SENIOR FIX: .white yerine .primary (Aydınlık modda okunabilirlik için)
                        .foregroundColor(.primary)
                    
                    Text("ODAK YILI")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(appearance.accentColor)
                        .tracking(2)
                }
            }
            
            Spacer()
            
            // SAĞ: Avatar View (Dinamik arka plana tam uyumlu)
            HStack(spacing: 12) {
                AvatarView(size: 40, showAura: false)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 15)
    }
    
    /// Sağ altta süzülen ve o günün durumuna göre akıllıca değişen AI asistan balonu.
    var floatingAIBubble: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    
                    Text(smartAIText)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(appearance.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                // ✨ SENIOR FIX: Adaptive Material kullanılarak aydınlık/karanlık modlarda kusursuz kontrast sağlandı
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .overlay(Capsule().stroke(appearance.accentColor.opacity(0.4), lineWidth: 1))
                .shadow(color: appearance.accentColor.opacity(0.2), radius: 10, x: 0, y: 5)
                .scaleEffect(isAIPulsing ? 1.05 : 0.95)
                .padding(.trailing, 20)
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAIPulsing = true
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: viewModel.selectedDate).capitalized
    }
    
    var smartAIText: String {
        let tasks = viewModel.getDailyFlow(for: viewModel.selectedDate)
        let activeCount = tasks.filter { !$0.isCompleted }.count
        
        if Calendar.current.isDateInToday(viewModel.selectedDate) {
            if activeCount == 0 { return "Sio: Bugün her şey tamam. Harikasın!" }
            if activeCount > 4 { return "Sio: Biraz yoğun bir gün, odaklanalım." }
            return "Sio: Günü bitirmek için \(activeCount) görev kaldı."
        } else if viewModel.selectedDate > Date() {
            if activeCount > 0 { return "YAVER: Geleceği planlamak harika." }
            return "Sio: Bu gün için henüz plan yok."
        } else {
            return "Sio: Geçmiş değiştirilemez ama ders alınabilir."
        }
    }
}
