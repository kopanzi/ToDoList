import Foundation
import SwiftUI
import WidgetKit
import Combine

/// Uygulamanın görev yönetimini, oyunlaştırma (XP) sistemini ve görsel tetikleyicilerini yöneten ana ViewModel.
/// Senior Notu: @MainActor ile işaretlenmiştir, böylece tüm UI güncellemeleri ana iş parçacığında güvenle yapılır.
@MainActor
final class TaskViewModel: ObservableObject {
    
    // MARK: - XP Sabitleri
    private struct XPRewards {
        static let newTask = 20 // Test modunda olduğumuz için görev ekleme puanını biraz artırdım
        // Tamamlama (completeTask) ve geri alma (undoTask) artık XPService tarafından dinamik hesaplanıyor!
    }
    
    // MARK: - Published Properties (Yayınlanan Veriler)
    
    @Published var tasks: [TaskModel] = [] {
        didSet {
            saveAndSync()
            // ✅ GÖRÜNÜM DEVRİMİ TETİKLEYİCİSİ
            // Her görev değişiminde stres seviyesini ölçüp temayı günceller.
            AppearanceManager.shared.updateAppearance(with: tasks)
        }
    }
    
    @Published var userXP: Int = UserDefaults.standard.integer(forKey: "userXP") {
        didSet {
            UserDefaults.standard.set(userXP, forKey: "userXP")
            reloadWidgets()
        }
    }
    
    @Published var isUnlocked: Bool = false     // Gizli Kasa kilidi
    @Published var showConfetti: Bool = false    // Rütbe atlama efekti
    @Published var errorMessage: String? = nil  // View tarafındaki uyarılar için
    
    // MARK: - Servisler (Private Dependencies)
    
    private let xpService = XPService.shared
    private let authService = AuthService.shared
    private let mediaManager = MediaManager.shared
    private let geminiService = GeminiService()
    private let hapticManager = HapticManager.shared
    private let dataService = DataService.shared
    
    // MARK: - Initialization
    
    init() {
        loadTasks()
        // Uygulama açıldığında mevcut görevlerle görünümü bir kez başlat
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
    
    /// View katmanının ihtiyaç duyduğu filtrelenmiş veriyi sağlar.
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
        
        // Sıralama: Tamamlanmamışlar üstte, yeni tarihliler en üstte
        return result.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            return $0.createdAt > $1.createdAt
        }
    }
    
    // MARK: - Görev Aksiyonları (Task Actions)
    
    /// 🔔 YENİ: isReminderEnabled parametresi eklendi ve varsayılan olarak false atandı.
    func addTask(title: String, priority: Priority, date: Date, category: Category?, isPrivate: Bool, isReminderEnabled: Bool = false) {
        let newTask = TaskModel(
            title: title,
            priority: priority,
            category: category,
            createdAt: date,
            isPrivate: isPrivate
        )
        tasks.append(newTask)
        addXP(amount: XPRewards.newTask)
        
        // 🔔 HATIRLATICI KURULUMU
        if isReminderEnabled {
            NotificationManager.shared.scheduleNotification(for: newTask)
        }
        
        hapticManager.triggerLightImpact()
    }
    
    // ... mevcut kodlar ...

        func deleteTask(at offsets: IndexSet) {
            offsets.forEach { index in
                let task = tasks[index]
                // ✨ YENİ: Diskten medya temizliği YERİNE çöp kutusuna gönderiyoruz
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
                // ✨ YENİ: Temizlenen görevleri de çöpe taşı
                TrashManager.shared.moveToTrash(task: task)
                NotificationManager.shared.cancelNotification(for: task.id)
            }
            tasks.removeAll { $0.isCompleted }
            hapticManager.triggerHeavyImpact()
        }

        // ✨ YENİ: Çöpten kurtarma fonksiyonu
        func restoreTask(_ task: TaskModel) {
            tasks.append(task)
            saveAndSync()
            hapticManager.triggerSuccess()
        }

    // ... mevcut kodlar ...
    
    func toggleCompletion(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            let isDone = tasks[index].isCompleted
            
            // 🔔 GÖREV BİTİNCE BİLDİRİMİ İPTAL ET (Gece yarısı gereksiz yere çalmasın)
            if isDone {
                NotificationManager.shared.cancelNotification(for: task.id)
            }
            
            // 🛠️ YENİ XP MANTIĞI: Görev zorluğuna (Priority) göre çarpanlı XP hesaplama
            let xpChange = xpService.calculateXP(for: tasks[index], isCompleted: isDone)
            addXP(amount: xpChange)
            
            // 🏆 GÜNLÜK 5 GÖREV BONUSU
            if isDone {
                let calendar = Calendar.current
                // Bugün oluşturulup bugün bitirilenleri sayar
                let todayCompleted = tasks.filter { $0.isCompleted && calendar.isDateInToday($0.createdAt) }.count
                
                // Tam 5. görevi bitirdiğinde dev bonusu patlat!
                if todayCompleted == 5 {
                    addXP(amount: 150) // Test için devasa bonus
                    self.errorMessage = "🔥 Günlük 5 Görev Serisi! +150 XP Bonus!" // Alert/Toast ile ekranda görünür
                    triggerLevelUpEffect() // Eğlenceli konfeti şöleni
                }
                
                hapticManager.triggerSuccess()
            } else {
                hapticManager.triggerWarning()
            }
        }
    }
    
    func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
    }
    
    func updateTaskNote(task: TaskModel, newNote: String) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].note = newNote
        }
    }

    // MARK: - Advanced Swipe Actions (Kaydırma Aksiyonları)
    
    /// Görevi tam 1 gün (24 saat) sonrasına erteler ve bildirimini günceller.
    func postponeTask(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // 1. Eski bildirimi iptal et
            NotificationManager.shared.cancelNotification(for: task.id)
            
            // 2. Tarihi tam 1 gün ileri at
            if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: tasks[index].createdAt) {
                tasks[index].createdAt = newDate
                
                // 3. Görev bitmediyse yarına yeni bir bildirim kur
                if !tasks[index].isCompleted {
                    NotificationManager.shared.scheduleNotification(for: tasks[index])
                }
            }
            
            hapticManager.triggerLightImpact()
        }
    }
    
    /// Görevin önceliğini anında 'Çok Acil' yapar.
    func prioritizeTask(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].priority = .urgent
            hapticManager.triggerSuccess()
        }
    }

    // MARK: - Bildirim İzinleri (YENİ 🔔)
    
    /// Kullanıcıdan bildirim gönderme izni ister (AddTaskView'dan tetiklenir)
    func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization()
    }

    // MARK: - XP & Rütbe Yönetimi
    
    private func addXP(amount: Int) {
        let oldRank = currentRank
        userXP += amount
        if userXP < 0 { userXP = 0 }
        
        // Rütbe atlama kontrolü (Yeni rütbenin rawValue'su eskisinden büyükse)
        if currentRank.rawValue > oldRank.rawValue && amount > 0 {
            triggerLevelUpEffect()
        }
    }
    
    /// View'lar için güncel rütbe bilgisini döner.
    var currentRank: Rank {
        xpService.getCurrentRank(for: userXP)
    }
    
    private func triggerLevelUpEffect() {
        showConfetti = true
        hapticManager.triggerHeavyImpact()
        // Efekti 4 saniye sonra kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.showConfetti = false
        }
    }
    
    // MARK: - Güvenlik (FaceID Entegrasyonu)
    
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
    
    /// Gemini üzerinden görev başlığına göre öneri alır.
    func generateAISuggestions(for task: TaskModel) async -> String? {
        let suggestion = await geminiService.oneriAl(gorevBasligi: task.title)
        return suggestion.isEmpty ? nil : suggestion
    }
    
    /// Göreve yeni görseller ekler ve diske kaydeder.
    func addImages(to task: TaskModel, images: [UIImage]) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        for image in images {
            if let id = mediaManager.saveImage(image) {
                tasks[index].imageIDs.append(id)
            }
        }
        hapticManager.triggerLightImpact()
    }
    
    // MARK: - Helpers (Yardımcı Metotlar)
    
    /// Bir görev silindiğinde diskteki ağır dosyalarını (resim/ses) temizler.
    private func cleanupTaskMedia(_ task: TaskModel) {
        task.imageIDs.forEach { mediaManager.deleteFile(id: $0, fileExtension: "jpg") }
        if let audioID = task.audioID {
            mediaManager.deleteFile(id: audioID, fileExtension: "m4a")
        }
    }
    
    /// Widget'ların güncel kalması için shared UserDefaults'a veri yazar.
    private func reloadWidgets() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults(suiteName: "group.com.kopanzi.yaver")?.set(encoded, forKey: "yaver_tasks_v2")
        }
        UserDefaults(suiteName: "group.com.kopanzi.yaver")?.set(userXP, forKey: "userXP")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
