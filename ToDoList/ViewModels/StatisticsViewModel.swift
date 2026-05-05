import Foundation
import SwiftUI
import Combine
import Charts

/// İstatistik ekranı için ham görev verilerini işleyip grafik formatına getiren beyin.
/// Senior Notu: Karmaşık tarih gruplama işlemleri 'Performance' odaklı olarak arka planda yapılır.
final class StatisticsViewModel: ObservableObject {
    
    // MARK: - Plottable Data Types
    
    struct DailyActivity: Identifiable, Equatable {
        let id = UUID()
        let date: Date
        let count: Int
    }
    
    // ✨ YENİ: Erteleme Yüzleşmesi Veri Modeli
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
    
    // Zaman Filtresi Seçenekleri (Kategori Analizi İçin)
    enum TimeFilter: String, CaseIterable, Identifiable {
        case daily = "Bugün"
        case weekly = "Bu Hafta"
        case monthly = "Bu Ay"
        case yearly = "Bu Yıl"
        case allTime = "Tümü"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Published Properties
    @Published var heatmapData: [DailyActivity] = []
    @Published var weeklyData: [DailyActivity] = []
    
    // ✨ YENİ: Erteleme Grafiğini Besleyecek Dizi
    @Published var procrastinationData: [ProcrastinationData] = []
    
    @Published var categoryDistribution: [CategoryData] = []
    @Published var totalFocusMinutes: Int = 0
    @Published var averageCompletionTime: String = "--:--"
    
    // Profildeki 4'lü istatistik verisini buraya taşıdık
    @Published var userStats: UserStats = .empty
    
    // Kategori grafiği için kullanıcının seçtiği filtre durumu
    @Published var categoryTimeFilter: TimeFilter = .allTime {
        didSet { updateCategoryDistribution() } // Filtre her değiştiğinde grafiği anında güncelle
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // Filtre değiştiğinde sistemi yormadan yeniden hesaplayabilmek için veriyi önbellekte tutuyoruz
    private var storedCompletedTasks: [TaskModel] = []
    
    // MARK: - Logic
    
    /// TaskViewModel'den gelen aktif ve arşivlenmiş görevleri birleştirerek analiz eder.
    func processTasks(activeTasks: [TaskModel], archivedTasks: [TaskModel], lifetimeAdded: Int, lifetimeCompleted: Int) {
        let allTasks = activeTasks + archivedTasks
        let completedTasks = allTasks.filter { $0.isCompleted }
        
        // Sadece biten görevleri filtreleme motoru için hafızaya al
        self.storedCompletedTasks = completedTasks
        
        // 1. Genel İstatistikleri Hesapla
        self.userStats = UserStatsService.shared.calculateStats(from: allTasks)
        
        // Defansif Programlama (Defensive Math & Clamping)
        if lifetimeAdded > 0 {
            // Tamamlanan görev sayısı ASLA toplamı geçemez (Güvenlik kilidi)
            let safeCompleted = min(lifetimeCompleted, lifetimeAdded)
            
            // Sıfıra bölünme riskini sıfıra indiriyoruz
            let safeAdded = max(lifetimeAdded, 1)
            
            self.userStats.completionRate = Int((Double(safeCompleted) / Double(safeAdded)) * 100)
        } else {
            self.userStats.completionRate = 0
        }
        
        // 2. Grafikler için Data Üretimi (Geçmiş dahil)
        self.heatmapData = generateHeatmapData(from: completedTasks)
        self.weeklyData = generateWeeklyData(from: completedTasks)
        
        // ✨ YENİ: Erteleme Verilerini Hesapla (Tüm geçmiş dahil)
        self.procrastinationData = generateProcrastinationData(from: allTasks)
        
        // 3. Kategori Dağılımını Güncelle (Seçili Filtreye Göre)
        updateCategoryDistribution()
        
        // 4. Hassas Ortalama Zaman
        calculateAverageTime(from: completedTasks)
    }
    
    // Seçilen zaman filtresine göre kategorileri yeniden hesaplar
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
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return true }
                return date >= monthAgo
            case .yearly:
                guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) else { return true }
                return date >= yearAgo
            case .allTime:
                return true
            }
        }
        
        // Filtrelenmiş görevleri kategori donut grafiği için modele dök
        self.categoryDistribution = generateCategoryData(from: filteredTasks)
    }
    
    // MARK: - Generators
    
    // ✨ YENİ: Zıt Yönlü Çubuklar için Başarı vs Erteleme Analizi
    private func generateProcrastinationData(from allTasks: [TaskModel]) -> [ProcrastinationData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Son 7 günü tarıyoruz (Haftalık yüzleşme en idealidir)
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            
            // O gün bitirilen zaferler
            let completedCount = allTasks.filter {
                $0.isCompleted && calendar.isDate($0.completedAt ?? $0.createdAt, inSameDayAs: date)
            }.count
            
            // O günün sırtındaki "Erteleme Yükü" (O güne ait aktif/pasif tüm görevlerin gecikme maliyeti)
            let delayedCount = allTasks.filter {
                calendar.isDate($0.completedAt ?? $0.createdAt, inSameDayAs: date)
            }.reduce(0) { $0 + ($1.delayedCount ?? 0) }
            
            return ProcrastinationData(date: date, completed: completedCount, delayed: delayedCount)
        }.reversed()
    }
    
    private func generateHeatmapData(from tasks: [TaskModel]) -> [DailyActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [DailyActivity] = []
        
        // Son 90 günü tara
        for i in 0..<90 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let count = tasks.filter { calendar.isDate($0.completedAt ?? $0.createdAt, inSameDayAs: date) }.count
                data.append(DailyActivity(date: date, count: count))
            }
        }
        return data.reversed()
    }
    
    private func generateWeeklyData(from tasks: [TaskModel]) -> [DailyActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let count = tasks.filter { calendar.isDate($0.completedAt ?? $0.createdAt, inSameDayAs: date) }.count
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
