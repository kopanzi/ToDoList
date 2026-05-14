import Foundation
import UIKit

// MARK: - Global Yardımcı Yapılar
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ImagePreviewItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Ana Not Modeli (V2)
// ✨ SENIOR FIX: Buluta uçabilmesi için Codable ve Identifiable eklendi!
struct NotModel: AppEntity, Codable, Identifiable {
    let id: String
    let baslik: String
    let icerik: String
    let createdAt: Date
    var isPrivate: Bool
    
    var gorselIDListesi: [String]
    var sesID: String?
    var sesIDListesi: [String]?
    
    // Hem eski hem yeni sesleri tek listede birleştiren hesaplanmış özellik
    var tumSesler: [String] {
        var list = [String]()
        if let s = sesID, !s.isEmpty { list.append(s) }
        if let sList = sesIDListesi { list.append(contentsOf: sList) }
        return list
    }
    
    var tarih: Date { createdAt }
    
    init(id: String = UUID().uuidString,
         baslik: String,
         icerik: String,
         createdAt: Date = Date(),
         isPrivate: Bool = false,
         gorselIDListesi: [String] = [],
         sesID: String? = nil,
         sesIDListesi: [String]? = []) {
        
        self.id = id
        self.baslik = baslik
        self.icerik = icerik
        self.createdAt = createdAt
        self.isPrivate = isPrivate
        self.gorselIDListesi = gorselIDListesi
        self.sesID = sesID
        self.sesIDListesi = sesIDListesi
    }
}
