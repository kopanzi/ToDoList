import SwiftUI
import Combine

/// Uygulamanın görsel atmosferini yöneten merkezi motor.
@MainActor
final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    // MARK: - Tasarım Paleti
    struct Palette {
        static let primary = Color(hex: "f27f0d")
        static let bgDark = Color(hex: "1a1612")
    }
    
    enum BackgroundStyle: String, CaseIterable, Codable, Identifiable {
        case glass = "Glassmorphism", solid = "Solid Dark", gradient = "Gradient", standard = "Standart"
        var id: String { self.rawValue }
    }
    
    @Published var editTarget: EditTarget = .mainScreen
    enum EditTarget: String { case mainScreen = "Ana Ekran", sidebar = "Sidebar" }
    
    // MARK: - Kalıcı Ayarlar
    @AppStorage("sidebarStyle") var sidebarStyle: BackgroundStyle = .glass
    @AppStorage("sidebarTheme") var sidebarTheme: Theme = .blue
    @AppStorage("mainScreenStyle") var mainScreenStyle: BackgroundStyle = .glass
    @AppStorage("mainScreenTheme") var mainScreenTheme: Theme = .blue
    @AppStorage("mainScreenOpacity") var mainScreenOpacity: Double = 0.85
    @AppStorage("isAutoMoodEnabled") var isAutoMoodEnabled: Bool = true
    @AppStorage("isAIMottoEnabled") var isAIMottoEnabled: Bool = true
    @AppStorage("layoutDensity") var layoutDensity: LayoutDensity = .comfortable
    
    // MARK: - Dinamik Veriler
    @Published var sidebarMeshColors: [Color] = [.indigo, .purple, .blue]
    @Published var mainMeshColors: [Color] = [.blue, .cyan, .teal]
    
    // ✨ SENIOR FIX: Uygulama açılır açılmaz bugünün mottosunu anında belleğe alır. (AI beklemez)
    @Published var dailyMotto: String = MottoService.shared.getDailyMotto()
    
    @Published var currentMood: MoodService.UserMood = .zen
    
    // ✅ KRİTİK DÜZELTME: accentColor eklendi
    var accentColor: Color {
        if isAutoMoodEnabled {
            return mainMeshColors.first ?? Palette.primary
        } else {
            return mainScreenTheme.mainColor
        }
    }
    
    private init() { refreshColors() }
    
    func updateAppearance(with tasks: [TaskModel]) {
        let newMood = MoodService.shared.calculateMood(from: tasks)
        
        // ✨ YENİ MANTIK: Mood'dan bağımsız olarak görev listesi her yenilendiğinde 24 saat kontrolü yap.
        if isAIMottoEnabled {
            let newMotto = MottoService.shared.getDailyMotto()
            if self.dailyMotto != newMotto {
                withAnimation { self.dailyMotto = newMotto }
            }
        }
        
        Task {
            if self.isAutoMoodEnabled {
                if self.currentMood != newMood {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self.currentMood = newMood
                        let colors = WallpaperService.shared.getMeshColors(for: newMood)
                        self.sidebarMeshColors = colors
                        self.mainMeshColors = colors
                    }
                    // AI Motto satırı buradan tamamen SİLİNDİ! (Artık yukarıda senkron olarak çalışıyor)
                }
            } else { refreshColors() }
        }
    }
    
    func refreshColors() {
        DispatchQueue.main.async {
            if !self.isAutoMoodEnabled {
                withAnimation {
                    self.sidebarMeshColors = [self.sidebarTheme.mainColor, self.sidebarTheme.mainColor.opacity(0.6), Palette.bgDark.opacity(0.2)]
                    self.mainMeshColors = [self.mainScreenTheme.mainColor, self.mainScreenTheme.mainColor.opacity(0.6), Palette.bgDark.opacity(0.2)]
                }
            }
        }
    }
}
