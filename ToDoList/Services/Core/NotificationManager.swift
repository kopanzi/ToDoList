import Foundation
import UserNotifications

/// Uygulama içi yerel bildirimleri (hatırlatıcıları) yönetir.
final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Kullanıcıdan bildirim izni ister.
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Bildirim izni alındı.")
            } else if let error = error {
                print("🛑 Bildirim izni hatası: \(error.localizedDescription)")
            }
        }
    }
    
    /// Bir görev için yerel bildirim planlar.
    func scheduleNotification(for task: TaskModel) {
        let content = UNMutableNotificationContent()
        content.title = "Görev Hatırlatıcı 🔔"
        content.body = task.title
        content.sound = .default
        
        // Görev tarihinden 5 dakika önce hatırlat (Örnek mantık)
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.createdAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// İptal edilen veya silinen görevin bildirimini kaldırır.
    func cancelNotification(for taskID: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskID])
    }
}
