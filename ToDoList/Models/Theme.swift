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
        // ✨ SENIOR UX TIP: Saf siyah (.black) cam efektiyle birleşince her şeyi (gölgeler, blur) yutar.
        // Color(white: 0.1) kullanarak o premium "Koyu Antrasit" hissini yakalıyoruz.
        case .dark: return Color(white: 0.1)
        }
    }
    
    /// Kart arkalarında ve arka planlarda kullanılan şeffaf ton.
    var backgroundColor: Color {
        mainColor.opacity(0.1)
    }
}
