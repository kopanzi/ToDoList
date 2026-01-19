import SwiftUI

struct TamEkranGorselView: View {
    // Dışarıdan gelen veriler
    var gorseller: [UIImage]
    @Binding var secilenIndex: Int // Hangi fotoğrafta olduğumuzu takip eder
    @Environment(\.dismiss) var dismiss // Sayfayı kapatmak için

    var body: some View {
        ZStack {
            // 1. Arka Plan (Simsiyah)
            Color.black.ignoresSafeArea()
            
            // 2. Fotoğraflar (Kaydırılabilir Sayfa Yapısı)
            TabView(selection: $secilenIndex) {
                ForEach(0..<gorseller.count, id: \.self) { index in
                    Image(uiImage: gorseller[index])
                        .resizable()
                        .scaledToFit() // Resmi bozmadan sığdır
                        .tag(index) // Sayfa numarası için önemli
                        .pinchToZoom() // (Opsiyonel: İleride zoom özelliği eklersek buraya gelir)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // Alt tarafta nokta nokta sayfa göstergesi
            
            // 3. Kapat Butonu (Sağ Üst)
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                            .shadow(radius: 5)
                    }
                }
                Spacer()
            }
        }
    }
}

// Zoom özelliği için küçük bir eklenti (Bonus)
extension View {
    func pinchToZoom() -> some View {
        self // Şimdilik basit bırakıyoruz, zoom karmaşık matematik gerektirir.
    }
}
