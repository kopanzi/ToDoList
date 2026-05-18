import SwiftUI

/// Uygulamanın 'Komuta Merkezi' olan istatistik ekranı.
/// Senior Notu: Bento kutularının (Bitirme Oranı, Zirve Saat, Odak Süresi) her birine
/// bağımsız zaman filtreleri (.daily, .weekly vb.) eklenerek tam bir Apple Dashboard havası katılmıştır.
/// Tüm derleyici (compiler) uyarıları ve bağlayıcı hataları kesin olarak giderilmiştir.
struct StatisticsView: View {
    // MARK: - Properties
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    @StateObject private var statsVM = StatisticsViewModel()
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. DİNAMİK ARKA PLAN (Apple Native HIG)
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
            processAllData()
        }
        // Görevlerde veya Odaklanma sürelerinde değişiklik olursa grafikleri anında canlı güncelle
        .onChange(of: taskVM.tasks) { _, _ in processAllData() }
        .onChange(of: taskVM.archivedTasks) { _, _ in processAllData() }
        .onChange(of: taskVM.focusSessions) { _, _ in processAllData() }
    }
    
    // MARK: - Merkezi Veri İşleme Motoru
    private func processAllData() {
        // 1. Görev verilerini işle
        statsVM.processTasks(
            activeTasks: taskVM.tasks,
            archivedTasks: taskVM.archivedTasks,
            lifetimeAdded: taskVM.lifetimeAddedTasks,
            lifetimeCompleted: taskVM.lifetimeCompletedTasks
        )
        // 2. Odaklanma sürelerini işle
        statsVM.processFocusSessions(taskVM.focusSessions)
    }
}

// MARK: - UI Components
private extension StatisticsView {
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("İSTATİSTİKLER")
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(appearance.accentColor) // Tema Rengi
            
            Text("Üretkenlik Raporu")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
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
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                journeyMessageView(completed: completedCount, total: totalCount)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineSpacing(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
        // GLASSMORPHISM (Adaptive)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding(.horizontal, 20)
    }
    
    // YAVER'İN ZEKA MOTORU
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
            
            // 1. Bitirme Oranı (Filtreli)
            CompletionRateCard(statsVM: statsVM)
            
            // 2. Seri (Streak - Her zaman bugünkü aktif seriyi gösterir)
            StatMiniCard(
                title: "SERİ",
                value: "\(statsVM.userStats.streakCount)",
                subtitle: "Gün",
                icon: "flame.fill",
                color: .orange
            )
            
            // 3. Zirve Saat (Filtreli)
            PeakTimeCard(statsVM: statsVM)
            
            // 4. Odaklanma Süresi (Filtreli)
            FocusTimeCard(statsVM: statsVM)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 1. DİNAMİK BİTİRME ORANI KARTI (Zaman Filtreli)
struct CompletionRateCard: View {
    @ObservedObject var statsVM: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                Menu {
                    Picker("Filtre", selection: $statsVM.completionRateFilter) {
                        ForEach(StatisticsViewModel.TimeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(statsVM.completionRateFilter.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(6)
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(statsVM.completionRateString)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: statsVM.completionRateString)
                
                Text("Bitirme Oranı")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - 2. DİNAMİK ZİRVE SAAT KARTI (Zaman Filtreli)
struct PeakTimeCard: View {
    @ObservedObject var statsVM: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                Menu {
                    Picker("Filtre", selection: $statsVM.peakTimeFilter) {
                        ForEach(StatisticsViewModel.TimeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(statsVM.peakTimeFilter.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(6)
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(statsVM.peakTimeString)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: statsVM.peakTimeString)
                
                Text("Zirve Saat")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - 3. DİNAMİK ODAK SÜRESİ KARTI (Zaman Filtreli)
struct FocusTimeCard: View {
    @ObservedObject var statsVM: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hourglass")
                    .foregroundColor(.purple)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                Menu {
                    Picker("Filtre", selection: $statsVM.focusTimeFilter) {
                        ForEach(StatisticsViewModel.TimeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(statsVM.focusTimeFilter.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(6)
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(statsVM.focusTimeString)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: statsVM.focusTimeString)
                
                Text("Odaklanılan")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - STANDART MİNİ KART TASARIMI (Seri için kullanılır)
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
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}
