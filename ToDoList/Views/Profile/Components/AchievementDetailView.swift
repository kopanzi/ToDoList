import SwiftUI

/// Bir başarı rozetine tıklandığında alttan açılan detay kartı.
struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Arka Plan
            Color(hex: "020807").ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 1. Büyük ve Parlayan Rozet İkonu
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: achievement.isUnlocked ? achievement.colors : [.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: achievement.isUnlocked ? achievement.colors.first!.opacity(0.5) : .clear, radius: 25, x: 0, y: 10)
                    
                    Image(systemName: achievement.isUnlocked ? achievement.iconName : "lock.fill")
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.5))
                }
                .padding(.top, 30)
                
                // 2. Metin Bilgileri
                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundColor(.white)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
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
