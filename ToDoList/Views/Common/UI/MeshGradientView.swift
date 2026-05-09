import SwiftUI
import Combine

/// iOS 18 MeshGradient kullanarak akışkan ve performanslı arka planlar çizen bileşen.
/// Senior Notu: Matematiksel olarak çizildiği için pil dostudur. Ek olarak ScenePhase entegrasyonu
/// yapılarak uygulama arka plandayken (Background) gereksiz GPU/CPU tüketimi (Battery Drain) engellenmiştir.
struct MeshGradientView: View {
    let colors: [Color]
    @State private var t: Float = 0.0
    
    // ✨ SENIOR FIX 1: Uygulamanın o anki durumunu (Aktif, Arka Plan, Kapalı) dinler
    @Environment(\.scenePhase) private var scenePhase
    
    // Animasyon döngüsü (Combine Publisher)
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    // MeshGradient(width: 3, height: 3) fonksiyonu KESİNLİKLE 9 renk ister.
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
        Group {
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
            } else {
                // ✨ SENIOR FIX 2: iOS 18 altı (iOS 17) için yedek planı daha da "Mesh" hissi verecek
                // şekilde güncelledik. Artık hem X hem Y ekseninde dönen bir sıvı (Fluid) gibi hareket eder.
                LinearGradient(
                    colors: colors.count >= 3 ? [colors[0], colors[1], colors[2]] : colors,
                    startPoint: UnitPoint(x: 0.5 + CGFloat(sin(t)*0.5), y: 0.5 - CGFloat(cos(t)*0.5)),
                    endPoint: UnitPoint(x: 0.5 - CGFloat(sin(t)*0.5), y: 0.5 + CGFloat(cos(t)*0.5))
                )
            }
        }
        .ignoresSafeArea()
        .onReceive(timer) { _ in
            // ✨ SENIOR FIX 3: Uygulama ön planda değilse (Kilitli veya ana ekrandaysa)
            // animasyonu çalıştırma. Bu sayede pil sömürmesinin (Battery Drain) önüne geçilir.
            guard scenePhase == .active else { return }
            
            // Renk geçişlerini yumuşatmak için t değerini güncelliyoruz
            withAnimation(.easeInOut(duration: 2.0)) {
                t += 0.5
            }
        }
    }
}
