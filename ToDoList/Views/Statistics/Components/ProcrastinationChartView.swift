import SwiftUI
import Charts

/// Kullanıcının bitirdiği görevler (Başarı) ile ertelediği görevleri (Yük) karşılaştıran interaktif grafik.
/// Senior Notu: Akışkanlık sorunlarını çözmek için 'Magnetic Snapping' algoritması ve
/// iOS Health tarzı 'Selection Overlay' (Vurgu Katmanı) entegre edilmiştir.
/// Tüm statik (.white / .black) renkler Adaptive (.primary / .secondary) olarak güncellenmiştir.
struct ProcrastinationChartView: View {
    // MARK: - Properties
    let data: [StatisticsViewModel.ProcrastinationData]
    @EnvironmentObject var appearance: AppearanceManager
    
    // Animasyon ve Hassas Seçim Durumları
    @State private var animationProgress: Double = 0.0
    @State private var rawSelectedDate: Date? = nil // Parmağın milimetrik konumu
    @State private var activeItem: StatisticsViewModel.ProcrastinationData? = nil // Mıknatısla yakalanan veri
    
    // Yaver'in Durum Analizi (Insight)
    var insightMessage: String {
        let totalDelayed = data.reduce(0) { $0 + $1.delayed }
        let totalCompleted = data.reduce(0) { $0 + $1.completed }
        
        if totalDelayed == 0 && totalCompleted == 0 {
            return "Henüz yeterli veri yok. Görev ekleyip tamamlamaya başla!"
        } else if totalDelayed == 0 {
            return "Kusursuz! Son 7 günde hiçbir işi ertelemedin. Odaklanman zirvede."
        } else if totalDelayed > totalCompleted {
            return "Uyarı: İş bitirmekten çok erteleme yapıyorsun. Günlük yükünü azaltmalısın."
        } else {
            return "Son 7 günde \(totalDelayed) kez erteleme yaptın. Dengeyi korumaya çalış."
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            // 1. ÜST PANEL (Başlık ve Akıllı Yorum)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("ERTELEME YÜZLEŞMESİ", systemImage: "scale.3d")
                        .font(.system(size: 12, weight: .bold))
                        // ✨ SENIOR FIX: Aydınlık/Karanlık moda tam uyum
                        .foregroundColor(.secondary)
                        .tracking(1)
                    
                    Spacer()
                }
                
                Text(insightMessage)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(appearance.accentColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(activeItem == nil ? 1 : 0) // Seçim varken odağı grafiğe ver
                    .animation(.easeInOut, value: activeItem == nil)
            }
            
            // 2. ANA GRAFİK MOTORU (Diverging Bar Chart)
            Chart {
                ForEach(data) { item in
                    let completedValue = Double(item.completed) * animationProgress
                    let delayedValue = Double(-item.delayed) * animationProgress
                    
                    // BAŞARI (YUKARI)
                    BarMark(
                        x: .value("Gün", item.date, unit: .day),
                        y: .value("Tamamlanan", completedValue)
                    )
                    .foregroundStyle(appearance.accentColor.gradient)
                    .cornerRadius(4)
                    // Fokus Efekti: Seçili sütun parlar, diğerleri solar
                    .opacity(activeItem == nil || activeItem?.id == item.id ? 1.0 : 0.3)
                    
                    // ERTELEME (AŞAĞI)
                    BarMark(
                        x: .value("Gün", item.date, unit: .day),
                        y: .value("Ertelenen", delayedValue)
                    )
                    .foregroundStyle(Color.red.opacity(0.8).gradient)
                    .cornerRadius(4)
                    .opacity(activeItem == nil || activeItem?.id == item.id ? 1.0 : 0.3)
                }
                
                // Sıfır Çizgisi (Dünya Ekseni)
                RuleMark(y: .value("Sıfır", 0))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                    // ✨ SENIOR FIX: .white yerine Adaptive
                    .foregroundStyle(Color.primary.opacity(0.2))
                
                // ✨ SEÇİLEN ALAN VURGUSU (Selection Background)
                // Apple Health tarzı; sütunun arkasında şık bir gölge katmanı
                if let selected = activeItem {
                    RectangleMark(
                        xStart: .value("Başlangıç", Calendar.current.date(byAdding: .hour, value: -12, to: selected.date)!),
                        xEnd: .value("Bitiş", Calendar.current.date(byAdding: .hour, value: 12, to: selected.date)!)
                    )
                    // ✨ SENIOR FIX: .white yerine Adaptive arka plan izi
                    .foregroundStyle(Color.primary.opacity(0.05))
                    .zIndex(-1) // Çubukların arkasında kalsın
                    
                    // Dikey Kılavuz Çizgi
                    RuleMark(x: .value("Seçili", selected.date, unit: .day))
                        .foregroundStyle(appearance.accentColor.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .zIndex(1)
                        .annotation(
                            position: .top,
                            spacing: 0,
                            overflowResolution: .automatic
                        ) {
                            tooltipView(for: selected)
                        }
                }
            }
            .frame(height: 180)
            // ✨ MAGNETIC INTERACTION: Ham parmak verisini yakala
            .chartXSelection(value: $rawSelectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.short))
                        .font(.system(size: 10, weight: .bold))
                        // ✨ SENIOR FIX: .white yerine .secondary
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(abs(intValue))")
                                .font(.system(size: 10, weight: .bold))
                                // ✨ SENIOR FIX: .white yerine .secondary
                                .foregroundStyle(Color.secondary.opacity(0.8))
                        }
                    }
                }
            }
            // ✨ DOKUNSAL GERİ BİLDİRİM: Akışın "sağlıklı" hissedilmesini sağlayan ana sos
            .sensoryFeedback(.selection, trigger: activeItem)
            
            // 3. LEJANT (Legend)
            HStack(spacing: 20) {
                legendItem(title: "Tamamlanan", color: appearance.accentColor)
                legendItem(title: "Ertelenen Yük", color: .red.opacity(0.8))
            }
        }
        .padding(24)
        // ✨ GLASSMORPHISM EFEKTİ (Adaptive UI)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(32)
        .onAppear { triggerAnimation() }
        // ✨ MIKNATIS ALGORİTMASI (Magnetic Snapping Logic)
        .onChange(of: rawSelectedDate) { _, newValue in
            if let date = newValue {
                // Parmağın olduğu tarihi en yakın günün başlangıcına kilitler (Snapping)
                let snappedDate = Calendar.current.startOfDay(for: date)
                let match = data.first { Calendar.current.isDate($0.date, inSameDayAs: snappedDate) }
                
                // Sadece yeni bir sütuna geçince state'i güncelle (Performans Fix)
                if match?.id != activeItem?.id {
                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
                        activeItem = match
                    }
                }
            } else {
                withAnimation(.spring(response: 0.3)) {
                    activeItem = nil
                }
            }
        }
    }
}

// MARK: - Sub-Views & Helpers
private extension ProcrastinationChartView {
    
    func triggerAnimation() {
        animationProgress = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animationProgress = 1.0
            }
        }
    }
    
    @ViewBuilder
    func tooltipView(for item: StatisticsViewModel.ProcrastinationData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formatDateShort(item.date))
                .font(.system(size: 10, weight: .black))
                // ✨ SENIOR FIX: .white yerine Adaptive .secondary
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 16) {
                scoreLabel(value: item.completed, icon: "arrow.up", color: appearance.accentColor)
                scoreLabel(value: item.delayed, icon: "arrow.down", color: .red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        // ✨ SENIOR FIX: Sabit Hex siyah yerine Sistem Arka Planına tam uyumlu material
        .background(Color(uiColor: .systemBackground).opacity(0.9).background(.regularMaterial))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        // Adaptive şık gölge
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
        .padding(.bottom, 12)
        .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
    }
    
    func scoreLabel(value: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                // ✨ SENIOR FIX: .white yerine .primary
                .foregroundColor(.primary)
        }
    }
    
    func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                // ✨ SENIOR FIX: .white yerine .secondary
                .foregroundColor(.secondary)
        }
    }
    
    func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: date)
    }
}
