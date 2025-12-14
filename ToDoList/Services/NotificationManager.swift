import Foundation
import UserNotifications

class NotificationManager {
    
    // Tekil instance (Singleton) - Her yerden buna ulaşacağız
    static let shared = NotificationManager()
    
    // 1. İzin İsteme Fonksiyonu
    func izinIste() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { basarili, hata in
            if basarili {
                print("Bildirim izni verildi! ✅")
            } else if let hata = hata {
                print("İzin hatası: \(hata.localizedDescription)")
            }
        }
    }
    
    // 2. Bildirim Planlama Fonksiyonu
    func bildirimPlanla(gorev: GorevModel) {
        // İçerik oluştur
        let icerik = UNMutableNotificationContent()
        icerik.title = "Hatırlatma: \(gorev.onem.rawValue)"
        icerik.body = gorev.baslik
        icerik.sound = .default
        
        // Tarihi hesapla (Görevin tarihinden bileşenleri al)
        let tarihBilesenleri = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: gorev.tarih)
        
        // Tetikleyici oluştur (O tarih gelince çalış)
        let tetikleyici = UNCalendarNotificationTrigger(dateMatching: tarihBilesenleri, repeats: false)
        
        // İsteği oluştur
        let istek = UNNotificationRequest(identifier: gorev.id.uuidString, content: icerik, trigger: tetikleyici)
        
        // Sisteme ekle
        UNUserNotificationCenter.current().add(istek)
        print("Bildirim planlandı: \(gorev.baslik) - \(gorev.tarih)")
    }
    
    // Tamamlanan görevin bildirimini iptal etme (Opsiyonel ama şık olur)
    func bildirimIptalEt(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
