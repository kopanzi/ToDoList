import SwiftUI

/// Uygulamanın kart ve liste yoğunluğunu belirleyen seçenekler.
/// Senior Notu: Codable ve Identifiable olması hem kaydedilmeyi hem de Picker içinde kullanımını kolaylaştırır.
enum LayoutDensity: String, CaseIterable, Codable, Identifiable {
    case compact = "Kompakt"
    case comfortable = "Rahat"
    
    var id: String { self.rawValue }
    
    /// Görünümdeki padding değerleri için çarpan.
    var paddingMultiplier: CGFloat {
        switch self {
        case .compact: return 0.65
        case .comfortable: return 1.2
        }
    }
    
    /// Yazı boyutları için standart değerlerin üzerine eklenen/çıkarılan değer.
    var fontSizeOffset: CGFloat {
        switch self {
        case .compact: return -2
        case .comfortable: return 1
        }
    }
}
