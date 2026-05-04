import Foundation
import SwiftUI
import Combine
import Charts

/// İstatistik ekranı için ham görev verilerini işleyip grafik formatına getiren beyin.
/// Senior Notu: Karmaşık tarih gruplama işlemleri 'Performance' odaklı olarak arka planda yapılır.
final class StatisticsViewModel: ObservableObject {
    
    // MARK: - Plottable Data Types
    
    // ✨ SENIOR FIX: Her iki modele de Equatable eklendi
    struct DailyActivity: Identifiable, Equatable {
        let id = UUID()
        let date: Date
        let count: Int
    }
    
    struct CategoryData: Identifiable, Equatable {
        let id = UUID()
        let category: String
        let count: Int
        let color: Color
    }
    
    // MARK: - Published Properties
    @Published var heatmapData: [DailyActivity] = []
    @Published var weeklyData: [DailyActivity] = []
    @Published var categoryDistribution: [CategoryData] = []
    @Published var totalFocusMinutes: Int = 0
    @Published var averageCompletionTime: String = "--:--"
    
    // ✨ SENIOR FIX: Profildeki 4'lü istatistik verisini buraya taşıdık
    @Published var userStats: UserStats = .empty
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Logic
    
    /// TaskViewModel'den gelen aktif ve arşivlenmiş görevleri birleştirerek analiz eder.
    func processTasks(activeTasks: [TaskModel], archivedTasks: [TaskModel], lifetimeAdded: Int, lifetimeCompleted: Int) {
        // ✨ SENIOR FIX: Sadece ekrandaki değil, geçmişteki tüm bitmiş görevleri analize dahil ediyoruz.
        let allTasks = activeTasks + archivedTasks
        let completedTasks = allTasks.filter { $0.isCompleted }
        
        // 1. Genel İstatistikleri Hesapla
        self.userStats = UserStatsService.shared.calculateStats(from: allTasks)
        
        // 🔥 KRİTİK DÜZELTME: Bitirme oranını ekrandaki azalan görevlere göre değil,
        // Yaver'in asla silinmeyen ömür boyu (lifetime) sayaçlarına göre eziyoruz.
        if lifetimeAdded > 0 {
            self.userStats.completionRate = Int((Double(lifetimeCompleted) / Double(lifetimeAdded)) * 100)
        } else {
            self.userStats.completionRate = 0
        }
        
        // 2. Grafikler için Data Üretimi (Geçmiş dahil)
        self.heatmapData = generateHeatmapData(from: completedTasks)
        
        // 3. Haftalık Ritim (Son 7 Gün)
        self.weeklyData = generateWeeklyData(from: completedTasks)
        
        // 4. Kategori Dağılımı
        self.categoryDistribution = generateCategoryData(from: completedTasks)
        
        // 5. Ortalama Tamamlama Saati (Hassas Zaman)
        calculateAverageTime(from: completedTasks)
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
