import SwiftUI

/// Profil sayfasındaki 4'lü üretkenlik verilerini gösteren "Bento Grid" kutucuğu.
/// Senior Notu: Statik beyaz/siyah renkler kaldırılarak Aydınlık/Karanlık mod (Adaptive UI)
/// uyumlu hale getirilmiştir. Glassmorphism efektleri güncellendi.
struct ProfileStatGrid: View {
    // MARK: - Properties
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            HapticManager.shared.triggerLightImpact()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // 1. ÜST BAŞLIK
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.2)
                    // ✨ SENIOR FIX: Sabit .white.opacity yerine aydınlık/karanlık mod uyumlu .secondary
                    .foregroundColor(.secondary)
                    // ✨ SENIOR FIX: Başlık uzunsa (...) yapmak yerine fontu küçült!
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                
                // 2. DEĞER VE İKON SATIRI
                HStack(alignment: .lastTextBaseline) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    
                    Spacer()
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color.opacity(0.5))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 85) // ✨ Kutu boyu biraz daha ferahlatıldı
        }
        .buttonStyle(BouncyGlassButtonStyle(color: color))
    }
}

// ✨ ÖZEL ESNEME ANİMASYONLU BUTON STİLİ
struct BouncyGlassButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    // ✨ SENIOR FIX: .white yerine .primary kullanılarak Adaptive UI sağlandı
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.06 : 0.03))
                    .background(.ultraThinMaterial.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(color.opacity(configuration.isPressed ? 0.3 : 0.12), lineWidth: 1)
            )
            // Gölgeyi karanlık/aydınlık moda uygun hale getirdik (.black.opacity(0.05) daha evrenseldir)
            .shadow(color: configuration.isPressed ? color.opacity(0.2) : Color.black.opacity(0.05), radius: configuration.isPressed ? 8 : 5, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
