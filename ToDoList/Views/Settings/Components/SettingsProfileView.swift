import SwiftUI

/// Kullanıcının rütbe, XP ve ilerleme bilgilerini şık bir kart içerisinde sunan bileşen.
/// Senior Notu: Bu bileşen sadece veriyi alır ve görüntüler, iş mantığı ViewModel'den beslenir.
struct SettingsProfileView: View {
    // MARK: - Properties
    let rankName: String
    let rankIcon: String
    let rankColor: Color
    let userXP: Int
    let progress: Double // 0.0 - 1.0 arası
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. RÜTBE İKONU (Sol Taraf)
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: rankIcon)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(rankColor)
            }
            .shadow(color: rankColor.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // 2. BİLGİ ALANI (Sağ Taraf)
            VStack(alignment: .leading, spacing: 6) {
                // Rütbe İsmi
                Text(rankName)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                // XP Bilgisi
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("\(userXP) XP")
                }
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
                
                // İlerleme Çubuğu (Progress Bar)
                VStack(alignment: .trailing, spacing: 4) {
                    ProgressView(value: progress)
                        .tint(rankColor)
                        .scaleEffect(x: 1, y: 1.5, anchor: .center) // Biraz daha kalın tasarım
                    
                    Text("%\(Int(progress * 100))")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Preview
#Preview {
    List {
        Section {
            SettingsProfileView(
                rankName: "Tosun Paşa",
                rankIcon: "trophy.fill",
                rankColor: .yellow,
                userXP: 1250,
                progress: 0.75
            )
        } header: {
            Text("Profil")
        }
    }
}
