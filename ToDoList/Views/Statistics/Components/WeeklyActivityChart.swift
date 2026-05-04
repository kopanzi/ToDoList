import SwiftUI
import Charts

/// Kullanıcının son 7 günlük görev tamamlama ritmini (Sütun Grafik) gösteren bileşen.
/// Senior Notu: SwiftUI Charts framework'ü kullanılmış ve açılışta çubukların dipten
/// yukarı doğru yumuşakça dolmasını sağlayan özel bir 'animationProgress' mantığı kurulmuştur.
struct WeeklyActivityChart: View {
    // MARK: - Properties
    let data: [StatisticsViewModel.DailyActivity]
    @EnvironmentObject var appearance: AppearanceManager
    
    // Grafiğin açılışında çubukların sıfırdan yükselmesi için çarpan
    @State private var animationProgress: CGFloat = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // 1. BAŞLIK VE ÖZET
            HStack {
                Label("HAFTALIK RİTİM", systemImage: "waveform.path.ecg")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                
                Spacer()
                
                // Toplam Haftalık Görev Sayısı
                let totalThisWeek = data.reduce(0) { $0 + $1.count }
                if totalThisWeek > 0 {
                    Text("\(totalThisWeek) Görev")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(appearance.accentColor)
                }
            }
            
            // 2. SÜTUN GRAFİĞİ (BAR CHART)
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Gün", item.date, unit: .day),
                        // ✨ SENIOR FIX: Animasyon çarpanı ile çubuklar sıfırdan yukarı uzar
                        y: .value("Görev", CGFloat(item.count) * animationProgress)
                    )
                    // Çubuk renkleri temanın ana renginden şeffafa doğru havalı bir degrade olur
                    .foregroundStyle(
                        LinearGradient(
                            colors: [appearance.accentColor, appearance.accentColor.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                    // Sıfır olan (görev yapılmayan) günlerde bile zeminde minik bir iz kalsın
                    .annotation(position: .overlay, alignment: .bottom) {
                        if item.count == 0 {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 2)
                                .cornerRadius(1)
                        }
                    }
                }
            }
            .frame(height: 180)
            // X Ekseni (Pzt, Sal, Çar...)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.short))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            // Y Eksenindeki kalabalık sayıları ve çizgileri gizleyip temiz bir görüntü (Clean UI) elde ediyoruz
            .chartYAxis(.hidden)
        }
        .padding(20)
        // ✨ GLASSMORPHISM
        .background(Color.white.opacity(0.05).background(.ultraThinMaterial))
        .cornerRadius(30)
        
        // ✨ AÇILIŞ ANİMASYONU
        .onAppear {
            triggerAnimation()
        }
        .onChange(of: data.count) { _, _ in
            triggerAnimation()
        }
    }
}

// MARK: - Helpers
private extension WeeklyActivityChart {
    func triggerAnimation() {
        // Önce sıfırla, sonra yay (spring) efektiyle doldur
        animationProgress = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animationProgress = 1.0
            }
        }
    }
}
