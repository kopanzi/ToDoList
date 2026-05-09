import SwiftUI

/// Sidebar içindeki her bir tıklanabilir menü satırı.
/// Senior Notu: İkonların sabit genişlikte tutulması, metinlerin jilet gibi hizalanmasını sağlar.
/// Statik beyaz renkler kaldırılarak Tema Motoru (AppearanceManager) ve Adaptive UI uyumu eklendi.
struct SidebarMenuItemView: View {
    // MARK: - Properties
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    // ✨ SENIOR FIX: Uygulamanın aktif temasını dinler
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        Button(action: {
            // Etkileşimi güçlendirmek için hafif dokunsal geri bildirim
            HapticManager.shared.triggerLightImpact()
            action()
        }) {
            HStack(spacing: 15) {
                // 1. İKON
                // frame(width) sabitlemesi, farklı ikon boyutlarında hizalamayı bozmaz.
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 26, alignment: .center)
                
                // 2. BAŞLIK
                Text(title)
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .medium)
                
                Spacer()
                
                // 3. SEÇİM GÖSTERGESİ (Aktif satırın sağında vurgu çubuğu)
                if isSelected {
                    Capsule()
                        .frame(width: 4, height: 18)
                        // ✨ SENIOR FIX: Sabit beyaz yerine Tema Rengi
                        .foregroundColor(appearance.accentColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            // ✨ SENIOR FIX: Seçiliyken Tema Rengi, değilken Adaptive (.primary)
            .foregroundColor(isSelected ? appearance.accentColor : .primary.opacity(0.7))
            .padding(.horizontal, 20)
            .padding(.vertical, 10) // Tıklama alanı biraz daha ferahlatıldı
            .background(
                // ✨ SENIOR FIX: Seçili olan satırın arkasına Tema Rengiyle çok hafif bir parlaklık ekliyoruz
                isSelected ? appearance.accentColor.opacity(0.12) : Color.clear
            )
            .contentShape(Rectangle()) // Boş alanlara da tıklanabilmesi için
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // ✨ SENIOR FIX: Sistem arkaplanında test edebilmek için
        Color(uiColor: .systemBackground).ignoresSafeArea()
        
        VStack(spacing: 5) {
            SidebarMenuItemView(title: "Tüm Görevler", icon: "checklist", isSelected: true, action: {})
            SidebarMenuItemView(title: "Gizli Kasa", icon: "lock.shield.fill", isSelected: false, action: {})
        }
    }
    .environmentObject(AppearanceManager.shared) // Preview çökmesini engeller
}
