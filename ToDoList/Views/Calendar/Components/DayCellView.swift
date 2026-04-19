import SwiftUI

/// Takvim üzerindeki tek bir günü temsil eden akıllı ve etkileşimli hücre.
/// Senior Notu: Kendi içinde veri hesaplamaz, dışarıdan aldığı Primitive (basit) verileri
/// en yüksek UI kalitesiyle (Glassmorphism, Heatmap Dots, Vault Indicator) çizer.
struct DayCellView: View {
    // MARK: - Properties
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let heatmapLevel: CalendarViewModel.HeatmapLevel
    let hasHiddenTasks: Bool
    let action: () -> Void
    
    @EnvironmentObject var appearance: AppearanceManager
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // 1. GÜN KUTUSU VE KİLİT
                ZStack(alignment: .topTrailing) {
                    
                    // Ana Gün Dairesi/Kapsülü
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(appearance.accentColor)
                                .shadow(color: appearance.accentColor.opacity(0.5), radius: 8, x: 0, y: 3)
                        } else if isToday {
                            Circle()
                                .fill(appearance.accentColor.opacity(0.15))
                                .overlay(
                                    Circle().stroke(appearance.accentColor.opacity(0.4), lineWidth: 1.5)
                                )
                        }
                        
                        Text(dayNumber)
                            .font(.system(size: 16, weight: isSelected || isToday ? .bold : .medium, design: .rounded))
                            .foregroundColor(textColor)
                    }
                    .frame(width: 42, height: 42)
                    
                    // 🔒 Gizli Kasa İndikatörü
                    if hasHiddenTasks {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.orange)
                            .shadow(color: .orange.opacity(0.6), radius: 3, x: 0, y: 0)
                            // Dairenin tam sağ üst köşesine estetik bir şekilde oturtuyoruz
                            .offset(x: 4, y: -2)
                    }
                }
                
                // 2. ISI HARİTASI (HEATMAP) NOKTALARI
                HStack(spacing: 3) {
                    if heatmapLevel == .none {
                        // UI zıplamasını engellemek için şeffaf bir tutucu (Placeholder)
                        Circle().fill(Color.clear).frame(width: 4, height: 4)
                    } else {
                        // Yoğunluğa göre 1, 2 veya 3 nokta çizer
                        ForEach(0..<dotCount, id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? appearance.accentColor : appearance.accentColor.opacity(0.6))
                                .frame(width: 4, height: 4)
                                .shadow(color: appearance.accentColor.opacity(0.4), radius: 2, x: 0, y: 0)
                        }
                    }
                }
                .frame(height: 4) // Sabit yükseklik
            }
            .contentShape(Rectangle()) // Tıklama alanını genişletmek için
        }
        .buttonStyle(DayCellButtonStyle())
    }
}

// MARK: - Private Helpers & Styles
private extension DayCellView {
    
    /// Tarihten sadece gün rakamını (Örn: "16") çıkarır.
    var dayNumber: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
    
    /// Günün durumuna göre metin rengini zekice belirler.
    var textColor: Color {
        if isSelected {
            // Seçiliyse neon rengin üzerinde zıt (koyu) renk şık durur
            return Color(hex: "10221f")
        }
        if isToday {
            return appearance.accentColor
        }
        
        // Tatil Günü Vurgusu (Hafta sonuysa hafif sönük göster)
        let isWeekend = Calendar.current.isDateInWeekend(date)
        if isWeekend && heatmapLevel == .none {
            return .white.opacity(0.3) // Dinlenme günü mesajı
        }
        
        return .white.opacity(0.9)
    }
    
    /// Isı haritası seviyesine göre nokta sayısını belirler (1, 2 veya 3).
    var dotCount: Int {
        switch heatmapLevel {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

// ✨ YENİ: Hücreye özel esneme (Bouncy) tıklama stili
struct DayCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "0a1412").ignoresSafeArea() // Koyu arka plan
        
        HStack(spacing: 15) {
            // Standart Gün (1 Nokta)
            DayCellView(
                date: Date(),
                isSelected: false,
                isToday: false,
                heatmapLevel: .low,
                hasHiddenTasks: false,
                action: {}
            )
            
            // Bugün (3 Nokta + Seçili Değil)
            DayCellView(
                date: Date(),
                isSelected: false,
                isToday: true,
                heatmapLevel: .high,
                hasHiddenTasks: false,
                action: {}
            )
            
            // Seçili Gün (Gizli Kasa + 2 Nokta)
            DayCellView(
                date: Date(),
                isSelected: true,
                isToday: false,
                heatmapLevel: .medium,
                hasHiddenTasks: true,
                action: {}
            )
            
            // Hafta Sonu Boş Gün (Sönük)
            DayCellView(
                date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                isSelected: false,
                isToday: false,
                heatmapLevel: .none,
                hasHiddenTasks: false,
                action: {}
            )
        }
    }
    .environmentObject(AppearanceManager.shared)
}
