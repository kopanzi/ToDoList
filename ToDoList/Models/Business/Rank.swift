import SwiftUI

/// Kullanıcının XP puanına göre sahip olabileceği 20 seviyelik rütbe tanımları.
/// Senior Notu: Geliştirme (Test) aşamasında olduğumuz için XP eşikleri hızlı atlanabilir şekilde tasarlanmıştır.
enum Rank: Int, CaseIterable, Codable {
    // 🌱 FAZ 1: Temel ve Uyanış (1-4)
    case odakYolcusu = 0
    case farkindalikKasifi = 50
    case duzenCiragi = 100
    case iradeSahibi = 200
    
    // ⚙️ FAZ 2: Sistem ve Eylem (5-8)
    case planKurucu = 300
    case rutinMimari = 400
    case isBitirici = 500
    case momentumSurucusu = 650
    
    // 🧠 FAZ 3: Zihinsel Hakimiyet (9-12)
    case sistemMuhendisi = 800
    case berrakZihin = 1000
    case akisUstasi = 1200
    case zamanBukucu = 1400
    
    // 🏛️ FAZ 4: Strateji ve Üretkenlik (13-16)
    case stratejiDehasi = 1600
    case verimMimari = 1800
    case zihinMimari = 2000
    case uretkenlikUstasi = 2200
    
    // 🌌 FAZ 5: Transandantal Zirve (17-20)
    case mutlakOdak = 2400
    case zenUstasi = 2600
    case safPotansiyel = 2800
    case zihninZirvesi = 3000
    
    /// Rütbenin ekranda görünecek ismi
    var name: String {
        switch self {
        case .odakYolcusu: return "Odak Yolcusu"
        case .farkindalikKasifi: return "Farkındalık Kaşifi"
        case .duzenCiragi: return "Düzen Çırağı"
        case .iradeSahibi: return "İrade Sahibi"
            
        case .planKurucu: return "Plan Kurucu"
        case .rutinMimari: return "Rutin Mimarı"
        case .isBitirici: return "İş Bitirici"
        case .momentumSurucusu: return "Momentum Sürücüsü"
            
        case .sistemMuhendisi: return "Sistem Mühendisi"
        case .berrakZihin: return "Berrak Zihin"
        case .akisUstasi: return "Akış Ustası"
        case .zamanBukucu: return "Zaman Bükücü"
            
        case .stratejiDehasi: return "Strateji Dehası"
        case .verimMimari: return "Verim Mimarı"
        case .zihinMimari: return "Zihin Mimarı"
        case .uretkenlikUstasi: return "Üretkenlik Ustası"
            
        case .mutlakOdak: return "Mutlak Odak"
        case .zenUstasi: return "Zen Ustası"
        case .safPotansiyel: return "Saf Potansiyel"
        case .zihninZirvesi: return "Zihnin Zirvesi"
        }
    }
    
    /// Rütbeyi temsil eden SF Symbol ikonu
    var icon: String {
        switch self {
        case .odakYolcusu: return "figure.walk"
        case .farkindalikKasifi: return "eye.circle.fill"
        case .duzenCiragi: return "tray.2.fill"
        case .iradeSahibi: return "shield.fill"
            
        case .planKurucu: return "list.bullet.clipboard.fill"
        case .rutinMimari: return "calendar.badge.clock"
        case .isBitirici: return "checkmark.seal.fill"
        case .momentumSurucusu: return "wind"
            
        case .sistemMuhendisi: return "gearshape.2.fill"
        case .berrakZihin: return "drop.fill"
        case .akisUstasi: return "water.waves"
        case .zamanBukucu: return "hourglass.tophalf.filled"
            
        case .stratejiDehasi: return "brain.head.profile"
        case .verimMimari: return "chart.line.uptrend.xyaxis"
        case .zihinMimari: return "cube.transparent.fill"
        case .uretkenlikUstasi: return "crown.fill"
            
        case .mutlakOdak: return "target"
        case .zenUstasi: return "leaf.fill" // ✨ SENIOR FIX: "yin.yang" yerine her cihazda çalışan "leaf.fill" kullanıldı.
        case .safPotansiyel: return "sparkles"
        case .zihninZirvesi: return "diamond.fill"
        }
    }
    
    /// Rütbenin tema rengi (Geliştikçe renkler ısınır ve değerlenir)
    var color: Color {
        switch self {
        case .odakYolcusu, .farkindalikKasifi: return .gray
        case .duzenCiragi, .iradeSahibi: return .blue
            
        case .planKurucu, .rutinMimari: return .cyan
        case .isBitirici, .momentumSurucusu: return .green
            
        case .sistemMuhendisi, .berrakZihin: return .teal
        case .akisUstasi, .zamanBukucu: return .indigo
            
        case .stratejiDehasi, .verimMimari: return .purple
        case .zihinMimari, .uretkenlikUstasi: return .pink
            
        case .mutlakOdak, .zenUstasi: return .orange
        case .safPotansiyel: return .red
        case .zihninZirvesi: return .yellow
        }
    }
    
    /// Bir sonraki rütbenin XP eşiği
    var nextThreshold: Int? {
        let allRanks = Rank.allCases
        guard let currentIndex = allRanks.firstIndex(of: self),
              currentIndex + 1 < allRanks.count else { return nil }
        return allRanks[currentIndex + 1].rawValue
    }
}
