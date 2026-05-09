import SwiftUI
import Charts

/// Kullanıcının bitirdiği görevlerin kategorilere göre dağılımını gösteren Halka (Donut) Grafik bileşeni.
/// Senior Notu: Statik beyaz renkler kaldırılarak Aydınlık/Karanlık mod (Adaptive UI)
/// uyumu tam sağlanmış, seçim anında grafik yaylanarak yenilenmeye devam etmektedir.
struct CategoryDonutChart: View {
    // MARK: - Properties
    let data: [StatisticsViewModel.CategoryData]
    
    // Üst bileşenden (StatisticsView) gelen filtre bağlantısı
    @Binding var selectedFilter: StatisticsViewModel.TimeFilter
    
    // Tema renklerine uymak için
    @EnvironmentObject var appearance: AppearanceManager
    
    // Grafiğin açılışında ve filtre değişiminde dolma efekti (Animation) vermek için
    @State private var animatedData: [StatisticsViewModel.CategoryData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // 1. BAŞLIK VE FİLTRE MENÜSÜ
            HStack {
                Label("KATEGORİ ANALİZİ", systemImage: "chart.pie.fill")
                    .font(.system(size: 12, weight: .bold))
                    // ✨ SENIOR FIX: Aydınlık modda okunabilirlik için .secondary
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Spacer()
                
                // Şık Açılır Menü (Drop-down Menu)
                Menu {
                    ForEach(StatisticsViewModel.TimeFilter.allCases) { filter in
                        Button(action: {
                            HapticManager.shared.triggerLightImpact()
                            // Seçim değiştiğinde grafik animasyonunu tetiklemek için viewModel otomatik çalışacak
                            selectedFilter = filter
                        }) {
                            HStack {
                                Text(filter.rawValue)
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedFilter.rawValue)
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(appearance.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(appearance.accentColor.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            // 2. İÇERİK (Grafik veya Boş Durum)
            if data.isEmpty {
                // Veri yoksa dinamik metinli boş kutu göster
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
                    // Halkanın içine toplam sayıyı yazma
                    .chartBackground { proxy in
                        VStack {
                            Text("Toplam")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary) // ✨ Adaptive
                            Text("\(data.reduce(0) { $0 + $1.count })")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.primary) // ✨ Adaptive
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
                                    .foregroundColor(.primary.opacity(0.8)) // ✨ Adaptive
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(item.count)")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(.primary) // ✨ Adaptive
                            }
                        }
                        
                        // 4'ten fazla kategori varsa "Diğerleri" diye belirt
                        if data.count > 4 {
                            Text("+ \(data.count - 4) Kategori Daha")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary) // ✨ Adaptive
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding(20)
        // ✨ GLASSMORPHISM EFEKTİ (Adaptive)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        // Grafiği yumuşak bir şekilde doldurmak için animasyon
        .onAppear {
            animateChart()
        }
        // Filtre değiştiğinde datalar güncellenir ve animasyon baştan oynatılır
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
                    // ✨ SENIOR FIX: Aydınlık/Karanlık mod duyarlı şeffaflık
                    .stroke(Color.primary.opacity(0.05), lineWidth: 15)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "chart.pie")
                    .font(.system(size: 24))
                    .foregroundColor(.primary.opacity(0.2)) // ✨ Adaptive
            }
            
            // Filtre metnine göre boş durum cümlesi dinamikleşir
            Text("\(selectedFilter.rawValue) İçin Veri Yok")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary) // ✨ Adaptive
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    /// Verileri sıfırdan doldurarak grafiğe açılış animasyonu ekler
    func animateChart() {
        // Önce sayıyı sıfırla ki chart çöksün
        animatedData = data.map { StatisticsViewModel.CategoryData(category: $0.category, count: 0, color: $0.color) }
        
        // Sonra yaylanarak gerçek değerlerine anime et
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                self.animatedData = self.data
            }
        }
    }
}
