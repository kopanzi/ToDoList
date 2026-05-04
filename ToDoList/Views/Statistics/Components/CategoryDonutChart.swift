import SwiftUI
import Charts

/// Kullanıcının bitirdiği görevlerin kategorilere göre dağılımını gösteren Halka (Donut) Grafik bileşeni.
/// Senior Notu: Veri olmadığında çökmeyi önleyen boş durum (Empty State) yönetimi ve
/// SwiftUI Charts ile yüksek performanslı çizim içerir.
struct CategoryDonutChart: View {
    // MARK: - Properties
    let data: [StatisticsViewModel.CategoryData]
    
    // Grafiğin açılışında dolma efekti (Animation) vermek için
    @State private var animatedData: [StatisticsViewModel.CategoryData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // 1. BAŞLIK
            HStack {
                Label("KATEGORİ ANALİZİ", systemImage: "chart.pie.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                
                Spacer()
                
                // Toplam Kategori Sayısı Rozeti
                if !data.isEmpty {
                    Text("\(data.count) Kategori")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            // 2. İÇERİK (Grafik veya Boş Durum)
            if data.isEmpty {
                // Veri yoksa şık bir boş kutu göster
                emptyStateView
            } else {
                HStack(spacing: 20) {
                    // Sol: Donut Chart
                    Chart(animatedData) { item in
                        SectorMark(
                            angle: .value("Görev Sayısı", item.count),
                            innerRadius: .ratio(0.65), // Halka kalınlığı
                            angularInset: 2 // Dilimler arası boşluk
                        )
                        .foregroundStyle(item.color.gradient)
                        .cornerRadius(6)
                    }
                    .frame(width: 140, height: 140)
                    // Halkanın içine toplam sayıyı yazma (ZStack kullanmadan Chart overlay ile)
                    .chartBackground { proxy in
                        VStack {
                            Text("Toplam")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("\(data.reduce(0) { $0 + $1.count })")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Sağ: Legend (En çok kullanılan ilk 4 kategori)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(data.prefix(4)) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color.gradient)
                                    .frame(width: 8, height: 8)
                                
                                Text(item.category)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(item.count)")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // 4'ten fazla kategori varsa "Diğerleri" diye belirt
                        if data.count > 4 {
                            Text("+ \(data.count - 4) Kategori Daha")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding(20)
        // ✨ GLASSMORPHISM EFEKTİ
        .background(Color.white.opacity(0.05).background(.ultraThinMaterial))
        .cornerRadius(30)
        // Grafiği yumuşak bir şekilde doldurmak için animasyon
        .onAppear {
            animateChart()
        }
        .onChange(of: data) { _, _ in
            animateChart()
        }
    }
}

// MARK: - Helpers
private extension CategoryDonutChart {
    
    var emptyStateView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 15)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "chart.pie")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.2))
            }
            
            Text("Veri Bekleniyor")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    /// Verileri sıfırdan doldurarak grafiğe açılış animasyonu ekler
    func animateChart() {
        // Önce sıfırla
        animatedData = data.map { StatisticsViewModel.CategoryData(category: $0.category, count: 0, color: $0.color) }
        
        // Sonra gerçek değerlerine anime et
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                self.animatedData = self.data
            }
        }
    }
}
