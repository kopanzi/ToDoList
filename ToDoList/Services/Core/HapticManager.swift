import UIKit
import SwiftUI

/// Cihazın Taptic Engine'ini kullanarak dokunsal (haptic) geri bildirimler oluşturur.
/// Merkezi bir noktadan yönetilmesi, uygulamanın tutarlı hissettirmesini sağlar.
final class HapticManager {
    
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Bildirim Titreşimleri (Success, Warning, Error)
    
    /// Başarılı bir işlem gerçekleştiğinde (Örn: Görev tamamlandı, Rütbe atlandı).
    func triggerSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare() // Gecikmeyi azaltmak için motoru hazırlar
        generator.notificationOccurred(.success)
    }
    
    /// Bir uyarı durumunda (Örn: Görev geri alındı).
    func triggerWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Bir hata durumunda (Örn: FaceID başarısız, İnternet yok).
    func triggerError() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Etkileşim Titreşimleri (Impact)
    
    /// Hafif bir dokunuş hissi (Örn: Buton tıklamaları, Menü açılışı).
    func triggerLightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Orta şiddette bir dokunuş hissi (Örn: Liste kaydırma sınırına gelme).
    func triggerMediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Güçlü bir dokunuş hissi (Örn: Büyük butonlar, önemli seçimler).
    func triggerHeavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Seçim Titreşimi (Selection)
    
    /// Picker veya Slider gibi bileşenlerde değer değiştiğinde.
    func triggerSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
