import SwiftUI

/// Arka plandaki akışkan Mesh Gradient paletlerini hazırlayan servis.
/// Senior Notu: Gemini AI bağımlılıkları tamamen temizlenmiş ve Motto yükü MottoService'e devredilmiştir.
final class WallpaperService {
    static let shared = WallpaperService()
    
    private init() {}
    
    /// Kullanıcının duygu durumuna (Mood) göre matematiksel Mesh Gradient renk dizilerini döndürür.
    func getMeshColors(for mood: MoodService.UserMood) -> [Color] {
        switch mood {
        case .zen:
            return [.mint, .teal, .cyan, .blue, .indigo, .white]
        case .productive:
            return [.blue, .purple, .indigo, .pink, .blue, .clear]
        case .urgent:
            return [.orange, .red, .pink, .purple, .orange, .black.opacity(0.3)]
        }
    }
}
