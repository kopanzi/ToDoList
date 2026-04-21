import SwiftUI
import PhotosUI

/// Görev notlarını düzenleme ve AI özelliklerini yöneten detay ekranı.
/// Senior Notu: Kamera ve Galeri entegrasyonu MVVM yapısına uygun olarak yeniden bağlandı.
/// Resim silme ve tam ekran önizleme yetenekleri eklendi.
struct TaskDetailView: View {
    // MARK: - Properties
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    @State private var noteText: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showCamera = false
    
    // ✨ YENİ: Tam ekran önizlemeyi tetikleyen yapı
    @State private var previewItem: ImagePreviewItem? = nil
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // 1. BAŞLIK VE DURUM
                TaskDetailHeaderView(task: task)
                
                // 2. BİLGİ KARTI
                TaskDetailInfoView(task: task)
                
                // 3. EDİTÖR (DÜZENLEME ALANI)
                TaskDetailEditorView(noteText: $noteText)
                
                // 4. MEDYA BÖLÜMÜ
                TaskDetailMediaView(
                    task: task,
                    viewModel: viewModel,
                    selectedItem: $selectedItem,
                    onCameraTap: { triggerCameraSafe() }, // ✨ SENIOR FIX: Güvenli kamera tetikleyicisi
                    onImageTap: { image in
                        // ✨ YENİ: Tıklanan resmi tam ekran aç
                        previewItem = ImagePreviewItem(image: image)
                    },
                    onImageDelete: { imageID in
                        // ✨ YENİ: Hem listeden hem de diskten güvenle sil (Anti-Leak)
                        HapticManager.shared.triggerMediumImpact()
                        withAnimation {
                            if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                                viewModel.tasks[index].imageIDs.removeAll(where: { $0 == imageID })
                                MediaManager.shared.deleteFile(id: imageID, fileExtension: "jpg")
                            }
                        }
                    }
                )
                
                // 5. AI ÖNERİSİ
                aiButton
            }
            .padding()
        }
        .onAppear { noteText = task.note }
        .onDisappear {
            // Çıkarken otomatik kaydet
            viewModel.updateTaskNote(task: task, newNote: noteText)
        }
        .navigationBarTitleDisplayMode(.inline)
        
        // ✨ FIX 1: GALERİ BAĞLANTISI (iOS 17 Uyumlu)
        // Galeriden fotoğraf seçildiği an bu blok tetiklenir ve resmi TaskViewModel'e kaydeder.
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.addImages(to: task, images: [uiImage])
                        selectedItem = nil // Bir sonraki seçim için sıfırlıyoruz ki üst üste seçebilelim
                    }
                }
            }
        }
        
        // ✨ FIX 2: KAMERA BAĞLANTISI
        // showCamera true olduğunda CameraPicker tam ekran olarak araya girer.
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                viewModel.addImages(to: task, images: [image])
            }
            .ignoresSafeArea()
        }
        
        // ✨ YENİ FIX 3: GÖRSEL ÖNİZLEME (Tam Ekran)
        .fullScreenCover(item: $previewItem) { item in
            ImagePreviewView(image: item.image)
        }
    }
}

// MARK: - Sub-Views & Helpers
private extension TaskDetailView {
    
    /// Yaver AI Butonu
    var aiButton: some View {
        Button(action: {
            Task {
                if let suggestion = await viewModel.generateAISuggestions(for: task) {
                    withAnimation { noteText += "\n\n🤖 AI Planı:\n\(suggestion)" }
                    HapticManager.shared.triggerSuccess()
                }
            }
        }) {
            Label("Yaver AI ile Planla", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(15)
        }
    }
    
    /// Kamerayı, klavye açıkken yaşanabilecek animasyon çakışmalarından koruyarak açar.
    func triggerCameraSafe() {
        // 1. Klavyeyi zorla kapatıyoruz
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 2. Sisteme 0.2 saniye nefes aldırıp kamerayı öyle tetikliyoruz
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticManager.shared.triggerLightImpact()
            showCamera = true
        }
    }
}
