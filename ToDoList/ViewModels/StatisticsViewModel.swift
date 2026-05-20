import Foundation
import SwiftUI
import Combine
import Charts

/// İstatistik ekranı için ham görev verilerini işleyip grafik formatına getiren beyin.
/// Senior Notu: Çöp kutusu veya silinmiş görevlerden bağımsız, tamamlanmış tüm görevlerin
/// tarihsel verisini koruyan 'Data Integrity' (Veri Bütünlüğü) odaklı Analytics Log yapısına geçilmiştir.
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
    
    // ✨ YENİ: Ölümsüz Analitik Kaydı Şablonu
    // Görevler diskten tamamen silinse bile istatistik grafikleri için bu hafif veri tutulur.
    struct AnalyticsTask: Codable, Equatable {
        let id: String
        let category: String
        let completedAt: Date
    }
    
    // Zaman Filtresi Seçenekleri
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
    
    @Published var totalFocusMinutes: Int = 0
    @Published var averageCompletionTime: String = "--:--"
    
    @Published var userStats: UserStats = .empty
    
    // MARK: - DİNAMİK FİLTRE MOTORLARI
    
    @Published var completionRateString: String = "%0"
    @Published var completionRateFilter: TimeFilter = .daily {
        didSet { updateCompletionRate() }
    }
    
    @Published var peakTimeString: String = "--:--"
    @Published var peakTimeFilter: TimeFilter = .daily {
        didSet { updatePeakTime() }
    }
    
    @Published var focusTimeString: String = "0 Dk"
    @Published var focusTimeFilter: TimeFilter = .daily {
        didSet { updateFocusTime() }
    }
    
    @Published var categoryTimeFilter: TimeFilter = .daily {
        didSet { updateCategoryDistribution() }
    }
    
    // MARK: - Private Cache (Önbellekler)
    private var cancellables = Set<AnyCancellable>()
    private var storedActiveTasks: [TaskModel] = []
    private var storedCompletedTasks: [TaskModel] = []
    private var storedFocusSessions: [FocusSession] = []
    
    // ✨ ÖLÜMSÜZ ANALİTİK HAFIZASI
    private let analyticsStorageKey = "yaver_analytics_history_v1"
    private var historicalTasks: [String: AnalyticsTask] = [:]
    
    // MARK: - Init
    init() {
        loadHistoricalTasks()
    }
    
    // MARK: - Core Logic
    
    func processTasks(activeTasks: [TaskModel], archivedTasks: [TaskModel], lifetimeAdded: Int, lifetimeCompleted: Int) {
        let allTasks = activeTasks + archivedTasks
        let completedTasks = allTasks.filter { $0.isCompleted }
        
        self.storedActiveTasks = activeTasks
        self.storedCompletedTasks = completedTasks
        
        // ✨ ANALİTİK SENKRONİZASYONU: Görevlerin silinmez geçmişini güncelle
        syncAnalyticsLog(with: allTasks)
        
        self.userStats = UserStatsService.shared.calculateStats(from: allTasks)
        
        updateCompletionRate()
        updatePeakTime()
        
        self.heatmapData = generateHeatmapData(from: completedTasks)
        self.weeklyData = generateWeeklyData(from: completedTasks)
        self.procrastinationData = generateProcrastinationData(from: allTasks)
        
        // ✨ Kategori grafiği artık ölümsüz hafızadan (historicalTasks) çizilir
        updateCategoryDistribution()
        
        calculateAverageTime(from: completedTasks)
    }
    
    func processFocusSessions(_ sessions: [FocusSession]) {
        self.storedFocusSessions = sessions
        updateFocusTime()
    }
    
    // MARK: - ✨ ÖLÜMSÜZ ANALİTİK MOTORU (Append-Only Log)
    
    private func loadHistoricalTasks() {
        if let data = UserDefaults.standard.data(forKey: analyticsStorageKey),
           let decoded = try? JSONDecoder().decode([String: AnalyticsTask].self, from: data) {
            self.historicalTasks = decoded
        }
    }
    
    private func saveHistoricalTasks() {
        if let encoded = try? JSONEncoder().encode(historicalTasks) {
            UserDefaults.standard.set(encoded, forKey: analyticsStorageKey)
        }
    }
    
    private func syncAnalyticsLog(with allTasks: [TaskModel]) {
        var isChanged = false
        
        for task in allTasks {
            if !task.isCompleted {
                // Eğer kullanıcı tiki geri aldıysa (Uncheck), analitikten de sil!
                if historicalTasks[task.id] != nil {
                    historicalTasks.removeValue(forKey: task.id)
                    isChanged = true
                }
            } else {
                // Görev tamamlandıysa analitik loguna kaydet
                let cat = task.category?.rawValue ?? "Diğer"
                let date = task.completedAt ?? task.createdAt
                
                if let existing = historicalTasks[task.id] {
                    // Veride değişim varsa güncelle
                    if existing.category != cat || existing.completedAt != date {
                        historicalTasks[task.id] = AnalyticsTask(id: task.id, category: cat, completedAt: date)
                        isChanged = true
                    }
                } else {
                    // Yeni tamamlanmış görev
                    historicalTasks[task.id] = AnalyticsTask(id: task.id, category: cat, completedAt: date)
                    isChanged = true
                }
            }
        }
        
        // Not: Çöp kutusundan kalıcı olarak silinen görevler 'allTasks' içinde gelmez.
        // Bu yüzden yukarıdaki döngüye girmezler ve 'historicalTasks' içinde SONSUZA KADAR kalırlar!
        
        if isChanged {
            saveHistoricalTasks()
        }
    }
    
    // MARK: - REAL-TIME FILTER ENGINES
    
    private func updateCompletionRate() {
        let now = Date()
        let calendar = Calendar.current
        
        let pendingCount = storedActiveTasks.filter { !$0.isCompleted }.count
        
        let filteredCompletedCount = storedCompletedTasks.filter { task in
            let date = task.completedAt ?? task.createdAt
            switch completionRateFilter {
            case .daily: return calendar.isDateInToday(date)
            case .weekly: guard let past = calendar.date(byAdding: .day, value: -7, to: now) else { return true }; return date >= past
            case .monthly: guard let past = calendar.date(byAdding: .day, value: -30, to: now) else { return true }; return date >= past
            case .yearly: guard let past = calendar.date(byAdding: .year, value: -1, to: now) else { return true }; return date >= past
            case .allTime: return true
            }
        }.count
        
        let total = pendingCount + filteredCompletedCount
        
        if total > 0 {
            let rate = Int((Double(filteredCompletedCount) / Double(total)) * 100)
            self.completionRateString = "%\(rate)"
            self.userStats.completionRate = rate
        } else {
            self.completionRateString = "%0"
            self.userStats.completionRate = 0
        }
    }
    
    private func updatePeakTime() {
        let now = Date()
        let calendar = Calendar.current
        
        let filteredCompleted = storedCompletedTasks.filter { task in
            let date = task.completedAt ?? task.createdAt
            switch peakTimeFilter {
            case .daily: return calendar.isDateInToday(date)
            case .weekly: guard let past = calendar.date(byAdding: .day, value: -7, to: now) else { return true }; return date >= past
            case .monthly: guard let past = calendar.date(byAdding: .day, value: -30, to: now) else { return true }; return date >= past
            case .yearly: guard let past = calendar.date(byAdding: .year, value: -1, to: now) else { return true }; return date >= past
            case .allTime: return true
            }
        }
        
        var hourCounts: [Int: Int] = [:]
        for task in filteredCompleted {
            let date = task.completedAt ?? task.createdAt
            let hour = calendar.component(.hour, from: date)
            hourCounts[hour, default: 0] += 1
        }
        
        if let bestHour = hourCounts.max(by: { $0.value < $1.value })?.key {
            self.peakTimeString = String(format: "%02d:00", bestHour)
            self.userStats.efficiencyTime = self.peakTimeString
        } else {
            self.peakTimeString = "--:--"
            self.userStats.efficiencyTime = "--:--"
        }
    }
    
    private func updateFocusTime() {
        let now = Date()
        let calendar = Calendar.current
        
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
            self.userStats.timeSaved = "\(hours)sa \(mins)dk"
        } else {
            self.focusTimeString = "\(mins) Dk"
            self.userStats.timeSaved = "\(mins) Dk"
        }
    }
    
    // ✨ SENIOR YENİLİK: Kategori Grafiği Artık Ölümsüz Veriden Okur!
    private func updateCategoryDistribution() {
        let calendar = Calendar.current
        let now = Date()
        
        // Artık fiziksel dosyalara değil, ölümsüz analitik hafızasına bakıyoruz.
        let filteredAnalytics = historicalTasks.values.filter { task in
            let date = task.completedAt
            
            switch categoryTimeFilter {
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
        
        // Yeni kullanıcılar ve veri kaybı sorunu yaşanmayacağı için yamayı (Reconciliation) kaldırdık.
        // Artık sadece saf ve geçerli görev verileri yansıtılacak.
        self.categoryDistribution = generateCategoryData(from: Array(filteredAnalytics))
    }
    
    // MARK: - High-Performance Generators
    
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
    
    // ✨ SENIOR YENİLİK: Sadece analitik geçmişini kullanarak grafik datasını üretir
    private func generateCategoryData(from analyticsTasks: [AnalyticsTask]) -> [CategoryData] {
        // Hatalı veya boş isme sahip veriler elenir
        let validTasks = analyticsTasks.filter { !$0.category.isEmpty }
        
        let groups = Dictionary(grouping: validTasks, by: { $0.category })
        
        return groups.map { (key, value) in
            // Kategori enum'ından rengini güvenle çekiyoruz
            let categoryColor = Category(rawValue: key)?.color ?? .gray
            
            return CategoryData(
                category: key.uppercased(),
                count: value.count,
                color: categoryColor
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
