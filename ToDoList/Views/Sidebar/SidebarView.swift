import SwiftUI

/// Yan menü navigasyonunu yöneten ana orkestratör bileşen.
/// Senior Notu: Bu View, iş mantığını 'Components' altındaki parçalara dağıtarak
/// temiz ve sürdürülebilir bir yapı sunar. Kategori listesi kaldırılarak sadeleştirilmiştir.
struct SidebarView: View {
    // MARK: - Properties
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // Navigasyon durumları
    @Binding var isMenuOpen: Bool
    @Binding var selectedScreen: ContentView.ScreenType
    @Binding var selectedCategory: Category?
    
    // ✨ YENİ: Odak Sayacını (Pomodoro) Açmak İçin Tetikleyici State
    @State private var showingFocusTimer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. ÜST PROFİL VE RÜTBE BÖLÜMÜ (Header Component) ✅
            SidebarHeaderView(
                rankName: taskVM.currentRank.name,
                rankIcon: taskVM.currentRank.icon,
                xp: taskVM.userXP,
                progress: XPService.shared.getProgressPercentage(xp: taskVM.userXP)
            )
            
            // 2. MENÜ LİSTESİ (Scrollable)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    
                    // ANA NAVİGASYON
                    Group {
                        SidebarMenuItemView(
                            title: "Tüm Görevler",
                            icon: "checklist",
                            isSelected: selectedScreen == .tasks && selectedCategory == nil
                        ) { navigate(to: .tasks) }
                        
                        SidebarMenuItemView(
                            title: "Gizli Kasa",
                            icon: "lock.shield.fill",
                            isSelected: selectedScreen == .hiddenTasks
                        ) { navigate(to: .hiddenTasks) }
                    }
                    
                    dividerLine
                    
                    // NOTLAR VE GİZLİ NOTLAR
                    Group {
                        SidebarMenuItemView(
                            title: "Not Defteri",
                            icon: "note.text",
                            isSelected: selectedScreen == .notes
                        ) { navigate(to: .notes) }
                        
                        SidebarMenuItemView(
                            title: "Gizli Notlar",
                            icon: "lock.doc.fill",
                            isSelected: selectedScreen == .hiddenNotes
                        ) { navigate(to: .hiddenNotes) }
                    }
                    
                    dividerLine
                    
                    // ✨ ARAÇLAR (TOOLS) BÖLÜMÜ
                    Group {
                        SidebarMenuItemView(
                            title: "Odak Sayacı",
                            icon: "timer",
                            isSelected: false // Tıklanınca başka bir ekrana yönlendirmiyor, modal açıyor
                        ) {
                            HapticManager.shared.triggerLightImpact()
                            // Önce sidebar'ı yumuşakça kapatıyoruz
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isMenuOpen = false
                            }
                            // Sidebar kapandıktan hemen sonra sayacı açıyoruz
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingFocusTimer = true
                            }
                        }
                        
                        // 🗑️ YENİ EKLENEN ÇÖP KUTUSU BUTONU
                        SidebarMenuItemView(
                            title: "Çöp Kutusu",
                            icon: "trash.fill",
                            isSelected: selectedScreen == .trash
                        ) {
                            navigate(to: .trash)
                        }
                    }
                    
                    dividerLine
                    
                    // AYARLAR
                    SidebarMenuItemView(
                        title: "Ayarlar",
                        icon: "gearshape.fill",
                        isSelected: selectedScreen == .settings
                    ) { navigate(to: .settings) }
                }
                .padding(.vertical)
            }
            
            Spacer()
            
            // SÜRÜM BİLGİSİ
            footerInfo
        }
        .frame(maxWidth: 250)
        .frame(maxHeight: .infinity)
        .background(Color.clear) // Arka plan ContentView'daki Mesh Gradient'ı gösterir
        .offset(x: isMenuOpen ? 0 : -250)
        .frame(maxWidth: .infinity, alignment: .leading)
        // ✨ YENİ: Odak Sayacını Tam Ekran (Full Screen) Açan Bağlantı
        .fullScreenCover(isPresented: $showingFocusTimer) {
            FocusTimerView(taskVM: taskVM)
        }
    }
}

// MARK: - View Sub-Parts
private extension SidebarView {
    
    var dividerLine: some View {
        Divider()
            .background(Color.white.opacity(0.15))
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
    }
    
    var footerInfo: some View {
        Text("Yaver v2.5.0 • Senior Edition")
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(.white.opacity(0.3))
            .padding(24)
    }
    
    /// Merkezi Navigasyon Mantığı
    func navigate(to screen: ContentView.ScreenType, category: Category? = nil) {
        HapticManager.shared.triggerLightImpact()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedScreen = screen
            selectedCategory = category
            isMenuOpen = false
        }
    }
}
