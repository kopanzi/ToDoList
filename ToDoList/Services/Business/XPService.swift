import Foundation
import SwiftUI

/// XP puanlarını ve rütbe geçişlerini hesaplayan merkezi servis.
/// Senior Notu: Görev zorluğuna göre dinamik çarpan (Multiplier) içerir.
final class XPService {
    static let shared = XPService()
    
    // 🛠️ TEST MODU: Geliştirme aşamasında seviyeleri hızlı görmek için taban XP 50 yapıldı.
    // Uygulama markete çıkarken burayı 10 yapabiliriz.
    private let baseTaskXP: Double = 50.0
    
    private init() {}
    
    /// Tamamlanma durumuna ve GÖREV ZORLUĞUNA (Priority) göre puan hesaplar.
    func calculateXP(for task: TaskModel, isCompleted: Bool) -> Int {
        var multiplier: Double = 1.0
        
        switch task.priority {
        case .low: multiplier = 1.0       // x1.0
        case .medium: multiplier = 1.5    // x1.5
        case .high: multiplier = 2.0      // x2.0
        case .urgent: multiplier = 2.5    // x2.5
        }
        
        let earnedXP = Int(baseTaskXP * multiplier)
        
        // Görev tamamlandıysa artı puan, tiki geri alındıysa eksi puan
        return isCompleted ? earnedXP : -earnedXP
    }
    
    /// Mevcut toplam XP'ye göre kullanıcının rütbesini bulur.
    func getCurrentRank(for xp: Int) -> Rank {
        // Rütbeleri büyükten küçüğe kontrol ederek uygun olanı döndürür.
        return Rank.allCases.reversed().first { xp >= $0.rawValue } ?? .odakYolcusu
    }
    
    /// Mevcut rütbe barı için ilerleme yüzdesini hesaplar (0.0 - 1.0).
    func getProgressPercentage(xp: Int) -> Double {
        let currentRank = getCurrentRank(for: xp)
        
        guard let nextThreshold = currentRank.nextThreshold else {
            return 1.0 // Maksimum rütbedeyse bar tam doludur.
        }
        
        let currentXPInLevel = Double(xp - currentRank.rawValue)
        let totalXPNeededInLevel = Double(nextThreshold - currentRank.rawValue)
        
        // Matematiksel taşmaları önlemek için 0 ile 1 arasına sabitliyoruz.
        return max(0, min(1.0, currentXPInLevel / totalXPNeededInLevel))
    }
}
