import SwiftUI

/// Yaver'in gizli kasası için buzlu cam (Glassmorphism) efektli, premium kilit ekranı.
/// Senior Notu: Sabit koyu renkler (.black, .white) ve hard-coded hex renkleri kaldırılarak
/// Temaya Duyarlı (Adaptive) ve AppearanceManager entegreli hale getirilmiştir.
struct LockScreenView: View {
    let icon: String
    let title: String
    let subtitle: String
    let onUnlockTap: () -> Void
    
    @State private var isPulsing = false
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        ZStack {
            // ✨ SENIOR FIX: Sabit siyah yerine temanın arka planını kalın bir camla kapatıyoruz
            // Böylece arkadaki olası sızıntıları gizlerken aydınlık moda da uyum sağlar
            Color.primary.opacity(0.05)
                .background(.regularMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Kalkan / Kilit İkonu
                ZStack {
                    Circle()
                        // ✨ SENIOR FIX: Sabit neon renk yerine seçili tema rengi
                        .fill(appearance.accentColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPulsing ? 1.1 : 0.95)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                    
                    Image(systemName: icon)
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(appearance.accentColor) // ✨ SENIOR FIX
                        .shadow(color: appearance.accentColor.opacity(0.6), radius: 15)
                }
                .padding(.top, 40)
                
                // Metinler
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        // ✨ SENIOR FIX: .white yerine .primary
                        .foregroundColor(.primary)
                        .tracking(2)
                    
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        // ✨ SENIOR FIX: .white.opacity yerine .secondary
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // Kilidi Aç Butonu
                Button(action: {
                    HapticManager.shared.triggerHeavyImpact()
                    onUnlockTap()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "faceid")
                            .font(.system(size: 20))
                        Text("Kilidi Aç")
                            .font(.system(size: 16, weight: .bold))
                    }
                    // ✨ SENIOR FIX: Buton arka planı tema rengi olacağı için, içindeki yazı zıt renkte (Cutout efekti) olmalı.
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(appearance.accentColor) // ✨ SENIOR FIX
                    .cornerRadius(16)
                    .shadow(color: appearance.accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}
