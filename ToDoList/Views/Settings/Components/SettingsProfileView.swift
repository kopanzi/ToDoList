import SwiftUI

/// Kullanıcının rütbe, XP ve ilerleme bilgilerini şık bir kart içerisinde sunan bileşen.
/// Senior Notu: Standart ProgressView kaldırılarak, Yaver'in premium tasarım diline (Neon & Glass)
/// uygun özel bir GeometryReader ilerleme çubuğu ve Gradient (Degrade) ikon kutusu entegre edilmiştir.
struct SettingsProfileView: View {
    // MARK: - Properties
    let rankName: String
    let rankIcon: String
    let rankColor: Color
    let userXP: Int
    let progress: Double // 0.0 - 1.0 arası
    
    var body: some View {
        HStack(spacing: 18) {
            // 1. RÜTBE İKONU (Sol Taraf - 3D Gradient Efekti)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [rankColor.opacity(0.25), rankColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 75, height: 75)
                
                // İnce ve şık bir çerçeve (Stroke)
                Circle()
                    .stroke(rankColor.opacity(0.3), lineWidth: 1)
                    .frame(width: 75, height: 75)
                
                Image(systemName: rankIcon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(rankColor)
                    // İkona çok hafif bir parlama efekti
                    .shadow(color: rankColor.opacity(0.5), radius: 5, x: 0, y: 3)
            }
            .shadow(color: rankColor.opacity(0.15), radius: 10, x: 0, y: 5)
            
            // 2. BİLGİ ALANI (Sağ Taraf)
            VStack(alignment: .leading, spacing: 6) {
                // Rütbe İsmi
                Text(rankName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary) // ✨ Adaptive (Aydınlık/Karanlık Uyumlu)
                
                // XP Bilgisi
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(userXP) XP")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(rankColor) // Sabit gri yerine rütbenin rengiyle daha çok dikkat çeker
                
                // 3. ÖZEL İLERLEME ÇUBUĞU (Custom Progress Bar)
                VStack(alignment: .trailing, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Arka Plan (Zemin) - Adaptive
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 6)
                            
                            // Dolan Kısım (Neon Gradient)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [rankColor, rankColor.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 6)
                                .shadow(color: rankColor.opacity(0.4), radius: 3, x: 0, y: 0)
                        }
                    }
                    .frame(height: 6)
                    
                    // Yüzde Metni
                    Text("%\(Int(progress * 100))")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
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
