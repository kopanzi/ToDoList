import SwiftUI

/// Kullanıcının son 90 günlük aktivitesini GitHub tarzı bir ısı haritasıyla gösteren bileşen.
/// Senior Notu: LazyHGrid kullanılarak dikeyde 7 satır (Haftanın günleri) oluşturulmuş,
/// yatayda kaydırılabilir premium bir deneyim sunulmuştur. Tıklanabilir detaylar eklenmiştir.
struct HeatmapGridView: View {
    // MARK: - Properties
    let data: [StatisticsViewModel.DailyActivity]
    @EnvironmentObject var appearance: AppearanceManager
    
    // Tıklanan kutucuğun detaylarını göstermek için
    @State private var selectedActivity: StatisticsViewModel.DailyActivity?
    
    // GitHub tarzı 7 günlük satır düzeni
    let rows = Array(repeating: GridItem(.fixed(14), spacing: 6), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // 1. BAŞLIK VE TOOLTIP (Tıklanan Günün Detayı)
            HStack {
                Label("ISI HARİTASI (SON 90 GÜN)", systemImage: "square.grid.3x3.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                
                Spacer()
                
                // Kullanıcı bir kutuya tıkladığında beliren bilgi ekranı
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
            
            // 2. YATAY KAYDIRILABİLİR IZGARA (Heatmap)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: rows, spacing: 6) {
                    ForEach(data) { activity in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(heatmapColor(for: activity.count))
                            .frame(width: 14, height: 14)
                            // Tıklanan kutuyu beyaz bir çerçeve ile vurgula
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(
                                        selectedActivity?.id == activity.id ? Color.white : Color.white.opacity(0.05),
                                        lineWidth: selectedActivity?.id == activity.id ? 2 : 0.5
                                    )
                            )
                            // Basıldığında hafifçe esnesin ve detayı göstersin
                            .scaleEffect(selectedActivity?.id == activity.id ? 1.15 : 1.0)
                            .onTapGesture {
                                HapticManager.shared.triggerLightImpact()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    if selectedActivity?.id == activity.id {
                                        selectedActivity = nil // Zaten seçiliyse kapat
                                    } else {
                                        selectedActivity = activity
                                    }
                                }
                            }
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 2)
            }
            // Başlangıçta en sağa (bugüne) kaydırılmış halde başlatmak istersen ScrollViewReader kullanılabilir.
            
            // 3. LEJANT (Legend) - Yoğunluk Açıklaması
            HStack {
                Text("Az")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatmapColor(for: i))
                            .frame(width: 10, height: 10)
                    }
                }
                
                Text("Çok")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        // ✨ GLASSMORPHISM
        .background(Color.white.opacity(0.05).background(.ultraThinMaterial))
        .cornerRadius(30)
    }
}

// MARK: - Helpers
private extension HeatmapGridView {
    
    /// Görev sayısına göre opaklığı/rengi belirler (Github formülü)
    func heatmapColor(for count: Int) -> Color {
        if count == 0 { return Color.white.opacity(0.05) }
        
        // 5 veya daha fazla görev "Maksimum" parlaklık sayılır
        let intensity = min(Double(count) / 5.0, 1.0)
        
        // Ana temanın rengini alır ve yoğunluğa göre opaklık uygular
        return appearance.accentColor.opacity(0.2 + (intensity * 0.8))
    }
    
    /// Tıklanan tarihi "14 Ekim" gibi şık bir formata çevirir
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        
        if Calendar.current.isDateInToday(date) {
            return "Bugün"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Dün"
        }
        
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}
