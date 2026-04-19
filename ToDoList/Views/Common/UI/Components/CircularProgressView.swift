import SwiftUI

/// Kullanıcının rütbe ilerlemesini veya herhangi bir yüzde değerini gösteren dairesel grafik.
/// Senior Notu: Animasyonlu geçişler ve özel çizgi uçları (lineCap) ile premium bir his sağlar.
struct CircularProgressView: View {
    // MARK: - Properties
    
    /// 0.0 ile 1.0 arasında ilerleme değeri.
    let progress: Double
    
    /// Çubuğun ana rengi (Neon Teal varsayılan).
    let color: Color
    
    /// Çizgi kalınlığı.
    var lineWidth: CGFloat = 4
    
    /// Yüzde metninin görünürlüğü.
    var showText: Bool = true
    
    var body: some View {
        ZStack {
            // 1. ARKA PLAN HALKASI (İz)
            Circle()
                .stroke(
                    color.opacity(0.1), // Hafif şeffaf iz
                    style: StrokeStyle(lineWidth: lineWidth)
                )
            
            // 2. İLERLEME HALKASI (Dolan Kısım)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round // Yuvarlatılmış uçlar (Modern görünüm)
                    )
                )
                // Saatin tersi yönünden başlaması için -90 derece döndürüyoruz
                .rotationEffect(.degrees(-90))
                // Veri değiştiğinde yumuşak geçiş sağlar
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progress)
            
            // 3. MERKEZİ YÜZDE METNİ
            if showText {
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        // Parlama efekti ekleyerek tasarımın neon havasını destekler
        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 0)
    }
}

// MARK: - Preview Section
#Preview {
    ZStack {
        // Koyu zemin üzerinde test edelim
        Color(hex: "020807").ignoresSafeArea()
        
        VStack(spacing: 40) {
            CircularProgressView(progress: 0.75, color: Color(hex: "0df2cc"))
                .frame(width: 80, height: 80)
            
            HStack(spacing: 30) {
                CircularProgressView(progress: 0.45, color: .orange, lineWidth: 6)
                    .frame(width: 50, height: 50)
                
                CircularProgressView(progress: 0.9, color: .purple, showText: false)
                    .frame(width: 40, height: 40)
            }
        }
    }
}
