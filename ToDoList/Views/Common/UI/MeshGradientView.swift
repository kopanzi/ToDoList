import SwiftUI
import Combine

/// iOS 18 MeshGradient kullanarak akışkan ve performanslı arka planlar çizen bileşen.
/// Senior Notu: Matematiksel olarak çizildiği için pil dostudur ve Combine ile animasyon döngüsü yönetilir.
struct MeshGradientView: View {
    let colors: [Color]
    @State private var t: Float = 0.0
    
    // Animasyon döngüsü (Combine Publisher)
    // autoconnect() sayesinde view ekranda olduğu sürece yayın yapar.
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    // ✨ SENIOR FIX: MeshGradient(width: 3, height: 3) fonksiyonu KESİNLİKLE 9 renk ister.
    // Dışarıdan 3 renk gelse bile, bunu 9'lu estetik bir palete (şablona) genişletiyoruz.
    private var expandedColors: [Color] {
        guard let c1 = colors.first else { return Array(repeating: .clear, count: 9) }
        let c2 = colors.count > 1 ? colors[1] : c1.opacity(0.7)
        let c3 = colors.count > 2 ? colors[2] : c1.opacity(0.4)
        
        // Renkleri 3x3 ızgaraya yumuşak geçişler sağlayacak şekilde dağıtıyoruz.
        return [
            c1, c2, c3,
            c2, c1, c3.opacity(0.8),
            c3, c2.opacity(0.8), c1
        ]
    }
    
    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [sin(t)*0.2 + 0.5, cos(t)*0.2 + 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                // Gelen 3 rengi değil, genişletilmiş 9 rengi veriyoruz!
                colors: expandedColors
            )
            .ignoresSafeArea()
            .onReceive(timer) { _ in
                // Renk geçişlerini yumuşatmak için t değerini güncelliyoruz
                withAnimation(.easeInOut(duration: 2)) {
                    t += 0.5
                }
            }
        } else {
            // ✨ SENIOR FIX: iOS 18 altı (Senin Cihazın - iOS 17) için yedek plan.
            // Artık statik değil! Renklerin başlangıç ve bitiş noktaları zamanla (t)
            // dairesel bir yörüngede (sin/cos) yavaşça hareket ediyor.
            LinearGradient(
                colors: colors.count >= 3 ? [colors[0], colors[1], colors[2]] : colors,
                startPoint: UnitPoint(x: 0.5 + CGFloat(sin(t)*0.3), y: 0),
                endPoint: UnitPoint(x: 0.5 - CGFloat(cos(t)*0.3), y: 1)
            )
            .ignoresSafeArea()
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 2)) {
                    t += 0.5
                }
            }
        }
    }
}
