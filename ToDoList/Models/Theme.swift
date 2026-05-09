import SwiftUI

/// Uygulamanın görsel kimliğini belirleyen ana tema yapısı.
enum Theme: String, CaseIterable, Identifiable, Codable {
    case indigo, blue, purple, pink, orange, red, green, dark
    
    var id: String { self.rawValue }
    
    /// Kullanıcının ayarlar ekranında göreceği Türkçe isimler.
    var displayName: String {
        switch self {
        case .indigo: return "Gece Mavisi"
        case .blue: return "Okyanus Mavisi"
        case .purple: return "Royal Mor"
        case .pink: return "Şeker Pembe"
        case .orange: return "Gün Batımı"
        case .red: return "Bayrak Kırmızı"
        case .green: return "Doğa Yeşili"
        case .dark: return "Gece Siyahı"
        }
    }
    
    /// SwiftUI içerisinde kullanılan ana renk.
    var mainColor: Color {
        switch self {
        case .indigo: return .indigo
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .orange: return .orange
        case .red: return .red
        case .green: return .green
        // ✨ SENIOR FIX: Gece Siyahı (.dark) teması artık Adaptive (Dinamik).
        // Cihaz Aydınlık moddaysa: Açık Gri/Buzul (Kirli beyaz) olur.
        // Cihaz Karanlık moddaysa: Premium Koyu Antrasit olur.
        case .dark:
            return Color(UIColor { traitCollection in
                return traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 0.1, alpha: 1.0)
                    : UIColor(white: 0.95, alpha: 1.0)
            })
        }
    }
    
    /// Kart arkalarında ve arka planlarda kullanılan şeffaf ton.
    var backgroundColor: Color {
        mainColor.opacity(0.1)
    }
}
