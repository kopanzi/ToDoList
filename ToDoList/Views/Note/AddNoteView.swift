import SwiftUI
import PhotosUI

/// Yeni not ekleme formu.
/// Senior Notu: Klavye animasyon çakışmaları, Presentation hataları ve Concurrency (Sendable) uyarıları
/// çözülmüştür. Çoklu ses kaydı (Multi-Audio) ve Kaydırmalı Galeri (Swipeable Gallery) destekler.
struct AddNoteView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    // Ses Yönetimi (Merkezi Servis)
    @StateObject private var audioManager = AudioManager.shared
    
    // Form Verileri
    @State private var baslik: String = ""
    @State private var icerik: String = ""
    @State private var isPrivate: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field { case baslik, icerik }
    
    // Medya Durumları
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var newlySelectedImages: [IdentifiableImage] = []
    
    // ✨ YENİ: Çoklu Ses (Multi-Audio) Durumları
    @State private var recordedAudios: [Data] = []
    @State private var activeAudioIndex: Int? = nil // Oynatılan sesi takip eder
    
    // ✨ YENİ: Kaydırmalı Galeri Durumları
    @State private var showCamera = false
    @State private var showPreview = false
    @State private var previewImages: [UIImage] = []
    @State private var previewIndex: Int = 0
    
    // MARK: - Initialization
    init(viewModel: NoteViewModel, isPrivateDefault: Bool) {
        self.viewModel = viewModel
        _isPrivate = State(initialValue: isPrivateDefault)
    }
    
    var body: some View {
        // ✨ SENIOR FIX: Concurrency (Sendable) hatasını önlemek için
        // MainActor izoleli rengi yerel bir değere (value type) kopyalıyoruz.
        let themeAccent = appearance.accentColor
        
        ZStack {
            NavigationStack {
                Form {
                    // 1. GİRİŞ VE GÜVENLİK
                    Section("GİRİŞ") {
                        HStack {
                            TextField("Not Başlığı...", text: $baslik)
                                .focused($focusedField, equals: .baslik)
                                .font(.body.weight(.medium))
                            
                            Button(action: {
                                HapticManager.shared.triggerSelection()
                                withAnimation(.spring(response: 0.3)) { isPrivate.toggle() }
                            }) {
                                Image(systemName: isPrivate ? "lock.fill" : "lock.open")
                                    .foregroundColor(isPrivate ? .orange : .secondary)
                            }
                        }
                    }
                    
                    // 2. NOT İÇERİĞİ
                    Section("NOT DETAYI") {
                        TextField("Notunuzu buraya dökebilirsiniz...", text: $icerik, axis: .vertical)
                            .lineLimit(4...10)
                            .focused($focusedField, equals: .icerik)
                    }
                    
                    // 3. ÇOKLU SES KAYIT PANELİ
                    Section("SESLİ NOTLAR") {
                        voiceRecordingSection
                    }
                    
                    // 4. MEDYA EKLEME VE KAYDIRMALI GALERİ
                    Section("MEDYA") {
                        HStack(spacing: 15) {
                            // 🖼️ GALERİ
                            PhotosPicker(selection: $selectedItems, matching: .images) {
                                mediaActionButton(title: "Galeri", icon: "photo.on.rectangle.angled", color: themeAccent)
                            }
                            .buttonStyle(.plain)
                            
                            // 📸 KAMERA
                            Button(action: { triggerCameraSafe() }) {
                                mediaActionButton(title: "Kamera", icon: "camera.fill", color: themeAccent)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        
                        // ✨ KAYDIRMALI YATAY LİSTE
                        if !newlySelectedImages.isEmpty {
                            selectedImagesHorizontalGallery
                        }
                    }
                }
                .navigationTitle("Yeni Not")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Vazgeç") {
                            audioManager.stopPlayback()
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Kaydet") { saveNote() }
                            .bold()
                            .foregroundColor(themeAccent)
                            .disabled(baslik.trimmingCharacters(in: .whitespaces).isEmpty && newlySelectedImages.isEmpty && recordedAudios.isEmpty)
                    }
                    
                    // Klavye kapatma asistanı
                    ToolbarItem(placement: .keyboard) {
                        Button("Bitti") { focusedField = nil }
                    }
                }
            }
        }
        // ✅ KAMERA
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { capturedImage in
                newlySelectedImages.append(IdentifiableImage(image: capturedImage))
            }
            .ignoresSafeArea()
        }
        // ✨ KAYDIRMALI GALERİ ÖNİZLEME
        .fullScreenCover(isPresented: $showPreview) {
            ImagePreviewView(images: previewImages, selectedIndex: previewIndex)
        }
        // Galeri Seçimi Sonrası İşlem
        .onChange(of: selectedItems) { _, _ in loadGalleryImages() }
    }
}

// MARK: - Sub-Views Extension
private extension AddNoteView {
    
    /// Kamerayı klavye animasyonu ile çakışmayacak şekilde güvenle açar.
    func triggerCameraSafe() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticManager.shared.triggerLightImpact()
            showCamera = true
        }
    }
    
    // ✨ Çoklu Ses Bölümü
    var voiceRecordingSection: some View {
        let themeAccent = appearance.accentColor
        
        return VStack(spacing: 12) {
            
            // DİNLENEN SES KAYITLARI LİSTESİ (ÇOKLU)
            if !recordedAudios.isEmpty {
                ForEach(recordedAudios.indices, id: \.self) { index in
                    seniorAudioPlayer(data: recordedAudios[index], index: index, themeAccent: themeAccent)
                }
            }
            
            // KAYIT AŞAMASI
            if audioManager.isRecording {
                HStack {
                    Circle().fill(.red).frame(width: 8, height: 8)
                        .opacity(audioManager.isRecording ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: audioManager.isRecording)
                    Text(formatTime(audioManager.currentProgress)).font(.system(.body, design: .monospaced).bold()).foregroundColor(.red)
                    Spacer()
                    Button("Durdur") {
                        // ✨ SENIOR FIX: Warning susturuldu
                        withAnimation {
                            if let data = audioManager.stopRecording() {
                                recordedAudios.append(data)
                            }
                        }
                    }
                    .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            // BAŞLANGIÇ AŞAMASI
            else {
                HStack {
                    Label("Sesli Not Ekle", systemImage: "mic.badge.plus")
                    Spacer()
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        audioManager.startRecording()
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(themeAccent)
                            .clipShape(Circle())
                            .shadow(color: themeAccent.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // ✨ Yeni Eklenen Sesi Oynatıcı
    @ViewBuilder
    func seniorAudioPlayer(data: Data, index: Int, themeAccent: Color) -> some View {
        let isThisPlaying = activeAudioIndex == index && audioManager.isPlaying
        
        VStack(spacing: 12) {
            HStack(spacing: 15) {
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    if isThisPlaying {
                        audioManager.togglePause()
                    } else {
                        audioManager.playAudio(data: data)
                        activeAudioIndex = index
                    }
                }) {
                    Image(systemName: isThisPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(Color(uiColor: .systemBackground))
                        .padding(12)
                        .background(themeAccent)
                        .clipShape(Circle())
                        .shadow(color: themeAccent.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kayıt \(index + 1)").font(.subheadline.bold())
                    Text(isThisPlaying ? "\(formatTime(audioManager.currentProgress)) / \(formatTime(audioManager.totalDuration))" : "Hazır")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    HapticManager.shared.triggerMediumImpact()
                    if isThisPlaying { audioManager.stopPlayback() }
                    withAnimation { let _ = recordedAudios.remove(at: index) }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Slider(value: Binding(
                get: { isThisPlaying ? audioManager.currentProgress : 0 },
                set: { val in if isThisPlaying { audioManager.seek(to: val) } }
            ), in: 0...(isThisPlaying && audioManager.totalDuration > 0 ? audioManager.totalDuration : 1))
            .tint(themeAccent)
        }
        .padding()
        .background(themeAccent.opacity(0.05))
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(themeAccent.opacity(0.1), lineWidth: 1))
    }
    
    // ✨ Resim Galerisi (Sağa Sola Kaydırmalı Tetikleyici)
    var selectedImagesHorizontalGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(newlySelectedImages) { item in
                    Image(uiImage: item.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 85, height: 85)
                        .cornerRadius(12)
                        .clipped()
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        .onTapGesture {
                            HapticManager.shared.triggerLightImpact()
                            // ✨ KAYDIRMALI GALERİYİ AÇ
                            previewImages = newlySelectedImages.map { $0.image }
                            previewIndex = newlySelectedImages.firstIndex(where: { $0.id == item.id }) ?? 0
                            showPreview = true
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                HapticManager.shared.triggerMediumImpact()
                                withAnimation { newlySelectedImages.removeAll(where: { $0.id == item.id }) }
                            } label: { Label("Sil", systemImage: "trash") }
                        }
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    func mediaActionButton(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.subheadline.bold())
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }
    
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func loadGalleryImages() {
        Task {
            for item in selectedItems {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    await MainActor.run { newlySelectedImages.append(IdentifiableImage(image: image)) }
                }
            }
            selectedItems.removeAll()
        }
    }
    
    func saveNote() {
        var finalTitle = baslik.trimmingCharacters(in: .whitespaces)
        if finalTitle.isEmpty && (!newlySelectedImages.isEmpty || !recordedAudios.isEmpty) {
            finalTitle = "Hızlı Not"
        }
        
        // 🛠️ SENIOR FIX: 'audios' parametresi ile Çoklu Ses Modelini ViewModel'e aktarıyoruz
        viewModel.addNote(
            title: finalTitle,
            content: icerik,
            isPrivate: isPrivate,
            images: newlySelectedImages.map { $0.image },
            audios: recordedAudios
        )
        audioManager.stopPlayback()
        dismiss()
    }
}
