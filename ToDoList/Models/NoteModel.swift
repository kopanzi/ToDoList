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

// MARK: - Ana Not Modeli
/// Senior Notu: Property isimleri (baslik, icerik, tarih) View katmanıyla tam uyumlu hale getirildi.
struct NotModel: AppEntity {
    let id: String
    let baslik: String
    let icerik: String
    let tarih: Date
    var isPrivate: Bool
    
    // Medya Referansları
    var gorselIDListesi: [String]
    var sesID: String?
    
    init(id: String = UUID().uuidString,
         baslik: String,
         icerik: String,
         tarih: Date = Date(),
         isPrivate: Bool = false,
         gorselIDListesi: [String] = [],
         sesID: String? = nil) {
        
        self.id = id
        self.baslik = baslik
        self.icerik = icerik
        self.tarih = tarih
        self.isPrivate = isPrivate
        self.gorselIDListesi = gorselIDListesi
        self.sesID = sesID
    }
    
    // Protokol Uyumu için
    var createdAt: Date { tarih }
}
