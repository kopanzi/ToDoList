import SwiftUI
import PhotosUI

/// Not içeriğini düzenleme ve gelişmiş medya yönetimi ekranı.
/// Senior Notu: Klavye animasyon çakışmaları, Concurrency (Sendable) ve
/// unused result (kullanılmayan sonuç) uyarıları tamamen çözülmüştür.
/// Hem eski kayıtlı sesler hem de sonradan eklenen çoklu ses kayıtları bir arada yönetilir.
struct NoteDetailView: View {
    // MARK: - Properties
    let note: NotModel
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var appearance: AppearanceManager
    @StateObject private var audioManager = AudioManager.shared
    
    // Düzenleme Durumları
    @State private var editedContent: String = ""
    @FocusState private var isEditorFocused: Bool
    
    // Medya (Görsel) States
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var newlySelectedImages: [IdentifiableImage] = []
    @State private var removedImageIDs = Set<String>()
    
    // Çoklu Ses (Audio) States
    @State private var newAudios: [Data] = []
    @State private var removedAudioIDs = Set<String>()
    @State private var activeAudioID: String? = nil // Eski seslerden çalan
    @State private var activeNewAudioIndex: Int? = nil // Yeni seslerden çalan
    
    // Bağımsız Sunum Değişkenleri
    @State private var showCamera = false
    @State private var showPreview = false
    @State private var previewImages: [UIImage] = []
    @State private var previewIndex: Int = 0
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // Concurrency (Sendable) hatasını önlemek için rengi yerel bir değere alıyoruz.
        let themeAccent = appearance.accentColor
        
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // 1. ÜST BAŞLIK VE TARİH
                    NoteDetailHeaderView(title: note.baslik, date: note.tarih)
                    
                    // 2. GELİŞMİŞ GALERİ (SWIPEABLE)
                    NoteDetailGalleryView(
                        selectedItems: $selectedItems,
                        newlySelectedImages: $newlySelectedImages,
                        removedImageIDs: $removedImageIDs,
                        existingImageIDs: note.gorselIDListesi,
                        onCameraTap: { triggerCameraSafe() },
                        onImageTap: { index, allImages in
                            HapticManager.shared.triggerLightImpact()
                            previewImages = allImages
                            previewIndex = index
                            showPreview = true
                        },
                        loadImage: { id in viewModel.loadImage(id: id) }
                    )
                    
                    // 3. İÇERİK EDİTÖRÜ
                    NoteDetailEditorView(content: $editedContent)
                        .focused($isEditorFocused)
                    
                    // 4. ÇOKLU SES OYNATICI VE YENİ KAYIT ALANI
                    VStack(alignment: .leading, spacing: 12) {
                        if !note.tumSesler.isEmpty || !newAudios.isEmpty {
                            Text("SESLİ NOTLAR")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            // Diskteki Eski Kayıtlar
                            let existingAudios = note.tumSesler.filter { !removedAudioIDs.contains($0) }
                            ForEach(existingAudios, id: \.self) { audioID in
                                seniorExistingAudioPlayer(audioID: audioID, themeAccent: themeAccent)
                            }
                            
                            // Yeni Eklenen Kayıtlar
                            ForEach(newAudios.indices, id: \.self) { index in
                                seniorNewAudioPlayer(data: newAudios[index], index: index, themeAccent: themeAccent)
                            }
                        }
                        
                        // Sonradan Ses Ekleme Butonu
                        voiceRecordingSection(themeAccent: themeAccent)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .onAppear { if editedContent.isEmpty { editedContent = note.icerik } }
            .onDisappear { audioManager.stopPlayback() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { saveChanges() }
                        .bold()
                        .foregroundColor(themeAccent)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Bitti") { isEditorFocused = false }
                }
            }
        }
        // KAMERA SUNUMU
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { capturedImage in
                newlySelectedImages.append(IdentifiableImage(image: capturedImage))
            }
            .ignoresSafeArea()
        }
        // KAYDIRMALI GALERİ ÖNİZLEME
        .fullScreenCover(isPresented: $showPreview) {
            ImagePreviewView(images: previewImages, selectedIndex: previewIndex)
        }
        .onChange(of: selectedItems) { _, _ in loadGalleryImages() }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Senior UI Bileşenleri
private extension NoteDetailView {
    
    func triggerCameraSafe() {
        isEditorFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticManager.shared.triggerLightImpact()
            showCamera = true
        }
    }
    
    // Ses Kayıt Bölümü
    @ViewBuilder
    func voiceRecordingSection(themeAccent: Color) -> some View {
        if audioManager.isRecording {
            HStack {
                Circle().fill(.red).frame(width: 8, height: 8)
                    .opacity(audioManager.isRecording ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: audioManager.isRecording)
                Text(formatTime(audioManager.currentProgress)).font(.system(.body, design: .monospaced).bold()).foregroundColor(.red)
                Spacer()
                Button("Durdur") {
                    // ✨ SENIOR FIX: Uyarı vermeyen kapalı kutu animasyon çağrısı
                    withAnimation {
                        if let data = audioManager.stopRecording() {
                            newAudios.append(data)
                        }
                    }
                }
                .foregroundColor(.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        } else {
            Button(action: {
                HapticManager.shared.triggerLightImpact()
                audioManager.startRecording()
            }) {
                HStack {
                    Image(systemName: "mic.badge.plus")
                    Text("Yeni Ses Kaydı Ekle")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(themeAccent.opacity(0.1))
                .foregroundColor(themeAccent)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeAccent.opacity(0.2), lineWidth: 1))
            }
        }
    }
    
    // Eski diskteki sesi oynatıcı
    @ViewBuilder
    func seniorExistingAudioPlayer(audioID: String, themeAccent: Color) -> some View {
        let isThisPlaying = activeAudioID == audioID && audioManager.isPlaying
        
        VStack(spacing: 12) {
            HStack(spacing: 15) {
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    if isThisPlaying {
                        audioManager.togglePause()
                    } else if let data = MediaManager.shared.loadAudio(id: audioID) {
                        audioManager.playAudio(data: data)
                        activeAudioID = audioID
                        activeNewAudioIndex = nil
                    }
                }) {
                    Image(systemName: isThisPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(Color(uiColor: .systemBackground))
                        .padding(15)
                        .background(themeAccent)
                        .clipShape(Circle())
                        .shadow(color: themeAccent.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isThisPlaying ? "Oynatılıyor" : "Ses Hazır").font(.subheadline.bold())
                    Text(isThisPlaying ? "\(formatTime(audioManager.currentProgress)) / \(formatTime(audioManager.totalDuration))" : "Kayıtlı Ses")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    HapticManager.shared.triggerMediumImpact()
                    if isThisPlaying { audioManager.stopPlayback() }
                    // ✨ SENIOR FIX: let _ = ile bloğu Void'e çevirdik, uyarıları kapattık
                    withAnimation { let _ = removedAudioIDs.insert(audioID) }
                } label: {
                    Image(systemName: "trash").foregroundColor(.red).padding(8).background(Color.red.opacity(0.1)).clipShape(Circle())
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
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(themeAccent.opacity(0.1), lineWidth: 1))
    }
    
    // Yeni eklenen sesi oynatıcı
    @ViewBuilder
    func seniorNewAudioPlayer(data: Data, index: Int, themeAccent: Color) -> some View {
        let isThisPlaying = activeNewAudioIndex == index && audioManager.isPlaying
        
        VStack(spacing: 12) {
            HStack(spacing: 15) {
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    if isThisPlaying {
                        audioManager.togglePause()
                    } else {
                        audioManager.playAudio(data: data)
                        activeNewAudioIndex = index
                        activeAudioID = nil
                    }
                }) {
                    Image(systemName: isThisPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(Color(uiColor: .systemBackground))
                        .padding(15)
                        .background(themeAccent)
                        .clipShape(Circle())
                        .shadow(color: themeAccent.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isThisPlaying ? "Oynatılıyor" : "Yeni Kayıt \(index + 1)").font(.subheadline.bold())
                    Text(isThisPlaying ? "\(formatTime(audioManager.currentProgress)) / \(formatTime(audioManager.totalDuration))" : "Eklenecek")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    HapticManager.shared.triggerMediumImpact()
                    if isThisPlaying { audioManager.stopPlayback() }
                    // ✨ SENIOR FIX: let _ = ile bloğu Void'e çevirdik, uyarıları kapattık
                    withAnimation { let _ = newAudios.remove(at: index) }
                } label: {
                    Image(systemName: "trash").foregroundColor(.red).padding(8).background(Color.red.opacity(0.1)).clipShape(Circle())
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
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(themeAccent.opacity(0.1), lineWidth: 1))
    }

    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func saveChanges() {
        HapticManager.shared.triggerSuccess()
        
        viewModel.updateNote(
            id: note.id,
            newTitle: note.baslik,
            newContent: editedContent,
            isPrivate: note.isPrivate,
            removedImageIDs: removedImageIDs,
            newImages: newlySelectedImages.map { $0.image },
            removedAudioIDs: removedAudioIDs,
            newAudios: newAudios
        )
        
        dismiss()
    }
    
    func loadGalleryImages() {
        Task {
            for item in selectedItems {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        newlySelectedImages.append(IdentifiableImage(image: image))
                    }
                }
            }
            selectedItems.removeAll()
        }
    }
}
