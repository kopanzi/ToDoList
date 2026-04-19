import SwiftUI

/// Not içeriğinin yazıldığı, yazdıkça dikeyde uzayan dinamik editör bileşeni.
struct NoteDetailEditorView: View {
    // MARK: - Properties
    /// Ana View'dan gelen içerik metni (Binding sayesinde çift taraflı senkronize çalışır)
    @Binding var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Sorumluluk Ayrımı: Etiket kısmını da burada tutuyoruz
            Text("Not İçeriği")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // 🛠️ SENIOR DOKUNUŞU:
            // TextField axis: .vertical kullanımı, içeriğe göre alanın büyümesini sağlar.
            // lineLimit(5...) ile en az 5 satır görünür, fazlası için otomatik uzar.
            TextField("Bir şeyler yazmaya başla...", text: $content, axis: .vertical)
                .font(.body)
                .padding(15)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                .lineLimit(5...)
        }
        .padding(.top, 10)
    }
}

// MARK: - Preview
#Preview {
    NoteDetailEditorView(content: .constant("Bu bir Senior test notudur.\nYazdıkça uzayan yapıyı deniyoruz."))
        .padding()
}
