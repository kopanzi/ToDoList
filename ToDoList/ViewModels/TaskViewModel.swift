import Foundation
import SwiftUI
import WidgetKit
import Combine
import FirebaseAuth // ✨ SENIOR FIX: Otomatik giriş tespiti için eklendi

// ✨ YENİ: Odak oturumlarını (Gerçek odaklanma süresini) tutacağımız veri modeli
struct FocusSession: Codable, Identifiable, Equatable {
    var id = UUID()
    let date: Date
    let durationMinutes: Int
}

/// Uygulamanın görev yönetimini, oyunlaştırma (XP) sistemini ve görsel tetikleyicilerini yöneten ana ViewModel.
/// Senior Notu: @MainActor ile işaretlenmiştir, tüm UI güncellemeleri ana iş parçacığında güvenle yapılır.
/// Veri kayıplarını önlemek için AppGroup, UserDefaults ve FIRESTORE işlemleri koruma altına alınmıştır.
@MainActor
final class TaskViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    
    /// Takvimden görev eklerken kullanılan geçici tarih tutucu
    @Published var defaultAdditionDate: Date? = nil
    
    /// Tüm görevlerin listesi. Değiştiğinde otomatik yerel hafızaya ve Widget'a kaydeder.
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
    
    // ✨ YENİ: Kullanıcının alın teri olan Odaklanma Süreleri Arşivi
    @Published var focusSessions: [FocusSession] = [] {
        didSet {
            saveFocusSessions()
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
        loadFocusSessions() // ✨ YENİ: Başlangıçta odak sürelerini yükle
        validateLifetimeCounters()
        
        // ✨ SENIOR FIX: Kullanıcı giriş yaptığını anında algılayıp bulutla eşleşme başlatan dinleyici
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.syncWithCloud()
            }
        }
    }
    
    // MARK: - CLOUD SYNC (BULUT MOTORU) ✨
    
    /// Giriş yapıldığında yerel görevler ile buluttaki görevleri akıllıca birleştirir.
    private func syncWithCloud() {
        Task {
            do {
                let cloudTasks = try await FirestoreManager.shared.fetchTasks()
                
                if cloudTasks.isEmpty && !self.tasks.isEmpty {
                    // İlk Buluşma: Bulut boş ama kullanıcının yerel görevleri var. Tümünü buluta yolla.
                    await FirestoreManager.shared.syncLocalTasksToCloud(tasks: self.tasks)
                } else if !cloudTasks.isEmpty {
                    // Akıllı Birleştirme (Smart Merge): Buluttaki verilerle telefondakileri birleştir
                    var mergedTasks = self.tasks
                    for cloudTask in cloudTasks {
                        if let index = mergedTasks.firstIndex(where: { $0.id == cloudTask.id }) {
                            // Görev zaten varsa buluttakini (daha güncel olanı) ez
                            mergedTasks[index] = cloudTask
                        } else {
                            // Bulutta var, telefonda yoksa listeye ekle
                            mergedTasks.append(cloudTask)
                        }
                    }
                    self.tasks = mergedTasks
                    
                    // Telefonun yerel hafızasından gelip bulutta olmayanlar varsa, tam eşzamanlama yap
                    await FirestoreManager.shared.syncLocalTasksToCloud(tasks: mergedTasks)
                }
            } catch {
                print("🛑 Bulut Senkronizasyon Hatası: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveTaskToCloud(_ task: TaskModel) {
            guard Auth.auth().currentUser != nil else {
                print("🛑 HATA: Kullanıcı giriş yapmamış, görev buluta gidemez!")
                return
            }
            Task {
                do {
                    try await FirestoreManager.shared.saveTask(task)
                    print("✅ GÖREV BAŞARIYLA BULUTA GİTTİ: \(task.title)")
                } catch {
                    print("🛑 GÖREV BULUT HATASI: \(error.localizedDescription)")
                    print("🛑 DETAYLI HATA: \(error)")
                }
            }
        }
    
    private func deleteTaskFromCloud(id: String) {
        guard Auth.auth().currentUser != nil else { return }
        Task { try? await FirestoreManager.shared.deleteTask(id: id) }
    }
    
    // MARK: - ODAK OTURUMU YÖNETİMİ (FOCUS SESSIONS) ✨
    
    private func loadFocusSessions() {
        if let data = UserDefaults.standard.data(forKey: "yaver_focus_sessions_v1"),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
            self.focusSessions = decoded
        }
    }
    
    private func saveFocusSessions() {
        if let encoded = try? JSONEncoder().encode(focusSessions) {
            UserDefaults.standard.set(encoded, forKey: "yaver_focus_sessions_v1")
        }
    }
    
    /// Pomodoro sayacı başarıyla bittiğinde çağrılır
    func addFocusSession(minutes: Int) {
        let newSession = FocusSession(date: Date(), durationMinutes: minutes)
        focusSessions.append(newSession)
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
        
        if result.contains(where: { $0.isPrivate != showPrivate }) {
            result = result.filter { $0.isPrivate == showPrivate }
        }
        
        if !showPrivate, let category = category {
            result = result.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            let delay0 = $0.delayedCount ?? 0
            let delay1 = $1.delayedCount ?? 0
            if delay0 != delay1 && !$0.isCompleted { return delay0 > delay1 }
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
        
        // ✨ Buluta Kaydet
        saveTaskToCloud(newTask)
        
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
            
            // ✨ Buluttan Sil
            deleteTaskFromCloud(id: task.id)
            
            if task.isCompleted {
                var archivedTask = task
                archivedTask.note = ""
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
            
            // ✨ Buluttan Sil
            deleteTaskFromCloud(id: task.id)
            
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
        archivedTasks.removeAll { $0.id == task.id }
        
        // ✨ Çöpten çıkardığımız için buluta tekrar yükle
        saveTaskToCloud(task)
        
        saveAndSync()
        hapticManager.triggerSuccess()
    }
    
    func toggleCompletion(task: TaskModel) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        tasks[index].isCompleted.toggle()
        let isDone = tasks[index].isCompleted
        tasks[index].completedAt = isDone ? Date() : nil
        
        // ✨ Değişikliği Buluta Yolla
        saveTaskToCloud(tasks[index])
        
        if isDone {
            NotificationManager.shared.cancelNotification(for: task.id)
            if let rID = task.routineID {
                RoutineManager.shared.incrementStreak(for: rID)
            }
        }
        
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
            // ✨ Değişikliği Buluta Yolla
            saveTaskToCloud(tasks[index])
        }
    }

    // MARK: - Özel İşlemler (Erteleme ve Öncelik)
    
    func postponeTask(task: TaskModel) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        NotificationManager.shared.cancelNotification(for: task.id)
        
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: tasks[index].createdAt) {
            withAnimation(.spring()) {
                tasks[index].createdAt = newDate
                tasks[index].delayedCount = (tasks[index].delayedCount ?? 0) + 1
            }
            // ✨ Değişikliği Buluta Yolla
            saveTaskToCloud(tasks[index])
            
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
            // ✨ Değişikliği Buluta Yolla
            saveTaskToCloud(tasks[index])
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
        // ✨ Değişikliği Buluta Yolla
        saveTaskToCloud(tasks[index])
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
