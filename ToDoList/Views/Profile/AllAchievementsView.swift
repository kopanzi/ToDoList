import SwiftUI

/// Tüm başarı rozetlerinin listelendiği detaylı grid ekranı.
/// Senior Notu: Arka plan Tema Motoruna (appearance.accentColor) bağlanmıştır.
struct AllAchievementsView: View {
    let achievements: [Achievement]
    @Environment(\.dismiss) var dismiss
    
    // ✨ SENIOR FIX: Tema Motoru eklendi
    @EnvironmentObject var appearance: AppearanceManager
    
    // Tıklanan rozetin detayını göstermek için
    @State private var selectedAchievement: Achievement? = nil
    
    // Grid yapısı (Yan yana 3 veya 4 kart sığacak şekilde otomatik ayarlanır)
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 15)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // ✨ SENIOR FIX: Hem aydınlık/karanlık mod uyumlu zemin hem de Tema Rengi (Tint)
                // Böylece "saf beyaz" hissiyatı kırılır ve tematik bir ekran oluşur.
                ZStack {
                    Color(uiColor: .systemGroupedBackground)
                    appearance.accentColor.opacity(0.06) // Profille bütünleşen tema tonu
                }
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(achievements) { achievement in
                            Button(action: {
                                HapticManager.shared.triggerSelection()
                                selectedAchievement = achievement
                            }) {
                                // AchievementGallery içindeki mevcut Adaptive kart tasarımını tekrar kullanıyoruz
                                AchievementCard(achievement: achievement)
                            }
                            .buttonStyle(BouncyScaleButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Tüm Başarılar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(appearance.accentColor) // ✨ Tema Rengi
                }
            }
            // Bu ekrandan da rozet detaylarına bakabilmek için sheet ekliyoruz
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailView(achievement: achievement)
                    .presentationDetents([.height(380)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AllAchievementsView(achievements: Achievement.defaultGallery)
        // ✨ SENIOR FIX: Preview'da çökmemesi için
        .environmentObject(AppearanceManager.shared)
}
