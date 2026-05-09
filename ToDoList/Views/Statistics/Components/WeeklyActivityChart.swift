import SwiftUI
import Charts

/// Kullanıcının son 7 günlük görev tamamlama ritmini (Sütun Grafik) gösteren bileşen.
/// Senior Notu: Statik beyaz/siyah renkler kaldırılarak Aydınlık/Karanlık mod (Adaptive UI)
/// uyumu tam sağlanmış, iOS Health tarzı rakamlar (annotation) modernize edilmiştir.
struct WeeklyActivityChart: View {
    // MARK: - Properties
    let data: [StatisticsViewModel.DailyActivity]
    @EnvironmentObject var appearance: AppearanceManager
    
    @State private var animationProgress: CGFloat = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // 1. BAŞLIK VE ÖZET
            HStack {
                Label("HAFTALIK RİTİM", systemImage: "waveform.path.ecg")
                    .font(.system(size: 12, weight: .bold))
                    // ✨ SENIOR FIX: Aydınlık/Karanlık mod uyumu
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Spacer()
                
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
                        y: .value("Görev", CGFloat(item.count) * animationProgress)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [appearance.accentColor, appearance.accentColor.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                    
                    // ✨ SENIOR FIX: Çubukların üzerinde sayıları iOS tarzı gösterme
                    .annotation(position: .top, alignment: .center) {
                        // Sadece sıfırdan büyükse ve animasyon dolmuşsa sayıyı göster
                        if item.count > 0 && animationProgress > 0.8 {
                            Text("\(item.count)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                // ✨ SENIOR FIX: .white yerine .primary kullanılarak her modda net okuma sağlandı
                                .foregroundColor(.primary)
                                // Tatlı bir yukarı çıkış animasyonu
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    
                    // Sıfır olan günlerde zeminde minik bir iz
                    .annotation(position: .overlay, alignment: .bottom) {
                        if item.count == 0 {
                            Rectangle()
                                // ✨ SENIOR FIX: Sabit beyaz yerine ortamın zıt rengi
                                .fill(Color.primary.opacity(0.1))
                                .frame(height: 2)
                                .cornerRadius(1)
                        }
                    }
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.short))
                        .font(.system(size: 10, weight: .bold))
                        // ✨ SENIOR FIX: .white yerine .secondary
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis(.hidden)
        }
        .padding(20)
        // ✨ GLASSMORPHISM EFEKTİ (Adaptive UI)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        
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
        animationProgress = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animationProgress = 1.0
            }
        }
    }
}
