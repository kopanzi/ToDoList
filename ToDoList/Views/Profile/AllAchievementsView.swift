import SwiftUI

/// Tüm başarı rozetlerinin listelendiği detaylı grid ekranı.
struct AllAchievementsView: View {
    let achievements: [Achievement]
    @Environment(\.dismiss) var dismiss
    
    // Tıklanan rozetin detayını göstermek için
    @State private var selectedAchievement: Achievement? = nil
    
    // Grid yapısı (Yan yana 3 veya 4 kart sığacak şekilde otomatik ayarlanır)
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 15)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Koyu arka plan
                Color(hex: "020807").ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(achievements) { achievement in
                            Button(action: {
                                HapticManager.shared.triggerSelection()
                                selectedAchievement = achievement
                            }) {
                                // AchievementGallery içindeki mevcut kart tasarımını tekrar kullanıyoruz
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
            // Navigation Bar'ın koyu temaya uyması için
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "0a1412"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "0df2cc"))
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

#Preview {
    AllAchievementsView(achievements: Achievement.defaultGallery)
}
