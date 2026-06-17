import SwiftUI
import PhotosUI

/// Kullanıcının üretkenlik verilerini ve başarılarını gösteren ana profil ekranı.
/// Senior Notu: Profil ve isim değiştirme (Edit) işlemleri SettingsView'a taşınarak
/// UI çakışmaları tamamen önlenmiş ve bu ekran bir "Vitrin" haline getirilmiştir.
struct ProfileView: View {
    // MARK: - Properties
    @StateObject private var userVM: UserViewModel
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // MARK: - Tıklama ve Yönlendirme (Sheets)
    @State private var selectedAchievement: Achievement? = nil
    @State private var showingSettings = false
    @State private var showingAllAchievements = false
    
    // Yalnızca okuma (Okunabilir) amaçlı isim
    @AppStorage("userName") private var userName: String = "Sİo Kullanıcısı"
    
    // MARK: - Initialization
    init(taskVM: TaskViewModel) {
        self.taskVM = taskVM
        _userVM = StateObject(wrappedValue: UserViewModel(taskViewModel: taskVM))
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // 1. ÜST HEADER (Avatar, İsim, Ayarlar)
                profileHeader
                
                // 2. RÜTBE VE XP KARTI (Oyunlaştırma Merkezi)
                rankCardSection
                
                // 3. YAPAY ZEKA ANALİZİ (Yerel Motor)
                AnalysisInsightCard(
                    userName: userName,
                    stats: userVM.stats,
                    insight: userVM.aiInsightNote,
                    isLoading: userVM.isLoadingInsight
                )
                
                // 4. BAŞARI GALERİSİ (Yatay Liste)
                AchievementGallery(
                    achievements: userVM.achievements,
                    onSelect: { achievement in
                        selectedAchievement = achievement
                    },
                    onSeeAllTap: {
                        showingAllAchievements = true
                    }
                )
                
                Spacer(minLength: 120)
            }
            .padding(.top, 10)
        }
        .scrollContentBackground(.hidden)
        .refreshable { userVM.refreshAll() }
        
        // MARK: - Modals & Overlays (Açılır Pencereler)
        
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement)
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
        }
        
        .sheet(isPresented: $showingAllAchievements) {
            AllAchievementsView(achievements: userVM.achievements)
        }
        
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                viewModel: SettingsViewModel(),
                taskVM: taskVM,
                onMenuTap: { showingSettings = false }
            )
        }
    }
}

// MARK: - Sub-Views & Helper Methods
private extension ProfileView {
    
    // MARK: Header (Üst Bilgi Alanı)
    var profileHeader: some View {
        HStack(spacing: 15) {
            
            // ✨ SENIOR FIX: Buradaki Button sarmalayıcı kaldırıldı!
            // Artık AvatarView'in kendi içindeki "Tam Ekran Önizleme" tıklaması sorunsuz çalışacak.
            AvatarView(size: 42)
            
            VStack(alignment: .leading, spacing: 2) {
                // İsmin etrafındaki Button da kaldırıldı.
                Text(userName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("SELF-OPTIMIZATION MODE")
                    .font(.system(size: 8, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(appearance.accentColor.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.triggerLightImpact()
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primary.opacity(0.7))
                    .padding(10)
                    .background(Color.primary.opacity(0.05))
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: Rütbe ve XP Kartı (Oyunlaştırma Merkezi)
    var rankCardSection: some View {
        let currentRank = XPService.shared.getCurrentRank(for: taskVM.userXP)
        
        return HStack(spacing: 16) {
            // Halka ve İkon (İç İçe)
            ZStack {
                CircularProgressView(
                    progress: XPService.shared.getProgressPercentage(xp: taskVM.userXP),
                    color: currentRank.color, // Direkt hesaptan alınan renk
                    lineWidth: 6,
                    showText: false
                )
                .frame(width: 55, height: 55)
                
                Image(systemName: currentRank.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(currentRank.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("MEVCUT RÜTBE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(currentRank.color.opacity(0.8)) // Rütbenin kendi rengi
                
                Text(currentRank.name)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.primary) // ✨ Adaptive
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text("Sıradaki: \(getNextRankName(currentRank: currentRank))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary) // ✨ Adaptive
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("XP İLERLEMESİ")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary) // ✨ Adaptive
                
                if let nextThreshold = currentRank.nextThreshold {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(taskVM.userXP)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.primary) // ✨ Adaptive
                        Text("/ \(nextThreshold)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary) // ✨ Adaptive
                    }
                } else {
                    // Maksimum seviyeye ulaştıysa sadece Max XP görünür
                    Text("MAX")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.primary) // ✨ Adaptive
                }
            }
        }
        .padding(18)
        .background(Color.primary.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    
    /// Bir sonraki rütbenin adını hesaplar
    func getNextRankName(currentRank: Rank) -> String {
        let allRanks = Rank.allCases
        if let currentIndex = allRanks.firstIndex(of: currentRank), currentIndex + 1 < allRanks.count {
            return allRanks[currentIndex + 1].name
        }
        return "Zirvedesin!"
    }
}
