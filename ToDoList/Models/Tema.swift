import SwiftUI

enum Tema: String, CaseIterable, Identifiable {
    case indigo, mavi, mor, pembe, turuncu, kirmizi, yesil
    
    var id: String { self.rawValue }
    
    // Ekranda görünecek isimler
    var isim: String {
        switch self {
        case .indigo: return "Gece Mavisi"
        case .mavi: return "Okyanus Mavisi"
        case .mor: return "Royal Mor"
        case .pembe: return "Şeker Pembe"
        case .turuncu: return "Gün Batımı"
        case .kirmizi: return "Bayrak Kırmızı"
        case .yesil: return "Doğa Yeşili"
        }
    }
    
    // SwiftUI Renk Karşılığı
    var renk: Color {
        switch self {
        case .indigo: return .indigo
        case .mavi: return .blue
        case .mor: return .purple
        case .pembe: return .pink
        case .turuncu: return .orange
        case .kirmizi: return .red
        case .yesil: return .green
        }
    }
    
    // Tema.swift içine, en alt parantezden önceye ekle:

    var arkaPlanRengi: Color {
        // Ana rengin %10 opaklıklı (çok açık) halini döndürür
        renk.opacity(0.1)
    }
}
