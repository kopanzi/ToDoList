import SwiftUI

/// Göreve ait notların girildiği, içeriğe göre otomatik dikeyde büyüyen editör bileşeni.
struct TaskDetailEditorView: View {
    // MARK: - Properties
    /// Ana görünümden gelen not metni (Binding sayesinde çift taraflı senkronize çalışır)
    @Binding var noteText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Başlık Etiketi
            Label("Notlar", systemImage: "note.text")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // 🛠️ SENIOR DOKUNUŞU:
            // Standard TextEditor yerine TextField(axis: .vertical) kullanmak,
            // SwiftUI'da dikeyde otomatik genişleyen, daha iyi padding ve
            // placeholder desteği sunan bir yapı sağlar.
            TextField("Detayları buraya yazabilirsin...", text: $noteText, axis: .vertical)
                .font(.body)
                .padding(15)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                .lineLimit(5...) // En az 5 satır yer kaplar, içerik arttıkça otomatik uzar.
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview
#Preview {
    TaskDetailEditorView(noteText: .constant("Bu bir örnek görev notudur. Yazdıkça bu alan otomatik olarak dikeyde genişleyecektir."))
        .padding()
}
