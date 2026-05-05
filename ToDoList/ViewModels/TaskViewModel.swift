import Foundation
import SwiftUI
import WidgetKit
import Combine

/// Uygulamanın görev yönetimini, oyunlaştırma (XP) sistemini ve görsel tetikleyicilerini yöneten ana ViewModel.
/// Senior Notu: @MainActor ile işaretlenmiştir, tüm UI güncellemeleri ana iş parçacığında güvenle yapılır.
/// Gemini API bağımlılıkları sistemden tamamen temizlenmiş, izole servislere (CalendarService vb.) devredilmiştir.
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
            
            // ✨ SENIOR FIX 1: Rutin motoru vb. arkadan görev eklerse sayacı otomatik hizala
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
    
    // ✨ SENIOR FIX: Ömür Boyu (Lifetime) Sayaçlar
    @Published var lifetimeAddedTasks: Int = UserDefaults.standard.integer(forKey: "lifetimeAddedTasks") {
        didSet { UserDefaults.standard.set(lifetimeAddedTasks, forKey: "lifetimeAddedTasks") }
    }
    
    @Published var lifetimeCompletedTasks: Int = UserDefaults.standard.integer(forKey: "lifetimeCompletedTasks") {
        didSet {
            UserDefaults.standard.set(lifetimeCompletedTasks, forKey: "lifetimeCompletedTasks")
            
            // ✨ SENIOR FIX 2: Gerçek Zamanlı (Real-time) Güvenlik Kilidi!
            // Kullanıcı seri şekilde tik atıp silse bile tamamlanan sayısı ekleneni geçemez.
            // Geçtiği an (Örn: 9 eklenen, 11 tamamlanan), ekleneni otomatik olarak 11'e eşitler.
            if lifetimeCompletedTasks > lifetimeAddedTasks {
                lifetimeAddedTasks = lifetimeCompletedTasks
            }
        }
    }
    
    // ✨ SENIOR FIX: Silinen görevlerin grafik verilerini yaşatmak için Arşiv Dizisi
    @Published var archivedTasks: [TaskModel] = [] {
        didSet {
            if let encoded = try? JSONEncoder().encode(archivedTasks) {
                UserDefaults.standard.set(encoded, forKey: "yaver_archived_tasks_v1")
            }
        }
    }
    
    @Published var isUnlocked: Bool = false      // Gizli Kasa biyometrik kilit durumu
    @Published var showConfetti: Bool = false    // Rütbe atlama veya büyük ödül kutlaması
    @Published var errorMessage: String? = nil   // UI'da gösterilecek hata veya tebrik mesajları
    
    // MARK: - Servisler (Dependencies)
    private let xpService = XPService.shared
    private let authService = AuthService.shared
    private let mediaManager = MediaManager.shared
    private let hapticManager = HapticManager.shared
    private let dataService = DataService.shared
    private let calendarService = CalendarService.shared
    // 🧹 SENIOR CLEANUP: GeminiService tamamen kaldırıldı!
    
    // MARK: - XP Ayarları
    private struct XPRewards {
        static let newTask = 20
        static let dailyGoalBonus = 150
    }
    
    // MARK: - Initialization
    init() {
        loadTasks()
        AppearanceManager.shared.updateAppearance(with: tasks)
        
        // ✨ Arşivlenmiş istatistik görevlerini yükle
        if let data = UserDefaults.standard.data(forKey: "yaver_archived_tasks_v1"),
           let decoded = try? JSONDecoder().decode([TaskModel].self, from: data) {
            self.archivedTasks = decoded
        }
        
        // ✨ SENIOR FIX: Kurşun Geçirmez 'Self-Healing' Matematiği
        // Ekranda aktif olarak görünen + arşivdeki tüm görevlerin kesin sayısı
        let absoluteTotalTasks = tasks.count + archivedTasks.count
        
        // Ekranda tikli olanlar + arşivdeki tüm görevler (arşivdekilerin hepsi bitmiştir zaten)
        let absoluteCompletedTasks = tasks.filter { $0.isCompleted }.count + archivedTasks.count
        
        // 1. Kural: Ömür boyu eklenenler, en az 'şu an var olan' toplam görev kadar olmalıdır.
        if lifetimeAddedTasks < absoluteTotalTasks {
            lifetimeAddedTasks = absoluteTotalTasks
        }
        
        // 2. Kural: Ömür boyu tamamlananlar, en az 'şu an bitmiş olanlar' kadar olmalıdır.
        if lifetimeCompletedTasks < absoluteCompletedTasks {
            lifetimeCompletedTasks = absoluteCompletedTasks
        }
        
        // 3. Güvenlik Kilidi: Ne olursa olsun, tamamlanan görev ekleneni geçemez!
        if lifetimeCompletedTasks > lifetimeAddedTasks {
            lifetimeAddedTasks = lifetimeCompletedTasks
        }
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
        
        // Akıllı Sıralama (Smart Sorting) Algoritması
        return result.sorted {
            // 1. Kural: Tamamlanmamış görevler her zaman üstte kalır
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            
            // 2. Kural: Akıllı Yığılma (Smart Stacking) Önceliği
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
        
        // ✨ Ömür boyu eklenen görev sayacını artır
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
            
            // ✨ Görev tamamlanmışsa grafikleri korumak için arşive kopyala
            // (Veritabanı şişmesin diye resimleri ve notu temizleyerek kopyalıyoruz)
            if task.isCompleted {
                var archivedTask = task
                archivedTask.note = ""
                archivedTask.imageIDs = []
                archivedTask.audioID = nil
                archivedTasks.append(archivedTask)
            }
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
            
            // ✨ Toplu temizlemede de grafikleri korumak için arşive yolla
            var archivedTask = task
            archivedTask.note = ""
            archivedTask.imageIDs = []
            archivedTask.audioID = nil
            archivedTasks.append(archivedTask)
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
        // ✨ Çöpten geri yüklenirse arşivden çıkar ki istatistiklerde çift (duplicate) sayılmasın
        archivedTasks.removeAll { $0.id == task.id }
        
        saveAndSync()
        hapticManager.triggerSuccess()
    }
    
    func toggleCompletion(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            let isDone = tasks[index].isCompleted
            
            // Görev tamamlandığında o anın saatini kaydet, iptal edilirse sil
            tasks[index].completedAt = isDone ? Date() : nil
            
            if isDone {
                NotificationManager.shared.cancelNotification(for: task.id)
                // Rutin tamamlandıysa alev serisini (Streak) artır!
                if let rID = task.routineID {
                    RoutineManager.shared.incrementStreak(for: rID)
                }
            }
            
            // Dinamik XP hesaplama (Zorluğa göre çarpan uygular)
            var xpChange = xpService.calculateXP(for: tasks[index], isCompleted: isDone)
            
            // Geri Dönüş (Comeback) Bonusu
            if isDone, let delayCount = tasks[index].delayedCount, delayCount > 1 {
                xpChange += (delayCount * 10)
            }
            
            addXP(amount: xpChange)
            
            // ✨ Ömür boyu tamamlanma sayacını güncelle
            if isDone {
                lifetimeCompletedTasks += 1
            } else if lifetimeCompletedTasks > 0 {
                lifetimeCompletedTasks -= 1
            }
            
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

    // ✨ SENIOR FIX: Erteleme Yüzleşmesi (Procrastination) Grafiği İçin
    func postponeTask(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            NotificationManager.shared.cancelNotification(for: task.id)
            if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: tasks[index].createdAt) {
                tasks[index].createdAt = newDate
                
                // KRİTİK EKLENTİ: Erteleme butonuna basıldığında Erteleme Yükü sayacını artırıyoruz
                tasks[index].delayedCount = (tasks[index].delayedCount ?? 0) + 1
                
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
    
    // MARK: - Medya Yönetimi
    
    func addImages(to task: TaskModel, images: [UIImage]) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        for image in images {
            if let id = mediaManager.saveImage(image) {
                tasks[index].imageIDs.append(id)
            }
        }
        hapticManager.triggerLightImpact()
    }
    
    // MARK: - Takvim (Calendar) Entegrasyonu
    
    /// Görevi Apple'ın yerel takvimine ekler.
    func addToCalendar(task: TaskModel) {
        Task {
            do {
                let hasAccess = try await calendarService.requestAccess()
                if hasAccess {
                    try calendarService.saveTaskToCalendar(task: task)
                    hapticManager.triggerSuccess()
                } else {
                    hapticManager.triggerError()
                }
            } catch {
                print("Takvim hatası: \(error)")
                hapticManager.triggerError()
            }
        }
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
