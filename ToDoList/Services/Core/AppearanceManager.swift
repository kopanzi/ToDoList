import SwiftUI
import Combine

/// Uygulamanın görsel atmosferini yöneten merkezi motor.
/// Senior Notu: Karmaşık Mesh, Solid ve Cam efektleri tamamen kaldırılarak
/// Apple HIG (Human Interface Guidelines) standartlarına uygun sade, hızlı ve
/// "System Background + Accent Color" (Sistem Arka Planı + Tema Rengi) mantığına geçilmiştir.
@MainActor
final class AppearanceManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AppearanceManager()
    
    // MARK: - Persistent Storage (AppStorage)
    
    // ✨ SENIOR FIX: Ana Ekran / Sidebar ayrımı kalktı. Tüm uygulama bu tek temaya itaat eder.
    // Uyumluluk için AppStorage anahtarını "mainScreenTheme" olarak bıraktık ki kullanıcıların eski seçimleri sıfırlanmasın.
    @AppStorage("mainScreenTheme") var mainTheme: Theme = .blue {
        didSet {
            // Tema değiştiğinde UI'ın anında tepki vermesi için yayını zorluyoruz
            objectWillChange.send()
        }
    }
    
    @AppStorage("layoutDensity") var layoutDensity: LayoutDensity = .comfortable
    
    // MARK: - Computed Properties
    
    /// Uygulama genelindeki aktif vurgu rengi (Butonlar, ikonlar, progress barlar vb. için)
    var accentColor: Color {
        mainTheme.mainColor
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Lifecycle & Compatibility
    
    /// 🧹 Ölü Kod Temizliği: Eski sistemden kalan ViewModel referanslarının (çağrılarının) patlamaması için tutuluyor.
    func updateAppearance(with tasks: [TaskModel]) {
        // Native Apple standartlarına geçtiğimiz için artık dinamik arka plan analizi yapmıyoruz.
    }
    
    /// Eski 'refreshColors' çağrılarının çökmemesi için içi boşaltılarak korundu.
    func refreshColors() { }
}
