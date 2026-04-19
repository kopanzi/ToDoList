import SwiftUI

/// Takvim modülünün ana ekranı. Üstteki 14 günlük şeridi ve alttaki zaman çizelgesini birleştirir.
/// Senior Notu: Bu View, kendi içinde state yönetmez; tüm veriyi CalendarViewModel'den çeker
/// ve alt bileşenlere dağıtarak "Single Source of Truth" (Tek Gerçeklik Kaynağı) prensibine uyar.
struct CalendarView: View {
    // MARK: - Properties
    @ObservedObject var taskVM: TaskViewModel
    @StateObject private var viewModel: CalendarViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // Sidebar'ı tetiklemek için
    var onMenuTap: () -> Void
    
    // Yüzen AI Balonu Animasyonu İçin
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
                // 1. ÜST HEADER (Ay, Yıl, Arama ve Avatar)
                headerView
                
                // 2. KOMPAKT HAFTALIK TAKVİM (Üst Yarı)
                CompactWeekView(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .zIndex(2) // Gölgenin alt listeye düşmesi için
                
                // 3. GÜNLÜK AKIŞ LİSTESİ (Alt Yarı - Kaydırılabilir)
                DailyFlowListView(viewModel: viewModel, taskVM: taskVM)
                    .zIndex(1)
            }
            
            // 4. YÜZEN AI BALONU (Floating Action Bubble)
            floatingAIBubble
        }
    }
}

// MARK: - Sub-Views & Helpers
private extension CalendarView {
    
    /// Ekranın en üstünde yer alan, Hamburger menü, Ay/Yıl ve Avatar'ı içeren başlık.
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
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentMonthName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("ODAK YILI")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(appearance.accentColor)
                        .tracking(2)
                }
            }
            
            Spacer()
            
            // SAĞ: Arama ve Avatar
            HStack(spacing: 12) {
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    // Arama aksiyonu (Şimdilik animasyonlu tepki veriyor)
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.05).background(.ultraThinMaterial))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)
                
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
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .background(.ultraThinMaterial.opacity(0.8))
                )
                .overlay(Capsule().stroke(appearance.accentColor.opacity(0.4), lineWidth: 1))
                .shadow(color: appearance.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                .scaleEffect(isAIPulsing ? 1.05 : 0.95)
                .padding(.trailing, 20)
                .padding(.bottom, 120) // Alt Navigasyon Barı için boşluk
            }
        }
        .onAppear {
            // Nefes alma (pulse) animasyonunu döngüye sok
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAIPulsing = true
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    /// Seçili aya ait ismi Türkçe olarak döndürür (Örn: "Ekim")
    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: viewModel.selectedDate).capitalized
    }
    
    /// Seçili güne bakarak AI balonunda görünecek akıllı bir mesaj üretir.
    var smartAIText: String {
        let tasks = viewModel.getDailyFlow(for: viewModel.selectedDate)
        let activeCount = tasks.filter { !$0.isCompleted }.count
        
        if Calendar.current.isDateInToday(viewModel.selectedDate) {
            if activeCount == 0 { return "AI: Bugün her şey tamam. Harikasın!" }
            if activeCount > 4 { return "AI: Biraz yoğun bir gün, odaklanalım." }
            return "AI: Günü bitirmek için \(activeCount) görev kaldı."
        } else if viewModel.selectedDate > Date() {
            if activeCount > 0 { return "AI: Geleceği planlamak harika." }
            return "AI: Bu gün için henüz plan yok."
        } else {
            return "AI: Geçmişi değiştirilemez ama ders alınabilir."
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Arkada Mesh Gradient simülasyonu
        Color(hex: "050a09").ignoresSafeArea()
        
        CalendarView(taskVM: TaskViewModel(), onMenuTap: {})
    }
    .environmentObject(AppearanceManager.shared)
}
