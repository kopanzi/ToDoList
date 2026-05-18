import SwiftUI
import FirebaseAuth

/// Yan menü navigasyonunu yöneten ana orkestratör bileşen.
struct SidebarView: View {
    // MARK: - Properties
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // Navigasyon durumları
    @Binding var isMenuOpen: Bool
    @Binding var selectedScreen: ContentView.ScreenType
    @Binding var selectedCategory: Category?
    
    // Alt sayfalar ve Modallar
    @State private var showingFocusTimer = false
    @State private var showingLoginSheet = false
    
    // Kullanıcının giriş yapıp yapmadığını anlık takip eden state
    @State private var isLoggedIn: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. ÜST PROFİL VE RÜTBE BÖLÜMÜ
            SidebarHeaderView(
                rankName: taskVM.currentRank.name,
                rankIcon: taskVM.currentRank.icon,
                xp: taskVM.userXP,
                progress: XPService.shared.getProgressPercentage(xp: taskVM.userXP)
            )
            
            // 2. MENÜ LİSTESİ
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
                    
                    // ARAÇLAR (TOOLS) BÖLÜMÜ
                    Group {
                        SidebarMenuItemView(
                            title: "Rutinlerim",
                            icon: "repeat.circle.fill",
                            isSelected: selectedScreen == .routines
                        ) { navigate(to: .routines) }
                        
                        SidebarMenuItemView(
                            title: "Odak Sayacı",
                            icon: "timer",
                            isSelected: false
                        ) {
                            HapticManager.shared.triggerLightImpact()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isMenuOpen = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showingFocusTimer = true }
                        }
                        
                        SidebarMenuItemView(
                            title: "Çöp Kutusu",
                            icon: "trash.fill",
                            isSelected: selectedScreen == .trash
                        ) { navigate(to: .trash) }
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
            
            // ✨ SENIOR FIX: Ayarlar ile buton arasına minimum nefes alma boşluğu eklendi.
            // Bu sayede buton her zaman aşağı doğru itilecek.
            Spacer(minLength: 30)
            
            // ✨ 3. DİNAMİK BULUT SENKRONİZASYON BUTONU (Senior iOS Tasarımı)
            if !isLoggedIn {
                Button(action: {
                    HapticManager.shared.triggerMediumImpact()
                    showingLoginSheet = true
                }) {
                    HStack(spacing: 12) {
                        // iOS 17/18 Standartlarına uygun şık, ince profil ikonu
                        Image(systemName: "person.crop.circle.badge.icloud")
                            .font(.system(size: 30, weight: .light))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(appearance.accentColor, .primary.opacity(0.7))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bulut Senkronizasyonu")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(1) // ✨ SENIOR FIX: Kesinlikle tek satır kalacak
                                .minimumScaleFactor(0.8) // Sığmazsa hafif küçülecek
                            
                            Text("Apple veya Google ile bağlan ya da misafir olarak kullan")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(2) // Taşmayı önler, sidebar'ı kaydırmaz
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer(minLength: 0)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                    .padding(12)
                    // Kaba değil, sistemin doğal akışına uyan çok hafif bir zemin
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.primary.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4) // ✨ SENIOR FIX: Butonu alt yazıya (footer) daha da yaklaştırdık (12'den 4'e indi)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // SÜRÜM BİLGİSİ
            footerInfo
        }
        .frame(maxWidth: 250)
        .frame(maxHeight: .infinity)
        .background(
            Color.primary.opacity(0.02)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle().frame(width: 1).foregroundColor(Color.primary.opacity(0.05)),
                    alignment: .trailing
                )
                .ignoresSafeArea()
        )
        .offset(x: isMenuOpen ? 0 : -250)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fullScreenCover(isPresented: $showingFocusTimer) { FocusTimerView(taskVM: taskVM) }
        
        // Yaver Premium Giriş Ekranı
        .sheet(isPresented: $showingLoginSheet) {
            PremiumLoginSheet()
        }
        
        // Giriş Durumunu Dinle
        .onAppear {
            isLoggedIn = Auth.auth().currentUser != nil
            _ = Auth.auth().addStateDidChangeListener { _, user in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.isLoggedIn = (user != nil)
                }
            }
        }
    }
}

// MARK: - View Sub-Parts
private extension SidebarView {
    var dividerLine: some View {
        Divider()
            .background(Color.primary.opacity(0.1))
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
    }
    var footerInfo: some View {
        Text("YAVER İLE HAYATI PLANLA")
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundColor(.secondary)
            // ✨ SENIOR FIX: Her yönden 24 px padding vermek yerine, yukarıdaki padding'i tıraşlayıp butona yer açtık.
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .padding(.top, 4)
    }
    func navigate(to screen: ContentView.ScreenType, category: Category? = nil) {
        HapticManager.shared.triggerLightImpact()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedScreen = screen
            selectedCategory = category
            isMenuOpen = false
        }
    }
}

// MARK: - ✨ PREMIUM LOGIN SHEET (Kusursuz Boyutlandırma)
struct PremiumLoginSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            
            Spacer().frame(height: 35) // Üstten zarif bir boşluk
            
            // Güvenlik ve Bulut İkonu
            Image(systemName: "lock.icloud.fill")
                .font(.system(size: 55))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .padding(.bottom, 20)
            
            // Başlık ve Güvenlik Mesajı (Microcopy)
            VStack(spacing: 12) {
                Text("Verileriniz Bizimle Güvende")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Anılarınız ve planlarınız cihazınızda kalmasın. Ücretsiz giriş yaparak verilerinizi bulutta şifreleyin. Cihazınız değişse bile hayatınız kaldığı yerden devam etsin.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .lineSpacing(4)
            }
            .padding(.bottom, 35) // İkon ve butonlar arası nefes alma payı
            
            // Giriş Butonları
            VStack(spacing: 14) {
                Button(action: {
                    HapticManager.shared.triggerMediumImpact()
                    Task {
                        try? await AuthManager.shared.signInWithApple()
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.system(size: 20))
                        Text("Apple ile Devam Et")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.primary)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .cornerRadius(14)
                }
                
                Button(action: {
                    HapticManager.shared.triggerMediumImpact()
                    Task {
                        try? await AuthManager.shared.signInWithGoogle()
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                        Text("Google ile Devam Et")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(14)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Gizlilik Politikası Uyarısı
            Text("Giriş yaparak Gizlilik Politikası ve Şartlar'ı kabul etmiş olursunuz.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        // ✨ SENIOR FIX: %65'ten %75'e çıkarıldı, içerik daraltıldı. Artık kesilme yok!
        .presentationDetents([.fraction(0.55), .large])
        // ✨ SENIOR FIX: Sahte çizgi yerine Apple'ın resmi şık tutamacı eklendi
        .presentationDragIndicator(.visible)
    }
}
