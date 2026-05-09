import SwiftUI

/// Görselleri tam ekran, sağa sola kaydırarak (Swipe) incelemeyi sağlayan ortak bileşen.
/// Senior Notu: Tek resim yerine dizi ve TabView desteği eklenerek "Swipe Gallery" oluşturuldu.
/// ✨ Ekstra Senior Dokunuşları: Çift Tıklama ile Yakınlaştırma (Zoom), Dokunarak Arayüzü Gizleme,
/// Sayfa geçişlerinde Haptic geri bildirim ve görünürlüğü artırılmış çıkış butonu eklendi.
struct ImagePreviewView: View {
    let images: [UIImage]
    @State var selectedIndex: Int
    @Environment(\.dismiss) var dismiss
    
    // Etkileşim Durumları (Interaction States)
    @State private var showUI: Bool = true
    @State private var scale: CGFloat = 1.0
    
    // 1. ESKİ YAPI İÇİN (Tek Resim - Geriye dönük uyumluluk)
    init(image: UIImage) {
        self.images = [image]
        self._selectedIndex = State(initialValue: 0)
    }
    
    // 2. YENİ YAPI İÇİN (Çoklu Resim ve Kaydırma)
    init(images: [UIImage], selectedIndex: Int) {
        self.images = images
        self._selectedIndex = State(initialValue: selectedIndex)
    }
    
    var body: some View {
        ZStack {
            // Arka plan: Arayüz gizlendiğinde tam siyah, aksi halde hafif şeffaf siyah
            Color.black
                .ignoresSafeArea()
            
            // ✨ SENIOR FIX: Sağa sola kaydırmalı (Swipeable) galeri yapısı
            TabView(selection: $selectedIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                        // ✨ ZOOM VE ETKİLEŞİM
                        .scaleEffect(selectedIndex == index ? scale : 1.0)
                        // Çift Tıklama (Yakınlaştır / Uzaklaştır)
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                } else {
                                    scale = 2.0
                                }
                            }
                        }
                        // Tek Tıklama (UI Gizle / Göster)
                        .onTapGesture(count: 1) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showUI.toggle()
                            }
                        }
                        // Pinch to Zoom (Çimdikleyerek Yakınlaştırma)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = value.magnitude
                                }
                                .onEnded { _ in
                                    // Çok küçültülürse veya büyütülürse normale dönsün
                                    if scale < 1.0 || scale > 3.0 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                        }
                                    }
                                }
                        )
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: showUI ? .always : .never))
            .ignoresSafeArea()
            .onChange(of: selectedIndex) { _, _ in
                // Resim değiştiğinde Zoom'u sıfırla ve titreşim ver
                scale = 1.0
                HapticManager.shared.triggerSelection()
            }
            
            // 3. ÜST BAR VE ÇIKIŞ BUTONU
            if showUI {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.shared.triggerLightImpact()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                // Beyaz resimlerde butonun kaybolmaması için arkasına siyah kalkan eklendi
                                .background(Circle().fill(Color.black.opacity(0.4)).frame(width: 28, height: 28))
                                .shadow(color: .black.opacity(0.3), radius: 5)
                                .padding(.trailing, 20)
                                .padding(.top, 20) // SafeArea notch payı
                        }
                    }
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        // UI gizlendiğinde cihazın saatini ve pil göstergesini de saklayarak tam sinematik mod sağlar
        .statusBar(hidden: !showUI)
    }
}
