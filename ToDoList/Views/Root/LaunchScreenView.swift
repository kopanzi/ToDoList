import SwiftUI

struct LaunchScreenView: View {
    @State private var animasyonBasladi = false
    @State private var opaklik = 0.0
    
    var body: some View {
        ZStack {
            // 1. ARKA PLAN: Siyah (Minimalist ve Asil)
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 2. LOGO: Beyaz Liste İkonu (Yaver'in Rozeti)
                Image(systemName: "list.bullet.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0) // Hafif parıltı
                
                // 3. İSİM: YAVER (Premium Yazı)
                Text("YAVER")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .tracking(5) // Harf aralarını açarak "marka" havası kattık
                    .foregroundColor(.white)
                    .shadow(radius: 5)
            }
            // Animasyon: Hafifçe büyüyerek ekrana gelsin
            .scaleEffect(animasyonBasladi ? 1.0 : 0.8)
            .opacity(opaklik)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animasyonBasladi = true
                opaklik = 1.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
