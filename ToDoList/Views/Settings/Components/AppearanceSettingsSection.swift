import SwiftUI

/// HTML tasarımındaki modern Apple estetiğini (Segmented control, stil kartları ve yatay palet)
/// SwiftUI mimarisine taşıyan gelişmiş ayarlar bölümü.
/// Senior Notu: Dinamik mod ve motto özellikleri kaldırılarak %100 manuel kontrol sağlanmıştır.
/// Eski koddan kalan gereksiz property çağrıları (isAutoMoodEnabled, Palette vb.) temizlendi.
struct AppearanceSettingsSection: View {
    // MARK: - Properties
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        Group {
            // 🧹 Eski "ZEKA VE MOTİVASYON" (Dinamik Mood / Motto) bölümü tamamen silindi!
            // Artık sistem sadece senin manuel olarak belirlediğin renklere itaat edecek.
            
            // 1. 🎨 GÖRÜNÜM HEDEFİ (Segmented Control)
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
            
            // 2. 🌈 RENK PALETİ (Yatay Şerit)
            Section {
                VStack(alignment: .leading, spacing: 15) {
                    Text("RENK PALETİ").font(.caption.bold()).foregroundColor(.secondary)
                    
                    // Dinamik mod kaldırıldığı için artık uyarı kutusuna gerek yok,
                    // direkt renk paletini gösteriyoruz.
                    colorPickerList
                }
                .padding(.vertical, 8)
            }
            
            // 3. ✨ STİL SEÇİMİ (Kart Tasarımı)
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
            
            // 4. 🔍 DERİNLİK (Sadece Ana Ekran için Slider)
            if appearance.editTarget == .mainScreen && appearance.mainScreenStyle != .standard {
                Section("DERİNLİK") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Pencere Şeffaflığı")
                            Spacer()
                            Text("%\(Int((1.0 - appearance.mainScreenOpacity) * 100))").foregroundColor(.secondary).monospacedDigit()
                        }
                        Slider(value: $appearance.mainScreenOpacity, in: 0.5...1.0, step: 0.05)
                            .tint(appearance.accentColor) // ✨ SENIOR FIX: Sildiğimiz Palette yerine aktif temayı kullanıyoruz
                    }
                    .padding(.vertical, 5)
                }
            }
            
            // 5. 📏 DÜZEN YOĞUNLUĞU
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
                            // ✨ SENIOR FIX: refreshColors() çağrısı söküldü çünkü
                            // AppearanceManager'daki @AppStorage didSet'i artık renkleri otomatik oluşturuyor!
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
                        .fill(isSelected ? appearance.accentColor : Color.gray.opacity(0.1)) // ✨ SENIOR FIX
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
                        .foregroundColor(appearance.accentColor) // ✨ SENIOR FIX
                        .font(.title3)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? appearance.accentColor : Color.clear, lineWidth: 2) // ✨ SENIOR FIX
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
