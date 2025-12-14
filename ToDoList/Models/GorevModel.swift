import SwiftUI

// Codable ekledik: Artık bu veriyi diske kaydedebiliriz
enum OnemDerecesi: String, CaseIterable, Codable {
    case dusuk = "Düşük"
    case orta = "Orta"
    case yuksek = "Yüksek"
    case acil = "Çok Acil"
    
    var renk: Color {
        switch self {
        case .dusuk: return .blue
        case .orta: return .orange
        case .yuksek: return .red
        case .acil: return .purple
        }
    }
}

// Codable ekledik
struct GorevModel: Identifiable, Codable {
    let id: UUID
    var baslik: String
    var tamamlandi: Bool
    var onem: OnemDerecesi
    var tarih: Date
    
    // Varsayılan değerler için initializer (Bu kolaylık sağlar)
    init(id: UUID = UUID(), baslik: String, tamamlandi: Bool = false, onem: OnemDerecesi = .orta, tarih: Date = Date()) {
        self.id = id
        self.baslik = baslik
        self.tamamlandi = tamamlandi
        self.onem = onem
        self.tarih = tarih
    }
}
