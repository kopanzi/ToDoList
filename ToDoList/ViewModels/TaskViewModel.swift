import Foundation
import SwiftUI
import WidgetKit
import Combine

/// Uygulamanın görev yönetimini, oyunlaştırma (XP) sistemini ve görsel tetikleyicilerini yöneten ana ViewModel.
/// Senior Notu: @MainActor ile işaretlenmiştir, böylece tüm UI güncellemeleri ana iş parçacığında güvenle yapılır.
@MainActor
final class TaskViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Takvimden görev eklerken kullanılan geçici tarih tutucu
    @Published var defaultAdditionDate: Date? = nil
    
    /// Tüm görevlerin listesi. Değiştiğinde otomatik kaydeder ve UI temasını günceller.
    @Published var tasks: [TaskModel] = [] {
        didSet {
            saveAndSync()
            // Görev listesi değişiminde stres seviyesini ölçüp Mesh Gradient renklerini günceller.
            AppearanceManager.shared.updateAppearance(with: tasks)
        }
    }
    
    /// Kullanıcının toplam tecrübe puanı.
    @Published var userXP: Int = UserDefaults.standard.integer(forKey: "userXP") {
        didSet {
            UserDefaults.standard.set(userXP, forKey: "userXP")
            reloadWidgets()
        }
    }
    
    @Published var isUnlocked: Bool = false      // Gizli Kasa biyometrik kilit durumu
    @Published var showConfetti: Bool = false     // Rütbe atlama veya büyük ödül kutlaması
    @Published var errorMessage: String? = nil   // UI'da gösterilecek hata veya tebrik mesajları
    
    // MARK: - Servisler (Dependencies)
    private let xpService = XPService.shared
    private let authService = AuthService.shared
    private let mediaManager = MediaManager.shared
    private let geminiService = GeminiService()
    private let hapticManager = HapticManager.shared
    private let dataService = DataService.shared
    
    // MARK: - XP Ayarları
    private struct XPRewards {
        static let newTask = 20
        static let dailyGoalBonus = 150
    }
    
    // MARK: - Initialization
    init() {
        loadTasks()
        AppearanceManager.shared.updateAppearance(with: tasks)
    }
    
    // MARK: - Veri İşlemleri
    func loadTasks() {
        self.tasks = dataService.loadTasks()
    }
    
    private func saveAndSync() {
        dataService.saveTasks(tasks)
        reloadWidgets()
    }
    
    // MARK: - Filtreleme ve Sıralama
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
        
        // ✨ SENIOR FIX: Akıllı Sıralama (Smart Sorting) Algoritması
        return result.sorted {
            // 1. Kural: Tamamlanmamış görevler her zaman üstte kalır
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            
            // 2. Kural: Akıllı Yığılma (Smart Stacking) Önceliği
            // Gecikmiş rutin görevleri en acil işimizdir, bu yüzden listede en tepeye iğnelenir!
            let delay0 = $0.delayedCount ?? 0
            let delay1 = $1.delayedCount ?? 0
            if delay0 != delay1 && !$0.isCompleted {
                return delay0 > delay1
            }
            
            // 3. Kural: En son eklenen en üstte görünür
            return $0.createdAt > $1.createdAt
        }
    }
    
    // MARK: - Görev CRUD İşlemleri
    func addTask(title: String, priority: Priority, date: Date, category: Category?, isPrivate: Bool, isReminderEnabled: Bool = false, images: [UIImage] = []) {
        let newTask = TaskModel(
            title: title,
            isCompleted: false,
            priority: priority,
            category: category,
            createdAt: date,
            isPrivate: isPrivate
        )
        
        withAnimation {
            tasks.append(newTask)
        }
        
        if !images.isEmpty {
            addImages(to: newTask, images: images)
        }
        
        addXP(amount: XPRewards.newTask)
        
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
        }
        tasks.remove(atOffsets: offsets)
        hapticManager.triggerMediumImpact()
    }
    
    func clearCompletedTasks() {
        let completed = tasks.filter { $0.isCompleted }
        guard !completed.isEmpty else { return }
        
        completed.forEach { task in
            TrashManager.shared.moveToTrash(task: task)
            NotificationManager.shared.cancelNotification(for: task.id)
        }
        
        withAnimation {
            tasks.removeAll { $0.isCompleted }
        }
        hapticManager.triggerHeavyImpact()
    }

    func restoreTask(_ task: TaskModel) {
        withAnimation {
            tasks.append(task)
        }
        saveAndSync()
        hapticManager.triggerSuccess()
    }
    
    func toggleCompletion(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            let isDone = tasks[index].isCompleted
            
            if isDone {
                NotificationManager.shared.cancelNotification(for: task.id)
                // ✨ SENIOR FIX 1: Rutin tamamlandıysa alev serisini (Streak) artır!
                if let rID = task.routineID {
                    RoutineManager.shared.incrementStreak(for: rID)
                }
            }
            
            // Dinamik XP hesaplama (Zorluğa göre çarpan uygular)
            var xpChange = xpService.calculateXP(for: tasks[index], isCompleted: isDone)
            
            // ✨ SENIOR FIX 2: Geri Dönüş (Comeback) Bonusu
            // Kullanıcı günlerdir ertelediği bir rutin görevini tamamlarsa ekstra XP ile ödüllendirilir.
            if isDone, let delayCount = tasks[index].delayedCount, delayCount > 1 {
                xpChange += (delayCount * 10)
            }
            
            addXP(amount: xpChange)
            
            if isDone {
                checkDailyBonus()
                hapticManager.triggerSuccess()
            } else {
                hapticManager.triggerWarning()
            }
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

    func postponeTask(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            NotificationManager.shared.cancelNotification(for: task.id)
            if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: tasks[index].createdAt) {
                tasks[index].createdAt = newDate
                if !tasks[index].isCompleted {
                    NotificationManager.shared.scheduleNotification(for: tasks[index])
                }
            }
            hapticManager.triggerLightImpact()
        }
    }
    
    func prioritizeTask(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].priority = .urgent
            hapticManager.triggerSuccess()
        }
    }

    // MARK: - XP & Rütbe & Güvenlik
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
    
    func authenticate() {
        Task {
            do {
                // 🛠️ SENIOR FIX: Trailing closure yerine modern Async/Await yapısına geçildi.
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
    
    // MARK: - AI & Medya
    func generateAISuggestions(for task: TaskModel) async -> String? {
        let suggestion = await geminiService.oneriAl(gorevBasligi: task.title)
        return suggestion.isEmpty ? nil : suggestion
    }
    
    func addImages(to task: TaskModel, images: [UIImage]) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        for image in images {
            if let id = mediaManager.saveImage(image) {
                tasks[index].imageIDs.append(id)
            }
        }
        hapticManager.triggerLightImpact()
    }
    
    // MARK: - Widget Reload
    private func reloadWidgets() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults(suiteName: "group.com.kopanzi.yaver")?.set(encoded, forKey: "yaver_tasks_v2")
        }
        UserDefaults(suiteName: "group.com.kopanzi.yaver")?.set(userXP, forKey: "userXP")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
