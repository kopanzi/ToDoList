import SwiftUI

/// Ayarlar ekranı.
/// Senior Notu: Mood ve Motto ayarları kaldırıldı. Tamamen manuel stil ve tema seçimine odaklandı.
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    var onMenuTap: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. PROFİL BÖLÜMÜ
                Section("Profil") {
                    SettingsProfileView(
                        rankName: taskVM.currentRank.name,
                        rankIcon: taskVM.currentRank.icon,
                        rankColor: taskVM.currentRank.color,
                        userXP: taskVM.userXP,
                        progress: XPService.shared.getProgressPercentage(xp: taskVM.userXP)
                    )
                }
                
                // 2. GÖRÜNÜM AYARLARI (GÜNCELLENDİ ✅)
                Section("Görünüm") {
                    // Hedef Seçimi (Ana Ekran mı Sidebar mı?)
                    Picker("Düzenlenecek Alan", selection: $appearance.editTarget) {
                        Text("Ana Ekran").tag(AppearanceManager.EditTarget.mainScreen)
                        Text("Sidebar").tag(AppearanceManager.EditTarget.sidebar)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                    
                    if appearance.editTarget == .mainScreen {
                        // ANA EKRAN AYARLARI
                        Picker("Stil", selection: $appearance.mainScreenStyle) {
                            ForEach(AppearanceManager.BackgroundStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        
                        Picker("Tema Rengi", selection: $appearance.mainScreenTheme) {
                            ForEach(Theme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        
                        HStack {
                            Text("Opaklık")
                            Slider(value: $appearance.mainScreenOpacity, in: 0.1...1.0)
                        }
                    } else {
                        // SIDEBAR AYARLARI
                        Picker("Stil", selection: $appearance.sidebarStyle) {
                            ForEach(AppearanceManager.BackgroundStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        
                        Picker("Tema Rengi", selection: $appearance.sidebarTheme) {
                            ForEach(Theme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                    }
                }
                
                // 3. UYGULAMA BİLGİLERİ
                Section("Hakkında") {
                    SettingsOptionRow(icon: "info.circle.fill", title: "Versiyon", color: .gray, detail: "3.0.0 (Manual Pro)")
                    Text("Geliştirici: Kopanzi")
                }
            }
            .navigationTitle("Ayarlar")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onMenuTap) {
                        Image(systemName: "line.3.horizontal").fontWeight(.bold)
                    }
                }
            }
        }
    }
}
