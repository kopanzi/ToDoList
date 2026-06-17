import SwiftUI

/// Görevlerin listelendiği ana ekran. (Adaptive Design)
/// Senior Notu: Tüm statik renkler (örn. .white, .black) kaldırılarak
/// Apple'ın Semantik renkleri (.primary, .secondary) ve Material tasarım dilleri kullanıldı.
/// Bu sayede aydınlık ve karanlık modda kusursuz okunabilirlik sağlanır.
struct TaskListView: View {
    // MARK: - Quick Filter Enum
    enum QuickFilter: Equatable {
        case all
        case urgent
        case category(Category)
    }
    
    // MARK: - Properties
    @ObservedObject var viewModel: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    var filterCategory: Category?
    var showPrivateOnly: Bool = false
    var onMenuTap: () -> Void
    
    @State private var searchText: String = ""
    @State private var showingAddTask = false
    @State private var selectedTab: BottomTab = .home
    
    // Filtreleme ve Gruplandırma State'leri
    @State private var selectedQuickFilter: QuickFilter = .all
    @State private var isCompletedSectionExpanded: Bool = false
    
    // ✨ ZEN MODU STATE'LERİ
    @State private var zenTaskToFocus: TaskModel? = nil
    @State private var zenMagnification: CGFloat = 1.0 // Pinch to zoom efekti için
    
    @AppStorage("userName") private var userName: String = "Sio Kullanıcısı"
    
    enum BottomTab { case home, schedule, stats, profile }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 1. DİNAMİK ANA İÇERİK
                Group {
                    switch selectedTab {
                    case .home:
                        homeContent
                            // ✨ PINCH TO ZOOM GESTURE (İki parmakla yakınlaştırarak Zen Moduna gir)
                            .scaleEffect(zenMagnification)
                            .simultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { val in
                                        if getZenTask() != nil {
                                            // Sadece büyütmeye izin ver (küçültme yok)
                                            withAnimation(.interactiveSpring()) {
                                                zenMagnification = max(1.0, val)
                                            }
                                        }
                                    }
                                    .onEnded { val in
                                        if val > 1.3 && getZenTask() != nil {
                                            HapticManager.shared.triggerHeavyImpact()
                                            zenTaskToFocus = getZenTask()
                                        }
                                        withAnimation(.spring()) {
                                            zenMagnification = 1.0
                                        }
                                    }
                            )
                    case .schedule:
                        CalendarView(taskVM: viewModel, onMenuTap: onMenuTap)
                            .transition(.opacity)
                    case .stats:
                        StatisticsView()
                            .transition(.opacity)
                    case .profile:
                        ProfileView(taskVM: viewModel)
                            .transition(.opacity)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 2. ALT NAVİGASYON BARI
                if selectedTab == .home || selectedTab == .stats {
                    bottomNavigationBar
                        .transition(.move(edge: .bottom))
                } else if selectedTab == .schedule || selectedTab == .profile {
                    bottomNavigationBar
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel, isPrivateDefault: showPrivateOnly)
            }
            // ✨ ZEN MODU TAM EKRAN KAPLAMASI
            .fullScreenCover(item: $zenTaskToFocus) { task in
                ZenFocusView(task: task, viewModel: viewModel) {
                    zenTaskToFocus = nil
                }
            }
        }
    }
}

// MARK: - Custom UI Components
private extension TaskListView {
    
    // MARK: Home Content (Görevler Ana Sayfası)
    var homeContent: some View {
        // 1. Temel Filtreleme
        var tasks = viewModel.getFilteredTasks(category: filterCategory, showPrivate: showPrivateOnly, searchText: searchText)
        
        // 2. Hızlı Filtreleme
        if filterCategory == nil && !showPrivateOnly {
            switch selectedQuickFilter {
            case .all: break
            case .urgent: tasks = tasks.filter { $0.priority == .urgent }
            case .category(let cat): tasks = tasks.filter { $0.category == cat }
            }
        }
        
        // 3. Akıllı Gruplandırma Verileri
        let activeTasks = tasks.filter { !$0.isCompleted }
        let completedTasks = tasks.filter { $0.isCompleted }
        
        let urgentTasks = activeTasks.filter { $0.priority == .urgent }
        let standardTasks = activeTasks.filter { $0.priority != .urgent }
        
        return List {
            // --- 1. ÜST BÖLÜM (Header, Arama, Baloncuklar) ---
            VStack(spacing: 24) {
                customTopBar
                customSearchBar
                
                if filterCategory == nil && !showPrivateOnly {
                    quickFilterPills
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 10)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            
            // --- 2. GÖREVLER (AKILLI BÖLÜMLENDİRME) ---
            if tasks.isEmpty {
                EmptyStateView(
                    title: showPrivateOnly ? "Kasa Boş" : "Görev Yok",
                    icon: showPrivateOnly ? "lock.shield" : (filterCategory?.icon ?? "checklist"),
                    description: "Yeni bir görev ekleyerek başlayabilirsin."
                )
                .padding(.top, 40)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                
                // 🔥 ÇOK ACİL BÖLÜMÜ
                if !urgentTasks.isEmpty {
                    if selectedQuickFilter == .urgent {
                        sectionHeader(title: "🔥 " + sectionTitle, color: .purple)
                        ForEach(urgentTasks) { task in taskRowWrapper(task: task) }
                    } else {
                        sectionHeader(title: "🔥 Çok Acil", color: .purple)
                        ForEach(urgentTasks) { task in taskRowWrapper(task: task) }
                        
                        if !standardTasks.isEmpty {
                            sectionHeader(title: "🎯 " + sectionTitle, color: .primary)
                            ForEach(standardTasks) { task in taskRowWrapper(task: task) }
                        }
                    }
                }
                // 🎯 STANDART BÖLÜM
                else if !standardTasks.isEmpty {
                    sectionHeader(title: "🎯 " + sectionTitle, color: .primary)
                    ForEach(standardTasks) { task in taskRowWrapper(task: task) }
                }
                
                // 📦 TAMAMLANANLAR BÖLÜMÜ (Akordiyon)
                if !completedTasks.isEmpty {
                    completedSectionHeader(count: completedTasks.count)
                    
                    if isCompletedSectionExpanded {
                        ForEach(completedTasks) { task in taskRowWrapper(task: task) }
                    }
                }
            }
            
            // --- 3. ALT BOŞLUK ---
            Color.clear
                .frame(height: 100)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        // Arka planı ContentView'daki Sistem Rengine devreder
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }
    
    // MARK: - Zen Mode Helpers
    
    func getZenTask() -> TaskModel? {
        let activeTasks = viewModel.tasks.filter { !$0.isCompleted && !$0.isPrivate }
        guard !activeTasks.isEmpty else { return nil }
        
        func priorityScore(_ p: Priority) -> Int {
            switch p { case .urgent: return 4; case .high: return 3; case .medium: return 2; case .low: return 1 }
        }
        
        return activeTasks.sorted { t1, t2 in
            let p1 = priorityScore(t1.priority)
            let p2 = priorityScore(t2.priority)
            if p1 != p2 { return p1 > p2 }
            return t1.createdAt < t2.createdAt
        }.first
    }
    
    // MARK: - Smart Section Helpers
    
    @ViewBuilder
    func sectionHeader(title: String, color: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
        }
        .font(.title3.bold())
        .foregroundColor(color)
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .padding(.bottom, 5)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    func completedSectionHeader(count: Int) -> some View {
        HStack {
            Button(action: {
                HapticManager.shared.triggerSelection()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isCompletedSectionExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isCompletedSectionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                    Text("Tamamlananlar (\(count))")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.triggerHeavyImpact()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.clearCompletedTasks()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                    Text("TEMİZLE")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.red.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.15))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 5)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    func taskRowWrapper(task: TaskModel) -> some View {
        ZStack {
            TaskRowView(task: task, viewModel: viewModel)
            
            NavigationLink(destination: TaskDetailView(task: task, viewModel: viewModel)) {
                EmptyView()
            }
            .opacity(0)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if task.routineID != nil {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        RoutineManager.shared.skipRoutineTask(task, taskViewModel: viewModel)
                    }
                } label: {
                    Label("Bugünü Atla", systemImage: "forward.end.fill")
                }
                .tint(.blue)
            } else {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.postponeTask(task: task)
                    }
                } label: {
                    Label("Ertele", systemImage: "clock.arrow.2.circlepath")
                }
                .tint(.orange)
            }
            
            if task.priority != .urgent {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.prioritizeTask(task: task)
                    }
                } label: {
                    Label("Acil", systemImage: "flame.fill")
                }
                .tint(.purple)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HapticManager.shared.triggerMediumImpact()
                if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                    viewModel.deleteTask(at: IndexSet(integer: index))
                }
            } label: {
                Label("Sil", systemImage: "trash")
            }
            .tint(.red)
        }
    }
    
    // MARK: Quick Filter Pills
    var quickFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                
                // ✨ ZEN MODU BUTONU
                if getZenTask() != nil {
                    Button(action: {
                        HapticManager.shared.triggerHeavyImpact()
                        zenTaskToFocus = getZenTask()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "target")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.orange)
                            
                            Text("Zen")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(uiColor: .tertiarySystemFill))
                                .background(.ultraThinMaterial)
                        )
                        .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                
                let activeColor = appearance.accentColor
                
                filterPill(title: "Tümü", icon: "tray.fill", activeColor: activeColor, isSelected: selectedQuickFilter == .all) {
                    selectedQuickFilter = .all
                }
                
                filterPill(title: "Acil", icon: "flame.fill", activeColor: .orange, isSelected: selectedQuickFilter == .urgent) {
                    selectedQuickFilter = .urgent
                }
                
                ForEach(Category.allCases) { cat in
                    filterPill(title: cat.rawValue, icon: cat.icon, activeColor: cat.color, isSelected: selectedQuickFilter == .category(cat)) {
                        selectedQuickFilter = .category(cat)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // ✨ SENIOR FIX: Pill'ler ZStack ile yeniden kurgulandı (Adaptive UI)
    func filterPill(title: String, icon: String, activeColor: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.triggerSelection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(isSelected ? activeColor : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if !isSelected {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                    Capsule()
                        // Aydınlık ve karanlık moda tam uyumlu sistem dolgusu
                        .fill(isSelected ? activeColor.opacity(0.15) : Color(uiColor: .tertiarySystemFill))
                }
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? activeColor.opacity(0.4) : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: Top Bar
    var customTopBar: some View {
        HStack(spacing: 16) {
            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 12) {
                AvatarView(size: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(timeBasedGreeting),")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(userName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.triggerLightImpact()
                showingAddTask = true
            }) {
                ZStack {
                    Circle()
                        .fill(appearance.accentColor)
                        .frame(width: 44, height: 44)
                        .shadow(color: appearance.accentColor.opacity(0.4), radius: 10, x: 0, y: 0)
                    
                    // Artı ikonu temaya binsin diye her zaman beyaz kalır
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: Search Bar
    var customSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 18))
            
            TextField("Görev, proje ara...", text: $searchText)
                .foregroundColor(.primary)
                .font(.system(size: 16))
                .submitLabel(.search)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        // Adaptive arkaplan form stili
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: Bottom Nav Bar
    var bottomNavigationBar: some View {
        HStack {
            navButton(icon: "house.fill", title: "Ana Sayfa", tab: .home)
            Spacer()
            navButton(icon: "calendar", title: "Takvim", tab: .schedule)
            Spacer()
            navButton(icon: "chart.bar.fill", title: "İstatistikler", tab: .stats)
            Spacer()
            navButton(icon: "person.fill", title: "Profil", tab: .profile)
        }
        .padding(.horizontal, 30)
        .padding(.top, 16)
        .padding(.bottom, 15)
        // ✨ SENIOR FIX: Sabit siyah yerine Apple'ın buzlu cam tabakası
        .background(.thickMaterial)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(Color.primary.opacity(0.05)),
            alignment: .top
        )
    }
    
    func navButton(icon: String, title: String, tab: BottomTab) -> some View {
        let isSelected = selectedTab == tab
        let activeColor = appearance.accentColor
        
        return Button(action: {
            HapticManager.shared.triggerLightImpact()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? activeColor : .secondary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? activeColor : .secondary)
            }
            .frame(width: 60)
        }
    }
    
    // MARK: - Helpers
    var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Günaydın"
        case 12..<17: return "İyi Günler"
        case 17..<22: return "İyi Akşamlar"
        default: return "İyi Geceler"
        }
    }
    
    var sectionTitle: String {
        if showPrivateOnly { return "Gizli Kasa" }
        if let category = filterCategory { return "\(category.rawValue) Görevleri" }
        
        switch selectedQuickFilter {
        case .all: return "Bugünün Odak Noktası"
        case .urgent: return "Acil Görevler"
        case .category(let cat): return "\(cat.rawValue) Görevleri"
        }
    }
}

// MARK: - ✨ ZEN ODAK MODU GÖRÜNÜMÜ ✨
/// Yaver'in gizli silahı. Dönen ruhani ateş çemberleri ile birlikte tek bir göreve odaklanmayı sağlar.
/// Senior Notu: Zen modu, doğası gereği odaklanmak için her zaman karanlık modda (Immersive Dark) kalmalıdır.
struct ZenFocusView: View {
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    var onExit: () -> Void
    
    // Aura Efekt Durumları
    @State private var isRotatingOut = false
    @State private var isRotatingIn = false
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Zen modu her zaman karanlıktır (Odak için)
            Color(hex: "050505").ignoresSafeArea()
            
            // ✨ RUHANİ ATEŞ ÇEMBERLERİ
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [.orange, .red, .pink, .purple, .orange]), center: .center),
                        lineWidth: 30
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 20)
                    .rotationEffect(.degrees(isRotatingOut ? 360 : 0))
                
                Circle()
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [.yellow, .orange, .clear, .yellow]), center: .center),
                        lineWidth: 15
                    )
                    .frame(width: 250, height: 250)
                    .blur(radius: 10)
                    .rotationEffect(.degrees(isRotatingIn ? -360 : 0))
            }
            .scaleEffect(isPulsing ? 1.05 : 0.95)
            .opacity(isPulsing ? 0.9 : 0.6)
            
            // 🎯 ANA İÇERİK
            VStack(spacing: 40) {
                Text("MUTLAK ODAK")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(.orange)
                    .tracking(6)
                    .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 24) {
                    if let category = task.category {
                        Text(category.rawValue.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(category.color.opacity(0.2))
                            .foregroundColor(category.color)
                            .clipShape(Capsule())
                    }
                    
                    Text(task.title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 30)
                }
                
                Spacer()
                
                VStack(spacing: 25) {
                    Button(action: {
                        HapticManager.shared.triggerHeavyImpact()
                        viewModel.toggleCompletion(task: task)
                        onExit()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("BİTİRDİM")
                        }
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(20)
                        .shadow(color: .orange.opacity(0.5), radius: 15, x: 0, y: 10)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        onExit()
                    }) {
                        Text("Vazgeç ve Çık")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { isRotatingOut = true }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { isRotatingIn = true }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { isPulsing = true }
        }
    }
}
