import SwiftUI
import PhotosUI

/// Uygulamanın kişiselleştirme ve ayarlar merkezi.
/// Senior Notu: Profil düzenleme (Kamera, Galeri, Emoji, İsim değiştirme) işlemleri
/// UI çakışmalarını engellemek amacıyla ProfileView'dan buraya taşınmıştır.
struct SettingsView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // Sidebar'ı açmak için dışarıdan gelen tetikleyici
    var onMenuTap: () -> Void
    
    // MARK: - Profil Düzenleme State'leri (AppStorage & Local)
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
    
    var body: some View {
        NavigationStack {
            Form {
                // ✨ 1. PROFİL AYARLARI (ProfileView'dan Taşındı)
                Section {
                    // Profil Fotoğrafını Değiştir Butonu
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        showingAvatarDialog = true
                    }) {
                        HStack(spacing: 16) {
                            // Avatarı Settings'te gösterirken üstüne tıklama çakışmasın diye 'showAura: false'
                            // ve .allowsHitTesting(false) ile içindeki tam ekran (Instagram) efektini kilitledik!
                            AvatarView(size: 36, showAura: false)
                                .allowsHitTesting(false)
                            
                            Text("Profil Fotoğrafını Değiştir")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary) // Adaptive
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    
                    // İsmi Değiştir Butonu
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
                    Text("PROFİL AYARLARI")
                        .font(.caption.bold())
                }
                .listRowBackground(Color.primary.opacity(0.03))
                
                // 2. GÖRÜNÜM AYARLARI (Mevcut)
                AppearanceSettingsSection()
                    .listRowBackground(Color.primary.opacity(0.03))
                
                // 3. SİSTEM VE DİL AYARLARI (Mevcut)
                Section {
                    Picker("Uygulama Dili", selection: $viewModel.selectedLanguage) {
                        Text("Türkçe").tag("tr")
                        Text("English").tag("en")
                        // Diğer diller eklenebilir
                    }
                    .tint(appearance.accentColor) // Seçici rengi temaya bağlandı
                } header: {
                    Text("SİSTEM & DİL")
                        .font(.caption.bold())
                }
                .listRowBackground(Color.primary.opacity(0.03))
                
                // 4. UYGULAMA BİLGİLERİ / HAKKINDA (Mevcut)
                Section {
                    SettingsOptionRow(
                        icon: "info.circle.fill",
                        title: "Versiyon",
                        color: appearance.accentColor,
                        detail: "\(viewModel.fullVersionString) (Pro)"
                    )
                    
                    SettingsOptionRow(
                        icon: "hammer.fill",
                        title: "Geliştirici",
                        color: .orange,
                        detail: "Kopanzi"
                    )
                } header: {
                    Text("HAKKINDA")
                        .font(.caption.bold())
                }
                .listRowBackground(Color.primary.opacity(0.03))
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            // Alt katmandaki Mesh Gradient'i ortaya çıkarır
            .scrollContentBackground(.hidden)
            .toolbar {
                // 🍔 SOL: Menü Butonu
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
            // MARK: - Modals ve Düzenleme Pencereleri
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
        }
    }
}

// MARK: - Logic (İş Mantığı)
private extension SettingsView {
    
    func triggerCameraSafe() {
        // Kamerayı güvenle tetikler, menü/sheet çakışmalarını önler
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

// MARK: - Preview
#Preview {
    SettingsView(
        viewModel: SettingsViewModel(),
        taskVM: TaskViewModel(),
        onMenuTap: {}
    )
    .environmentObject(AppearanceManager.shared)
}
