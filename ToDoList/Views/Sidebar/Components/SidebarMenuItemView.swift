import SwiftUI

/// Sidebar içindeki her bir tıklanabilir menü satırı.
/// Senior Notu: İkonların sabit genişlikte tutulması, metinlerin jilet gibi hizalanmasını sağlar.
struct SidebarMenuItemView: View {
    // MARK: - Properties
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
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
                
                // 3. SEÇİM GÖSTERGESİ (Aktif satırın sağında beyaz bir çubuk)
                if isSelected {
                    Capsule()
                        .frame(width: 4, height: 18)
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                // Seçili olan satırın arkasına çok hafif bir parlaklık ekliyoruz
                isSelected ? Color.white.opacity(0.1) : Color.clear
            )
            .contentShape(Rectangle()) // Boş alanlara da tıklanabilmesi için
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        VStack(spacing: 5) {
            SidebarMenuItemView(title: "Tüm Görevler", icon: "checklist", isSelected: true, action: {})
            SidebarMenuItemView(title: "Gizli Kasa", icon: "lock.shield.fill", isSelected: false, action: {})
        }
    }
}
