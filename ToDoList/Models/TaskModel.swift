import Foundation
import SwiftUI

// MARK: - Enums
/// Görevlerin kategorilerini tanımlar.
enum Category: String, CaseIterable, Codable, Identifiable {
    case business = "İş"
    case school = "Okul"
    case home = "Ev"
    case grocery = "Market"
    case sport = "Spor"
    case personal = "Kişisel"
    case project = "Proje"
    
    var id: String { self.rawValue }
    
    /// Kategoriye özgü sistem ikonları (SF Symbols).
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
    
    /// Kategoriye özgü renkler.
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

/// Görevlerin öncelik derecelerini tanımlar.
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
/// Temel Görev (To-Do) modeli.
struct TaskModel: AppEntity {
    var id: String = UUID().uuidString
    var title: String
    var isCompleted: Bool = false
    var priority: Priority = .medium
    var category: Category? = nil
    var createdAt: Date = Date()
    var isPrivate: Bool = false
    var note: String = ""
    
    var imageIDs: [String] = []
    var audioID: String?
    
    // ✨ RUTİN ENTEGRASYONU (Hayalet Çalışan ve Akıllı Yığılma İçin)
    // Varsayılan değer verildiği için projedeki hiçbir eski kodu bozmaz!
    var routineID: String? = nil
    var delayedCount: Int? = 0
}
