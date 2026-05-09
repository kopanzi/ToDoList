import SwiftUI

/// Uygulamanın ana navigasyon, katman ve güvenlik yöneticisi.
/// Senior Notu: Mesh ve Gradient gibi yorucu arka planlar temizlenerek
/// %100 Apple HIG standartlarına uygun (Sistem Arka Planı) mimariye geçildi.
struct ContentView: View {
    // MARK: - State Management
    @Environment(\.scenePhase) private var scenePhase // Uygulama durumunu (arka plan/aktif) izler
    
    // Merkezi state instance'ları (Tüm uygulama bunları kullanır)
    @StateObject private var appearance = AppearanceManager.shared
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var noteVM = NoteViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    
    // Navigasyon ve UI Durumları
    @State private var isMenuOpen = false
    @State private var selectedScreen: ScreenType = .tasks
    @State private var selectedCategory: Category? = nil
    
    /// Uygulama rotalarını temsil eden enum
    enum ScreenType { case tasks, notes, settings, hiddenTasks, hiddenNotes, trash, routines }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 🎨 KATMAN 1: GLOBAL SIDEBAR ARKA PLANI
            // ✨ SENIOR FIX: Native Apple Sistem Arka Planı (Karanlıkta Siyah, Aydınlıkta Beyaz)
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // 🍔 KATMAN 2: SIDEBAR (YAN MENÜ)
            SidebarView(
                taskVM: taskVM,
                isMenuOpen: $isMenuOpen,
                selectedScreen: $selectedScreen,
                selectedCategory: $selectedCategory
            )
            
            // 📲 KATMAN 3: ANA PENCERE (İÇERİK ALANI)
            mainContentWindow
        }
        // Tüm alt görünümlere (View) ortam objelerini aktar
        .environmentObject(appearance)
        .environmentObject(taskVM)
        .environmentObject(noteVM)
        .environmentObject(settingsVM)
        
        // --- Global Konfigürasyonlar ---
        .onAppear {
            setupGlobalUI()
        }
        
        // ✨ SENIOR FIX: AUTO-LOCK (Kasa Güvenliği) & iOS 17 onChange Standardı
        .onChange(of: selectedScreen) { oldValue, newValue in
            handleAutoLock(for: newValue)
        }
        
        // ✨ GHOST WORKER: Uygulamaya her girişte rutinleri kontrol et
        .onChange(of: scenePhase) { oldValue, newPhase in
            if newPhase == .active {
                RoutineManager.shared.checkRoutines(with: taskVM)
            }
        }
    }
}

// MARK: - View Sub-Parts (Modüler Parçalar)
private extension ContentView {
    
    /// Ana ekranın çerçevesini, animasyonlarını ve kendi özel arka planını yönetir.
    var mainContentWindow: some View {
        ZStack {
            // 🎨 ANA EKRAN ARKA PLANI
            // ✨ SENIOR FIX: Listelerin kusursuz göründüğü gruplanmış sistem arka planı
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            // 📺 AKTİF EKRAN İÇERİĞİ
            currentScreenView
                .scrollContentBackground(.hidden) // Global liste temizliği
            
            // Menü açıkken içeriği karartan ve tıklanabilen koruma kalkanı
            if isMenuOpen {
                Color.black.opacity(0.01) // Neredeyse görünmez ama tıklamaları yakalar
                    .ignoresSafeArea()
                    .onTapGesture { toggleMenu() }
            }
            
            // Ekran kenarından çekerek menüyü açma desteği
            edgeDragHandler
        }
        // ✨ SENIOR FIX: Pürüzsüz köşeler için .continuous stili kullanıldı
        .clipShape(RoundedRectangle(cornerRadius: isMenuOpen ? 30 : 0, style: .continuous))
        .scaleEffect(isMenuOpen ? 0.86 : 1) // Hafifçe küçülterek ferahlatıcı (snappy) his yaratır
        .offset(x: isMenuOpen ? 260 : 0)
        // ✨ SENIOR FIX: Gölge şeffaflığı Adaptive (Aydınlık/Karanlık) yapıya uygun olması için hafifletildi
        .shadow(color: .black.opacity(isMenuOpen ? 0.15 : 0), radius: 25, x: -5, y: 0)
        // Apple HIG standartlarına uygun, hızlı ve yaylanan geçiş
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: isMenuOpen)
        .ignoresSafeArea(edges: isMenuOpen ? [] : .all)
    }
    
    /// Seçili sekmeye göre doğru ekranı döner. (Routing Katmanı)
    @ViewBuilder
    var currentScreenView: some View {
        switch selectedScreen {
        case .tasks:
            TaskListView(viewModel: taskVM, filterCategory: selectedCategory, onMenuTap: toggleMenu)
            
        case .routines:
            RoutinesView(onBackTap: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selectedScreen = .tasks }
            })
            
        case .hiddenTasks:
            if taskVM.isUnlocked {
                TaskListView(viewModel: taskVM, showPrivateOnly: true, onMenuTap: toggleMenu)
            } else {
                LockScreenView(
                    icon: "lock.shield.fill", title: "GİZLİ KASA",
                    subtitle: "Özel görevlerinize erişmek için lütfen doğrulama yapın.",
                    onUnlockTap: { taskVM.authenticate() }
                )
                .onAppear { taskVM.authenticate() }
            }
            
        case .notes:
            NoteListView(viewModel: noteVM, onMenuTap: toggleMenu)
            
        case .hiddenNotes:
            if noteVM.isUnlocked {
                NoteListView(viewModel: noteVM, showPrivateOnly: true, onMenuTap: toggleMenu)
            } else {
                LockScreenView(
                    icon: "lock.doc.fill", title: "GİZLİ NOTLAR",
                    subtitle: "Özel fikirlerinizi korumak için lütfen doğrulama yapın.",
                    onUnlockTap: { noteVM.authenticateForPrivateNotes() }
                )
                .onAppear { noteVM.authenticateForPrivateNotes() }
            }
            
        case .settings:
            SettingsView(viewModel: settingsVM, taskVM: taskVM, onMenuTap: toggleMenu)
            
        case .trash:
            TrashView(taskVM: taskVM, noteVM: noteVM, onMenuTap: toggleMenu)
        }
    }
    
    // MARK: - Navigation & Action Helpers
    
    func setupGlobalUI() {
        // iOS Listelerin arka plan rengini temizleyerek şeffaf görünümü garantiler
        UITableView.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
    }
    
    func handleAutoLock(for screen: ScreenType) {
        // Eğer hedef kilitli ekranlardan biri değilse, eski kilitli ekranı arkadan kitle
        if screen != .hiddenTasks { taskVM.lockVault() }
        if screen != .hiddenNotes { noteVM.lockVault() }
    }
    
    /// ✨ SENIOR FIX: Intent-Based Edge Swipe (Niyet Odaklı Kenar Çekmesi)
    var edgeDragHandler: some View {
        HStack {
            Color.clear
                .frame(width: 25) // Tutma alanı daraltılarak kazara açılmalar önlendi
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            // Sadece yeterince mesafe VEYA parmak hızı (velocity) yüksekse açılır
                            let isIntentionalPull = value.translation.width > 60 || value.predictedEndTranslation.width > 120
                            if isIntentionalPull && !isMenuOpen {
                                toggleMenu()
                            }
                        }
                )
            Spacer()
        }
    }
    
    func toggleMenu() {
        HapticManager.shared.triggerLightImpact()
        withAnimation { isMenuOpen.toggle() }
    }
}
