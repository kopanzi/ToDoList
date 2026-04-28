import SwiftUI

/// Uygulamanın navigasyon ve görsel katman yöneticisi.
/// Senior Notu: Biyometrik güvenlik kontrolleri (LockScreen) araya girerek,
/// gizli ekranlara yetkisiz erişimi katman düzeyinde engeller.
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
    // ✨ SENIOR FIX: 'routines' rotası eklendi, Type hataları çözüldü!
    enum ScreenType { case tasks, notes, settings, hiddenTasks, hiddenNotes, trash, routines }
    
    var body: some View {
        ZStack {
            // 🎨 KATMAN 1: GLOBAL ARKA PLAN (En Altta) ✅
            layerBackground(
                for: appearance.sidebarStyle,
                meshColors: appearance.sidebarMeshColors,
                solidColor: appearance.sidebarTheme.mainColor
            )
            .ignoresSafeArea()
            
            // 📝 KATMAN 2: AI MOTTO FİLİGRAN ✅
            if appearance.isAIMottoEnabled {
                mottoWatermarkLayer
            }
            
            // 🍔 KATMAN 3: SIDEBAR İÇERİĞİ
            SidebarView(
                taskVM: taskVM,
                isMenuOpen: $isMenuOpen,
                selectedScreen: $selectedScreen,
                selectedCategory: $selectedCategory
            )
            
            // 📲 KATMAN 4: ANA PENCERE (İçerik Alanı) ✅
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
        // Görevler değiştiğinde görünümü güncelle
        .onReceive(taskVM.$tasks) { tasks in
            appearance.updateAppearance(with: tasks)
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

private extension ContentView {
    
    var mainContentWindow: some View {
        ZStack {
            // ANA EKRANIN KENDİ ARKA PLANI
            Group {
                if appearance.mainScreenStyle == .glass {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(1.0 - appearance.mainScreenOpacity)
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
            
            if isMenuOpen {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture { toggleMenu() }
            }
            
            edgeDragHandler
        }
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
            if #available(iOS 18.0, *) {
                MeshGradientView(colors: meshColors).blur(radius: 25)
            } else {
                Color.clear.background(.ultraThinMaterial)
            }
        case .solid:
            AppearanceManager.Palette.bgDark
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
            
        // ✨ SENIOR FIX: Rutinler sayfası buraya bağlandı, geri tuşu aktif!
        case .routines:
            RoutinesView(onBackTap: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedScreen = .tasks
                }
            })
            
        // ✨ GİZLİ GÖREVLER KASASI (KİLİTLİ)
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
                // Ekrana girer girmez yüz tanımayı otomatik tetikle
                .onAppear { taskVM.authenticate() }
            }
            
        case .notes:
            NoteListView(viewModel: noteVM, onMenuTap: toggleMenu)
            
        // ✨ GİZLİ NOTLAR KASASI (KİLİTLİ)
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
                // Ekrana girer girmez yüz tanımayı otomatik tetikle
                .onAppear { noteVM.authenticateForPrivateNotes() }
            }
            
        case .settings:
            SettingsView(viewModel: settingsVM, taskVM: taskVM, onMenuTap: toggleMenu)
            
        case .trash:
            TrashView(taskVM: taskVM, noteVM: noteVM, onMenuTap: toggleMenu)
        }
    }
    
    var mottoWatermarkLayer: some View {
        VStack {
            Spacer()
            Text(appearance.dailyMotto)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.06))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 140)
                .rotationEffect(.degrees(-7))
        }
        .allowsHitTesting(false)
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
