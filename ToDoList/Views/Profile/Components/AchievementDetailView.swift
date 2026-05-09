import SwiftUI

/// Bir başarı rozetine tıklandığında alttan açılan detay kartı (Sheet).
/// Senior Notu: Arka plan Tema Motoruna bağlandı. Cihaz aydınlık veya karanlık modda olsa bile
/// seçili tema rengi (Örn: Mor, Mavi) arka planda hafif bir renk filtresi olarak hissettirilir.
struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) var dismiss
    
    // ✨ SENIOR FIX: Tema motorunu dahil ettik
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        ZStack {
            // ✨ SENIOR FIX: Hem aydınlık/karanlık mod uyumlu zemin hem de üzerine Tema Rengi (Tint)
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                appearance.accentColor.opacity(0.06) // Temanın ruhunu yansıtan hafif şeffaf renk
            }
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 1. Büyük ve Parlayan Rozet İkonu
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: achievement.isUnlocked ? achievement.colors : [Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: achievement.isUnlocked ? achievement.colors.first!.opacity(0.5) : .clear, radius: 25, x: 0, y: 10)
                    
                    Image(systemName: achievement.isUnlocked ? achievement.iconName : "lock.fill")
                        .font(.system(size: 45, weight: .bold))
                        // ✨ SENIOR FIX: Kilitliyken sistem rengine (Adaptive) uyar, açıkken renkli zeminde beyaz kalır.
                        .foregroundColor(achievement.isUnlocked ? .white : Color.primary.opacity(0.5))
                }
                .padding(.top, 30)
                
                // 2. Metin Bilgileri
                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundColor(.primary) // ✨ Adaptive
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary) // ✨ Adaptive
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                // 3. Durum Etiketi
                HStack(spacing: 8) {
                    Image(systemName: achievement.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    Text(achievement.isUnlocked ? "Kazanıldı" : "Henüz Kilitli")
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(achievement.isUnlocked ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .foregroundColor(achievement.isUnlocked ? .green : .orange)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(achievement.isUnlocked ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1))
                
                Spacer()
            }
        }
    }
}
