import SwiftUI

/// Görev yoğunluğunu ve önceliklerini analiz ederek uygulamanın 'Mood'unu (Duygu Durumu) belirleyen servis.
/// Senior Notu: Bu servis saf bir mantık (Business Logic) katmanıdır.
/// ViewModel'den aldığı ham veriyi işleyerek AppearanceManager'a sinyal gönderir.
final class MoodService {
    
    // MARK: - Singleton
    static let shared = MoodService()
    private init() {}
    
    // MARK: - Mood Types
    /// Kullanıcının iş yüküne göre belirlenen duygu durumları.
    enum UserMood: String, CaseIterable {
        case zen         // Sakin: Görev az veya hepsi düşük öncelikli. (Yeşil/Mavi Tonlar)
        case productive  // Verimli: Normal iş temposu, dengeli dağılım. (Mavi/Mor Tonlar)
        case urgent      // Acil: Çok fazla yüksek öncelikli görev birikmiş. (Turuncu/Kırmızı Tonlar)
    }
    
    // MARK: - Logic
    
    /// Verilen görev listesini analiz ederek uygun duygu durumunu hesaplar.
    /// - Parameter tasks: Analiz edilecek görev dizisi.
    /// - Returns: Hesaplanan UserMood.
    func calculateMood(from tasks: [TaskModel]) -> UserMood {
        // 1. Sadece tamamlanmamış (aktif) görevleri filtrele
        let activeTasks = tasks.filter { !$0.isCompleted }
        
        // 2. Eğer hiç aktif görev yoksa direkt 'Zen' moduna geç (Kullanıcıyı rahatlat)
        guard !activeTasks.isEmpty else { return .zen }
        
        // 3. Kritik öneme sahip görevleri say (Yüksek ve Çok Acil)
        let urgentTasksCount = activeTasks.filter {
            $0.priority == .urgent || $0.priority == .high
        }.count
        
        // 4. Stres Oranı Hesaplama: (Kritik İşler / Toplam Aktif İşler)
        let stressRatio = Double(urgentTasksCount) / Double(activeTasks.count)
        
        // MARK: - Senior Karar Algoritması
        
        // EŞİK 1: Eğer aktif görevlerin %50'den fazlası acilse veya toplamda 5'ten fazla acil iş varsa
        if stressRatio > 0.5 || urgentTasksCount >= 5 {
            return .urgent
        }
        
        // EŞİK 2: Eğer aktif görevlerin %15'inden fazlası acilse veya toplamda 3'ten fazla aktif görev varsa
        else if stressRatio > 0.15 || activeTasks.count > 3 {
            return .productive
        }
        
        // VARSAYILAN: İşler kontrol altında
        else {
            return .zen
        }
    }
}
