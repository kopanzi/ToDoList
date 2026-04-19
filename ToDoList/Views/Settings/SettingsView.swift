import SwiftUI

/// Ayarlar ekranını yöneten ana orkestratör bileşen.
/// Senior Notu: Bu View; profil, gelişmiş görünüm ve uygulama bilgilerini
/// merkezi 'AppearanceManager' ve 'SettingsViewModel' üzerinden koordine eder.
struct SettingsView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var taskVM: TaskViewModel
    
    // Global görünüm motoru
    @EnvironmentObject var appearance: AppearanceManager
    
    // Sidebar'ı tetiklemek için kullanılan aksiyon
    var onMenuTap: () -> Void
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // 1. PROFİL VE RÜTBE BÖLÜMÜ (Hero Section)
                Section {
                    SettingsProfileView(
                        rankName: taskVM.currentRank.name,
                        rankIcon: taskVM.currentRank.icon,
                        rankColor: taskVM.currentRank.color,
                        userXP: taskVM.userXP,
                        progress: XPService.shared.getProgressPercentage(xp: taskVM.userXP)
                    )
                } header: {
                    Text("Profil")
                }
                
                // 2. GELİŞMİŞ GÖRÜNÜM AYARLARI (Görünüm Devrimi ✅)
                // Bu bölüm AI Motto, Mood ve Mesh Gradient kontrollerini içerir.
                AppearanceSettingsSection()
                
                // 3. GENEL UYGULAMA AYARLARI
                Section("Uygulama") {
                    // Dil Seçimi
                    Picker(selection: $viewModel.selectedLanguage) {
                        Text("Türkçe").tag("tr")
                        Text("English").tag("en")
                    } label: {
                        SettingsOptionRow(
                            icon: "globe",
                            title: "Uygulama Dili",
                            color: .blue,
                            detail: viewModel.selectedLanguage == "tr" ? "Türkçe" : "English"
                        )
                    }
                }
                
                // 4. HAKKINDA BÖLÜMÜ
                Section("Hakkında") {
                    SettingsOptionRow(
                        icon: "info.circle.fill",
                        title: "Versiyon",
                        color: .gray,
                        detail: "2.5.0 (UI Revolution)"
                    )
                    
                    Link(destination: URL(string: "https://www.apple.com")!) {
                        SettingsOptionRow(
                            icon: "person.2.fill",
                            title: "Geliştirici",
                            color: .orange,
                            detail: "Kopanzi"
                        )
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 🍔 SOL: Menü Butonu (Sidebar Tetikleyici)
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        onMenuTap()
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView(
        viewModel: SettingsViewModel(),
        taskVM: TaskViewModel(),
        onMenuTap: {}
    )
    .environmentObject(AppearanceManager.shared)
}
