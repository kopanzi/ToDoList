import SwiftUI
import Combine

/// Profil ekranındaki üretkenlik verilerini, AI analizlerini ve ROZET KAZANIMLARINI yöneten ana merkez.
/// Senior Notu: Gemini API bağımlılığı tamamen kaldırılmış, yerine %100 yerel ve
/// sıfır gecikmeli "AnalysisService" (Kural Tabanlı Motor) entegre edilmiştir.
@MainActor
final class UserViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var stats: UserStats = .empty
    @Published var achievements: [Achievement] = []
    
    // Ekranda görünen aktif analiz notu
    @Published var aiInsightNote: String = ""
    @Published var isLoadingInsight: Bool = false
    
    // 🛠️ SENIOR FIX: Yaver'in verdiği son tavsiyeyi cihaz hafızasına kazıyoruz.
    // Böylece sayfa her değiştiğinde analiz sıfırlanıp unutulmaz.
    @AppStorage("lastAIInsight") private var savedAIInsight: String = "Performans verileriniz harika görünüyor! Yaver'den güncel bir tavsiye almak için sayfayı aşağı kaydırarak yenileyin."
    
    // Kullanıcı adını anlık olarak cihaz hafızasından okuyoruz
    @AppStorage("userName") private var userName: String = "Yaver Kullanıcısı"
    
    // MARK: - Private Dependencies
    private let taskVM: TaskViewModel
    private let statsService = UserStatsService.shared
    private let hapticManager = HapticManager.shared
    private let dataService = DataService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // Yapay zekaya gereksiz istek atmamak için önceki durumları tutuyoruz
    private var lastCompletedTaskCount: Int = 0
    
    // MARK: - Initialization
    init(taskViewModel: TaskViewModel) {
        self.taskVM = taskViewModel
        
        // ✨ SENIOR FIX 1: Sayfa ilk açıldığında Combine'ın gereksiz tetiklenmesini önlemek için,
        // başlangıç değerini ekrandaki geçici görevler yerine 'Ömür Boyu' (Lifetime) sayaçtan alıyoruz!
        self.lastCompletedTaskCount = taskViewModel.lifetimeCompletedTasks
        
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
        
        // Sadece istatistikleri yükle
        refreshStats()
    }
    
    // MARK: - Core Logic
    private func setupSubscriptions() {
        // ✨ SENIOR FIX 2: Artık sadece aktif görevleri değil, arşivlenmiş (çöpe atılmış)
        // görevleri de dinliyoruz ki Profil ekranındaki grafikler silinmesin!
        taskVM.$tasks
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.refreshStats()
                self.checkIfNeedsAutoInsight()
            }
            .store(in: &cancellables)
            
        taskVM.$archivedTasks
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.refreshStats()
            }
            .store(in: &cancellables)
    }
    
    /// Pull-to-Refresh (Aşağı Kaydırarak Yenileme) yapıldığında tetiklenir
    func refreshAll() {
        refreshStats()
        fetchAIInsight() // Manuel yenileme olduğu için analizi kesinlikle çalıştır
        hapticManager.triggerLightImpact()
    }
    
    private func refreshStats() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            // ✨ SENIOR FIX 3: İstatistiklerin 'İstatistikler' ekranıyla birebir tutarlı olması için
            // çöpe atılan ama arşivde tutulan geçmiş görevleri de hesaba katıyoruz!
            let allTasks = taskVM.tasks + taskVM.archivedTasks
            self.stats = statsService.calculateStats(from: allTasks)
            
            // 🔥 KRİTİK MATEMATİK KİLİDİ: Bitirme oranını ekrandaki azalan görevlere göre değil,
            // Yaver'in asla silinmeyen ömür boyu (lifetime) sayaçlarına göre eziyoruz.
            if taskVM.lifetimeAddedTasks > 0 {
                let safeCompleted = min(taskVM.lifetimeCompletedTasks, taskVM.lifetimeAddedTasks)
                let safeAdded = max(taskVM.lifetimeAddedTasks, 1)
                self.stats.completionRate = Int((Double(safeCompleted) / Double(safeAdded)) * 100)
            } else {
                self.stats.completionRate = 0
            }
            
            self.evaluateAchievements(from: allTasks) // Başarımları da tüm geçmişe göre değerlendir
        }
    }
    
    /// Sadece yeni bir görev tamamlandığında otomatik tavsiye alır
    private func checkIfNeedsAutoInsight() {
        // ✨ SENIOR FIX 4: Ekrandaki geçici görevler yerine, asla silinmeyen ömür boyu sayacı kullanıyoruz.
        let currentCompletedCount = taskVM.lifetimeCompletedTasks
        
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
    
    // MARK: - Yerel Analiz Motoru (Local Analytical Insight)
    func fetchAIInsight() {
        guard !isLoadingInsight, stats.completionRate > 0 else { return }
        
        // Uygulamanın yaşadığını hissettirmek için çok kısa bir "yükleniyor" efekti verelim
        isLoadingInsight = true
        
        // 1. Gerekli istatistikleri Ayrıştır (Parsing)
        let peakHourString = stats.efficiencyPeakRange.prefix(2)
        let peakHour = Int(peakHourString) ?? 12
        
        let hoursString = stats.timeSaved.replacingOccurrences(of: "sa", with: "")
        let hours = Int(hoursString) ?? 0
        let minutesSaved = hours * 60
        
        // 2. Yerel Analiz Servisine gönder
        let result = AnalysisService.shared.generateReport(
            completionRate: Double(stats.completionRate) / 100.0,
            streak: stats.streakCount,
            peakHour: peakHour,
            timeSavedInMinutes: minutesSaved
        )
        
        // 3. UX Dokunuşu: Yansıtma animasyonu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut) {
                self.aiInsightNote = result
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
