import SwiftUI

/// Uygulamanın navigasyon ve görsel katman yöneticisi.
/// Senior Notu: Biyometrik güvenlik kontrolleri (LockScreen) araya girerek,
/// gizli ekranlara yetkisiz erişimi katman düzeyinde engeller.
/// Dinamik motto ve duygu durumu özellikleri tamamen kaldırılarak "Manual Pro" tasarıma geçilmiştir.
struct ContentView: View {
    // MARK: - State Management
    @Environment(\.scenePhase) var scenePhase // ✨ SENIOR FIX: Hayalet çalışanı uyandırmak için uygulama durumunu dinler
    
    @StateObject private var appearance = AppearanceManager.shared
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var noteVM = NoteViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    
    @State private var isMenuOpen = false
    @State private var selectedScreen: ScreenType = .tasks
    @State private var selectedCategory: Category? = nil
    @GestureState private var dragOffset: CGFloat = 0
    
    // Uygulama Rotaları
    enum ScreenType { case tasks, notes, settings, hiddenTasks, hiddenNotes, trash, routines }
    
    var body: some View {
        ZStack {
            // 🎨 KATMAN 1: GLOBAL ARKA PLAN (En Altta - Genellikle Sidebar'ı renklendirir)
            layerBackground(
                for: appearance.sidebarStyle,
                meshColors: appearance.sidebarMeshColors,
                solidColor: appearance.sidebarTheme.mainColor
            )
            .ignoresSafeArea()
            
            // 🧹 KATMAN 2: Motto filigranı tamamen kaldırıldı. Artık temiz ve sade bir arayüz var.
            
            // 🍔 KATMAN 3: SIDEBAR İÇERİĞİ
            SidebarView(
                taskVM: taskVM,
                isMenuOpen: $isMenuOpen,
                selectedScreen: $selectedScreen,
                selectedCategory: $selectedCategory
            )
            
            // 📲 KATMAN 4: ANA PENCERE (İçerik Alanı)
            mainContentWindow
        }
        .environmentObject(appearance)
        .environmentObject(taskVM)
        .environmentObject(noteVM)
        .environmentObject(settingsVM)
        // 🛠️ TÜM LİSTELERİ VE FORMLARI ŞEFFAFLIĞA ZORLA (Global Fix)
        .onAppear {
            UITableView.appearance().backgroundColor = .clear
            UICollectionView.appearance().backgroundColor = .clear
        }
        // ✨ SENIOR FIX: AUTO-LOCK (Kullanıcı sekme değiştirdiğinde kasalar anında kilitlenir!)
        .onChange(of: selectedScreen) { _, newScreen in
            if newScreen != .hiddenTasks {
                taskVM.lockVault()
            }
            if newScreen != .hiddenNotes {
                noteVM.lockVault()
            }
        }
        // ✨ YENİ: HAYALET ÇALIŞAN (Ghost Worker) UYANDIRMA MOTORU
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Kullanıcı uygulamaya her girdiğinde Motor çalışır!
                RoutineManager.shared.checkRoutines(with: taskVM)
            }
        }
    }
}

// MARK: - View Sub-Parts
private extension ContentView {
    
    var mainContentWindow: some View {
        ZStack {
            // ANA EKRANIN KENDİ ARKA PLANI
            Group {
                if appearance.mainScreenStyle == .glass {
                    // ✨ SENIOR FIX: Camın arkasında Ana Ekranın kendi Mesh Gradient renkleri dönecek!
                    layerBackground(
                        for: .glass,
                        meshColors: appearance.mainMeshColors, // Sidebar'ın değil, Ana Ekranın renkleri
                        solidColor: appearance.mainScreenTheme.mainColor
                    )
                    .opacity(appearance.mainScreenOpacity)
                    .overlay(Color.clear.background(.ultraThinMaterial)) // Cam efektini üstüne seriyoruz
                } else {
                    layerBackground(
                        for: appearance.mainScreenStyle,
                        meshColors: appearance.mainMeshColors,
                        solidColor: appearance.mainScreenTheme.mainColor
                    )
                    .opacity(appearance.mainScreenOpacity)
                    .background(Color(uiColor: .systemBackground))
                }
            }
            .ignoresSafeArea()
            
            // 📺 AKTİF EKRAN İÇERİĞİ VE KİLİT KONTROLÜ
            currentScreenView
                .scrollContentBackground(.hidden)
            
            // Menü açıkken içeriğe tıklandığında menüyü kapatan kalkan
            if isMenuOpen {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture { toggleMenu() }
            }
            
            edgeDragHandler
        }
        // Sidebar açılış animasyonları
        .cornerRadius(isMenuOpen ? 30 : 0)
        .scaleEffect(isMenuOpen ? 0.84 : 1)
        .offset(x: isMenuOpen ? 250 : 0)
        .shadow(color: .black.opacity(isMenuOpen ? 0.3 : 0), radius: 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isMenuOpen)
        .ignoresSafeArea(edges: isMenuOpen ? [] : .all)
    }
    
    @ViewBuilder
    func layerBackground(for style: AppearanceManager.BackgroundStyle, meshColors: [Color], solidColor: Color) -> some View {
        switch style {
        case .glass:
            // ✨ SENIOR FIX: iOS 18 kontrolünü sildik çünkü MeshGradientView zaten
            // kendi içinde iOS 17 için harika bir yedek (fallback) barındırıyor!
            MeshGradientView(colors: meshColors).blur(radius: 25)
        case .solid:
            solidColor.opacity(0.1) // Saf siyah yerine temanın karanlık ama kendi rengine çalan bir tonu
        case .gradient:
            LinearGradient(colors: meshColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        case .standard:
            Color(uiColor: .systemBackground)
        }
    }
    
    @ViewBuilder
    var currentScreenView: some View {
        switch selectedScreen {
        case .tasks:
            TaskListView(viewModel: taskVM, filterCategory: selectedCategory, onMenuTap: toggleMenu)
            
        case .routines:
            RoutinesView(onBackTap: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedScreen = .tasks
                }
            })
            
        case .hiddenTasks:
            if taskVM.isUnlocked {
                TaskListView(viewModel: taskVM, showPrivateOnly: true, onMenuTap: toggleMenu)
            } else {
                LockScreenView(
                    icon: "lock.shield.fill",
                    title: "GİZLİ KASA",
                    subtitle: "Size özel görevlere erişmek için Yaver'e kimliğinizi doğrulayın.",
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
                    icon: "lock.doc.fill",
                    title: "GİZLİ NOTLAR",
                    subtitle: "Özel fikirlerinize erişmek için lütfen kimliğinizi doğrulayın.",
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
    
    var edgeDragHandler: some View {
        HStack {
            Color.clear
                .frame(width: 30)
                .contentShape(Rectangle())
                .gesture(DragGesture().onEnded { if $0.translation.width > 50 && !isMenuOpen { toggleMenu() } })
            Spacer()
        }
    }
    
    func toggleMenu() {
        HapticManager.shared.triggerLightImpact()
        withAnimation { isMenuOpen.toggle() }
    }
}
