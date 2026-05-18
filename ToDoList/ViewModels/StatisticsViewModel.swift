import Foundation
import SwiftUI
import Combine
import Charts

/// İstatistik ekranı için ham görev verilerini işleyip grafik formatına getiren beyin.
/// Senior Notu: O(N*M) karmaşıklığındaki (maliyetli) döngüler, O(N) Dictionary (Sözlük)
/// haritalamasına dönüştürülerek binlerce görevde bile sıfır gecikme (Lag-free) sağlanmıştır.
/// UI güncellemeleri için @MainActor garantisi eklenmiştir.
@MainActor
final class StatisticsViewModel: ObservableObject {
    
    // MARK: - Plottable Data Types
    
    struct DailyActivity: Identifiable, Equatable {
        let id = UUID()
        let date: Date
        let count: Int
    }
    
    struct ProcrastinationData: Identifiable, Equatable {
        let id = UUID()
        let date: Date
        let completed: Int
        let delayed: Int
    }
    
    struct CategoryData: Identifiable, Equatable {
        let id = UUID()
        let category: String
        let count: Int
        let color: Color
    }
    
    // Zaman Filtresi Seçenekleri (Kategori, Odak, Yüzde ve Zirve Saat Analizleri İçin)
    enum TimeFilter: String, CaseIterable, Identifiable {
        case daily = "Bugün"
        case weekly = "Bu Hafta"
        case monthly = "Bu Ay"
        case yearly = "Bu Yıl"
        case allTime = "Tümü"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Published Properties (Grafik Verileri)
    @Published var heatmapData: [DailyActivity] = []
    @Published var weeklyData: [DailyActivity] = []
    @Published var procrastinationData: [ProcrastinationData] = []
    @Published var categoryDistribution: [CategoryData] = []
    
    // Geriye dönük uyumluluk için eski değişkenleri de beslemeye devam ediyoruz
    @Published var totalFocusMinutes: Int = 0
    @Published var averageCompletionTime: String = "--:--"
    
    // Profildeki 4'lü istatistik verisini buraya taşıdık
    @Published var userStats: UserStats = .empty
    
    // MARK: - ✨ DİNAMİK FİLTRE MOTORLARI (Bento Box İçin)
    
    // 1. Bitirme Yüzdesi Filtresi
    @Published var completionRateString: String = "%0"
    @Published var completionRateFilter: TimeFilter = .daily {
        didSet { updateCompletionRate() }
    }
    
    // 2. Zirve Saat Filtresi
    @Published var peakTimeString: String = "--:--"
    @Published var peakTimeFilter: TimeFilter = .daily {
        didSet { updatePeakTime() }
    }
    
    // 3. Odaklanılan Gerçek Süre Filtresi
    @Published var focusTimeString: String = "0 Dk"
    @Published var focusTimeFilter: TimeFilter = .daily {
        didSet { updateFocusTime() }
    }
    
    // 4. Kategori Grafiği Filtresi
    @Published var categoryTimeFilter: TimeFilter = .allTime {
        didSet { updateCategoryDistribution() }
    }
    
    // MARK: - Private Cache (Önbellekler)
    private var cancellables = Set<AnyCancellable>()
    private var storedActiveTasks: [TaskModel] = []
    private var storedCompletedTasks: [TaskModel] = []
    private var storedFocusSessions: [FocusSession] = []
    
    // MARK: - Core Logic
    
    /// TaskViewModel'den gelen aktif, tamamlanmış ve arşivlenmiş görevleri analiz eder.
    func processTasks(activeTasks: [TaskModel], archivedTasks: [TaskModel], lifetimeAdded: Int, lifetimeCompleted: Int) {
        let allTasks = activeTasks + archivedTasks
        let completedTasks = allTasks.filter { $0.isCompleted }
        
        // Hafızadaki önbelleği güncelle (Filtreler değiştikçe hızlıca hesaplama yapabilmek için)
        self.storedActiveTasks = activeTasks
        self.storedCompletedTasks = completedTasks
        
        // Genel temel verileri hesapla (Seri - Streak takibi vb. eski özellikler bozulmasın diye)
        self.userStats = UserStatsService.shared.calculateStats(from: allTasks)
        
        // Filtreli dinamik bento kutusu hesaplamalarını tetikle
        updateCompletionRate()
        updatePeakTime()
        
        // Grafikler için Data Üretimi (Eski işleyişle %100 uyumlu)
        self.heatmapData = generateHeatmapData(from: completedTasks)
        self.weeklyData = generateWeeklyData(from: completedTasks)
        self.procrastinationData = generateProcrastinationData(from: allTasks)
        
        // Kategori Dağılımını Güncelle
        updateCategoryDistribution()
        
        // Hassas Ortalama Zaman hesabı (Eski özellik)
        calculateAverageTime(from: completedTasks)
    }
    
    /// Odak sayacı bittiğinde tetiklenen süre işleme motoru.
    func processFocusSessions(_ sessions: [FocusSession]) {
        self.storedFocusSessions = sessions
        updateFocusTime()
    }
    
    // MARK: - ✨ REAL-TIME FILTER ENGINES (Matematiksel Filtre Hesaplayıcıları)
    
    /// 📏 1. Bitirme Yüzdesi Hesaplama Motoru (Daily Momentum & Denominator Problem Fix)
    private func updateCompletionRate() {
        let now = Date()
        let calendar = Calendar.current
        
        // Şu an masada yapmayı beklediğin (henüz tamamlanmamış) aktif görevler
        let pendingCount = storedActiveTasks.filter { !$0.isCompleted }.count
        
        // Seçilen zaman filtresine uyan tamamlanmış görevlerin sayısı
        let filteredCompletedCount = storedCompletedTasks.filter { task in
            let date = task.completedAt ?? task.createdAt
            switch completionRateFilter {
            case .daily:
                return calendar.isDateInToday(date)
            case .weekly:
                guard let past = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
                return date >= past
            case .monthly:
                guard let past = calendar.date(byAdding: .day, value: -30, to: now) else { return true }
                return date >= past
            case .yearly:
                guard let past = calendar.date(byAdding: .year, value: -1, to: now) else { return true }
                return date >= past
            case .allTime:
                return true
            }
        }.count
        
        let total = pendingCount + filteredCompletedCount
        
        if total > 0 {
            let rate = Int((Double(filteredCompletedCount) / Double(total)) * 100)
            self.completionRateString = "%\(rate)"
            self.userStats.completionRate = rate // Profil uyumluluğu için
        } else {
            self.completionRateString = "%0"
            self.userStats.completionRate = 0
        }
    }
    
    /// ⏰ 2. Zirve Saat Hesaplama Motoru (Precision Mode/Clustering Algorithm)
    private func updatePeakTime() {
        let now = Date()
        let calendar = Calendar.current
        
        // Seçilen zaman filtresine uyan tamamlanmış görevleri al
        let filteredCompleted = storedCompletedTasks.filter { task in
            let date = task.completedAt ?? task.createdAt
            switch peakTimeFilter {
            case .daily:
                return calendar.isDateInToday(date)
            case .weekly:
                guard let past = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
                return date >= past
            case .monthly:
                guard let past = calendar.date(byAdding: .day, value: -30, to: now) else { return true }
                return date >= past
            case .yearly:
                guard let past = calendar.date(byAdding: .year, value: -1, to: now) else { return true }
                return date >= past
            case .allTime:
                return true
            }
        }
        
        // Saat bazında gruplama yapıp en çok tekrarlananı (Mod) bul
        var hourCounts: [Int: Int] = [:]
        for task in filteredCompleted {
            let date = task.completedAt ?? task.createdAt
            let hour = calendar.component(.hour, from: date)
            hourCounts[hour, default: 0] += 1
        }
        
        if let bestHour = hourCounts.max(by: { $0.value < $1.value })?.key {
            self.peakTimeString = String(format: "%02d:00", bestHour)
            self.userStats.efficiencyTime = self.peakTimeString // Profil uyumluluğu için
        } else {
            // Eğer o gün/dönem hiç görev bitmediyse temiz bir görünüm ver
            self.peakTimeString = "--:--"
            self.userStats.efficiencyTime = "--:--"
        }
    }
    
    /// ⏳ 3. Odaklanılan Gerçek Süre Hesaplama Motoru (Real Focus Time Fix)
    private func updateFocusTime() {
        let now = Date()
        let calendar = Calendar.current
        
        // Seçilen zaman filtresine uyan odak oturumlarını filtrele
        let filteredSessions = storedFocusSessions.filter { session in
            switch focusTimeFilter {
            case .daily: return calendar.isDateInToday(session.date)
            case .weekly: guard let past = calendar.date(byAdding: .day, value: -7, to: now) else { return true }; return session.date >= past
            case .monthly: guard let past = calendar.date(byAdding: .day, value: -30, to: now) else { return true }; return session.date >= past
            case .yearly: guard let past = calendar.date(byAdding: .year, value: -1, to: now) else { return true }; return session.date >= past
            case .allTime: return true
            }
        }
        
        let totalMinutes = filteredSessions.reduce(0) { $0 + $1.durationMinutes }
        self.totalFocusMinutes = totalMinutes
        
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        
        if hours > 0 {
            self.focusTimeString = "\(hours)sa \(mins)dk"
            self.userStats.timeSaved = "\(hours)sa \(mins)dk" // Eski timeSaved Bento kutusunu besler
        } else {
            self.focusTimeString = "\(mins) Dk"
            self.userStats.timeSaved = "\(mins) Dk" // Eski timeSaved Bento kutusunu besler
        }
    }
    
    /// 📊 4. Kategori Grafiği Zaman Filtresi İşleyicisi
    private func updateCategoryDistribution() {
        let calendar = Calendar.current
        let now = Date()
        
        let filteredTasks = storedCompletedTasks.filter { task in
            let date = task.completedAt ?? task.createdAt
            
            switch categoryTimeFilter {
            case .daily:
                return calendar.isDateInToday(date)
            case .weekly:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
                return date >= weekAgo
            case .monthly:
                guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return true }
                return date >= monthAgo
            case .yearly:
                guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) else { return true }
                return date >= yearAgo
            case .allTime:
                return true
            }
        }
        self.categoryDistribution = generateCategoryData(from: filteredTasks)
    }
    
    // MARK: - High-Performance Generators (Grafik Veri Üreticileri)
    
    private func generateProcrastinationData(from allTasks: [TaskModel]) -> [ProcrastinationData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dailyStats: [Date: (completed: Int, delayed: Int)] = [:]
        
        for task in allTasks {
            let targetDate = task.completedAt ?? task.createdAt
            let startOfDay = calendar.startOfDay(for: targetDate)
            
            var current = dailyStats[startOfDay, default: (0, 0)]
            if task.isCompleted { current.completed += 1 }
            if let delayed = task.delayedCount, delayed > 0 { current.delayed += delayed }
            dailyStats[startOfDay] = current
        }
        
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let stats = dailyStats[date, default: (0, 0)]
            return ProcrastinationData(date: date, completed: stats.completed, delayed: stats.delayed)
        }.reversed()
    }
    
    private func generateHeatmapData(from tasks: [TaskModel]) -> [DailyActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dailyCounts: [Date: Int] = [:]
        
        for task in tasks {
            let targetDate = task.completedAt ?? task.createdAt
            let startOfDay = calendar.startOfDay(for: targetDate)
            dailyCounts[startOfDay, default: 0] += 1
        }
        
        var data: [DailyActivity] = []
        for i in 0..<90 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let count = dailyCounts[date, default: 0]
                data.append(DailyActivity(date: date, count: count))
            }
        }
        return data.reversed()
    }
    
    private func generateWeeklyData(from tasks: [TaskModel]) -> [DailyActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dailyCounts: [Date: Int] = [:]
        
        for task in tasks {
            let targetDate = task.completedAt ?? task.createdAt
            let startOfDay = calendar.startOfDay(for: targetDate)
            dailyCounts[startOfDay, default: 0] += 1
        }
        
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let count = dailyCounts[date, default: 0]
            return DailyActivity(date: date, count: count)
        }.reversed()
    }
    
    private func generateCategoryData(from tasks: [TaskModel]) -> [CategoryData] {
        let groups = Dictionary(grouping: tasks, by: { $0.category?.rawValue ?? "Diğer" })
        return groups.map { (key, value) in
            CategoryData(
                category: key.uppercased(),
                count: value.count,
                color: value.first?.category?.color ?? .gray
            )
        }.sorted(by: { $0.count > $1.count })
    }
    
    private func calculateAverageTime(from tasks: [TaskModel]) {
        guard !tasks.isEmpty else { return }
        let calendar = Calendar.current
        var totalMinutes = 0
        
        for task in tasks {
            let date = task.completedAt ?? task.createdAt
            let components = calendar.dateComponents([.hour, .minute], from: date)
            totalMinutes += (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }
        
        let avg = totalMinutes / tasks.count
        self.averageCompletionTime = String(format: "%02d:%02d", avg / 60, avg % 60)
    }
}
