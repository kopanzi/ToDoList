import SwiftUI

/// Uygulamanın 'Komuta Merkezi' olan istatistik ekranı.
/// Senior Notu: Eski MeshGradient ve statik renkler tamamen kaldırılarak
/// Apple HIG (Sistem Arkaplanı + Adaptive Renkler) standartlarına geçirilmiştir.
/// mainMeshColors hatası çözülmüştür.
struct StatisticsView: View {
    // MARK: - Properties
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    @StateObject private var statsVM = StatisticsViewModel()
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. DİNAMİK ARKA PLAN (Apple Native HIG)
            // ✨ SENIOR FIX: Hata veren Mesh Gradient silindi, Adaptive Sistem Arka Planı eklendi.
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    
                    // HEADER (Başlık Bölümü)
                    headerSection
                    
                    // YOLCULUK ÖZETİ (Ömür Boyu Sayaçlar ile)
                    journeySummaryCard
                    
                    // 1. ÖZET KARTLARI (Bento Box - 4'lü Analiz Kutuları)
                    summaryCards
                    
                    // 2. HAFTALIK AKTİVİTE
                    WeeklyActivityChart(data: statsVM.weeklyData)
                        .padding(.horizontal, 20)
                    
                    // 3. ERTELEME YÜZLEŞMESİ GRAFİĞİ
                    ProcrastinationChartView(data: statsVM.procrastinationData)
                        .padding(.horizontal, 20)
                    
                    // 4. KATEGORİ DAĞILIMI
                    CategoryDonutChart(
                        data: statsVM.categoryDistribution,
                        selectedFilter: $statsVM.categoryTimeFilter
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
        }
        // Sayfa açıldığında verileri işle
        .onAppear {
            statsVM.processTasks(
                activeTasks: taskVM.tasks,
                archivedTasks: taskVM.archivedTasks,
                lifetimeAdded: taskVM.lifetimeAddedTasks,
                lifetimeCompleted: taskVM.lifetimeCompletedTasks
            )
        }
        // Görevlerde bir değişiklik olursa grafikleri anında canlı güncelle
        .onChange(of: taskVM.tasks) { _, newTasks in
            statsVM.processTasks(
                activeTasks: newTasks,
                archivedTasks: taskVM.archivedTasks,
                lifetimeAdded: taskVM.lifetimeAddedTasks,
                lifetimeCompleted: taskVM.lifetimeCompletedTasks
            )
        }
        // Arşiv (çöpe atılan bitmiş görevler) değişirse de grafikleri güncelle
        .onChange(of: taskVM.archivedTasks) { _, newArchived in
            statsVM.processTasks(
                activeTasks: taskVM.tasks,
                archivedTasks: newArchived,
                lifetimeAdded: taskVM.lifetimeAddedTasks,
                lifetimeCompleted: taskVM.lifetimeCompletedTasks
            )
        }
    }
}

// MARK: - UI Components
private extension StatisticsView {
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("İSTATİSTİKLER")
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(appearance.accentColor) // ✨ Tema Rengi
            
            Text("Üretkenlik Raporu")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary) // ✨ Adaptive (Karanlıkta beyaz, aydınlıkta siyah)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
    
    var journeySummaryCard: some View {
        let completedCount = taskVM.lifetimeCompletedTasks
        let totalCount = taskVM.lifetimeAddedTasks
        
        return HStack(spacing: 16) {
            // Sol Taraftaki Madalya İkonu
            ZStack {
                Circle()
                    .fill(appearance.accentColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "medal.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(appearance.accentColor)
            }
            
            // Sağ Taraftaki Dinamik Metin Alanı
            VStack(alignment: .leading, spacing: 6) {
                Text("YAVER İLE YOLCULUĞUN")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary) // ✨ Adaptive
                    .tracking(1)
                
                // Text yapılarını birleştirerek içindeki sadece bazı kelimeleri renklendiriyoruz!
                journeyMessageView(completed: completedCount, total: totalCount)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.9)) // ✨ Adaptive
                    .lineSpacing(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
        // ✨ GLASSMORPHISM (Adaptive)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding(.horizontal, 20)
    }
    
    // ✨ YAVER'İN ZEKA MOTORU: Görev durumuna göre farklı cümleler kurar
    func journeyMessageView(completed: Int, total: Int) -> Text {
        if total == 0 {
            return Text("Henüz bir görev eklemedin. Maceraya başlamak için ilk görevini oluştur!")
        } else if completed == 0 {
            return Text("Bugüne kadar eklediğin ") +
            Text("\(total) görevin ").bold().foregroundColor(appearance.accentColor) +
            Text("var. İlk zaferini kazanmak için birini tamamla!")
        } else if completed == total {
            return Text("Harika! Bugüne kadar eklediğin ") +
            Text("tüm görevleri (\(completed)) ").bold().foregroundColor(appearance.accentColor) +
            Text("başarıyla tamamladın. Kusursuz bir tablo!")
        } else {
            return Text("Bugüne kadar eklediğin \(total) görevin tam ") +
            Text("\(completed) tanesini ").bold().foregroundColor(appearance.accentColor) +
            Text("tamamladın. Aynen böyle devam et!")
        }
    }
    
    var summaryCards: some View {
        // Profildeki 4'lü Bento Box
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            
            // 1. Bitirme Oranı
            StatMiniCard(
                title: "BİTİRME",
                value: "%\(statsVM.userStats.completionRate)",
                subtitle: "Oran",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            // 2. Seri (Streak)
            StatMiniCard(
                title: "SERİ",
                value: "\(statsVM.userStats.streakCount)",
                subtitle: "Gün",
                icon: "flame.fill",
                color: .orange
            )
            
            // 3. Zirve Saat
            StatMiniCard(
                title: "ZİRVE SAAT",
                value: statsVM.userStats.efficiencyTime,
                subtitle: "Ortalama",
                icon: "bolt.fill",
                color: .blue
            )
            
            // 4. Kazanılan Zaman
            StatMiniCard(
                title: "KAZANÇ",
                value: statsVM.userStats.timeSaved,
                subtitle: "Zaman",
                icon: "timer",
                color: .purple
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Mini Kutu Tasarımı (StatMiniCard)
/// En üstte duran 4'lü özet kutucuklarının tasarımı
struct StatMiniCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.secondary) // ✨ Adaptive
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary) // ✨ Adaptive
                    .lineLimit(1)
                    .minimumScaleFactor(0.5) // Yazı çok uzunsa sığdırmak için küçülür
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary) // ✨ Adaptive
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        // ✨ GLASSMORPHISM EFEKTİ (Adaptive)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}
