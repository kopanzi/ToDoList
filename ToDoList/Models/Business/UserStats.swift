import Foundation

/// Kullanıcının üretkenlik performansını temsil eden veri modeli.
/// Senior Notu: Bu model sadece saf veriyi taşır (Data Carrier).
/// Hesaplama mantığı 'UserStatsService' içinde yaşar.
struct UserStats: Codable, Equatable {
    /// Görevlerin tamamlanma yüzdesi (Örn: 85 için %85)
    var completionRate: Int
    
    /// Aralıksız aktif olunan gün sayısı (Seri)
    var streakCount: Int
    
    /// Gün içindeki en verimli saat (Örn: "09:00")
    var efficiencyTime: String
    
    /// Üretkenlik sayesinde kazanılan toplam süre (Örn: "12sa")
    var timeSaved: String
    
    /// Haftalık duygu yoğunluğu verisi (Grafik için 7 adet 0.0 - 1.0 arası değer)
    var weeklyMoodIntensity: [Double]
    
    /// En yüksek odaklanma aralığı (Örn: "09:00 - 11:30")
    var efficiencyPeakRange: String
    
    /// Varsayılan/Boş değerlerle başlatma (Initial State)
    static var empty: UserStats {
        UserStats(
            completionRate: 0,
            streakCount: 0,
            efficiencyTime: "--:--",
            timeSaved: "0sa",
            weeklyMoodIntensity: [0, 0, 0, 0, 0, 0, 0],
            efficiencyPeakRange: "Veri bekleniyor"
        )
    }
}
