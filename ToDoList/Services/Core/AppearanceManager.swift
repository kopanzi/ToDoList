import SwiftUI
import Combine

/// Uygulamanın görsel atmosferini yöneten merkezi motor.
/// Senior Notu: Motto özellikleri tamamen sökülmüş, %100 manuel yapıya geçilmiştir.
@MainActor
final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    // MARK: - Arka Plan Stilleri
    enum BackgroundStyle: String, CaseIterable, Codable, Identifiable {
        case glass = "Glassmorphism", solid = "Solid Dark", gradient = "Gradient", standard = "Standart"
        var id: String { self.rawValue }
    }
    
    @Published var editTarget: EditTarget = .mainScreen
    enum EditTarget: String { case mainScreen = "Ana Ekran", sidebar = "Sidebar" }
    
    // MARK: - Kalıcı Ayarlar
    @AppStorage("sidebarStyle") var sidebarStyle: BackgroundStyle = .glass
    @AppStorage("sidebarTheme") var sidebarTheme: Theme = .blue {
        didSet { generateSidebarColors() }
    }
    
    @AppStorage("mainScreenStyle") var mainScreenStyle: BackgroundStyle = .glass
    @AppStorage("mainScreenTheme") var mainScreenTheme: Theme = .blue {
        didSet { generateMainColors() }
    }
    
    @AppStorage("mainScreenOpacity") var mainScreenOpacity: Double = 0.85
    @AppStorage("layoutDensity") var layoutDensity: LayoutDensity = .comfortable
    
    // MARK: - Dinamik Veriler
    @Published var sidebarMeshColors: [Color] = [.indigo, .purple, .blue]
    @Published var mainMeshColors: [Color] = [.blue, .cyan, .teal]
    
    // Vurgu Rengi
    var accentColor: Color {
        mainScreenTheme.mainColor
    }
    
    private init() {
        generateSidebarColors()
        generateMainColors()
    }
    
    // MARK: - Renk Üretim Motoru
    
    private func generateSidebarColors() {
        withAnimation(.easeInOut(duration: 0.5)) {
            self.sidebarMeshColors = [
                sidebarTheme.mainColor,
                sidebarTheme.mainColor.opacity(0.7),
                sidebarTheme.mainColor.opacity(0.4)
            ]
        }
    }
    
    private func generateMainColors() {
        withAnimation(.easeInOut(duration: 0.5)) {
            self.mainMeshColors = [
                mainScreenTheme.mainColor,
                mainScreenTheme.mainColor.opacity(0.7),
                mainScreenTheme.mainColor.opacity(0.4)
            ]
        }
    }
    
    // 🧹 updateAppearance artık bir iş yapmıyor, sadece TaskViewModel'in hata vermemesi için boş bırakıldı.
    func updateAppearance(with tasks: [TaskModel]) { }
}
