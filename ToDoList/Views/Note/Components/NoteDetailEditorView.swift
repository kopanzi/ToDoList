import SwiftUI

/// Not içeriğinin yazıldığı, yazdıkça dikeyde uzayan dinamik editör bileşeni.
/// Senior Notu: Focus state eklenerek kullanıcı yazı yazmaya başladığında
/// çerçevenin temanın rengiyle parlaması (Highlight) sağlandı.
struct NoteDetailEditorView: View {
    // MARK: - Properties
    /// Ana View'dan gelen içerik metni (Binding sayesinde çift taraflı senkronize çalışır)
    @Binding var content: String
    
    // ✨ SENIOR FIX: Uygulamanın aktif temasını dinler
    @EnvironmentObject var appearance: AppearanceManager
    
    // ✨ SENIOR FIX: Klavye açık mı / Editöre odaklanıldı mı durumu
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // Sorumluluk Ayrımı: Etiket ve İkon
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(appearance.accentColor) // ✨ İkon rengi temaya bağlandı
                
                Text("Not İçeriği")
            }
            .font(.headline)
            .foregroundColor(.secondary)
            
            // 🛠️ SENIOR DOKUNUŞU: Yazı yazarken kutunun etrafı tema rengiyle parlar
            TextField("Bir şeyler yazmaya başla...", text: $content, axis: .vertical)
                .focused($isFocused)
                .font(.body)
                .padding(16) // Padding 15'ten 16'ya çekilerek biraz daha ferahlatıldı
                // Sabit gri yerine aydınlık/karanlık mod uyumlu şeffaf zemin
                .background(Color.primary.opacity(0.03))
                .cornerRadius(16)
                .lineLimit(5...) // En az 5 satır görünür, fazlası için otomatik uzar
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            // Odaklanıldığında tema rengi, aksi halde çok hafif bir sınır çizgisi
                            isFocused ? appearance.accentColor : Color.primary.opacity(0.05),
                            lineWidth: isFocused ? 1.5 : 1
                        )
                )
                // Renk ve kalınlık değişimine yumuşak geçiş animasyonu
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .padding(.top, 10)
    }
}

// MARK: - Preview
#Preview {
    NoteDetailEditorView(content: .constant("Bu bir Senior test notudur.\nYazdıkça uzayan yapıyı deniyoruz."))
        .padding()
        // ✨ SENIOR FIX: Preview'da (Önizleme) uygulamanın çökmemesi için environment ekliyoruz
        .environmentObject(AppearanceManager.shared)
}
