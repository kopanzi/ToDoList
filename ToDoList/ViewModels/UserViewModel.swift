import SwiftUI
import Combine

/// Profil ekranındaki üretkenlik verilerini, AI analizlerini ve ROZET KAZANIMLARINI yöneten ana merkez.
/// Senior Notu: Performans optimizasyonu (Debounce) ve güvenli rozet taşıma (Migration) algoritmaları eklendi.
@MainActor
final class UserViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    @Published var stats: UserStats = .empty
    @Published var achievements: [Achievement] = []
    
    // Ekranda görünen aktif analiz notu
    @Published var aiInsightNote: String = ""
    @Published var isLoadingInsight: Bool = false
    
    // Yaver'in verdiği son tavsiyeyi cihaz hafızasında tutarız
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
        
        // Sayfa ilk açıldığında başlangıç değerini 'Ömür Boyu' sayaçtan alıyoruz
        self.lastCompletedTaskCount = taskViewModel.lifetimeCompletedTasks
        
        // Hafızadaki son tavsiyeyi yükle
        self.aiInsightNote = savedAIInsight
        
        loadAndMergeAchievements()
        setupSubscriptions()
        refreshStats()
    }
    
    // MARK: - Core Logic & Subscriptions
    
    private func setupSubscriptions() {
        // ✨ SENIOR FIX 1: (Performans)
        // Görevler listesi çok hızlı değiştiğinde (örn: 3 görevi peş peşe tamamlama)
        // sistemi yormamak için 'debounce' kullanıyoruz. İşlemler bittikten 0.5 saniye sonra TEK BİR KERE analiz yapılır.
        taskVM.$tasks
            .dropFirst() // Init anındaki ilk gereksiz yayını atlar
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.refreshStats()
                self.checkIfNeedsAutoInsight()
            }
            .store(in: &cancellables)
            
        taskVM.$archivedTasks
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
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
            // İstatistiklerin tüm geçmişle (çöpe atılan arşiv görevleri) tutarlı olmasını sağlar
            let allTasks = taskVM.tasks + taskVM.archivedTasks
            self.stats = statsService.calculateStats(from: allTasks)
            
            // 🔥 KRİTİK MATEMATİK KİLİDİ: Bitirme oranını ömür boyu sayaçlarına göre eziyoruz.
            if taskVM.lifetimeAddedTasks > 0 {
                let safeCompleted = min(taskVM.lifetimeCompletedTasks, taskVM.lifetimeAddedTasks)
                let safeAdded = max(taskVM.lifetimeAddedTasks, 1)
                self.stats.completionRate = Int((Double(safeCompleted) / Double(safeAdded)) * 100)
            } else {
                self.stats.completionRate = 0
            }
            
            self.evaluateAchievements(from: allTasks)
        }
    }
    
    /// Sadece yeni bir görev tamamlandığında otomatik tavsiye alır
    private func checkIfNeedsAutoInsight() {
        let currentCompletedCount = taskVM.lifetimeCompletedTasks
        
        // Eğer bitirilen görev sayısı öncekinden fazlaysa Yaver bizi tebrik etsin!
        if currentCompletedCount > lastCompletedTaskCount {
            fetchAIInsight()
        }
        
        lastCompletedTaskCount = currentCompletedCount
    }
    
    // MARK: - 🏆 Başarı/Rozet Yönetimi
    
    /// ✨ SENIOR FIX 2: Güvenli Rozet Taşıma (Migration)
    /// Eski kodda yer alan ".count" kontrolü tehlikeliydi. Bu yeni yapı,
    /// gelecekte yeni rozetler eklendiğinde eski kazanılmış rozetleri korur ve yenilerini kilitli ekler.
    private func loadAndMergeAchievements() {
        let savedAchievements = dataService.loadAchievements()
        var mergedAchievements = Achievement.defaultGallery // En güncel rozet şablonu
        
        for saved in savedAchievements where saved.isUnlocked {
            if let index = mergedAchievements.firstIndex(where: { $0.title == saved.title }) {
                mergedAchievements[index].isUnlocked = true
                mergedAchievements[index].unlockedAt = saved.unlockedAt
            }
        }
        
        self.achievements = mergedAchievements
    }
    
    private func evaluateAchievements(from tasks: [TaskModel]) {
        let completedTasks = tasks.filter { $0.isCompleted }
        var newlyUnlocked = false
        let calendar = Calendar.current
        
        for index in achievements.indices {
            // Zaten açıksa kontrol etme
            guard !achievements[index].isUnlocked else { continue }
            
            var shouldUnlock = false
            
            switch achievements[index].title {
            case "Erkenci":
                shouldUnlock = completedTasks.contains { calendar.component(.hour, from: $0.createdAt) < 8 }
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
                    return weekday == 1 || weekday == 7 // 1: Pazar, 7: Cumartesi
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
    
    // MARK: - Yerel Analiz Motoru
    
    func fetchAIInsight() {
        guard !isLoadingInsight, stats.completionRate > 0 else { return }
        
        // Uygulamanın yaşadığını hissettirmek için çok kısa bir "yükleniyor" efekti
        isLoadingInsight = true
        
        // Gerekli istatistikleri Ayrıştır (Parsing)
        let peakHourString = stats.efficiencyPeakRange.prefix(2)
        let peakHour = Int(peakHourString) ?? 12
        
        let hoursString = stats.timeSaved.replacingOccurrences(of: "sa", with: "")
        let hours = Int(hoursString) ?? 0
        let minutesSaved = hours * 60
        
        // Yerel Analiz Servisine gönder (Sıfır Gecikme)
        let result = AnalysisService.shared.generateReport(
            completionRate: Double(stats.completionRate) / 100.0,
            streak: stats.streakCount,
            peakHour: peakHour,
            timeSavedInMinutes: minutesSaved
        )
        
        // UX Dokunuşu: Yumuşak geçişli yansıtma animasyonu
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
