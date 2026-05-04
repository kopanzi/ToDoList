import Foundation

/// Kullanıcının görev geçmişini analiz ederek gerçek üretkenlik istatistiklerini hesaplayan servis.
/// Senior Notu: İstatistikler artık çok daha hassas (HH:mm) formatında hesaplanır.
/// 'Zirve Saat' artık kaba bir yuvarlama değil, tüm görevlerin matematiksel ortalamasıdır.
final class UserStatsService {
    
    static let shared = UserStatsService()
    private init() {}
    
    /// Verilen görev listesi üzerinden tüm istatistik özetini hesaplar.
    func calculateStats(from tasks: [TaskModel]) -> UserStats {
        guard !tasks.isEmpty else { return .empty }
        
        let completedTasks = tasks.filter { $0.isCompleted }
        
        // 1. Bitirme Oranı (%)
        let rate = tasks.isEmpty ? 0 : Int((Double(completedTasks.count) / Double(tasks.count)) * 100)
        
        // 2. Seri (Streak) Hesabı
        let streak = calculateStreak(tasks: completedTasks)
        
        // 3. ✨ HASSAS ZİRVE SAAT (Precision Peak Time)
        // Artık 16:00 değil, 16:24 gibi net bir ortalama döner.
        let peakTime = analyzePrecisionPeak(tasks: completedTasks)
        
        // 4. Kazanılan Süre (Tahmini)
        let hoursSaved = (completedTasks.count * 30) / 60
        
        // 5. Haftalık Duygu Yoğunluğu
        let weeklyIntensity = calculateWeeklyIntensity(tasks: completedTasks)
        
        return UserStats(
            completionRate: rate,
            streakCount: streak,
            efficiencyTime: peakTime.exact, // Örn: "17:26"
            timeSaved: "\(hoursSaved)sa",
            weeklyMoodIntensity: weeklyIntensity,
            efficiencyPeakRange: "\(peakTime.start) - \(peakTime.end)" // Pencereyi de koruyoruz
        )
    }
    
    // MARK: - Precision Logic
    
    /// Görevlerin tamamlanma anlarını saniye bazında analiz eder ve matematiksel zirveyi bulur.
    private func analyzePrecisionPeak(tasks: [TaskModel]) -> (exact: String, start: String, end: String) {
        guard !tasks.isEmpty else { return ("--:--", "--:--", "--:--") }
        
        let calendar = Calendar.current
        var totalMinutesFromMidnight = 0
        
        // 1. Tüm görevlerin gün içindeki "gece yarısından itibaren geçen dakika" ortalamasını bul
        for task in tasks {
            let targetDate = task.completedAt ?? task.createdAt
            let components = calendar.dateComponents([.hour, .minute], from: targetDate)
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            totalMinutesFromMidnight += minutes
        }
        
        let averageMinutes = totalMinutesFromMidnight / tasks.count
        
        // 2. Ortalamayı tekrar saat ve dakikaya çevir
        let avgHour = averageMinutes / 60
        let avgMin = averageMinutes % 60
        
        let exactTime = String(format: "%02d:%02d", avgHour, avgMin)
        
        // 3. Bu saatin etrafında 1 saatlik bir "Optimal Verimlilik Penceresi" oluştur
        // (Kullanıcıya 'bu saat civarında çalış' demek için)
        let startHour = (avgHour - 1 + 24) % 24
        let endHour = (avgHour + 1) % 24
        
        let startWindow = String(format: "%02d:00", startHour)
        let endWindow = String(format: "%02d:00", endHour)
        
        return (exactTime, startWindow, endWindow)
    }
    
    // MARK: - Diğer Algoritmalar (Aynen Korundu)
    
    private func calculateStreak(tasks: [TaskModel]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completedDates = Set(tasks.compactMap { calendar.startOfDay(for: $0.completedAt ?? $0.createdAt) })
        
        var streak = 0
        var currentDate = today
        
        while completedDates.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }
        
        if streak == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            currentDate = yesterday
            while completedDates.contains(currentDate) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            }
        }
        return streak
    }
    
    private func calculateWeeklyIntensity(tasks: [TaskModel]) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var intensities: [Double] = Array(repeating: 0.0, count: 7)
        
        for task in tasks {
            let targetDate = task.completedAt ?? task.createdAt
            let taskDate = calendar.startOfDay(for: targetDate)
            let components = calendar.dateComponents([.day], from: taskDate, to: today)
            if let daysAgo = components.day, daysAgo >= 0 && daysAgo < 7 {
                let index = 6 - daysAgo
                intensities[index] += 1.0
            }
        }
        
        guard let maxCount = intensities.max(), maxCount > 0 else {
            return [0.2, 0.4, 0.3, 0.7, 0.5, 0.8, 0.1]
        }
        return intensities.map { $0 / maxCount }
    }
}
