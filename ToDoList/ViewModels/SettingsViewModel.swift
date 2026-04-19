import Foundation
import SwiftUI
import Combine // 🛠️ ObservableObject protokolü için gerekli

/// Uygulama ayarlarını ve kullanıcı tercihlerini yönetir.
final class SettingsViewModel: ObservableObject {
    
    // Tema seçimini hem diskte (AppStorage) hem de yayında (Published) tutuyoruz.
    // Bu sayede tema değiştiği an tüm uygulama anlık olarak renk değiştirir.
    @AppStorage("selectedTheme") private var savedTheme: Theme = .blue
    
    @Published var selectedTheme: Theme = .blue {
        didSet {
            savedTheme = selectedTheme
        }
    }
    
    @AppStorage("selectedLanguage") var selectedLanguage: String = "tr"
    
    init() {
        // Uygulama açıldığında kaydedilmiş temayı yükle
        self.selectedTheme = savedTheme
    }
}
