import SwiftUI

/// Yaver'in gizli kasası için buzlu cam (Glassmorphism) efektli, premium kilit ekranı.
struct LockScreenView: View {
    let icon: String
    let title: String
    let subtitle: String
    let onUnlockTap: () -> Void
    
    @State private var isPulsing = false
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        ZStack {
            // Arka planı tamamen bulanıklaştırarak arkadaki olası sızıntıları gizler
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Kalkan / Kilit İkonu
                ZStack {
                    Circle()
                        .fill(Color(hex: "0df2cc").opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPulsing ? 1.1 : 0.95)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                    
                    Image(systemName: icon)
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(Color(hex: "0df2cc"))
                        .shadow(color: Color(hex: "0df2cc").opacity(0.6), radius: 15)
                }
                .padding(.top, 40)
                
                // Metinler
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
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
                    .foregroundColor(Color(hex: "10221f"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "0df2cc"))
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "0df2cc").opacity(0.4), radius: 15, x: 0, y: 8)
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
