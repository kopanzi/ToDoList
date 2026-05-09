import SwiftUI

/// Uygulamanın ilk açılışında kullanıcıyı karşılayan Premium Launch Screen.
/// Senior Notu: Sabit siyah/beyaz renkler kaldırılarak Aydınlık/Karanlık mod (Adaptive UI)
/// ve Tema Motoru (AppearanceManager) entegrasyonu sağlandı.
struct LaunchScreenView: View {
    // ✨ SENIOR FIX: Temayı güvenli bir şekilde (Singleton üzerinden) dinliyoruz
    @ObservedObject private var appearance = AppearanceManager.shared
    
    @State private var animasyonBasladi = false
    @State private var opaklik = 0.0
    
    var body: some View {
        ZStack {
            // 1. ARKA PLAN: Adaptive Sistem Arka Planı
            // Cihaz aydınlık moddaysa beyaz, karanlık moddaysa siyah/koyu gri olur.
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // ✨ YENİ: Arka planda temanın ruhunu yansıtan, nefes alan bir parlama (Aura)
            Circle()
                .fill(appearance.accentColor.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .scaleEffect(animasyonBasladi ? 1.2 : 0.8)
            
            VStack(spacing: 20) {
                // 2. LOGO: Tematik ve Adaptive
                ZStack {
                    // Arkadaki tema renkli hafif parlama
                    Circle()
                        .fill(appearance.accentColor.opacity(0.3))
                        .frame(width: 90, height: 90)
                        .blur(radius: 20)
                        .opacity(animasyonBasladi ? 1.0 : 0.0)
                    
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.system(size: 100))
                        // ✨ SENIOR FIX: .white yerine .primary kullanıldı (Mod uyumlu)
                        .foregroundColor(.primary)
                        // İkona derinlik katan tema renkli gölge
                        .shadow(color: appearance.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                // 3. İSİM: YAVER (Premium Yazı)
                Text("YAVER")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .tracking(8) // Harf aralarını biraz daha açarak "High-End" marka havası kattık
                    .foregroundColor(.primary) // ✨ SENIOR FIX: Adaptive renk
                    // Altında temanın rengiyle çok hafif bir yansıma
                    .shadow(color: appearance.accentColor.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            // Animasyon: Hafifçe büyüyerek ekrana gelsin
            .scaleEffect(animasyonBasladi ? 1.0 : 0.85)
            .opacity(opaklik)
        }
        .onAppear {
            // Apple standartlarına uygun yumuşak bir beliriş
            withAnimation(.easeOut(duration: 1.2)) {
                animasyonBasladi = true
                opaklik = 1.0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LaunchScreenView()
}
