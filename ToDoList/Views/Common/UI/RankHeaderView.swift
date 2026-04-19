import SwiftUI

/// Kullanıcının rütbe ve XP durumunu gösteren, yeni "Glassmorphism" tasarımlı kart.
/// Senior Notu: Tailwind'deki 'glass-card' CSS sınıfları SwiftUI materyallerine dönüştürüldü.
struct RankHeaderView: View {
    // MARK: - Properties
    let xp: Int
    let rank: Rank
    let progress: Double   // 0.0 - 1.0 arası
    
    var body: some View {
        VStack(spacing: 16) {
            // 1. ÜST BÖLÜM: İkon, Rütbe ve XP
            HStack(alignment: .center, spacing: 16) {
                
                // Sol: Gradient İkon Kutusu
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.indigo, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: rank.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Orta: Rütbe İsimleri
                VStack(alignment: .leading, spacing: 2) {
                    Text(rank.name)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Rank \(rank.rawValue / 50 + 1)") // Basit bir seviye mantığı
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Sağ: XP Skor
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(xp)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "0df2cc")) // Tasarımdaki Primary Neon renk
                    
                    Text("/ \(rank.nextThreshold ?? 9999) XP")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // 2. İLERLEME ÇUBUĞU (Progress Bar)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Arka Plan (Koyu Lacivert/Gri)
                    Capsule()
                        .fill(Color(hex: "1e293b"))
                        .frame(height: 6)
                    
                    // Dolan Kısım (Neon Turuncu)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 6)
                        .shadow(color: .orange.opacity(0.5), radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: 6)
            
            // 3. ALT BİLGİ VE LİNK
            HStack {
                Text("Sıradaki: Odak Modu")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 2) {
                        Text("Detaylar")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "0df2cc"))
                }
            }
        }
        .padding(20)
        // ✨ GLASSMORPHISM EFEKTİ
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "10221f").opacity(0.6)) // Koyu yeşil/siyah transparan
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(hex: "0df2cc").opacity(0.1), lineWidth: 1) // İnce neon border
        )
        .padding(.horizontal)
    }
}
