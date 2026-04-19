import SwiftUI

/// HTML tasarımındaki modern Apple estetiğini (Segmented control, stil kartları ve yatay palet)
/// SwiftUI mimarisine taşıyan gelişmiş ayarlar bölümü.
/// Senior Notu: Bu bileşen AppearanceManager üzerinden tüm görsel atmosferi yönetir.
struct AppearanceSettingsSection: View {
    // MARK: - Properties
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        Group {
            // 1. 🧠 ZEKA VE MOTİVASYON (En Üstte)
            Section("ZEKA VE MOTİVASYON") {
                Toggle(isOn: $appearance.isAutoMoodEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dinamik Duygu Durumu")
                            Text("Yoğunluğa göre renkler otomatik değişir.").font(.caption2).foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "brain.head.profile").foregroundColor(.purple)
                    }
                }
                .tint(.purple)
                .onChange(of: appearance.isAutoMoodEnabled) { _, _ in
                    HapticManager.shared.triggerSelection()
                    appearance.refreshColors()
                }
                
                // ✨ SENIOR FIX: Metinler yerel motto mantığına uygun hale getirildi.
                Toggle(isOn: $appearance.isAIMottoEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Günlük Motto")
                            Text("Her gün yenilenen motive edici sözler.").font(.caption2).foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "quote.opening").foregroundColor(.orange)
                    }
                }
                .tint(.orange)
            }
            
            // 2. 🎨 GÖRÜNÜM HEDEFİ (Segmented Control) ✅
            // Kullanıcı hangi alanı düzenlediğini buradan seçer.
            Section {
                Picker("Düzenlenecek Alan", selection: $appearance.editTarget) {
                    Text("Ana Ekran").tag(AppearanceManager.EditTarget.mainScreen)
                    Text("Sidebar").tag(AppearanceManager.EditTarget.sidebar)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .padding(.vertical, 8)
            }
            
            // 3. 🌈 RENK PALETİ (Yatay Şerit) ✅
            Section {
                VStack(alignment: .leading, spacing: 15) {
                    Text("RENK PALETİ").font(.caption.bold()).foregroundColor(.secondary)
                    
                    if appearance.isAutoMoodEnabled {
                        // Dinamik mod açıkken kullanıcıyı bilgilendiren şık kutu
                        HStack(spacing: 12) {
                            Image(systemName: "wand.and.stars")
                                .font(.title3)
                            Text("Dinamik mod aktifken renkler asistanınız tarafından otomatik belirlenir.")
                                .font(.caption)
                        }
                        .foregroundColor(AppearanceManager.Palette.primary)
                        .padding()
                        .background(AppearanceManager.Palette.primary.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        colorPickerList
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 4. ✨ STİL SEÇİMİ (Kart Tasarımı) ✅
            Section("STİL") {
                VStack(spacing: 12) {
                    styleCard(
                        title: "Glassmorphism",
                        subtitle: "Yarı saydam ve bulanık tasarım",
                        icon: "circle.hexagongrid.fill",
                        style: .glass
                    )
                    
                    styleCard(
                        title: "Solid Dark",
                        subtitle: "Yüksek kontrast ve derinlik",
                        icon: "moon.stars.fill",
                        style: .solid
                    )
                    
                    styleCard(
                        title: "Gradient",
                        subtitle: "Yumuşak ve akışkan geçişler",
                        icon: "aqi.medium",
                        style: .gradient
                    )
                }
                .listRowBackground(Color.clear)
            }
            
            // 5. 🔍 DERİNLİK (Sadece Ana Ekran için Slider)
            if appearance.editTarget == .mainScreen && appearance.mainScreenStyle != .standard {
                Section("DERİNLİK") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Pencere Şeffaflığı")
                            Spacer()
                            Text("%\(Int((1.0 - appearance.mainScreenOpacity) * 100))").foregroundColor(.secondary).monospacedDigit()
                        }
                        Slider(value: $appearance.mainScreenOpacity, in: 0.5...1.0, step: 0.05)
                            .tint(AppearanceManager.Palette.primary)
                    }
                    .padding(.vertical, 5)
                }
            }
            
            // 6. 📏 DÜZEN YOĞUNLUĞU
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
        let currentTargetTheme = appearance.editTarget == .mainScreen ? appearance.mainScreenTheme : appearance.sidebarTheme
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Theme.allCases) { theme in
                    Button {
                        HapticManager.shared.triggerSelection()
                        withAnimation {
                            if appearance.editTarget == .mainScreen {
                                appearance.mainScreenTheme = theme
                            } else {
                                appearance.sidebarTheme = theme
                            }
                            appearance.refreshColors()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(theme.mainColor)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: currentTargetTheme == theme ? 3 : 0)
                                )
                                .shadow(color: theme.mainColor.opacity(0.3), radius: 5, x: 0, y: 3)
                            
                            if currentTargetTheme == theme {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 2)
        }
    }
    
    /// Tasarımdaki şık stil kartlarını oluşturan fonksiyon
    func styleCard(title: String, subtitle: String, icon: String, style: AppearanceManager.BackgroundStyle) -> some View {
        let currentTargetStyle = appearance.editTarget == .mainScreen ? appearance.mainScreenStyle : appearance.sidebarStyle
        let isSelected = currentTargetStyle == style
        
        return Button {
            HapticManager.shared.triggerLightImpact()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if appearance.editTarget == .mainScreen {
                    appearance.mainScreenStyle = style
                } else {
                    appearance.sidebarStyle = style
                }
            }
        } label: {
            HStack(spacing: 16) {
                // İkon Kutusu
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AppearanceManager.Palette.primary : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                // Metinler
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Seçim İşareti
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppearanceManager.Palette.primary)
                        .font(.title3)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppearanceManager.Palette.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        Form {
            AppearanceSettingsSection()
        }
        .navigationTitle("Tema Ayarları")
    }
    .environmentObject(AppearanceManager.shared)
}
