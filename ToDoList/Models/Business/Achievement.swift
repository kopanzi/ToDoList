import SwiftUI

/// Uygulama içindeki başarı rozetlerini ve kazanım durumlarını temsil eden model.
struct Achievement: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    let title: String
    let description: String
    
    // 🛠️ SENIOR FIX: Eski bozuk verileri otomatik onaran yapı (Migration)
    private var _iconName: String
    
    var iconName: String {
        get {
            // Hafızadaki eski bozuk ikonları anında yenileriyle değiştiriyoruz
            if _iconName == "wb.twilight" { return "sunrise.fill" }
            if _iconName == "military_tech" { return "rosette" }
            return _iconName
        }
        set { _iconName = newValue }
    }
    
    let hexColors: [String]
    var isUnlocked: Bool
    var unlockedAt: Date?
    
    var colors: [Color] {
        hexColors.isEmpty ? [.gray] : hexColors.map { Color(hex: $0) }
    }
    
    // Codable (UserDefaults) okuma/yazma işlemi için JSON anahtarlarını eşliyoruz
    enum CodingKeys: String, CodingKey {
        case id, title, description, hexColors, isUnlocked, unlockedAt
        case _iconName = "iconName" // JSON'daki "iconName" verisini bizim _iconName'e yaz
    }
    
    // Modelin eskisi gibi başlatılabilmesi için özel Init
    init(id: String = UUID().uuidString, title: String, description: String, iconName: String, hexColors: [String], isUnlocked: Bool, unlockedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self._iconName = iconName
        self.hexColors = hexColors
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
}

// MARK: - Predefined Achievements
extension Achievement {
    /// Kullanıcı ilk girdiğinde tüm rozetler kilitli (isUnlocked: false) olarak gelir.
    static let defaultGallery: [Achievement] = [
        Achievement(
            title: "Erkenci",
            description: "Sabah 08:00'den önce oluşturulmuş bir görevi tamamla.",
            iconName: "sunrise.fill",
            hexColors: ["#FBBF24", "#F97316"],
            isUnlocked: false,
            unlockedAt: nil
        ),
        Achievement(
            title: "AI Ustası",
            description: "Bir görevin detaylarında 'Sio AI ile Planla' özelliğini kullan.",
            iconName: "bolt.fill",
            hexColors: ["#0DF2CC", "#3B82F6"],
            isUnlocked: false,
            unlockedAt: nil
        ),
        Achievement(
            title: "Odak",
            description: "Verimliliğini kanıtla ve toplamda 5 görev tamamla.",
            iconName: "rosette",
            hexColors: ["#A855F7", "#EC4899"],
            isUnlocked: false,
            unlockedAt: nil
        ),
        Achievement(
            title: "Gizemli",
            description: "Güvenliği sağla ve Gizli Kasa'ya bir görev ekle.",
            iconName: "lock.fill",
            hexColors: ["#475569", "#1E293B"],
            isUnlocked: false,
            unlockedAt: nil
        ),
        // ✨ YENİ EKLENEN ROZETLER ✨
        Achievement(
            title: "Gece Baykuşu",
            description: "Gece 22:00'den sonra bir görev tamamla.",
            iconName: "moon.stars.fill",
            hexColors: ["#312E81", "#4338CA"], // Koyu Lacivert / Gece Mavisi
            isUnlocked: false,
            unlockedAt: nil
        ),
        Achievement(
            title: "Hafta Sonu Savaşçısı",
            description: "Tatil günlerinde bile üretken ol ve görev bitir.",
            iconName: "tent.fill",
            hexColors: ["#166534", "#15803D"], // Doğa Yeşili
            isUnlocked: false,
            unlockedAt: nil
        ),
        Achievement(
            title: "Sesli Düşünür",
            description: "Detaylandırmak için bir göreve ses kaydı ekle.",
            iconName: "waveform",
            hexColors: ["#0284C7", "#06B6D4"], // Dalga Mavisi
            isUnlocked: false,
            unlockedAt: nil
        ),
        Achievement(
            title: "Görsel Hafıza",
            description: "Bir göreve fotoğraf veya görsel ekle.",
            iconName: "camera.macro",
            hexColors: ["#BE185D", "#E11D48"], // Kamera Pembesi
            isUnlocked: false,
            unlockedAt: nil
        )
    ]
}
