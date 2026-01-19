import Foundation
import SwiftUI

// --- 1. KATEGORİLER ---
enum Kategori: String, CaseIterable, Codable, Identifiable {
    case isYeri = "İş"
    case okul = "Okul"
    case ev = "Ev"
    case market = "Market"
    case spor = "Spor"
    case kisisel = "Kişisel"
    case proje = "Proje"
    
    var id: String { self.rawValue }
    
    var ikon: String {
        switch self {
        case .isYeri: return "briefcase.fill"
        case .okul: return "graduationcap.fill"
        case .ev: return "house.fill"
        case .market: return "cart.fill"
        case .spor: return "figure.run"
        case .kisisel: return "person.fill"
        case .proje: return "hammer.fill"
        }
    }
    
    var renk: Color {
        switch self {
        case .isYeri: return .blue
        case .okul: return .orange
        case .ev: return .green
        case .market: return .pink
        case .spor: return .red
        case .kisisel: return .purple
        case .proje: return .indigo
        }
    }
}

// --- 2. ÖNEM DERECESİ ---
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

// --- 3. GÖREV MODELİ ---
struct GorevModel: Identifiable, Codable {
    var id: String = UUID().uuidString
    var baslik: String
    var tamamlandi: Bool = false
    var onem: OnemDerecesi = .orta
    
    // ✨ YENİ: Kategori artık Opsiyonel (Kategori? = nil)
    // Varsayılan değer nil, yani kategorisiz.
    var kategori: Kategori? = nil
    
    var tarih: Date = Date()
    var gizliMi: Bool = false
    
    var not: String = ""
    var gorselListesi: [Data] = []
    var sesKaydiData: Data?
}
