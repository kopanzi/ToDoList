import SwiftUI

/// Takvim üzerindeki tek bir günü temsil eden akıllı ve etkileşimli hücre.
/// Senior Notu: Statik beyaz (.white) renkler kaldırılarak Aydınlık/Karanlık mod (Adaptive UI)
/// uyumu tam sağlanmıştır. Geçmiş günleri soluklaştırma (Dimming) mantığı korunmuştur.
struct DayCellView: View {
    // MARK: - Properties
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let heatmapLevel: CalendarViewModel.HeatmapLevel
    let hasHiddenTasks: Bool
    let action: () -> Void
    
    // Basılı tutma eylemi için kanal
    var onLongPress: (() -> Void)? = nil
    
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
        // SwiftUI'ın standart buton tıklamasını engellemeden basılı tutmayı algılar
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                onLongPress?()
            }
        )
    }
}

// MARK: - Private Helpers & Styles
private extension DayCellView {
    
    var dayNumber: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
    
    // ✨ SENIOR FIX: Aydınlık ve Karanlık moda tam duyarlı renk yöneticisi
    var textColor: Color {
        if isSelected {
            // Cutout Efekti: Temanın kendi arka plan rengini kullanarak
            // seçili yuvarlağın içinde yazının delik/kesik gibi durmasını sağlar.
            return Color(uiColor: .systemBackground)
        }
        if isToday {
            return appearance.accentColor
        }
        
        let calendar = Calendar.current
        let isPast = calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
        
        // ✨ .white yerine .primary kullanıyoruz!
        if isPast && heatmapLevel == .none {
            return .primary.opacity(0.25)
        }
        
        if calendar.isDateInWeekend(date) && heatmapLevel == .none {
            return .primary.opacity(0.4)
        }
        
        return .primary.opacity(0.9)
    }
    
    var dotCount: Int {
        switch heatmapLevel {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

// Hücreye özel esneme (Bouncy) tıklama stili
struct DayCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
