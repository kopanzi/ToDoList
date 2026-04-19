import SwiftUI

/// Yaver'in başarı ve kutlama anlarında (Örn: Odak Sayacı bitimi, Rütbe atlama)
/// ekranda sinematik ve tatmin edici bir görsel şölen sunan bileşen.
struct KonfetiView: View {
    // ✨ Yaver'in "Glassmorphism" ve "Neon" temasına uygun elit renk paleti
    let premiumColors: [Color] = [
        Color(hex: "0df2cc"), // Yaver Neon Teal
        .orange,
        .purple,
        .pink,
        .yellow,
        .cyan,
        .white
    ]
    
    var body: some View {
        // ✨ SENIOR FIX: UIScreen.main yerine GeometryReader ile ekran boyutunu alıyoruz.
        GeometryReader { geo in
            ZStack {
                // Kaosu önlemek ve kaliteyi artırmak için parçacık sayısı 60'a optimize edildi.
                ForEach(0..<60, id: \.self) { _ in
                    ConfettiPiece(
                        color: premiumColors.randomElement() ?? .orange,
                        screenSize: geo.size // Ekran boyutunu parçacığa aktarıyoruz
                    )
                }
            }
            // ZStack'in tüm alanı kaplamasını garanti altına alıyoruz
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Alt katmandaki butonlara tıklanmayı engellememesi için
        .allowsHitTesting(false)
    }
}

// MARK: - Tekil Konfeti Parçacığı
struct ConfettiPiece: View {
    let color: Color
    let screenSize: CGSize // ✨ Üst görünümden gelen ekran boyutu
    
    // Animasyon Durumları
    @State private var location: CGPoint = CGPoint(x: 0, y: -50) // Merkezden hafif yukarıda başlar
    @State private var rotation3D: Double = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.1
    
    // Rastgele Fiziksel Özellikler (Her parçacık benzersizdir)
    @State private var shapeType = Int.random(in: 0...2)
    @State private var spinAxis = (
        x: CGFloat.random(in: -1...1),
        y: CGFloat.random(in: -1...1),
        z: CGFloat.random(in: -1...1)
    )
    
    let animationDuration = Double.random(in: 3.5...5.0)
    let isBlurred = Bool.random() // Bazı parçacıklara sinematik derinlik katar
    
    var body: some View {
        Group {
            switch shapeType {
            case 0:
                // Klasik dikdörtgen
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 8, height: 16)
            case 1:
                // Daire
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
            default:
                // Elmas (Döndürülmüş kare)
                Rectangle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .rotationEffect(.degrees(45))
            }
        }
        // Hafif bir neon parlaması
        .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 0)
        // Kamera odak uzaklığı (Depth of Field) simülasyonu
        .blur(radius: isBlurred ? 2.0 : 0)
        .scaleEffect(scale)
        // 3 Boyutlu takla atma efekti
        .rotation3DEffect(.degrees(rotation3D), axis: spinAxis)
        .offset(x: location.x, y: location.y)
        .opacity(opacity)
        .onAppear {
            // ✨ SENIOR FIX: UIScreen hesaplamalarını onAppear içine ve GeometryReader değerine taşıdık.
            let endX = CGFloat.random(in: -screenSize.width...screenSize.width)
            let endY = CGFloat.random(in: screenSize.height * 0.3...screenSize.height * 1.2)
            
            // 1. AŞAMA: Aniden "Pop" diye büyüme (Patlama hissi)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = CGFloat.random(in: 0.8...1.5)
            }
            
            // 2. AŞAMA: Zarifçe süzülme ve havada takla atma
            withAnimation(.easeOut(duration: animationDuration)) {
                location = CGPoint(x: endX, y: endY)
                rotation3D = Double.random(in: 720...1440) // En az 2-4 takla
            }
            
            // 3. AŞAMA: Yere düşmeden hemen önce yumuşakça silinme
            withAnimation(.easeIn(duration: 1.0).delay(animationDuration - 1.0)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Test için siyah bir arka plan
        Color.black.ignoresSafeArea()
        
        KonfetiView()
    }
}
