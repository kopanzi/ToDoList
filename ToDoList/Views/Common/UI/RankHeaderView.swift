import SwiftUI

/// Kullanıcının rütbe ve XP durumunu gösteren, yeni "Glassmorphism" tasarımlı kart.
/// Senior Notu: Sabit koyu renkler ve beyaz metinler (.white) kaldırılarak
/// Aydınlık/Karanlık mod (Adaptive UI) ve Dinamik Tema ile %100 uyumlu hale getirilmiştir.
struct RankHeaderView: View {
    // MARK: - Properties
    let xp: Int
    let rank: Rank
    let progress: Double   // 0.0 - 1.0 arası
    
    // ✨ SENIOR FIX: Temanın vurgu renklerini anlık alabilmek için eklendi
    @EnvironmentObject var appearance: AppearanceManager
    
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
                    
                    // İkon renkli gradient'in içinde olduğu için kontrast gereği her zaman beyaz kalmalı
                    Image(systemName: rank.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Orta: Rütbe İsimleri
                VStack(alignment: .leading, spacing: 2) {
                    Text(rank.name)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        // ✨ SENIOR FIX: .white yerine .primary
                        .foregroundColor(.primary)
                    
                    Text("Rank \(rank.rawValue / 50 + 1)") // Basit bir seviye mantığı
                        .font(.system(size: 11, weight: .medium))
                        // ✨ SENIOR FIX: Adaptive ikincil renk
                        .foregroundColor(.primary.opacity(0.5))
                }
                
                Spacer()
                
                // Sağ: XP Skor
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(xp)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        // ✨ SENIOR FIX: Sabit neon renk yerine kullanıcının seçtiği ana tema rengi
                        .foregroundColor(appearance.accentColor)
                    
                    Text("/ \(rank.nextThreshold ?? 9999) XP")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary.opacity(0.5))
                }
            }
            
            // 2. İLERLEME ÇUBUĞU (Progress Bar)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Arka Plan (Aydınlık/Karanlık uyumlu Adaptive Kapsül)
                    Capsule()
                        // ✨ SENIOR FIX: Koyu lacivert yerine tema uyumlu şeffaf gri
                        .fill(Color.primary.opacity(0.1))
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
                    .foregroundColor(.primary.opacity(0.5)) // ✨ SENIOR FIX
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 2) {
                        Text("Detaylar")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(appearance.accentColor) // ✨ SENIOR FIX
                }
            }
        }
        .padding(20)
        // ✨ GLASSMORPHISM EFEKTİ (Adaptive)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                // ✨ SENIOR FIX: Karanlık modda koyu siyahımsı, aydınlıkta açık renkli akıllı cam efekti
                .fill(Color.primary.opacity(0.03))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                // ✨ SENIOR FIX: İnce neon border yerine mod uyumlu ince sınır çizgisi
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
