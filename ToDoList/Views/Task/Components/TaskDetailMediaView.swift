import SwiftUI
import PhotosUI

/// Görev detay ekranında medya öğelerini (Görsel ve Ses) ve aksiyon butonlarını yöneten bileşen.
/// Senior Notu: Sabit beyaz ve mavi renkler kaldırılarak Adaptive UI ve Tema Motoru uyumu sağlandı.
/// Resimlerin üzerine tıklayarak tam ekran önizleme ve silme özellikleri tamamen mod uyumludur.
struct TaskDetailMediaView: View {
    // MARK: - Properties
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    /// Galeri seçimi için ana görünümle senkronize çalışan binding
    @Binding var selectedItem: PhotosPickerItem?
    
    /// Aksiyon Tetikleyicileri
    var onCameraTap: () -> Void
    var onImageTap: (UIImage) -> Void
    var onImageDelete: (String) -> Void
    
    var body: some View {
        // ✨ SENIOR FIX: Concurrency/Sendable hatasını önlemek için rengi değere alıyoruz.
        let themeAccent = appearance.accentColor
        
        VStack(alignment: .leading, spacing: 20) {
            
            // 1. GÖRSEL GALERİSİ (Yatay Şerit - Silme ve Önizleme Destekli)
            if !task.imageIDs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Ekler (\(task.imageIDs.count))", systemImage: "paperclip")
                        .font(.headline)
                        .foregroundColor(.secondary) // ✨ Adaptive
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(task.imageIDs, id: \.self) { id in
                                if let image = MediaManager.shared.loadImage(id: id) {
                                    ZStack(alignment: .topTrailing) {
                                        // Resim Kutusu
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .cornerRadius(12)
                                            .clipped()
                                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                            // ✨ SENIOR FIX: Aydınlık/Karanlık modda resmi belirginleştiren şık çerçeve
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                            .onTapGesture {
                                                HapticManager.shared.triggerLightImpact()
                                                onImageTap(image)
                                            }
                                        
                                        // Silme Butonu (X)
                                        Button(action: {
                                            HapticManager.shared.triggerMediumImpact()
                                            onImageDelete(id)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.red)
                                                // ✨ SENIOR FIX: Sabit .white yerine Sistem Arkaplanı ile Cutout (Kesik) efekti
                                                .background(Circle().fill(Color(uiColor: .systemBackground)).frame(width: 14, height: 14))
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
                        .foregroundColor(.secondary) // ✨ Adaptive
                    
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
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
                                    .tint(themeAccent) // ✨ Tema Rengi
                            }
                        }
                        .padding()
                        // ✨ SENIOR FIX: Sabit mavi yerine Tema Rengine bağlandı
                        .background(themeAccent.opacity(0.1))
                        .foregroundColor(themeAccent)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeAccent.opacity(0.2), lineWidth: 1))
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
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(themeAccent.opacity(0.2), lineWidth: 1))
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
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(themeAccent.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
