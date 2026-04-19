import SwiftUI
import Combine

/// Profil ekranındaki üretkenlik verilerini, AI analizlerini ve ROZET KAZANIMLARINI yöneten ana merkez.
/// Senior Notu: Gereksiz API çağrılarını önlemek için AI Insight sadece 'manuel yenileme'
/// veya 'görev durumu değişimi' tetiklediğinde güncellenir ve AppStorage ile önbelleğe (cache) alınır.
@MainActor
final class UserViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var stats: UserStats = .empty
    @Published var achievements: [Achievement] = []
    
    // Ekranda görünen aktif AI notu
    @Published var aiInsightNote: String = ""
    @Published var isLoadingInsight: Bool = false
    
    // 🛠️ SENIOR FIX: Yaver'in verdiği son tavsiyeyi cihaz hafızasına kazıyoruz.
    // Böylece sayfa her değiştiğinde AI sıfırlanıp unutulmaz.
    @AppStorage("lastAIInsight") private var savedAIInsight: String = "Performans verileriniz harika görünüyor! Yaver'den güncel bir tavsiye almak için sayfayı aşağı kaydırarak yenileyin."
    
    // Kullanıcı adını anlık olarak cihaz hafızasından okuyoruz
    @AppStorage("userName") private var userName: String = "Yaver Kullanıcısı"
    
    // MARK: - Private Dependencies
    private let taskVM: TaskViewModel
    private let statsService = UserStatsService.shared
    private let geminiService = GeminiService()
    private let hapticManager = HapticManager.shared
    private let dataService = DataService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // Yapay zekaya gereksiz istek atmamak için önceki durumları tutuyoruz
    private var lastCompletedTaskCount: Int = 0
    
    // MARK: - Initialization
    init(taskViewModel: TaskViewModel) {
        self.taskVM = taskViewModel
        
        // 🛠️ SENIOR FIX: Sayfa ilk açıldığında Combine'ın gereksiz tetiklenmesini önlemek için,
        // başlangıç değerini 0 yerine mevcut tamamlanmış görev sayısı olarak ayarlıyoruz!
        self.lastCompletedTaskCount = taskViewModel.tasks.filter { $0.isCompleted }.count
        
        // Uygulama açıldığında hafızadaki son tavsiyeyi ekrana yükle
        self.aiInsightNote = savedAIInsight
        
        // 1. DİSKTEN ROZETLERİ YÜKLE
        let savedAchievements = dataService.loadAchievements()
        if savedAchievements.isEmpty {
            self.achievements = Achievement.defaultGallery
        } else {
            if savedAchievements.count < Achievement.defaultGallery.count {
                self.achievements = Achievement.defaultGallery
                for saved in savedAchievements where saved.isUnlocked {
                    if let index = self.achievements.firstIndex(where: { $0.title == saved.title }) {
                        self.achievements[index].isUnlocked = true
                        self.achievements[index].unlockedAt = saved.unlockedAt
                    }
                }
            } else {
                self.achievements = achievements
                self.achievements = savedAchievements
            }
        }
        
        setupSubscriptions()
        
        // Sadece istatistikleri yükle, API'ye boşuna istek atma
        refreshStats(with: taskVM.tasks)
    }
    
    // MARK: - Core Logic
    private func setupSubscriptions() {
        taskVM.$tasks
            .receive(on: RunLoop.main)
            .sink { [weak self] tasks in
                guard let self = self else { return }
                self.refreshStats(with: tasks)
                self.checkIfNeedsAutoInsight(tasks: tasks)
            }
            .store(in: &cancellables)
    }
    
    /// Pull-to-Refresh (Aşağı Kaydırarak Yenileme) yapıldığında tetiklenir
    func refreshAll() {
        refreshStats(with: taskVM.tasks)
        fetchAIInsight() // Manuel yenileme olduğu için AI'ı kesinlikle çalıştır
        hapticManager.triggerLightImpact()
    }
    
    private func refreshStats(with tasks: [TaskModel]) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            self.stats = statsService.calculateStats(from: tasks)
            self.evaluateAchievements(from: tasks)
        }
    }
    
    /// Sadece yeni bir görev tamamlandığında otomatik tavsiye alır
    private func checkIfNeedsAutoInsight(tasks: [TaskModel]) {
        let currentCompletedCount = tasks.filter { $0.isCompleted }.count
        
        // Eğer bitirilen görev sayısı öncekinden fazlaysa Yaver bizi tebrik etsin!
        if currentCompletedCount > lastCompletedTaskCount {
            fetchAIInsight()
        }
        
        // Değeri her zaman güncelle ki eşitlik korunsun
        lastCompletedTaskCount = currentCompletedCount
    }
    
    // MARK: - 🏆 Başarı/Rozet Kilit Açma Mantığı (Unlock Engine)
    
    private func evaluateAchievements(from tasks: [TaskModel]) {
        let completedTasks = tasks.filter { $0.isCompleted }
        var newlyUnlocked = false
        
        let calendar = Calendar.current
        
        for index in achievements.indices {
            let achievement = achievements[index]
            
            if achievement.isUnlocked { continue }
            
            var shouldUnlock = false
            
            switch achievement.title {
            case "Erkenci":
                shouldUnlock = completedTasks.contains {
                    calendar.component(.hour, from: $0.createdAt) < 8
                }
            case "AI Ustası":
                shouldUnlock = tasks.contains { $0.note.contains("🤖") || $0.note.localizedCaseInsensitiveContains("AI") }
            case "Odak":
                shouldUnlock = completedTasks.count >= 5
            case "Gizemli":
                shouldUnlock = tasks.contains { $0.isPrivate }
            case "Gece Baykuşu":
                shouldUnlock = completedTasks.contains {
                    let hour = calendar.component(.hour, from: $0.createdAt)
                    return hour >= 22 || hour < 4
                }
            case "Hafta Sonu Savaşçısı":
                shouldUnlock = completedTasks.contains {
                    let weekday = calendar.component(.weekday, from: $0.createdAt)
                    return weekday == 1 || weekday == 7
                }
            case "Sesli Düşünür":
                shouldUnlock = tasks.contains { $0.audioID != nil }
            case "Görsel Hafıza":
                shouldUnlock = tasks.contains { !$0.imageIDs.isEmpty }
            default:
                break
            }
            
            if shouldUnlock {
                achievements[index].isUnlocked = true
                achievements[index].unlockedAt = Date()
                newlyUnlocked = true
            }
        }
        
        if newlyUnlocked {
            hapticManager.triggerHeavyImpact()
            dataService.saveAchievements(self.achievements)
        }
    }
    
    // MARK: - AI Analytical Insight
    func fetchAIInsight() {
        guard !isLoadingInsight, stats.completionRate > 0 else { return }
        isLoadingInsight = true
        
        Task {
            let prompt = """
            Kullanıcının adı \(userName). Mevcut verimlilik istatistikleri:
            - Tamamlama Oranı: %\(stats.completionRate)
            - Günlük Seri: \(stats.streakCount) gün
            - En Verimli Saat Aralığı: \(stats.efficiencyPeakRange)
            
            Bu verilere bakarak \(userName)'e 2 cümlelik, motive edici ve bir sonraki adımı için akıllıca bir tavsiye veren analiz yazar mısın? Tırnak kullanma.
            """
            
            let result = await geminiService.oneriAl(gorevBasligi: prompt)
            
            withAnimation(.easeInOut) {
                self.aiInsightNote = result
                // 🛠️ SENIOR FIX: Başarılı olan tavsiyeyi cihazın hafızasına kaydet (Cache)
                self.savedAIInsight = result
                self.isLoadingInsight = false
            }
        }
    }
    
    // MARK: - User Actions
    func achievementTapped(_ achievement: Achievement) {
        hapticManager.triggerLightImpact()
    }
}
