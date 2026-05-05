import SwiftUI
import Charts

/// Kullanıcının son 90 günlük üretkenlik trendini Apple Stocks / Health tarzında
/// akışkan, degrade (gradient) dolgulu ve etkileşimli bir alan grafiğiyle gösterir.
struct TrendAreaChartView: View {
    let data: [StatisticsViewModel.DailyActivity]
    @EnvironmentObject var appearance: AppearanceManager
    
    // Parmağı grafikte kaydırırken (Scrubbing) seçilen tarihi tutar
    @State private var selectedDate: Date? = nil
    @State private var animatedData: [StatisticsViewModel.DailyActivity] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // 1. BAŞLIK VE ETKİLEŞİMLİ DETAY (TOOLTIP)
            HStack {
                Label("90 GÜNLÜK ÜRETKENLİK TRENDİ", systemImage: "waveform.path.ecg")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                
                Spacer()
                
                // Kullanıcı grafiğe dokunuyorsa o günün detayını göster
                if let selected = selectedActivity {
                    HStack(spacing: 4) {
                        Text("\(selected.count) Görev")
                            .foregroundColor(appearance.accentColor)
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        Text(formatDate(selected.date))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .font(.system(size: 10, weight: .bold))
                    .transition(.opacity.combined(with: .scale))
                }
            }
            
            // 2. AKIŞKAN ALAN GRAFİĞİ (SMOOTH AREA CHART)
            if data.isEmpty {
                Color.clear.frame(height: 150) // Boşluk tutucu
            } else {
                Chart {
                    ForEach(animatedData) { item in
                        // ALTTAKİ ŞEFFAF DOLGU (Gradient)
                        AreaMark(
                            x: .value("Tarih", item.date),
                            y: .value("Görev", item.count)
                        )
                        .interpolationMethod(.catmullRom) // Yumuşak kıvrımlar (Senior dokunuşu)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    appearance.accentColor.opacity(0.5),
                                    appearance.accentColor.opacity(0.01)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // ÜSTTEKİ KESKİN NEON ÇİZGİ
                        LineMark(
                            x: .value("Tarih", item.date),
                            y: .value("Görev", item.count)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(appearance.accentColor)
                        // Gölgelendirme ile neon parlama efekti
                        .shadow(color: appearance.accentColor.opacity(0.6), radius: 5, x: 0, y: 3)
                    }
                    
                    // ✨ KULLANICI DOKUNDUĞUNDA ÇIKAN DİKEY ÇİZGİ (RULE MARK)
                    if let selectedDate = selectedDate, let selected = selectedActivity {
                        RuleMark(x: .value("Seçili Tarih", selectedDate))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                            .foregroundStyle(appearance.accentColor.opacity(0.5))
                            .annotation(position: .top) {
                                // Çizginin tepesinde çıkan minik kutucuk
                                VStack(spacing: 2) {
                                    Text("\(selected.count)")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundColor(appearance.accentColor)
                                    Text(formatDateShort(selected.date))
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6).background(.ultraThinMaterial))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(appearance.accentColor.opacity(0.3), lineWidth: 1))
                            }
                    }
                }
                .frame(height: 160)
                .chartXAxis(.hidden) // Alt tarihleri gizleyip temiz bir görünüm sağlıyoruz
                .chartYAxis(.hidden) // Sol rakamları gizliyoruz
                // ✨ ETKİLEŞİM (Scrubbing)
                .chartXSelection(value: $selectedDate)
            }
        }
        .padding(20)
        // ✨ GLASSMORPHISM
        .background(Color.white.opacity(0.05).background(.ultraThinMaterial))
        .cornerRadius(30)
        .onAppear {
            animateChart()
        }
        .onChange(of: data) { _, _ in
            animateChart()
        }
    }
}

// MARK: - Helpers
private extension TrendAreaChartView {
    
    /// Seçili tarihe denk gelen veriyi bulur
    var selectedActivity: StatisticsViewModel.DailyActivity? {
        guard let selectedDate = selectedDate else { return nil }
        // Chart, parmağın bulunduğu noktaya en yakın tarihi döner, biz de onu array'de buluruz
        return data.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) })
    }
    
    /// Yüklenirken grafiğin 0'dan yukarı doğru büyüme animasyonu
    func animateChart() {
        // Önce her şeyi 0'a çek
        animatedData = data.map { StatisticsViewModel.DailyActivity(date: $0.date, count: 0) }
        
        // Sonra gerçek veriye yaylanarak çıkar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                self.animatedData = self.data
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        if Calendar.current.isDateInToday(date) { return "Bugün" }
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
    
    func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}
