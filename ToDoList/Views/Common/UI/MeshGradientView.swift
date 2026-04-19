import SwiftUI
import Combine // ✅ KRİTİK DÜZELTME: autoconnect() için bu import şart!

/// iOS 18 MeshGradient kullanarak akışkan ve performanslı arka planlar çizen bileşen.
/// Senior Notu: Matematiksel olarak çizildiği için pil dostudur ve Combine ile animasyon döngüsü yönetilir.
struct MeshGradientView: View {
    let colors: [Color]
    @State private var t: Float = 0.0
    
    // Animasyon döngüsü (Combine Publisher)
    // autoconnect() sayesinde view ekranda olduğu sürece yayın yapar.
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
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
                colors: colors
            )
            .ignoresSafeArea()
            .onReceive(timer) { _ in
                // Renk geçişlerini yumuşatmak için t değerini güncelliyoruz
                withAnimation(.easeInOut(duration: 2)) {
                    t += 0.5
                }
            }
        } else {
            // iOS 18 altı için şık bir Linear Gradient fallback (Geri çekilme planı)
            LinearGradient(
                colors: colors.count >= 2 ? [colors[0], colors[1]] : [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}
