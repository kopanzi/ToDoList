import Foundation
import SwiftUI
import Combine

/// Uygulama ayarlarını, kullanıcı tercihlerini ve sistem metadatalarını yöneten merkez.
/// Senior Notu: @MainActor eklendi. Sabit (Hardcoded) versiyon numaraları yerine
/// dinamik Bundle okuma özellikleri sisteme dahil edilerek profesyonel bir yapı kuruldu.
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published / AppStorage Properties
    
    // Tema seçimini hem diskte (AppStorage) hem de yayında (Published) tutuyoruz.
    // Bu sayede tema değiştiği an tüm uygulama anlık olarak renk değiştirir.
    @AppStorage("selectedTheme") private var savedTheme: Theme = .blue
    
    @Published var selectedTheme: Theme = .blue {
        didSet {
            savedTheme = selectedTheme
            // SwiftUI'ın bazı durumlarda değişimi kaçırmasını önlemek için manuel tetikleyici
            objectWillChange.send()
        }
    }
    
    @AppStorage("selectedLanguage") var selectedLanguage: String = "tr" {
        didSet {
            // Dil değişimi tüm uygulamayı etkileyeceği için sinyali garanti altına alıyoruz
            objectWillChange.send()
        }
    }
    
    // MARK: - Dynamic App Metadata (Sistem Bilgileri)
    
    /// Uygulamanın Info.plist dosyasından dinamik olarak okunan Versiyon numarası.
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Uygulamanın Info.plist dosyasından dinamik olarak okunan Build (İnşa) numarası.
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Arayüzde (SettingsView) göstermek için hazırlanmış tam versiyon dökümü.
    var fullVersionString: String {
        "v\(appVersion) (\(buildNumber))"
    }
    
    // MARK: - Initialization
    
    init() {
        // Uygulama açıldığında kaydedilmiş temayı yükle
        self.selectedTheme = savedTheme
    }
    
    // MARK: - Actions
    
    /// Kullanıcı tüm ayarları sıfırlamak isterse kullanılacak güvenli metod.
    func resetToDefaults() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.selectedTheme = .blue
            self.selectedLanguage = "tr"
        }
        HapticManager.shared.triggerWarning()
    }
}
