import SwiftUI
import PhotosUI

/// Yeni not ekleme formu.
/// Senior Notu: Klavye animasyon çakışmaları ve Presentation hataları,
/// birbirinden bağımsız @State değişkenleri ve Callback tabanlı CameraPicker ile çözülmüştür.
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
    @State private var recordedAudioData: Data? = nil
    
    // ✅ SENIOR ÇÖZÜM: Sunumlar için tamamen bağımsız state'ler.
    // Artık 'capturedImage' binding'ine ihtiyacımız yok, çünkü CameraPicker closure kullanıyor.
    @State private var showCamera = false
    @State private var previewImage: ImagePreviewItem?
    
    // MARK: - Initialization
    init(viewModel: NoteViewModel, isPrivateDefault: Bool) {
        self.viewModel = viewModel
        _isPrivate = State(initialValue: isPrivateDefault)
    }
    
    var body: some View {
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
                    
                    // 3. SES KAYIT PANELİ
                    Section("SESLİ NOT") {
                        voiceRecordingSection
                    }
                    
                    // 4. MEDYA EKLEME
                    Section("MEDYA") {
                        HStack(spacing: 15) {
                            // 🖼️ GALERİ: Sistem bileşeni, anlık açılır
                            PhotosPicker(selection: $selectedItems, matching: .images) {
                                mediaActionButton(title: "Galeri", icon: "photo.stack", color: .blue)
                            }
                            
                            // 📸 KAMERA: Güvenli tetikleyici ile açılır ✅
                            Button(action: { triggerCameraSafe() }) {
                                mediaActionButton(title: "Kamera", icon: "camera", color: .green)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        
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
                            .disabled(baslik.isEmpty && newlySelectedImages.isEmpty && recordedAudioData == nil)
                    }
                    
                    // Klavye kapatma asistanı
                    ToolbarItem(placement: .keyboard) {
                        Button("Bitti") { focusedField = nil }
                    }
                }
            }
        }
        // ✅ CALLBACK TABANLI KAMERA SUNUMU:
        // isPresented binding'i SwiftUI tarafından yönetilir, Picker'ın kendi içindeki o boş UIViewController
        // sayesinde iOS hiyerarşisi kilitlenmez ve galeri asla yanlışlıkla açılmaz.
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { capturedImage in
                // Delegate callback olarak burayı tetikler, binding state çakışması yaşanmaz.
                newlySelectedImages.append(IdentifiableImage(image: capturedImage))
            }
            .ignoresSafeArea()
        }
        // Görsel Önizleme
        .fullScreenCover(item: $previewImage) { item in
            ImagePreviewView(image: item.image)
        }
        // Galeri Seçimi Sonrası İşlem
        .onChange(of: selectedItems) { _, _ in loadGalleryImages() }
    }
}

// MARK: - Sub-Views Extension
private extension AddNoteView {
    
    /// Kamerayı klavye animasyonu ile çakışmayacak şekilde güvenle açar.
    func triggerCameraSafe() {
        // 1. Klavyeyi STATE üzerinden ve UIKit üzerinden kapat ✅
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 2. Klavye kapanma animasyonunun bitmesi için çok küçük ve hayati bir gecikme (0.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticManager.shared.triggerLightImpact()
            showCamera = true
        }
    }
    
    var voiceRecordingSection: some View {
        VStack(spacing: 12) {
            if audioManager.isRecording {
                HStack {
                    Circle().fill(.red).frame(width: 8, height: 8)
                        .opacity(audioManager.isRecording ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: audioManager.isRecording)
                    Text(formatTime(audioManager.currentProgress)).font(.system(.body, design: .monospaced).bold()).foregroundColor(.red)
                    Spacer()
                    Button("Durdur") { withAnimation { recordedAudioData = audioManager.stopRecording() } }
                }
            } else if let audioData = recordedAudioData {
                VStack(spacing: 12) {
                    HStack(spacing: 15) {
                        Button(action: {
                            if audioManager.isPlaying { audioManager.togglePause() }
                            else { audioManager.playAudio(data: audioData) }
                        }) {
                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .foregroundColor(.white).padding(12).background(Color.blue).clipShape(Circle())
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Kayıt Hazır").font(.subheadline.bold())
                            Text("\(formatTime(audioManager.currentProgress)) / \(formatTime(audioManager.totalDuration))").font(.caption.monospacedDigit()).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            recordedAudioData = nil
                            audioManager.stopPlayback()
                        } label: { Image(systemName: "trash").foregroundColor(.red) }
                    }
                    
                    Slider(value: Binding(get: { audioManager.currentProgress }, set: { audioManager.seek(to: $0) }), in: 0...(audioManager.totalDuration > 0 ? audioManager.totalDuration : 1))
                        .tint(.blue)
                }
                .padding().background(Color.blue.opacity(0.05)).cornerRadius(15)
            } else {
                HStack {
                    Label("Sesli Not Ekle", systemImage: "mic.badge.plus")
                    Spacer()
                    Button(action: { audioManager.startRecording() }) {
                        Image(systemName: "mic.fill").foregroundColor(.white).padding(10).background(appearance.accentColor).clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    var selectedImagesHorizontalGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(newlySelectedImages) { item in
                    Image(uiImage: item.image)
                        .resizable().scaledToFill().frame(width: 85, height: 85).cornerRadius(12).clipped()
                        // Resme basınca önizlemeyi tetikler
                        .onTapGesture { previewImage = ImagePreviewItem(image: item.image) }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation { newlySelectedImages.removeAll(where: { $0.id == item.id }) }
                            } label: { Label("Sil", systemImage: "trash") }
                        }
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    func mediaActionButton(title: String, icon: String, color: Color) -> some View {
        HStack { Image(systemName: icon); Text(title) }
            .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(color.opacity(0.1)).foregroundColor(color).cornerRadius(12)
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
        viewModel.addNote(
            title: baslik,
            content: icerik,
            isPrivate: isPrivate,
            images: newlySelectedImages.map { $0.image },
            audioData: recordedAudioData
        )
        audioManager.stopPlayback()
        dismiss()
    }
}
