import SwiftUI
import PhotosUI

/// Görev detay ekranında medya öğelerini (Görsel ve Ses) ve aksiyon butonlarını yöneten bileşen.
/// Senior Notu: Galeri ve Kamera butonları minimal tasarıma geçirildi. Resimlerin üzerine tıklayarak
/// tam ekran önizleme ve silme (X butonu) özellikleri eklendi.
struct TaskDetailMediaView: View {
    // MARK: - Properties
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager // ✨ Buton renklerini temaya uydurmak için eklendi
    
    /// Galeri seçimi için ana görünümle senkronize çalışan binding
    @Binding var selectedItem: PhotosPickerItem?
    
    /// Aksiyon Tetikleyicileri
    var onCameraTap: () -> Void
    var onImageTap: (UIImage) -> Void     // ✨ YENİ: Resme tıklanma durumu
    var onImageDelete: (String) -> Void   // ✨ YENİ: Resim silinme durumu
    
    var body: some View {
        // ✨ SENIOR FIX: Concurrency/Sendable hatasını önlemek için rengi değere (value type) alıyoruz.
        let themeAccent = appearance.accentColor
        
        VStack(alignment: .leading, spacing: 20) {
            
            // 1. GÖRSEL GALERİSİ (Yatay Şerit - Silme ve Önizleme Destekli)
            if !task.imageIDs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Ekler (\(task.imageIDs.count))", systemImage: "paperclip")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(task.imageIDs, id: \.self) { id in
                                if let image = MediaManager.shared.loadImage(id: id) {
                                    ZStack(alignment: .topTrailing) {
                                        // Resim Kutusu
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90) // Biraz daha zarif ve toplu
                                            .cornerRadius(12)
                                            .clipped()
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                            // ✨ SENIOR FIX: Resme tıklayınca önizlemeyi tetikler
                                            .onTapGesture {
                                                HapticManager.shared.triggerLightImpact()
                                                onImageTap(image)
                                            }
                                        
                                        // ✨ SENIOR FIX: Silme Butonu (X)
                                        Button(action: {
                                            HapticManager.shared.triggerMediumImpact()
                                            onImageDelete(id)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white).frame(width: 14, height: 14))
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                    .padding([.top, .trailing], 6)
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
            
            // 3. AKSİYON BUTONLARI (Zarif ve Minimal Tasarım)
            HStack(spacing: 15) {
                // Fotoğraf Galerisi Seçicisi
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Galeri", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(themeAccent.opacity(0.1))
                        .foregroundColor(themeAccent)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                // Kamera Butonu
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    onCameraTap()
                }) {
                    Label("Kamera", systemImage: "camera.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(themeAccent.opacity(0.1))
                        .foregroundColor(themeAccent)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TaskDetailMediaView(
        task: TaskModel(title: "Test", priority: .medium),
        viewModel: TaskViewModel(),
        selectedItem: .constant(nil),
        onCameraTap: {},
        onImageTap: { _ in },
        onImageDelete: { _ in }
    )
    .environmentObject(AppearanceManager.shared)
    .padding()
}
