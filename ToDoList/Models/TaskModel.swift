import Foundation
import SwiftUI

// MARK: - Enums
enum Category: String, CaseIterable, Codable, Identifiable {
    case business = "İş"
    case school = "Okul"
    case home = "Ev"
    case grocery = "Market"
    case sport = "Spor"
    case personal = "Kişisel"
    case project = "Proje"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .business: return "briefcase.fill"
        case .school: return "graduationcap.fill"
        case .home: return "house.fill"
        case .grocery: return "cart.fill"
        case .sport: return "figure.run"
        case .personal: return "person.fill"
        case .project: return "hammer.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .business: return .blue
        case .school: return .orange
        case .home: return .green
        case .grocery: return .pink
        case .sport: return .red
        case .personal: return .purple
        case .project: return .indigo
        }
    }
}

enum Priority: String, CaseIterable, Codable {
    case low = "Düşük"
    case medium = "Orta"
    case high = "Yüksek"
    case urgent = "Çok Acil"
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

// MARK: - Model
struct TaskModel: AppEntity, Equatable, Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var isCompleted: Bool = false
    var priority: Priority = .medium
    var category: Category? = nil
    var createdAt: Date = Date()
    var completedAt: Date? = nil
    var isPrivate: Bool = false
    var note: String = ""
    var imageIDs: [String] = []
    var audioID: String?
    var routineID: String? = nil
    var delayedCount: Int? = 0
    
    // 🛡️ SENIOR FIX: FIRESTORE GÜVENLİK DUVARI (CodingKeys)
    // Firestore'a "Sadece bu listedekileri al, renklere/ikonlara karışma!" diyoruz.
    enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, priority, category, createdAt, completedAt, isPrivate, note, imageIDs, audioID, routineID, delayedCount
    }
}
