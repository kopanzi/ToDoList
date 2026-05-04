import SwiftUI
import PhotosUI

/// Kullanıcının üretkenlik verilerini ve başarılarını gösteren ana profil ekranı.
/// Senior Notu: Karmaşık istatistikler StatisticsView'a devredilmiş,
/// bu ekran kullanıcının 'Oyuncu Kimliği' (Gamification) olarak sadeleştirilmiştir.
struct ProfileView: View {
    // MARK: - Properties
    @StateObject private var userVM: UserViewModel
    
    // ✨ SENIOR FIX 1: @EnvironmentObject yerine @ObservedObject kullanıyoruz.
    // Çünkü bu View'ı oluştururken taskVM'yi dışarıdan parametre olarak alıyoruz.
    @ObservedObject var taskVM: TaskViewModel
    
    @EnvironmentObject var appearance: AppearanceManager
    
    // MARK: - Tıklama ve Yönlendirme (Sheets)
    @State private var selectedAchievement: Achievement? = nil
    @State private var showingSettings = false
    @State private var showingAllAchievements = false
    
    // MARK: - İsim Değiştirme (AppStorage)
    @AppStorage("userName") private var userName: String = "Yaver Kullanıcısı"
    @State private var showingNameEditAlert = false
    @State private var tempUserName = ""
    
    // MARK: - Avatar / Profil Fotoğrafı İşlemleri
    @AppStorage("userAvatarID") private var userAvatarID: String = ""
    @AppStorage("userAvatarEmoji") private var userAvatarEmoji: String = ""
    
    @State private var showingAvatarDialog = false
    @State private var showCameraForAvatar = false
    @State private var showGalleryForAvatar = false // Çakışmayı önleyen güvenli galeri tetikleyicisi
    @State private var showingEmojiAlert = false
    @State private var tempEmoji = ""
    @State private var selectedAvatarItem: PhotosPickerItem? = nil
    
    // MARK: - Initialization
    init(taskVM: TaskViewModel) {
        // ✨ SENIOR FIX 2: taskVM'i doğru bir şekilde atıyoruz.
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
        
        .confirmationDialog("Profil Fotoğrafı", isPresented: $showingAvatarDialog, titleVisibility: .visible) {
            Button("Kameradan Çek") { triggerCameraSafe() }
            Button("Galeriden Seç") { showGalleryForAvatar = true }
            Button("Emoji / İkon Seç") {
                tempEmoji = userAvatarEmoji
                showingEmojiAlert = true
            }
            if !userAvatarID.isEmpty || !userAvatarEmoji.isEmpty {
                Button("Avatarı Sıfırla", role: .destructive) { removeAvatar() }
            }
            Button("İptal", role: .cancel) { }
        }
        
        .fullScreenCover(isPresented: $showCameraForAvatar) {
            CameraPicker { image in saveNewAvatar(image) }.ignoresSafeArea()
        }
        
        .photosPicker(isPresented: $showGalleryForAvatar, selection: $selectedAvatarItem, matching: .images)
        .onChange(of: selectedAvatarItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { saveNewAvatar(image) }
                }
            }
        }
        
        .alert("Emoji Seç", isPresented: $showingEmojiAlert) {
            TextField("Örn: 🚀, 🤖, 🦁", text: $tempEmoji)
            Button("İptal", role: .cancel) { }
            Button("Kaydet") { saveEmoji() }
        } message: { Text("Klavyeden bir emoji seç. Fotoğrafın yerine bu görünecektir.") }
        
        .alert("İsmini Değiştir", isPresented: $showingNameEditAlert) {
            TextField("Yeni İsim/Nickname", text: $tempUserName)
            Button("İptal", role: .cancel) { }
            Button("Kaydet") {
                let trimmed = tempUserName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    userName = trimmed
                    HapticManager.shared.triggerSuccess()
                }
            }
        } message: { Text("Profilinde ve asistanında görünmesini istediğin ismi gir.") }
    }
}

// MARK: - Sub-Views & Helper Methods
private extension ProfileView {
    
    // MARK: Header (Üst Bilgi Alanı)
    var profileHeader: some View {
        HStack(spacing: 15) {
            
            Button(action: {
                HapticManager.shared.triggerLightImpact()
                showingAvatarDialog = true
            }) {
                AvatarView(size: 42)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Button(action: {
                    tempUserName = userName
                    showingNameEditAlert = true
                    HapticManager.shared.triggerLightImpact()
                }) {
                    HStack(spacing: 4) {
                        Text(userName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
                
                Text("SELF-OPTIMIZATION MODE")
                    .font(.system(size: 8, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "0df2cc").opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.triggerLightImpact()
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: Rütbe ve XP Kartı (Oyunlaştırma Merkezi)
    var rankCardSection: some View {
        // ✨ SENIOR FIX 3: Rütbe objesini güvenli bir şekilde direkt XPService'den çekiyoruz.
        // Böylece TaskViewModel'deki yapısal değişiklikler bu sayfayı asla bozmaz.
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
                    .foregroundColor(currentRank.color.opacity(0.8))
                
                Text(currentRank.name)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text("Sıradaki: \(getNextRankName(currentRank: currentRank))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("XP İLERLEMESİ")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                
                if let nextThreshold = currentRank.nextThreshold {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(taskVM.userXP)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("/ \(nextThreshold)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    // Maksimum seviyeye ulaştıysa sadece Max XP görünür
                    Text("MAX")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.03).background(.ultraThinMaterial))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.05), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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
    
    // MARK: - Avatar Actions
    
    func triggerCameraSafe() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCameraForAvatar = true
        }
    }
    
    func saveNewAvatar(_ image: UIImage) {
        if !userAvatarID.isEmpty {
            MediaManager.shared.deleteFile(id: userAvatarID, fileExtension: "jpg")
        }
        if let newID = MediaManager.shared.saveImage(image) {
            userAvatarID = newID
            userAvatarEmoji = ""
            HapticManager.shared.triggerSuccess()
        }
    }
    
    func saveEmoji() {
        if let firstChar = tempEmoji.first {
            userAvatarEmoji = String(firstChar)
            if !userAvatarID.isEmpty {
                MediaManager.shared.deleteFile(id: userAvatarID, fileExtension: "jpg")
                userAvatarID = ""
            }
            HapticManager.shared.triggerSuccess()
        }
    }
    
    func removeAvatar() {
        if !userAvatarID.isEmpty {
            MediaManager.shared.deleteFile(id: userAvatarID, fileExtension: "jpg")
            userAvatarID = ""
        }
        userAvatarEmoji = ""
        HapticManager.shared.triggerMediumImpact()
    }
}
