import Foundation
import EventKit

/// Yaver'in iOS yerel takvimi (Apple Calendar) ile konuşmasını sağlayan servis.
/// Senior Notu: EventKit'in karmaşık yapısını ve izin yönetimini izole ederek,
/// uygulamanın (ViewModel'lerin) geri kalanını temiz tutar.
@MainActor // EKEventStore Thread-Safety uyarılarını önlemek için MainActor'e alındı
final class CalendarService {
    
    // MARK: - Singleton
    static let shared = CalendarService()
    
    // EKEventStore'un tek bir instance (merkezi) olarak tutulması Apple tarafından şiddetle önerilir.
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - İzin (Permission) Yönetimi
    
    /// Takvime etkinlik eklemek için gerekli izinleri asenkron olarak ister.
    func requestAccess() async throws -> Bool {
        var granted = false
        
        do {
            // iOS 17 ve sonrası için yeni güvenlik modeli (Tam erişim gereklidir)
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                // iOS 16 ve öncesi için geleneksel erişim izni
                granted = try await eventStore.requestAccess(to: .event)
            }
        } catch {
            print("🛑 Takvim izni istenirken hata oluştu: \(error.localizedDescription)")
            throw error
        }
        
        return granted
    }
    
    // MARK: - Etkinlik Ekleme
    
    /// Verilen görev verilerini kullanarak doğrudan cihazın yerel takvimine etkinlik oluşturur.
    func saveTaskToCalendar(title: String, date: Date, note: String) throws {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = date
        // Standart odaklanma (Pomodoro) mantığına uygun olarak 1 saatlik blok ayarlanır
        event.endDate = date.addingTimeInterval(3600)
        
        // Eğer görev notu boşsa, takvimde havalı bir varsayılan not görünür
        event.notes = note.isEmpty ? "Yaver Uygulamasından Eklendi 🚀" : note
        
        // Kullanıcının iOS'ta seçtiği varsayılan etkinlik takvimini bul (iCloud, Gmail vb.)
        guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
            print("🛑 Varsayılan takvim bulunamadı.")
            throw NSError(domain: "CalendarService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Varsayılan takvim bulunamadı."])
        }
        
        event.calendar = defaultCalendar
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Takvime başarıyla eklendi: \(title)")
        } catch {
            print("🛑 Takvime kaydedilirken hata oluştu: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Overloads (Kullanım Kolaylığı)
    
    /// Doğrudan bir `TaskModel` objesi alarak takvime kaydetme kolaylığı sağlar (Eski koduna ithafen).
    func saveTaskToCalendar(task: TaskModel) throws {
        try saveTaskToCalendar(title: task.title, date: task.createdAt, note: task.note)
    }
}
