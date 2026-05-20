import SwiftUI
import Charts

/// Kullanıcının bitirdiği görevlerin kategorilere göre dağılımını gösteren Halka (Donut) Grafik bileşeni.
/// Senior Notu: Top 4 dışındaki kategoriler "Diğer" başlığı altında birleştirilir.
/// Kullanıcı detay görmek isterse akordiyon (Accordion) animasyonuyla liste aşağı doğru genişler.
struct CategoryDonutChart: View {
    // MARK: - Properties
    let data: [StatisticsViewModel.CategoryData]
    
    // Üst bileşenden (StatisticsView) gelen filtre bağlantısı
    @Binding var selectedFilter: StatisticsViewModel.TimeFilter
    
    // Tema renklerine uymak için
    @EnvironmentObject var appearance: AppearanceManager
    
    // Grafiğin açılışında ve filtre değişiminde dolma efekti (Animation) vermek için
    @State private var animatedData: [StatisticsViewModel.CategoryData] = []
    
    // ✨ SENIOR FIX: "Diğer" kategorilerini göstermek için genişleme durumu
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // 1. BAŞLIK VE FİLTRE MENÜSÜ
            HStack {
                Label("KATEGORİ ANALİZİ", systemImage: "chart.pie.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary) // Aydınlık/Karanlık mod uyumu
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
                    .font(.system(size: 9, weight: .black))
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
                // ✨ SENIOR FIX: Alignment .top yapıldı ki liste uzadığında grafik yukarıda sabit kalsın!
                HStack(alignment: .top, spacing: 20) {
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
                                .foregroundColor(.secondary)
                            Text("\(data.reduce(0) { $0 + $1.count })")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Sağ: Legend (Lejant)
                    VStack(alignment: .leading, spacing: 12) {
                        // En çok kullanılan ilk 4 kategoriyi göster
                        ForEach(data.prefix(4)) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color.gradient)
                                    .frame(width: 8, height: 8)
                                
                                Text(item.category)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.8))
                                    .lineLimit(1)
                                
                                Spacer(minLength: 10)
                                
                                Text("\(item.count)")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // ✨ SENIOR FIX: 4'ten fazla kategori varsa genişletilebilir "Diğer" menüsü
                        if data.count > 4 {
                            let otherCategories = Array(data.dropFirst(4))
                            let otherTasksTotal = otherCategories.reduce(0) { $0 + $1.count } // Geriye kalanların toplamı
                            
                            // Akordiyon (Genişlet/Daralt) Butonu
                            Button(action: {
                                HapticManager.shared.triggerSelection()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3).gradient)
                                        .frame(width: 8, height: 8)
                                    
                                    Text("Diğer (\(otherCategories.count))")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    // Yön Ok İkonu
                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary.opacity(0.6))
                                    
                                    Spacer(minLength: 10)
                                    
                                    Text("\(otherTasksTotal)")
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                            .buttonStyle(.plain) // Butonun tıklama efektini arındırır
                            
                            // 🚀 YENİ: Alt Liste (Genişlediğinde açılır)
                            if isExpanded {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(otherCategories) { item in
                                        HStack(spacing: 8) {
                                            // Hiyerarşi (Alt dal) hissi vermek için hafif boşluk
                                            Color.clear.frame(width: 8, height: 8)
                                            
                                            Circle()
                                                .fill(item.color.gradient)
                                                .frame(width: 6, height: 6)
                                            
                                            Text(item.category)
                                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                                .foregroundColor(.primary.opacity(0.7))
                                                .lineLimit(1)
                                            
                                            Spacer(minLength: 10)
                                            
                                            Text("\(item.count)")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(.primary.opacity(0.7))
                                        }
                                    }
                                }
                                .padding(.top, 2)
                                // Zarif bir kayarak açılma animasyonu
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(.top, 4) // Grafikle yazıları ortalamak için ince ayar
                }
            }
        }
        .padding(20)
        // ✨ GLASSMORPHISM EFEKTİ
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.primary.opacity(0.05), lineWidth: 1))
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
                    .stroke(Color.primary.opacity(0.05), lineWidth: 15)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "chart.pie")
                    .font(.system(size: 24))
                    .foregroundColor(.primary.opacity(0.2))
            }
            
            // Filtre metnine göre boş durum cümlesi dinamikleşir
            Text("\(selectedFilter.rawValue) İçin Veri Yok")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    /// Verileri sıfırdan doldurarak grafiğe açılış animasyonu ekler
    func animateChart() {
        // Önce sayıyı sıfırla ki chart çöksün
        animatedData = data.map { StatisticsViewModel.CategoryData(category: $0.category, count: 0, color: $0.color) }
        
        // Liste filtrelendiğinde eğer 4'ten aza düşerse kutuyu otomatik topla (Bug önleyici)
        if data.count <= 4 {
            isExpanded = false
        }
        
        // Sonra yaylanarak gerçek değerlerine anime et
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                self.animatedData = self.data
            }
        }
    }
}
