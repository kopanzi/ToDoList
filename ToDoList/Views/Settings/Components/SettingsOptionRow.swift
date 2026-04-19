import SwiftUI

/// Ayarlar sayfasındaki her bir satır (Toggle, Link veya Buton) için standart şablon.
/// Senior Notu: Bu bileşen sayesinde tüm ayar satırları uygulama genelinde tutarlı görünür.
struct SettingsOptionRow: View {
    // MARK: - Properties
    let icon: String       // SF Symbol ismi
    let title: String      // Satır başlığı
    let color: Color       // İkonun arka plan rengi
    var detail: String? = nil // Sağ tarafta görünecek isteğe bağlı detay metni
    
    var body: some View {
        HStack(spacing: 15) {
            // 1. İKON KUTUSU
            // İkonu renkli ve yuvarlatılmış bir kutu içinde sunarak görsel hiyerarşiyi artırıyoruz.
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.1)) // Renk tonunu yumuşatıyoruz
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline.bold())
            }
            
            // 2. BAŞLIK
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            // 3. DETAY METNİ (Varsa)
            if let detail = detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4) // Form satırları arasında ferah bir alan bırakır
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
