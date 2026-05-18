import SwiftUI
import PhotosUI
import FirebaseAuth

/// Uygulamanın kişiselleştirme ve ayarlar merkezi.
/// Senior Notu: Düzen (Kompakt/Rahat) ayarı kaldırılarak sadeleştirildi.
/// Apple HIG standartlarına uygun olarak Çıkış Yap butonu en alta taşındı ve
/// Bulut statüsü Premium bir görünüme kavuşturuldu.
struct SettingsView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    @StateObject private var authManager = AuthManager.shared
    
    // Sidebar'ı açmak için dışarıdan gelen tetikleyici
    var onMenuTap: () -> Void
    
    // MARK: - Profil Düzenleme State'leri
    @AppStorage("userName") private var userName: String = "Yaver Kullanıcısı"
    @AppStorage("userAvatarID") private var userAvatarID: String = ""
    @AppStorage("userAvatarEmoji") private var userAvatarEmoji: String = ""
    
    @State private var showingNameEditAlert = false
    @State private var tempUserName = ""
    
    @State private var showingAvatarDialog = false
    @State private var showCameraForAvatar = false
    @State private var showGalleryForAvatar = false
    @State private var showingEmojiAlert = false
    @State private var tempEmoji = ""
    @State private var selectedAvatarItem: PhotosPickerItem? = nil
    
    @State private var showingLoginSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                // ✨ 0. BULUT YEDEKLEME VE HESAP (Premium iOS Standardı)
                Section {
                    if authManager.userSession != nil {
                        // 🟢 GİRİŞ YAPILMIŞ DURUM (Apple ID Tarzı)
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(appearance.accentColor.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "checkmark.icloud.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(appearance.accentColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Bulut Senkronizasyonu Aktif")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                    } else {
                        // 🔴 GİRİŞ YAPILMAMIŞ DURUM (GUEST)
                        Button(action: {
                            HapticManager.shared.triggerLightImpact()
                            showingLoginSheet = true
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: "person.crop.circle.badge.icloud")
                                    .font(.system(size: 30))
                                    .foregroundColor(appearance.accentColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Verilerini Buluta Yedekle")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Apple veya Google ile giriş yap")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(Color.primary.opacity(0.03))
                
                // ✨ 1. PROFİL AYARLARI
                Section {
                    // Profil Fotoğrafını Değiştir
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        showingAvatarDialog = true
                    }) {
                        HStack(spacing: 16) {
                            AvatarView(size: 36, showAura: false)
                                .allowsHitTesting(false)
                            
                            Text("Profil Fotoğrafını Değiştir")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    
                    // İsmi Değiştir
                    Button(action: {
                        tempUserName = userName
                        showingNameEditAlert = true
                        HapticManager.shared.triggerLightImpact()
                    }) {
                        SettingsOptionRow(
                            icon: "pencil.and.outline",
                            title: "İsmi Değiştir",
                            color: appearance.accentColor,
                            detail: userName
                        )
                    }
                    .buttonStyle(.plain)
                    
                } header: {
                    Text("PROFİL AYARLARI").font(.caption.bold())
                }
                .listRowBackground(Color.primary.opacity(0.03))
                
                // ✨ 2. TEMA RENGİ (Eski dosyadan kurtarılıp buraya gömüldü)
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Theme.allCases) { theme in
                                Button {
                                    HapticManager.shared.triggerSelection()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        appearance.mainTheme = theme
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(theme.mainColor)
                                            .frame(width: 44, height: 44)
                                            .shadow(color: theme.mainColor.opacity(0.3), radius: 5, x: 0, y: 3)
                                        
                                        if appearance.mainTheme == theme {
                                            Circle().stroke(Color.primary.opacity(0.8), lineWidth: 2)
                                                .frame(width: 52, height: 52)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .black))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .scaleEffect(appearance.mainTheme == theme ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: appearance.mainTheme)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                    }
                    .listRowInsets(EdgeInsets()) // Kenardan kenara tam sığması için
                } header: {
                    Text("TEMA RENGİ").font(.caption.bold())
                }
                .listRowBackground(Color.primary.opacity(0.03))
                
                // ✨ 3. SİSTEM & DİL
                Section {
                    Picker("Uygulama Dili", selection: $viewModel.selectedLanguage) {
                        Text("Türkçe").tag("tr")
                        Text("English").tag("en")
                    }
                    .tint(appearance.accentColor)
                } header: {
                    Text("SİSTEM & DİL").font(.caption.bold())
                }
                .listRowBackground(Color.primary.opacity(0.03))
                
                // ✨ 4. HAKKINDA
                Section {
                    SettingsOptionRow(
                        icon: "info.circle.fill",
                        title: "Versiyon",
                        color: appearance.accentColor,
                        // ✨ SENIOR FIX: Karmaşık yapı silindi, sadece Apple HIG standartlarına uygun "1.0" tarzı ana sürüm numarası bırakıldı.
                        detail: viewModel.appVersion
                    )
                    
                    SettingsOptionRow(
                        icon: "hammer.fill",
                        title: "Geliştirici",
                        color: .orange,
                        detail: "Kopanzi"
                    )
                } header: {
                    Text("HAKKINDA").font(.caption.bold())
                }
                .listRowBackground(Color.primary.opacity(0.03))
                
                // ✨ 5. ÇIKIŞ YAP (Sadece giriş yapıldıysa görünür)
                if authManager.userSession != nil {
                    Section {
                        Button(action: {
                            HapticManager.shared.triggerMediumImpact()
                            do {
                                try authManager.signOut()
                            } catch {
                                print("Çıkış hatası: \(error.localizedDescription)")
                            }
                        }) {
                            Text("Hesaptan Çıkış Yap")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .listRowBackground(Color.primary.opacity(0.03))
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .toolbar {
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
            
            // MARK: - Modals
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
            } message: {
                Text("Klavyeden bir emoji seç. Fotoğrafın yerine bu görünecektir.")
            }
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
            } message: {
                Text("Profilinde ve asistanında görünmesini istediğin ismi gir.")
            }
            .sheet(isPresented: $showingLoginSheet) {
                LoginView()
            }
        }
    }
}

// MARK: - Logic (İş Mantığı)
private extension SettingsView {
    
    func triggerCameraSafe() {
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
