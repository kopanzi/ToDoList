import SwiftUI

/// Kullanıcının kazandığı başarı rozetlerini yatay bir listede sergileyen bileşen.
/// Senior Notu: "Hepsini Gör" butonu ve arkaplanlar Tema Motoruna (Adaptive) bağlandı.
struct AchievementGallery: View {
    // MARK: - Properties
    let achievements: [Achievement]
    let onSelect: (Achievement) -> Void
    let onSeeAllTap: () -> Void
    
    // ✨ SENIOR FIX: Tema Motoru
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 1. ÜST BAŞLIK VE AKSİYON
            HStack {
                Text("BAŞARI GALERİSİ")
                    .font(.system(size: 10, weight: .black))
                    // ✨ SENIOR FIX: Aydınlık/Karanlık mod uyumu için .secondary kullanıldı
                    .foregroundColor(.secondary)
                    .tracking(1.5)
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    onSeeAllTap()
                }) {
                    Text("Hepsini Gör")
                        .font(.system(size: 10, weight: .bold))
                        // ✨ SENIOR FIX: Sabit neon renk yerine kullanıcının aktif Tema Rengi
                        .foregroundColor(appearance.accentColor.opacity(0.8))
                }
            }
            .padding(.horizontal, 22)
            
            // 2. YATAY KAYAN ROZET LİSTESİ
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(achievements) { achievement in
                        Button(action: {
                            HapticManager.shared.triggerSelection()
                            onSelect(achievement)
                        }) {
                            AchievementCard(achievement: achievement)
                        }
                        .buttonStyle(BouncyScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 5)
            }
        }
    }
}

// MARK: - Alt Bileşen: Tekil Rozet Kartı
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if achievement.isUnlocked {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: achievement.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: achievement.colors.first?.opacity(0.4) ?? .clear, radius: 8, x: 0, y: 4)
                    
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 20, weight: .bold))
                        // ✨ Not: İkon rengi renkli (gradient) zemin üstünde kontrast için her zaman beyaz kalmalı
                        .foregroundColor(.white)
                } else {
                    Circle()
                        // ✨ SENIOR FIX: Kilitli rozetin zemini Adaptive yapıldı
                        .fill(Color.primary.opacity(0.05))
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.5)) // ✨ SENIOR FIX: Adaptive kilit ikonu
                }
            }
            .frame(width: 46, height: 46)
            
            Text(achievement.title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                // ✨ SENIOR FIX: Başlık rengi kilit ve açık olma durumuna göre aydınlık/karanlık moda tam uyum sağlar
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary.opacity(0.5))
                .lineLimit(1)
        }
        .frame(width: 85, height: 95)
        // ✨ GLASSMORPHISM EFEKTİ (Adaptive UI)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                // ✨ SENIOR FIX: .white yerine .primary ile tam kontrast uyumu
                .fill(Color.primary.opacity(0.03))
                .background(.ultraThinMaterial.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(achievement.isUnlocked ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03), lineWidth: 1)
        )
    }
}

// ROZETLERE ÖZEL ESNEME STİLİ
struct BouncyScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
