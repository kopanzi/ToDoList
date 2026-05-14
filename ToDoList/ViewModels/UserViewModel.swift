import SwiftUI
import Combine
import FirebaseAuth // ✨ SENIOR FIX: Bulut bağlantısı için eklendi

/// Profil ekranındaki üretkenlik verilerini, AI analizlerini ve ROZET KAZANIMLARINI yöneten ana merkez.
/// Senior Notu: Performans optimizasyonu (Debounce) ve güvenli rozet taşıma (Migration) algoritmaları korunmuş,
/// üzerine Firestore bulut senkronizasyonu (Cloud Sync) entegre edilmiştir.
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
        
        // ✨ SENIOR FIX: Kullanıcı giriş yaptığını algıla ve buluttaki rozetleri telefona çek
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.syncAchievementsWithCloud()
            }
        }
    }
    
    // MARK: - CLOUD SYNC (BULUT MOTORU) ✨
    
    /// Giriş yapıldığında yerel rozetler ile buluttaki rozetleri akıllıca birleştirir.
    private func syncAchievementsWithCloud() {
        Task {
            do {
                let cloudAchievements = try await FirestoreManager.shared.fetchAchievements()
                
                if cloudAchievements.isEmpty {
                    // İlk Buluşma: Bulut boş ama telefonda kazanılmış rozetler var. Tümünü buluta yolla.
                    let unlockedCount = self.achievements.filter { $0.isUnlocked }.count
                    if unlockedCount > 0 {
                        try? await FirestoreManager.shared.saveAchievements(self.achievements)
                    }
                } else {
                    // Akıllı Birleştirme (Smart Merge): Buluttaki verilerle yereli birleştir
                    var merged = self.achievements
                    var hasChanges = false
                    
                    for cloudAch in cloudAchievements where cloudAch.isUnlocked {
                        // Eğer bulutta rozet açıksa ve telefonda kilitliyse, telefondakini aç
                        if let index = merged.firstIndex(where: { $0.title == cloudAch.title }), !merged[index].isUnlocked {
                            merged[index].isUnlocked = true
                            merged[index].unlockedAt = cloudAch.unlockedAt
                            hasChanges = true
                        }
                    }
                    
                    // Eğer yerel veride değişiklik olduysa hem cihazı hem bulutu güncelle
                    if hasChanges {
                        self.achievements = merged
                        DataService.shared.saveAchievements(merged)
                        try? await FirestoreManager.shared.saveAchievements(merged)
                    }
                }
            } catch {
                print("🛑 Başarılar Bulut Senkronizasyon Hatası: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveAchievementsToCloud() {
        guard Auth.auth().currentUser != nil else { return }
        Task { try? await FirestoreManager.shared.saveAchievements(self.achievements) }
    }
    
    // MARK: - Core Logic & Subscriptions
    
    private func setupSubscriptions() {
        // Görevler listesi çok hızlı değiştiğinde sistemi yormamak için 'debounce' kullanıyoruz.
        taskVM.$tasks
            .dropFirst()
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
    
    func refreshAll() {
        refreshStats()
        fetchAIInsight()
        hapticManager.triggerLightImpact()
    }
    
    private func refreshStats() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            let allTasks = taskVM.tasks + taskVM.archivedTasks
            self.stats = statsService.calculateStats(from: allTasks)
            
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
    
    private func checkIfNeedsAutoInsight() {
        let currentCompletedCount = taskVM.lifetimeCompletedTasks
        if currentCompletedCount > lastCompletedTaskCount {
            fetchAIInsight()
        }
        lastCompletedTaskCount = currentCompletedCount
    }
    
    // MARK: - 🏆 Başarı/Rozet Yönetimi
    
    private func loadAndMergeAchievements() {
        let savedAchievements = dataService.loadAchievements()
        var mergedAchievements = Achievement.defaultGallery
        
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
            
            // ✨ YENİ: Yeni bir rozet kazanıldığında onu anında buluta yedekle!
            saveAchievementsToCloud()
        }
    }
    
    // MARK: - Yerel Analiz Motoru
    
    func fetchAIInsight() {
        guard !isLoadingInsight, stats.completionRate > 0 else { return }
        isLoadingInsight = true
        
        let peakHourString = stats.efficiencyPeakRange.prefix(2)
        let peakHour = Int(peakHourString) ?? 12
        
        let hoursString = stats.timeSaved.replacingOccurrences(of: "sa", with: "")
        let hours = Int(hoursString) ?? 0
        let minutesSaved = hours * 60
        
        let result = AnalysisService.shared.generateReport(
            completionRate: Double(stats.completionRate) / 100.0,
            streak: stats.streakCount,
            peakHour: peakHour,
            timeSavedInMinutes: minutesSaved
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut) {
                self.aiInsightNote = result
                self.savedAIInsight = result
                self.isLoadingInsight = false
            }
        }
    }
    
    func achievementTapped(_ achievement: Achievement) {
        hapticManager.triggerLightImpact()
    }
}
