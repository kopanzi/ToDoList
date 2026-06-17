import SwiftUI

/// Uygulamanın ilk açılışında kullanıcıyı karşılayan Premium Launch Screen.
/// Sio: To Do List & Tasks markasına özel olarak güncellendi.
struct LaunchScreenView: View {
    // Temayı güvenli bir şekilde (Singleton üzerinden) dinliyoruz
    @ObservedObject private var appearance = AppearanceManager.shared
    
    @State private var animasyonBasladi = false
    @State private var opaklik = 0.0
    
    var body: some View {
        ZStack {
            // 1. ARKA PLAN: Adaptive Sistem Arka Planı
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // ✨ SİO AURA: Arka planda temanın ruhunu yansıtan, nefes alan bir parlama
            Circle()
                .fill(appearance.accentColor.opacity(0.15))
                .frame(width: 320, height: 320)
                .blur(radius: 65)
                .scaleEffect(animasyonBasladi ? 1.2 : 0.8)
            
            VStack(spacing: 24) {
                // 2. YENİ SİO LOGOSU
                ZStack {
                    // Arkadaki tema renkli hafif parlama
                    Circle()
                        .fill(appearance.accentColor.opacity(0.3))
                        .frame(width: 130, height: 130)
                        .blur(radius: 25)
                        .opacity(animasyonBasladi ? 1.0 : 0.0)
                    
                    // Sio ikonu (Assets klasöründeki adı "SioLogo" olmalı)
                    Image("SioLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        // Görsel kare olduğu için köşelerini kusursuz iOS App ikonu formunda yuvarlatıyoruz
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        // İkona derinlik katan tema renkli gölge
                        .shadow(color: appearance.accentColor.opacity(0.35), radius: 15, x: 0, y: 8)
                }
                
                // 3. İSİM VE ALT BAŞLIK
                VStack(spacing: 8) {
                    Text("Sio")
                        // Boyutu 72'ye çıkarıldı, ekranda devasa ve çok asil duracak
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .tracking(4) // Tok ve "High-End" marka havası
                        .foregroundColor(.primary)
                        .shadow(color: appearance.accentColor.opacity(0.4), radius: 5, x: 0, y: 3)
                    
                    Text("To Do List & Tasks")
                        // Alt başlık da orantılı olarak 18'e çıkarıldı
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.secondary)
                }
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
