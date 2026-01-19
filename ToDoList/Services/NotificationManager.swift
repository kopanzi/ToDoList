import Foundation
import UserNotifications

// NSObject ve Delegate ekledik: Uygulama açıkken de bildirimleri yakalamak için şart!
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        // Delegate ataması yapıyoruz
        UNUserNotificationCenter.current().delegate = self
    }
    
    // 1. İZİN İSTEME
    func izinIste() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Bildirim izni verildi! ✅")
            } else if let error = error {
                print("Bildirim hatası: \(error.localizedDescription)")
            }
        }
    }
    
    // 2. GÖREV PLANLAMA (Takvim Bazlı)
    func bildirimPlanla(gorev: GorevModel) {
        let content = UNMutableNotificationContent()
        content.title = "Hatırlatma: \(gorev.baslik)"
        content.body = gorev.not.isEmpty ? "Görevi tamamlama zamanı!" : gorev.not
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: gorev.tarih)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: gorev.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        print("⏰ Görev için bildirim kuruldu: \(gorev.baslik)")
    }
    
    // 3. ANLIK BİLDİRİM GÖNDER (Pomodoro ve Test İçin Yeni Özellik 🚀)
    func anlikBildirimGonder(baslik: String, icerik: String) {
        let content = UNMutableNotificationContent()
        content.title = baslik
        content.body = icerik
        content.sound = .default
        
        // 1 saniye sonra tetikle (Hemen gelmesi için)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // 4. BİLDİRİM İPTALİ
    func bildirimIptal(gorev: GorevModel) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [gorev.id])
    }
    
    // MARK: - DELEGATE METODU (SİHİRLİ KISIM ✨)
    // Uygulama ön plandayken (kullanıcı ekrana bakarken) bildirimin görünmesini sağlar.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Banner göster, ses çal, badge göster
        completionHandler([.banner, .sound, .badge])
    }
}
