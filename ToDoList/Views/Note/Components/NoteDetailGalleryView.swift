import SwiftUI
import PhotosUI

/// Not detay ekranındaki medya galerisi.
/// Senior Notu: Sorumluluk tamamen ayrılmıştır. Bu bileşen sadece UI çizer,
/// sunum (presentation) ve State işlemleri üst View (NoteDetailView) tarafından yönetilir.
struct NoteDetailGalleryView: View {
    // MARK: - Bindings
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var newlySelectedImages: [IdentifiableImage]
    @Binding var removedImageIDs: Set<String>
    
    // MARK: - Properties
    let existingImageIDs: [String]
    let onCameraTap: () -> Void
    // ✨ SENIOR FIX: Tıklanan resmin indeksini ve tüm resimlerin listesini döner
    let onImageTap: (Int, [UIImage]) -> Void
    let loadImage: (String) -> UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // 1. AKSİYON BUTONLARI (Kamera ve Galeri)
            HStack(spacing: 15) {
                // 🖼️ GALERİ: Sistem bileşeni, anında ve güvenle açılır.
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                    mediaActionButton(title: "Galeri", icon: "photo.on.rectangle", color: .blue)
                }
                
                // 📸 KAMERA: Üst katmandaki güvenli 'triggerCameraSafe' fonksiyonunu tetikler.
                Button(action: onCameraTap) {
                    mediaActionButton(title: "Kamera", icon: "camera.fill", color: .green)
                }
            }
            
            // 2. GÖRSEL LİSTESİ (Hem Eskiler Hem Yeniler)
            let currentVisibleIDs = existingImageIDs.filter { !removedImageIDs.contains($0) }
            
            if !currentVisibleIDs.isEmpty || !newlySelectedImages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ekler")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Diskte Zaten Kayıtlı Olanlar
                            ForEach(currentVisibleIDs, id: \.self) { imageID in
                                if let image = loadImage(imageID) {
                                    thumbnail(image: image) {
                                        HapticManager.shared.triggerMediumImpact()
                                        // ✨ SENIOR FIX: withAnimation sarı uyarı çözümü
                                        let _ = withAnimation { removedImageIDs.insert(imageID) }
                                    }
                                    .onTapGesture {
                                        HapticManager.shared.triggerLightImpact()
                                        // ✨ Tüm resimleri birleştir ve indeksi bulup gönder
                                        let allImages = currentVisibleIDs.compactMap { loadImage($0) } + newlySelectedImages.map { $0.image }
                                        let index = currentVisibleIDs.firstIndex(of: imageID) ?? 0
                                        onImageTap(index, allImages)
                                    }
                                }
                            }
                            
                            // Yeni Seçilenler / Çekilenler
                            ForEach(newlySelectedImages) { item in
                                thumbnail(image: item.image) {
                                    HapticManager.shared.triggerMediumImpact()
                                    // ✨ SENIOR FIX: withAnimation sarı uyarı çözümü
                                    let _ = withAnimation { newlySelectedImages.removeAll(where: { $0.id == item.id }) }
                                }
                                .onTapGesture {
                                    HapticManager.shared.triggerLightImpact()
                                    // ✨ Tüm resimleri birleştir ve indeksi bulup gönder
                                    let allImages = currentVisibleIDs.compactMap { loadImage($0) } + newlySelectedImages.map { $0.image }
                                    let offset = currentVisibleIDs.count
                                    let index = newlySelectedImages.firstIndex(where: { $0.id == item.id }) ?? 0
                                    onImageTap(offset + index, allImages)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
    }
}

// MARK: - Private Helpers
private extension NoteDetailGalleryView {
    
    /// Medya butonları için standart "Senior" tasarım şablonu
    func mediaActionButton(title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
    }
    
    /// Resim önizleme kartı (Silme butonlu)
    func thumbnail(image: UIImage, onDelete: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            // Görsel
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .cornerRadius(12)
                .clipped()
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            
            // Silme Butonu
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                    .background(Circle().fill(Color.white).frame(width: 16, height: 16))
            }
            .offset(x: 6, y: -6) // Butonun köşeden hafif dışarı taşması için
        }
        .padding([.top, .trailing], 6) // Shadow ve silme butonunun kesilmemesi için ekstra pay
    }
}
