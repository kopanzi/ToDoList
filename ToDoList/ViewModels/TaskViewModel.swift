import Foundation
import SwiftUI
import WidgetKit
import Combine

/// Uygulamanın görev yönetimini, oyunlaştırma (XP) sistemini ve görsel tetikleyicilerini yöneten ana ViewModel.
/// Senior Notu: @MainActor ile işaretlenmiştir, tüm UI güncellemeleri ana iş parçacığında güvenle yapılır.
/// Veri kayıplarını önlemek için AppGroup ve UserDefaults işlemleri 'do-catch' ile koruma altına alınmıştır.
@MainActor
final class TaskViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    
    /// Takvimden görev eklerken kullanılan geçici tarih tutucu
    @Published var defaultAdditionDate: Date? = nil
    
    /// Tüm görevlerin listesi. Değiştiğinde otomatik kaydeder ve UI temasını günceller.
    @Published var tasks: [TaskModel] = [] {
        didSet {
            saveAndSync()
            
            // Legacy uyumluluk: Tema manuel olsa bile ViewModel'in çökmemesi için tetikleyiciyi koruyoruz.
            AppearanceManager.shared.updateAppearance(with: tasks)
            
            // Rutin motoru arkadan görev eklerse sayacı otomatik hizala
            let absoluteTotal = tasks.count + archivedTasks.count
            if lifetimeAddedTasks < absoluteTotal {
                lifetimeAddedTasks = absoluteTotal
            }
        }
    }
    
    /// Kullanıcının toplam tecrübe puanı.
    @Published var userXP: Int = UserDefaults.standard.integer(forKey: "userXP") {
        didSet {
            UserDefaults.standard.set(userXP, forKey: "userXP")
            reloadWidgets()
        }
    }
    
    // MARK: - Ömür Boyu (Lifetime) Sayaçlar
    
    @Published var lifetimeAddedTasks: Int = UserDefaults.standard.integer(forKey: "lifetimeAddedTasks") {
        didSet { UserDefaults.standard.set(lifetimeAddedTasks, forKey: "lifetimeAddedTasks") }
    }
    
    @Published var lifetimeCompletedTasks: Int = UserDefaults.standard.integer(forKey: "lifetimeCompletedTasks") {
        didSet {
            UserDefaults.standard.set(lifetimeCompletedTasks, forKey: "lifetimeCompletedTasks")
            
            // Gerçek Zamanlı Güvenlik Kilidi: Tamamlanan sayısı, ekleneni geçemez!
            if lifetimeCompletedTasks > lifetimeAddedTasks {
                lifetimeAddedTasks = lifetimeCompletedTasks
            }
        }
    }
    
    /// Silinen görevlerin istatistik grafiklerinde yaşamasını sağlayan arşiv dizisi
    @Published var archivedTasks: [TaskModel] = [] {
        didSet { saveArchivedTasks() }
    }
    
    // MARK: - UI Tetikleyicileri
    @Published var isUnlocked: Bool = false      // Gizli Kasa biyometrik kilit durumu
    @Published var showConfetti: Bool = false    // Rütbe atlama veya büyük ödül kutlaması
    @Published var errorMessage: String? = nil   // UI'da gösterilecek hata mesajları
    
    // MARK: - Servisler (Dependencies)
    private let xpService = XPService.shared
    private let authService = AuthService.shared
    private let mediaManager = MediaManager.shared
    private let hapticManager = HapticManager.shared
    private let dataService = DataService.shared
    private let calendarService = CalendarService.shared
    
    // MARK: - XP Ayarları
    private struct XPRewards {
        static let newTask = 20
        static let dailyGoalBonus = 150
    }
    
    // MARK: - Initialization
    init() {
        loadTasks()
        AppearanceManager.shared.updateAppearance(with: tasks)
        loadArchivedTasks()
        validateLifetimeCounters()
    }
    
    // MARK: - Veri Yükleme & Doğrulama (Self-Healing)
    
    private func loadTasks() {
        self.tasks = dataService.loadTasks()
    }
    
    private func loadArchivedTasks() {
        guard let data = UserDefaults.standard.data(forKey: "yaver_archived_tasks_v1") else { return }
        do {
            self.archivedTasks = try JSONDecoder().decode([TaskModel].self, from: data)
        } catch {
            print("🛑 Arşiv Yükleme Hatası: \(error.localizedDescription)")
            self.archivedTasks = []
        }
    }
    
    private func saveArchivedTasks() {
        do {
            let encoded = try JSONEncoder().encode(archivedTasks)
            UserDefaults.standard.set(encoded, forKey: "yaver_archived_tasks_v1")
        } catch {
            print("🛑 Arşiv Kaydetme Hatası: \(error.localizedDescription)")
        }
    }
    
    /// Veri bozulmalarına karşı sayaçları onaran matematiksel zırh
    private func validateLifetimeCounters() {
        let absoluteTotalTasks = tasks.count + archivedTasks.count
        let absoluteCompletedTasks = tasks.filter { $0.isCompleted }.count + archivedTasks.count
        
        if lifetimeAddedTasks < absoluteTotalTasks {
            lifetimeAddedTasks = absoluteTotalTasks
        }
        
        if lifetimeCompletedTasks < absoluteCompletedTasks {
            lifetimeCompletedTasks = absoluteCompletedTasks
        }
        
        if lifetimeCompletedTasks > lifetimeAddedTasks {
            lifetimeAddedTasks = lifetimeCompletedTasks
        }
    }
    
    private func saveAndSync() {
        dataService.saveTasks(tasks)
        reloadWidgets()
    }
    
    // MARK: - Filtreleme ve Akıllı Sıralama
    
    func getFilteredTasks(category: Category?, showPrivate: Bool, searchText: String) -> [TaskModel] {
        var result = tasks
        
        // 1. Gizlilik Filtresi
        result = result.filter { $0.isPrivate == showPrivate }
        
        // 2. Kategori Filtresi
        if !showPrivate, let category = category {
            result = result.filter { $0.category == category }
        }
        
        // 3. Arama Filtresi
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // 4. Akıllı Sıralama (Smart Sorting)
        return result.sorted {
            // Kural 1: Tamamlanmamışlar üstte kalır
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            
            // Kural 2: Akıllı Yığılma (Stacking) Önceliği - Çok Gecikenler Üste!
            let delay0 = $0.delayedCount ?? 0
            let delay1 = $1.delayedCount ?? 0
            if delay0 != delay1 && !$0.isCompleted {
                return delay0 > delay1
            }
            
            // Kural 3: En son eklenen en üstte görünür
            return $0.createdAt > $1.createdAt
        }
    }
    
    // MARK: - Görev CRUD (Create, Read, Update, Delete)
    
    func addTask(title: String, priority: Priority, date: Date, category: Category?, isPrivate: Bool, isReminderEnabled: Bool = false, images: [UIImage] = []) {
        let newTask = TaskModel(
            title: title,
            isCompleted: false,
            priority: priority,
            category: category,
            createdAt: date,
            isPrivate: isPrivate
        )
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            tasks.append(newTask)
        }
        
        if !images.isEmpty { addImages(to: newTask, images: images) }
        
        addXP(amount: XPRewards.newTask)
        lifetimeAddedTasks += 1
        
        if isReminderEnabled {
            NotificationManager.shared.scheduleNotification(for: newTask)
        }
        
        hapticManager.triggerLightImpact()
    }
    
    func deleteTask(at offsets: IndexSet) {
        offsets.forEach { index in
            let task = tasks[index]
            TrashManager.shared.moveToTrash(task: task)
            NotificationManager.shared.cancelNotification(for: task.id)
            
            // Eğer görev tamamlanmışsa grafikleri korumak için arşive kopyala
            if task.isCompleted {
                var archivedTask = task
                archivedTask.note = "" // Ağır verileri temizle
                archivedTask.imageIDs = []
                archivedTask.audioID = nil
                archivedTasks.append(archivedTask)
            }
        }
        
        withAnimation(.easeOut(duration: 0.2)) {
            tasks.remove(atOffsets: offsets)
        }
        hapticManager.triggerMediumImpact()
    }
    
    func clearCompletedTasks() {
        let completed = tasks.filter { $0.isCompleted }
        guard !completed.isEmpty else { return }
        
        completed.forEach { task in
            TrashManager.shared.moveToTrash(task: task)
            NotificationManager.shared.cancelNotification(for: task.id)
            
            var archivedTask = task
            archivedTask.note = ""
            archivedTask.imageIDs = []
            archivedTask.audioID = nil
            archivedTasks.append(archivedTask)
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            tasks.removeAll { $0.isCompleted }
        }
        hapticManager.triggerHeavyImpact()
    }

    func restoreTask(_ task: TaskModel) {
        withAnimation(.spring()) {
            tasks.append(task)
        }
        // Çöpten geri yüklendiği için arşivden çıkar (İstatistiklerde çift sayılmasın)
        archivedTasks.removeAll { $0.id == task.id }
        
        saveAndSync()
        hapticManager.triggerSuccess()
    }
    
    func toggleCompletion(task: TaskModel) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        tasks[index].isCompleted.toggle()
        let isDone = tasks[index].isCompleted
        
        // Görev tamamlandığında saati kaydet
        tasks[index].completedAt = isDone ? Date() : nil
        
        if isDone {
            NotificationManager.shared.cancelNotification(for: task.id)
            // Rutin serisini artır
            if let rID = task.routineID {
                RoutineManager.shared.incrementStreak(for: rID)
            }
        }
        
        // XP Hesaplama ve Geri Dönüş Bonusu
        var xpChange = xpService.calculateXP(for: tasks[index], isCompleted: isDone)
        if isDone, let delayCount = tasks[index].delayedCount, delayCount > 1 {
            xpChange += (delayCount * 10)
        }
        
        addXP(amount: xpChange)
        
        if isDone {
            lifetimeCompletedTasks += 1
            checkDailyBonus()
            hapticManager.triggerSuccess()
        } else {
            if lifetimeCompletedTasks > 0 { lifetimeCompletedTasks -= 1 }
            hapticManager.triggerWarning()
        }
    }
    
    private func checkDailyBonus() {
        let calendar = Calendar.current
        let todayCompletedCount = tasks.filter {
            $0.isCompleted && calendar.isDateInToday($0.createdAt)
        }.count
        
        if todayCompletedCount == 5 {
            addXP(amount: XPRewards.dailyGoalBonus)
            self.errorMessage = "🔥 Günlük 5 Görev Tamamlandı! +150 XP Bonus!"
            triggerLevelUpEffect()
        }
    }
    
    func updateTaskNote(task: TaskModel, newNote: String) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].note = newNote
        }
    }

    // MARK: - Özel İşlemler (Erteleme ve Öncelik)
    
    func postponeTask(task: TaskModel) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        NotificationManager.shared.cancelNotification(for: task.id)
        
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: tasks[index].createdAt) {
            withAnimation(.spring()) {
                tasks[index].createdAt = newDate
                // Erteleme yükünü artır
                tasks[index].delayedCount = (tasks[index].delayedCount ?? 0) + 1
            }
            
            if !tasks[index].isCompleted {
                NotificationManager.shared.scheduleNotification(for: tasks[index])
            }
        }
        hapticManager.triggerLightImpact()
    }
    
    func prioritizeTask(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            withAnimation(.spring()) {
                tasks[index].priority = .urgent
            }
            hapticManager.triggerSuccess()
        }
    }

    // MARK: - Oyunlaştırma (XP & Rütbe)
    
    private func addXP(amount: Int) {
        let oldRank = currentRank
        userXP += amount
        if userXP < 0 { userXP = 0 }
        
        if currentRank.rawValue > oldRank.rawValue && amount > 0 {
            triggerLevelUpEffect()
        }
    }
    
    var currentRank: Rank {
        xpService.getCurrentRank(for: userXP)
    }
    
    private func triggerLevelUpEffect() {
        showConfetti = true
        hapticManager.triggerHeavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.showConfetti = false
        }
    }
    
    // MARK: - Güvenlik (Auth)
    
    func authenticate() {
        Task {
            do {
                let success = try await authService.authenticate(reason: "Gizli görevlerinize erişmek için doğrulama yapın.")
                self.isUnlocked = success
                if success {
                    hapticManager.triggerSuccess()
                } else {
                    self.errorMessage = "Kimlik doğrulaması başarısız."
                }
            } catch {
                self.isUnlocked = false
                self.errorMessage = error.localizedDescription
                hapticManager.triggerError()
            }
        }
    }
    
    func lockVault() {
        isUnlocked = false
    }
    
    // MARK: - Medya ve Takvim
    
    func addImages(to task: TaskModel, images: [UIImage]) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        for image in images {
            if let id = mediaManager.saveImage(image) {
                tasks[index].imageIDs.append(id)
            }
        }
        hapticManager.triggerLightImpact()
    }
    
    func addToCalendar(task: TaskModel) {
        Task {
            do {
                let hasAccess = try await calendarService.requestAccess()
                if hasAccess {
                    try calendarService.saveTaskToCalendar(task: task)
                    hapticManager.triggerSuccess()
                } else {
                    self.errorMessage = "Takvim erişim izni alınamadı."
                    hapticManager.triggerError()
                }
            } catch {
                print("🛑 Takvim Hatası: \(error.localizedDescription)")
                self.errorMessage = "Görev takvime eklenemedi."
                hapticManager.triggerError()
            }
        }
    }
    
    // MARK: - Widget Entegrasyonu
    
    private func reloadWidgets() {
        // AppGroup Data Sharing (Widget'ların ana uygulamadan veri çekebilmesi için)
        if let defaults = UserDefaults(suiteName: "group.com.kopanzi.yaver") {
            do {
                let encodedTasks = try JSONEncoder().encode(tasks)
                defaults.set(encodedTasks, forKey: "yaver_tasks_v2")
                defaults.set(userXP, forKey: "userXP")
            } catch {
                print("🛑 Widget Data Sync Hatası: \(error.localizedDescription)")
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
