import SwiftUI
import PhotosUI

/// Not içeriğini düzenleme ve gelişmiş medya yönetimi ekranı.
/// Senior Notu: Klavye animasyon çakışmaları ve Presentation hataları,
/// birbirinden bağımsız @State değişkenleri ve Callback tabanlı CameraPicker ile tamamen çözülmüştür.
struct NoteDetailView: View {
    // MARK: - Properties
    let note: NotModel
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var appearance: AppearanceManager
    @StateObject private var audioManager = AudioManager.shared
    
    // Düzenleme Durumları
    @State private var editedContent: String = ""
    @State private var isAnalyzing: Bool = false
    @FocusState private var isEditorFocused: Bool
    
    // Medya States
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var newlySelectedImages: [IdentifiableImage] = []
    @State private var removedImageIDs = Set<String>()
    
    // ✅ SENIOR ÇÖZÜM: Bağımsız Sunum Değişkenleri
    // Enum (ActiveSheet) yapısı kaldırıldı. Galeri, Kamera ve Önizleme birbirini ASLA ezemez.
    @State private var showCamera = false
    @State private var previewImage: ImagePreviewItem?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // 1. ÜST BAŞLIK VE TARİH
                    // 🛠️ DÜZELTME: 'createdAt' yerine modelin standart mülkü 'tarih' kullanıldı.
                    NoteDetailHeaderView(title: note.baslik, date: note.tarih)
                    
                    // 2. GELİŞMİŞ SES OYNATICI (Slider ve Sarma)
                    if let audioID = note.sesID {
                        seniorAudioPlayer(audioID: audioID)
                    }
                    
                    // 3. GELİŞMİŞ GALERİ
                    NoteDetailGalleryView(
                        selectedItems: $selectedItems,
                        newlySelectedImages: $newlySelectedImages,
                        removedImageIDs: $removedImageIDs,
                        existingImageIDs: note.gorselIDListesi,
                        onCameraTap: { triggerCameraSafe() }, // Güvenli Tetikleyici ✅
                        onImageTap: { img in previewImage = ImagePreviewItem(image: img) },
                        loadImage: { id in viewModel.loadImage(id: id) }
                    )
                    
                    // 4. İÇERİK EDİTÖRÜ
                    NoteDetailEditorView(content: $editedContent)
                        .focused($isEditorFocused)
                    
                    // 5. AI PARLATMA BUTONU
                    aiPolishButton
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
                        .foregroundColor(appearance.accentColor)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Bitti") { isEditorFocused = false }
                }
            }
        }
        // ✅ CALLBACK TABANLI KAMERA SUNUMU:
        // isPresented binding'i SwiftUI tarafından yönetilir, picker içinden değil!
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { capturedImage in
                // Delegate callback olarak burayı tetikler, binding state çakışması yaşanmaz.
                newlySelectedImages.append(IdentifiableImage(image: capturedImage))
            }
            .ignoresSafeArea()
        }
        // Görsel önizleme
        .fullScreenCover(item: $previewImage) { item in
            ImagePreviewView(image: item.image)
        }
        .onChange(of: selectedItems) { _, _ in loadGalleryImages() }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Senior UI Bileşenleri
private extension NoteDetailView {
    
    /// Kamerayı klavye animasyonu ile çakışmayacak şekilde (0.2s bekleme ile) tetikler.
    func triggerCameraSafe() {
        // 1. Klavyeyi kapat ve UIKit seviyesinde komut gönder
        isEditorFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 2. Animasyonun bitmesini garantileyen nefes payı
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticManager.shared.triggerLightImpact()
            showCamera = true
        }
    }
    
    @ViewBuilder
    func seniorAudioPlayer(audioID: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SESLİ NOT").font(.caption.bold()).foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                HStack(spacing: 20) {
                    Button(action: {
                        if audioManager.isPlaying {
                            audioManager.togglePause()
                        } else if let data = MediaManager.shared.loadAudio(id: audioID) {
                            audioManager.playAudio(data: data)
                        }
                    }) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(15)
                            .background(appearance.accentColor)
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(audioManager.isPlaying ? "Oynatılıyor" : "Ses Hazır")
                            .font(.subheadline.bold())
                        Text("\(formatTime(audioManager.currentProgress)) / \(formatTime(audioManager.totalDuration))")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if audioManager.isPlaying || audioManager.currentProgress > 0 {
                        Button(action: { audioManager.stopPlayback() }) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                                .padding(10)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                
                Slider(value: Binding(get: {
                    audioManager.currentProgress
                }, set: { newValue in
                    audioManager.seek(to: newValue)
                }), in: 0...(audioManager.totalDuration > 0 ? audioManager.totalDuration : 1))
                .tint(appearance.accentColor)
            }
            .padding()
            .background(appearance.accentColor.opacity(0.08))
            .cornerRadius(20)
        }
    }
    
    var aiPolishButton: some View {
        Button(action: {
            Task {
                isAnalyzing = true
                if let polished = await viewModel.polishNoteContent(content: editedContent) {
                    withAnimation { editedContent = polished }
                    HapticManager.shared.triggerSuccess()
                }
                isAnalyzing = false
            }
        }) {
            HStack {
                if isAnalyzing { ProgressView().tint(.white).padding(.trailing, 8) }
                Image(systemName: "wand.and.stars")
                Text(isAnalyzing ? "Yaver Düzenliyor..." : "AI ile Metni Düzenle")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
        .disabled(isAnalyzing || editedContent.isEmpty)
    }

    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func saveChanges() {
        // 🛠️ SENIOR MVVM ÇÖZÜMÜ:
        // Hata veren o eski "NotModel(createdAt: ...)" kısmını tamamen sildik.
        // Artık View kendi kendine modeli değiştirmeye çalışmıyor, işlemi tertemiz bir şekilde
        // NoteViewModel içindeki 'updateNote' fonksiyonuna devrediyor!
        viewModel.updateNote(
            id: note.id,
            newTitle: note.baslik,
            newContent: editedContent,
            isPrivate: note.isPrivate,
            removedImageIDs: removedImageIDs,
            newImages: newlySelectedImages.map { $0.image }
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
