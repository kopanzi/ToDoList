import SwiftUI

/// Ayarlar sayfasındaki her bir satır (Toggle, Link veya Buton) için standart şablon.
/// Senior Notu: İkon kutularına derinlik (Shadow & Stroke) ve yuvarlatılmış (Rounded)
/// premium tipografi eklenerek UI zenginleştirilmiş, Adaptive uyum korunmuştur.
struct SettingsOptionRow: View {
    // MARK: - Properties
    let icon: String       // SF Symbol ismi
    let title: String      // Satır başlığı
    let color: Color       // İkonun arka plan rengi
    var detail: String? = nil // Sağ tarafta görünecek isteğe bağlı detay metni
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. İKON KUTUSU (Premium Tasarım)
            // İkonu renkli, gölgeli ve yuvarlatılmış bir kutu içinde sunarak görsel hiyerarşiyi artırıyoruz.
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    // ✨ SENIOR FIX: Düz şeffaflık yerine gradient ile çok hafif 3D (derinlik) hissiyatı
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .bold))
            }
            // Hafifçe belirgin bir çerçeve (Stroke)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            
            // 2. BAŞLIK
            Text(title)
                // ✨ SENIOR FIX: Daha modern, yuvarlak hatlı ve dolgun tipografi
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary) // Adaptive (Aydınlık/Karanlık uyumlu)
            
            Spacer()
            
            // 3. DETAY METNİ (Varsa)
            if let detail = detail {
                Text(detail)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6) // Form satırları arasında daha ferah bir alan bırakır
    }
}

// MARK: - Preview
#Preview {
    List {
        SettingsOptionRow(icon: "moon.fill", title: "Karanlık Mod", color: .purple)
        SettingsOptionRow(icon: "globe", title: "Dil", color: .blue, detail: "Türkçe")
        SettingsOptionRow(icon: "trash.fill", title: "Verileri Sıfırla", color: .red)
    }
}
