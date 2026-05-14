import Foundation
import SwiftUI
import Combine
import FirebaseAuth // ✨ SENIOR FIX: Bulut bağlantısı için eklendi

/// Uygulama ayarlarını, kullanıcı tercihlerini ve sistem metadatalarını yöneten merkez.
/// Senior Notu: @MainActor eklendi. Tema ve Dil seçimleri artık Firestore (Bulut) ile
/// senkronize edilerek cihazlar arası kesintisiz (Seamless) deneyim sağlanmıştır.
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published / AppStorage Properties
    
    @AppStorage("selectedTheme") private var savedTheme: Theme = .blue
    
    @Published var selectedTheme: Theme = .blue {
        didSet {
            savedTheme = selectedTheme
            objectWillChange.send()
            // ✨ Ayar her değiştiğinde anında buluta yolla
            saveSettingsToCloud()
        }
    }
    
    @AppStorage("selectedLanguage") var selectedLanguage: String = "tr" {
        didSet {
            objectWillChange.send()
            // ✨ Ayar her değiştiğinde anında buluta yolla
            saveSettingsToCloud()
        }
    }
    
    // MARK: - Dynamic App Metadata (Sistem Bilgileri)
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var fullVersionString: String {
        "v\(appVersion) (\(buildNumber))"
    }
    
    // MARK: - Initialization
    
    init() {
        // Uygulama açıldığında kaydedilmiş temayı yükle
        self.selectedTheme = savedTheme
        
        // ✨ SENIOR FIX: Kullanıcı giriş yaptığını algıla ve buluttaki ayarları telefona çek
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.syncSettingsWithCloud()
            }
        }
    }
    
    // MARK: - CLOUD SYNC (BULUT MOTORU) ✨
    
    /// Giriş yapıldığında buluttaki ayarları cihaza uygular.
    private func syncSettingsWithCloud() {
        Task {
            do {
                if let cloudSettings = try await FirestoreManager.shared.fetchSettings() {
                    // Bulutta ayar varsa, telefona uygula (Cihazlar arası eşitlik)
                    if self.selectedTheme != cloudSettings.theme {
                        self.selectedTheme = cloudSettings.theme
                    }
                    if self.selectedLanguage != cloudSettings.language {
                        self.selectedLanguage = cloudSettings.language
                    }
                } else {
                    // Bulutta ayar yoksa (ilk giriş), cihazın yerelindeki ayarları buluta gönder
                    try? await FirestoreManager.shared.saveSettings(theme: self.selectedTheme, language: self.selectedLanguage)
                }
            } catch {
                print("🛑 Ayarlar Bulut Senkronizasyon Hatası: \(error.localizedDescription)")
            }
        }
    }
    
    /// Kullanıcı bir ayarı değiştirdiğinde bunu buluta kaydeder.
    private func saveSettingsToCloud() {
        guard Auth.auth().currentUser != nil else { return }
        Task {
            try? await FirestoreManager.shared.saveSettings(theme: self.selectedTheme, language: self.selectedLanguage)
        }
    }
    
    // MARK: - Actions
    
    func resetToDefaults() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.selectedTheme = .blue
            self.selectedLanguage = "tr"
        }
        HapticManager.shared.triggerWarning()
    }
}
