import SwiftUI

/// Not listesindeki her bir satırı temsil eden bileşen.
/// Senior Notu: Çift ok hatasını önlemek için manuel chevron silinmiş,
/// Çoklu Ses desteği ve Adaptive Glassmorphism (Buzlu Cam) tasarımı entegre edilmiştir.
struct NoteRowView: View {
    // MARK: - Properties
    let note: NotModel
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        HStack(spacing: 16) {
            
            // 1. GÖRSEL ÖNİZLEME VEYA İKON
            ZStack {
                if let firstImageID = note.gorselIDListesi.first,
                   let image = viewModel.loadImage(id: firstImageID) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Görsel yoksa temanın ana renginde şık bir placeholder (tutucu) gösterilir
                    Color.primary.opacity(0.04)
                    
                    // Not gizli ise kilitli dosya, değilse normal not ikonu
                    Image(systemName: note.isPrivate ? "lock.doc.fill" : "note.text")
                        .font(.system(size: 20))
                        .foregroundColor(appearance.accentColor.opacity(0.7))
                }
            }
            .frame(width: 55, height: 55)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            
            // 2. METİN BİLGİLERİ VE ROZETLER
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(note.baslik)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Gizli Kasa (Kilitli Not) Göstergesi
                    if note.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    
                    // ✨ SENIOR FIX: Çoklu Ses Kaydı Göstergesi
                    if !note.tumSesler.isEmpty {
                        Image(systemName: "waveform")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(appearance.accentColor)
                    }
                }
                
                Text(note.icerik.isEmpty ? "İçerik yok..." : note.icerik)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Oluşturulma Tarihi
                Text(note.createdAt.formatted(.dateTime.day().month().hour().minute()))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.4))
            }
            
            Spacer()
            
            // ✨ SENIOR FIX: Çift ok hatasını çözen hamle!
            // Burada bulunan manuel Image(systemName: "chevron.right") kodu tamamen silindi.
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // ✨ GLASSMORPHISM EFEKTİ (Havada Süzülen Kart Hissi)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.03))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        // ✅ HIZLI AKSİYON MENÜSÜ
        .contextMenu {
            Button(role: .destructive) {
                HapticManager.shared.triggerMediumImpact()
                if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
                    viewModel.deleteNote(at: IndexSet(integer: index))
                }
            } label: {
                Label("Sil", systemImage: "trash")
            }
            
            Divider()
            
            Text("Oluşturulma: \(note.createdAt.formatted())")
                .font(.caption)
        }
    }
}
