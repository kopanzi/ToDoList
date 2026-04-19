import SwiftUI
import PhotosUI

/// Görev detay ekranında medya öğelerini (Görsel ve Ses) ve aksiyon butonlarını yöneten bileşen.
struct TaskDetailMediaView: View {
    // MARK: - Properties
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    
    /// Galeri seçimi için ana görünümle senkronize çalışan binding
    @Binding var selectedItem: PhotosPickerItem?
    
    /// Kamera tetikleyicisi
    var onCameraTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // 1. GÖRSEL GALERİSİ (Yatay Şerit)
            if !task.imageIDs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Ekler (\(task.imageIDs.count))", systemImage: "paperclip")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(task.imageIDs, id: \.self) { id in
                                if let image = MediaManager.shared.loadImage(id: id) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(12)
                                        .clipped()
                                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                            }
                        }
                    }
                }
            }
            
            // 2. SES KAYDI ALANI (Varsa gösterilir)
            if let audioID = task.audioID {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sesli Not")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        if let data = MediaManager.shared.loadAudio(id: audioID) {
                            AudioManager.shared.playAudio(data: data)
                        }
                    }) {
                        HStack {
                            Image(systemName: AudioManager.shared.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                            
                            Text(AudioManager.shared.isPlaying ? "Durdur" : "Ses Kaydını Dinle")
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if AudioManager.shared.isPlaying {
                                ProgressView()
                                    .tint(.blue)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                }
            }
            
            // 3. AKSİYON BUTONLARI (Galeri & Kamera)
            HStack(spacing: 15) {
                // Fotoğraf Galerisi Seçicisi
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    mediaButton(title: "Galeri", icon: "photo.on.rectangle")
                }
                
                // Kamera Butonu
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    onCameraTap()
                }) {
                    mediaButton(title: "Kamera", icon: "camera")
                }
            }
        }
    }
}

// MARK: - Private Helpers
private extension TaskDetailMediaView {
    
    /// Medya aksiyon butonları için standart tasarım şablonu
    func mediaButton(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .foregroundColor(.primary)
            .font(.subheadline.bold())
            .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    TaskDetailMediaView(
        task: TaskModel(title: "Test", priority: .medium),
        viewModel: TaskViewModel(),
        selectedItem: .constant(nil),
        onCameraTap: {}
    )
    .padding()
}
