import SwiftUI

/// Ayarlar bölümündeki Görünüm kontrol paneli.
/// Senior Notu: Sistem arka planına (Apple HIG) geçildiği için
/// Derinlik, Cam Efekti ve Sidebar ayrımı gibi gereksiz ayarlar tamamen temizlendi.
/// Sadece Tema Rengi ve Liste Yoğunluğu bırakıldı.
struct AppearanceSettingsSection: View {
    // MARK: - Properties
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        Group {
            // 1.  TEMA RENGİ PALETİ (Yatay Şerit)
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("TEMA RENGİ")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    
                    colorPickerList
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // 2. 📏 DÜZEN YOĞUNLUĞU
            Section("DÜZEN") {
                Picker("Liste Yoğunluğu", selection: $appearance.layoutDensity) {
                    ForEach(LayoutDensity.allCases) { density in
                        Text(density.rawValue).tag(density)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

// MARK: - Alt Bileşenler (Private Subviews)
private extension AppearanceSettingsSection {
    
    /// Yatayda kayan renk seçici listesi
    var colorPickerList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Theme.allCases) { theme in
                    Button {
                        HapticManager.shared.triggerSelection()
                        // Tıklama anında yaylanarak (spring) rengi tüm uygulamaya uygula
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            appearance.mainTheme = theme
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(theme.mainColor)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    // Seçili olanın etrafında temanın moduna (Aydınlık/Karanlık) duyarlı ince bir sınır belirir
                                    Circle().stroke(Color.primary.opacity(0.8), lineWidth: appearance.mainTheme == theme ? 3 : 0)
                                )
                                .shadow(color: theme.mainColor.opacity(0.3), radius: 5, x: 0, y: 3)
                            
                            // Seçili İkonu
                            if appearance.mainTheme == theme {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .black))
                                    // İç ikon canlı renklerin üstünde her zaman beyaz kalmalıdır
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    // Seçilen rengin kutusu diğerlerinden biraz daha büyük durur (Pop-out)
                    .scaleEffect(appearance.mainTheme == theme ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: appearance.mainTheme)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
        }
    }
}
