import SwiftUI

/// Gemini'den motto çeken ve Mesh Gradient paletleri hazırlayan servis.
final class WallpaperService {
    static let shared = WallpaperService()
    private let geminiService = GeminiService()
    
    private init() {}
    
    /// Kullanıcının o anki mood'una göre Gemini'den kısa bir motivasyon mottosu ister.
    func fetchDailyMotto(for mood: MoodService.UserMood) async -> String {
        let prompt = "Kullanıcı şu an '\(mood.rawValue)' modunda. Ona notlarının arkasında filigran olarak duracak, 5 kelimeyi geçmeyen, Türkçe, çok karizmatik ve motive edici bir cümle yaz. Sadece cümleyi döndür."
        let response = await geminiService.oneriAl(gorevBasligi: prompt)
        return response.replacingOccurrences(of: "\"", with: "")
    }
    
    /// Mood'a göre matematiksel Mesh Gradient renk dizilerini döndürür.
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
