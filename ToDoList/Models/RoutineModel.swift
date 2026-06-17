import Foundation

/// Rutinlerin tekrar sıklığını belirleyen zaman birimleri.
enum RoutineFrequency: String, Codable, CaseIterable {
    case hour = "Saat"
    case day = "Gün"
    case week = "Hafta"
    case month = "Ay"
}

/// "Görev Fabrikası".
struct RoutineModel: Identifiable, Codable, Equatable {
    let id: String
    
    // MARK: - Şablon Bilgileri
    var title: String
    var priority: Priority
    var category: Category?
    var note: String
    
    // MARK: - Zamanlama Motoru
    var startDate: Date
    var interval: Int
    var frequency: RoutineFrequency
    var nextTriggerDate: Date
    
    // MARK: - Oyunlaştırma (Gamification)
    var streakCount: Int
    var freezeCount: Int
    var lastCompletedDate: Date?
    
    // MARK: - Durum (State)
    var isActive: Bool
    let createdAt: Date
    
    // 🛡️ SENIOR FIX: FIRESTORE GÜVENLİK DUVARI (CodingKeys)
    enum CodingKeys: String, CodingKey {
        case id, title, priority, category, note, startDate, interval, frequency, nextTriggerDate, streakCount, freezeCount, lastCompletedDate, isActive, createdAt
    }
    
    init(id: String = UUID().uuidString, title: String, priority: Priority = .medium, category: Category? = nil, note: String = "", startDate: Date, interval: Int, frequency: RoutineFrequency, freezeCount: Int = 0, isActive: Bool = true) {
        self.id = id
        self.title = title
        self.priority = priority
        self.category = category
        self.note = note
        self.startDate = startDate
        self.interval = interval
        self.frequency = frequency
        self.isActive = isActive
        self.createdAt = Date()
        self.streakCount = 0
        self.freezeCount = freezeCount
        self.nextTriggerDate = startDate
    }
    
    // 📚 YENİ: Hazır Alışkanlık Şablonları (Templates)
    static let templates: [RoutineModel] = [
        RoutineModel(title: "Su İç", priority: .medium, category: .personal, note: "Günde en az 2 litre", startDate: Date(), interval: 2, frequency: .hour),
        RoutineModel(title: "Kitap Oku", priority: .low, category: .personal, note: "Günde 20 sayfa", startDate: Date(), interval: 1, frequency: .day),
        RoutineModel(title: "İlaç Al", priority: .urgent, category: .personal, note: "Doktorun yazdığı ilaçlar", startDate: Date(), interval: 8, frequency: .hour),
        RoutineModel(title: "Egzersiz Yap", priority: .high, category: .sport, note: "30 dakika kardiyo", startDate: Date(), interval: 1, frequency: .day),
        RoutineModel(title: "Yabancı Dil", priority: .medium, category: .school, note: "15 dakika kelime pratiği", startDate: Date(), interval: 1, frequency: .day)
    ]
}
