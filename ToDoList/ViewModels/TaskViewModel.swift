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
        // Başlangıçta temayı mevcut görev durumuna göre ayarla
        AppearanceManager.shared.updateAppearance(with: tasks)
    }
    
    // MARK: - Veri İşlemleri (Data Operations)
    
    func loadTasks() {
        self.tasks = dataService.loadTasks()
    }
    
    private func saveAndSync() {
        dataService.saveTasks(tasks)
        reloadWidgets()
    }
    
    // MARK: - Filtreleme Mantığı (Filtering Logic)
    
    /// Görünüm (View) katmanı için filtrelenmiş ve sıralanmış veri sağlar.
    func getFilteredTasks(category: Category?, showPrivate: Bool, searchText: String) -> [TaskModel] {
        var result = tasks
        
        // 1. Gizlilik Filtresi
        result = result.filter { $0.isPrivate == showPrivate }
        
        // 2. Kategori Filtresi (Sadece genel görevlerde)
        if !showPrivate, let category = category {
            result = result.filter { $0.category == category }
        }
        
        // 3. Arama Filtresi
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Sıralama: Bitmemiş görevler üstte, tarihe göre yeniden eskiye
        return result.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            return $0.createdAt > $1.createdAt
        }
    }
    
    // MARK: - Görev CRUD İşlemleri
    
    /// Yeni görev ekler.
    /// ✅ SENIOR FIX: images parametresi eklendi, böylece görev oluşturulurken fotoğraflar da kaydedilecek.
    func addTask(title: String, priority: Priority, date: Date, category: Category?, isPrivate: Bool, isReminderEnabled: Bool = false, images: [UIImage] = []) {
        let newTask = TaskModel(
            title: title,
            isCompleted: false, // 🎯 İlk sırada bu olmalı
            priority: priority,   // 🎯 Sonra bu gelmeli
            category: category,
            createdAt: date,
            isPrivate: isPrivate
        )
        
        withAnimation {
            tasks.append(newTask)
        }
        
        // ✨ MEDYA ENTEGRASYONU: Eğer resim seçildiyse, yeni oluşturulan göreve ekle
        if !images.isEmpty {
            addImages(to: newTask, images: images)
        }
        
        addXP(amount: XPRewards.newTask)
        
        if isReminderEnabled {
            NotificationManager.shared.scheduleNotification(for: newTask)
        }
        
        hapticManager.triggerLightImpact()
    }
    
    /// Görevi silmek yerine Çöp Kutusuna (TrashManager) taşır.
    func deleteTask(at offsets: IndexSet) {
        offsets.forEach { index in
            let task = tasks[index]
            TrashManager.shared.moveToTrash(task: task)
            NotificationManager.shared.cancelNotification(for: task.id)
        }
        tasks.remove(atOffsets: offsets)
        hapticManager.triggerMediumImpact()
    }
    
    /// Tamamlanan tüm görevleri toplu halde Çöp Kutusuna gönderir.
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

    /// Çöp kutusundan geri yüklenen görevi listeye ekler.
    func restoreTask(_ task: TaskModel) {
        withAnimation {
            tasks.append(task)
        }
        saveAndSync()
        hapticManager.triggerSuccess()
    }
    
    /// Görevin tamamlanma durumunu değiştirir ve XP hesaplamasını tetikler.
    func toggleCompletion(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            let isDone = tasks[index].isCompleted
            
            // Bildirim iptal (Biten görev hatırlatılmamalı)
            if isDone {
                NotificationManager.shared.cancelNotification(for: task.id)
            }
            
            // Dinamik XP hesaplama (Zorluğa göre çarpan uygular)
            let xpChange = xpService.calculateXP(for: tasks[index], isCompleted: isDone)
            addXP(amount: xpChange)
            
            // 🏆 GÜNLÜK 5 GÖREV SERİSİ KONTROLÜ
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
        // Bugün bitirilen (isCompleted) görevlerin sayısı
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

    // MARK: - Gelişmiş Kaydırma Aksiyonları (Swipe)
    
    /// Görevi 24 saat sonrasına öteler.
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
    
    /// Önceliği anında en üst seviyeye çeker.
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
        
        // Rütbe atlama durumunda konfeti patlat
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
        // Konfeti etkisini 4 saniye sonra durdur
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.showConfetti = false
        }
    }
    
    /// Biyometrik doğrulama (FaceID) başlatır.
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
