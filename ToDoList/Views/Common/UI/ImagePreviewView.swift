import SwiftUI

/// Görseli tam ekran, siyah arka plan üzerinde merkezde gösteren ortak bileşen.
struct ImagePreviewView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(20)
                    }
                }
                Spacer()
            }
        }
    }
}
