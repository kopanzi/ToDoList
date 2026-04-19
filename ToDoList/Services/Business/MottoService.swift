import SwiftUI

/// Günlük mottoları sıralı bir şekilde veren ve 24 saatlik döngüyü AppStorage ile takip eden servis.
final class MottoService {
    static let shared = MottoService()
    
    // Cihaz hafızasında son güncelleme tarihini ve şu anki sözün sırasını tutuyoruz.
    @AppStorage("lastMottoUpdateDate") private var lastUpdateDate: Double = 0
    @AppStorage("currentMottoIndex") private var currentIndex: Int = 0
    
    private init() {}
    
    /// 24 saat kontrolü yaparak sıradaki mottoyu döndürür.
    func getDailyMotto() -> String {
        let now = Date().timeIntervalSince1970
        let secondsInDay: TimeInterval = 10 // 24 Saat = 86400 Saniye
        
        // Kullanıcı uygulamayı ilk kez açıyorsa
        if lastUpdateDate == 0 {
            lastUpdateDate = now
            return MottoList.quotes[currentIndex]
        }
        
        // En son güncellemenin üzerinden tam 24 saat geçtiyse
        if now - lastUpdateDate >= secondsInDay {
            // İndeksi 1 artır, listenin sonuna gelirse başa dön (Modulo mantığı)
            currentIndex = (currentIndex + 1) % MottoList.quotes.count
            lastUpdateDate = now
        }
        
        return MottoList.quotes[currentIndex]
    }
}
