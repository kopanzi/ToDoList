import SwiftUI

/// Profil sayfasındaki Yerel Analiz bileşeni.
/// Senior Notu: 7 Günlük ritim grafiği İstatistikler sayfasına taşındığı için buradan kaldırıldı.
/// Arka plan renkleri Tema Motoruna (%100) bağlandı ve arayüz çok daha odaklı hale getirildi.
struct AnalysisInsightCard: View {
    // MARK: - Properties
    let userName: String
    let stats: UserStats
    let insight: String
    let isLoading: Bool
    
    // ✨ SENIOR FIX: Tema Motoru eklendi
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        let themeAccent = appearance.accentColor
        
        VStack(spacing: 20) {
            
            // 1. ÜST BAŞLIK (Header)
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(themeAccent.opacity(0.2)) // ✨ Tema Rengi
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeAccent) // ✨ Tema Rengi
                    }
                    .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("SIO ANALİZ MOTORU")
                            .font(.system(size: 11, weight: .black))
                            .tracking(0.5)
                            .foregroundColor(.primary) // ✨ Adaptive
                        
                        Text("YEREL OPTİMİZASYON • \(userName.uppercased())")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.secondary) // ✨ Adaptive
                    }
                }
                
                Spacer()
                
                Text("Offline")
                    .font(.system(size: 9, weight: .black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(themeAccent.opacity(0.1)) // ✨ Tema Rengi
                    .foregroundColor(themeAccent) // ✨ Tema Rengi
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(themeAccent.opacity(0.2), lineWidth: 1))
            }
            
            // 2. YEREL TAVSİYE ALANI (Ana Odak Noktası)
            VStack(alignment: .leading, spacing: 14) {
                if isLoading {
                    ProgressView()
                        .tint(themeAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                } else {
                    Text("\"\(insight)\"")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.primary.opacity(0.9)) // ✨ Adaptive
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            // ✨ SENIOR FIX: Kartın içi de temanın rengine hafifçe uyum sağlar
            .background(themeAccent.opacity(0.04))
            .cornerRadius(16)
        }
        .padding(24)
        // ✨ STITCH GLASSMORPHISM ARKA PLAN (Adaptive & Tematik)
        .background(
            ZStack {
                Color.primary.opacity(0.02)
                LinearGradient(
                    colors: [Color.clear, themeAccent.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .background(.ultraThinMaterial)
        )
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.05), themeAccent.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // Dışarıdan ekstra padding ile ekran kenarlarına yapışmasını engelliyoruz
        .padding(.horizontal, 20)
    }
}
