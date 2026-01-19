import SwiftUI

struct KonfetiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { i in
                KonfetiParcasi(animate: $animate, index: i)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct KonfetiParcasi: View {
    @Binding var animate: Bool
    let index: Int
    
    // Rastgele renkler
    let renkler: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    
    var body: some View {
        Rectangle()
            .fill(renkler.randomElement()!)
            .frame(width: 8, height: 8)
            .offset(x: animate ? CGFloat.random(in: -200...200) : 0,
                    y: animate ? CGFloat.random(in: -100...400) : -200)
            .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
            .opacity(animate ? 0 : 1)
            .animation(
                Animation.easeOut(duration: Double.random(in: 1.0...2.0))
                    .delay(Double.random(in: 0.0...0.2)),
                value: animate
            )
    }
}
