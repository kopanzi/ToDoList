import SwiftUI

/// Göreve ait notların girildiği, içeriğe göre otomatik dikeyde büyüyen editör bileşeni.
/// Senior Notu: Focus state eklenerek kullanıcı yazı yazmaya başladığında
/// çerçevenin temanın rengiyle parlaması (Highlight) ve Adaptive UI uyumu sağlandı.
struct TaskDetailEditorView: View {
    // MARK: - Properties
    /// Ana görünümden gelen not metni (Binding sayesinde çift taraflı senkronize çalışır)
    @Binding var noteText: String
    
    // ✨ SENIOR FIX: Uygulamanın aktif temasını dinler
    @EnvironmentObject var appearance: AppearanceManager
    
    // ✨ SENIOR FIX: Klavye açık mı / Editöre odaklanıldı mı durumu
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // 1. Sorumluluk Ayrımı: Etiket ve İkon
            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .foregroundColor(appearance.accentColor) // ✨ İkon rengi temaya bağlandı
                
                Text("Notlar")
            }
            .font(.headline)
            .foregroundColor(.secondary)
            
            // 2. Dinamik Metin Editörü
            TextField("Detayları buraya yazabilirsin...", text: $noteText, axis: .vertical)
                .focused($isFocused)
                .font(.body)
                .padding(16) // Ferahlık için biraz artırıldı
                // ✨ SENIOR FIX: Aydınlık/Karanlık mod uyumlu şeffaf zemin
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)
                .lineLimit(5...) // En az 5 satır yer kaplar, içerik arttıkça otomatik uzar.
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            // Odaklanıldığında tema rengi, aksi halde çok hafif bir sınır çizgisi
                            isFocused ? appearance.accentColor : Color.primary.opacity(0.05),
                            lineWidth: isFocused ? 1.5 : 1
                        )
                )
                // Renk ve kalınlık değişimine yumuşak geçiş animasyonu
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Preview
#Preview {
    TaskDetailEditorView(noteText: .constant("Bu bir örnek görev notudur. Yazdıkça bu alan otomatik olarak dikeyde genişleyecektir."))
        .padding()
        // ✨ SENIOR FIX: Preview'da çökmemesi için
        .environmentObject(AppearanceManager.shared)
}
