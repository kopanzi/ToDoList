import Foundation
import UIKit

// MARK: - Global Yardımcı Yapılar
// Senior Notu: Bu yapıların burada tanımlanması çakışmaları (ambiguity) önler.

/// Görselleri SwiftUI listelerinde kimlikli kullanmak için sarmalayıcı.
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// .fullScreenCover içinde görselleri önizlemek için gereken yapı.
struct ImagePreviewItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Ana Not Modeli (V2)

/// Not defteri için optimize edilmiş, AppEntity protokolüne tam uyumlu veri modeli.
/// Senior Notu: Protokol gereksinimi olan 'createdAt' eklendi, 'tarih' ise
/// View'ların kırılmaması için computed property olarak korundu.
struct NotModel: AppEntity {
    let id: String
    let baslik: String
    let icerik: String
    let createdAt: Date // ✅ AppEntity protokolü için 'tarih' ismi 'createdAt' olarak güncellendi.
    var isPrivate: Bool
    
    var gorselIDListesi: [String]
    var sesID: String? // Eski sürüm (Legacy) uyumluluğu için korundu
    var sesIDListesi: [String]? // ✨ YENİ: Çoklu ses desteği
    
    // ✨ YENİ: Hem eski hem yeni sesleri tek listede birleştiren hesaplanmış özellik
    var tumSesler: [String] {
        var list = [String]()
        if let s = sesID, !s.isEmpty { list.append(s) }
        if let sList = sesIDListesi { list.append(contentsOf: sList) }
        return list
    }
    
    // 🔥 GERİYE DÖNÜK UYUMLULUK:
    // Mevcut View'ların (NoteDetailView, NoteRowView vb.) 'note.tarih' çağrıları
    // hata vermesin diye bu hesaplanmış mülkü ekliyoruz.
    var tarih: Date { createdAt }
    
    init(id: String = UUID().uuidString,
         baslik: String,
         icerik: String,
         createdAt: Date = Date(), // Protokol standardı
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
