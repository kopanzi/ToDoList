import Foundation
import UserNotifications

/// Uygulama içi yerel bildirimleri (hatırlatıcıları) yönetir.
/// Senior Notu: Rutinler için Apple'ın kısıtlamalarını aşan "Gelecek Kuyruklama (Future Queueing)" eklendi.
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
    
    // MARK: - 🔁 RUTİN ENTEGRASYONU (Yeni Eklendi)
    
    /// Bir rutin için gelecekteki bildirimleri planlar (Uygulama kapalı olsa bile çalışır).
    func scheduleRoutineNotifications(for routine: RoutineModel) {
        // 1. Önce eski planlanmış bildirimleri temizle (Çakışmayı önlemek için)
        cancelRoutineNotification(for: routine.id)
        
        // 2. Rutin pasifse (Tatilde modu vb.) yeni bildirim kurma
        guard routine.isActive else { return }
        
        // 3. Bildirim içeriğini hazırla
        let content = UNMutableNotificationContent()
        content.title = "🔁 Rutin Vakti: \(routine.title)"
        content.body = routine.note.isEmpty ? "Alışkanlığını sürdürme zamanı geldi! 🔥 Masaya geçelim." : routine.note
        content.sound = .default
        content.threadIdentifier = routine.id // Kilit ekranında rutinleri bir araya (yığın) gruplar
        
        // 4. GELECEK KUYRUĞU (Sıradaki 5 Tetiklenmeyi Kur)
        var nextDate = routine.nextTriggerDate
        let calendar = Calendar.current
        
        for i in 1...5 {
            // Eğer tarih gelecekteyse alarmı kur
            if nextDate > Date() {
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                // Benzersiz bir ID ile planla (Örn: routineID_pending_1)
                let requestID = "\(routine.id)_pending_\(i)"
                let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
            
            // Bir sonraki alarm tarihini hesapla
            nextDate = calculateNextDate(from: nextDate, interval: routine.interval, frequency: routine.frequency)
        }
    }
    
    /// Bir rutine ait "tüm" planlanmış bildirimleri bulur ve iptal eder.
    func cancelRoutineNotification(for routineID: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Sadece bu rutinin ID'sini içeren bildirimleri filtrele
            let identifiersToRemove = requests
                .map { $0.identifier }
                .filter { $0.starts(with: routineID) }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    
    /// Zaman hesaplama motoru
    private func calculateNextDate(from date: Date, interval: Int, frequency: RoutineFrequency) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .hour:
            return calendar.date(byAdding: .hour, value: interval, to: date) ?? date
        case .day:
            return calendar.date(byAdding: .day, value: interval, to: date) ?? date
        case .week:
            return calendar.date(byAdding: .day, value: interval * 7, to: date) ?? date
        case .month:
            return calendar.date(byAdding: .month, value: interval, to: date) ?? date
        }
    }
}
