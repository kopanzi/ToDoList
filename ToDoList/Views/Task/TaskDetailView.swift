import SwiftUI
import PhotosUI

/// Görev notlarını düzenleme özelliklerini yöneten detay ekranı.
/// Senior Notu: Orkestratör View'dır. Klavye yönetimi (Bitti butonu) eklendi,
/// arkaplan uyumluluğu garantilendi ve bileşenlerin modülerliği korundu.
struct TaskDetailView: View {
    // MARK: - Properties
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    @State private var noteText: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showCamera = false
    
    // Tam ekran önizlemeyi tetikleyen yapı
    @State private var previewItem: ImagePreviewItem? = nil
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Arkaplanın ContentView'dan gelen Sistem Rengini (Adaptive) almasını sağlarız
            Color.clear.ignoresSafeArea()
            
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
                        onCameraTap: { triggerCameraSafe() }, // Güvenli kamera tetikleyicisi
                        onImageTap: { image in
                            HapticManager.shared.triggerLightImpact()
                            previewItem = ImagePreviewItem(image: image)
                        },
                        onImageDelete: { imageID in
                            // Hem listeden hem de diskten güvenle sil (Anti-Leak)
                            HapticManager.shared.triggerMediumImpact()
                            withAnimation {
                                if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                                    viewModel.tasks[index].imageIDs.removeAll(where: { $0 == imageID })
                                    MediaManager.shared.deleteFile(id: imageID, fileExtension: "jpg")
                                }
                            }
                        }
                    )
                }
                .padding()
                // ✨ SENIOR FIX: Ekranı aşağı kaydırdığında içerik dibe yapışmasın diye ekstra boşluk
                .padding(.bottom, 40)
            }
        }
        .onAppear { noteText = task.note }
        .onDisappear {
            // Çıkarken otomatik kaydet
            viewModel.updateTaskNote(task: task, newNote: noteText)
        }
        .navigationTitle("Görev Detayı")
        .navigationBarTitleDisplayMode(.inline)
        // ✨ SENIOR UX FIX: Klavye kapatma asistanı
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Bitti") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .bold()
                    .foregroundColor(appearance.accentColor) // ✨ Tema Rengi
                }
            }
        }
        
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
