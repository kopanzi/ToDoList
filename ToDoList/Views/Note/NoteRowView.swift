import SwiftUI

/// Not listesindeki her bir satırı temsil eden bileşen.
/// Senior Notu: 'NoteModel' ismi 'NotModel' olarak güncellenmiş ve
/// modeldeki Türkçe mülk isimleri (baslik, icerik vb.) entegre edilmiştir.
struct NoteRowView: View {
    // MARK: - Properties
    let note: NotModel // ✅ DÜZELTME: NoteModel yerine NotModel kullanıldı.
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        HStack(spacing: 15) {
            // 1. GÖRSEL ÖNİZLEME
            ZStack {
                // NotModel içindeki gorselIDListesi kullanılıyor ✅
                if let firstImageID = note.gorselIDListesi.first,
                   let image = viewModel.loadImage(id: firstImageID) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Görsel yoksa varsayılan ikon
                    Color.primary.opacity(0.05)
                    Image(systemName: "note.text")
                        .foregroundColor(appearance.accentColor.opacity(0.5))
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(10)
            .clipped()
            
            // 2. METİN BİLGİLERİ
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(note.baslik) // ✅ title -> baslik
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    // Kilitli not göstergesi
                    // NotModel'de isPrivate alanı henüz yoksa TaskModel'deki gibi eklenebilir.
                    // Eğer modelde yoksa bu kısmı şimdilik yorum satırı yapabilirsin.
                    /*
                    if note.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    */
                    
                    // Ses kaydı göstergesi ✅
                    if note.sesID != nil {
                        Image(systemName: "waveform")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
                
                Text(note.icerik.isEmpty ? "İçerik yok" : note.icerik) // ✅ content -> icerik
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Oluşturulma tarihi
                Text(note.createdAt.formatted(.dateTime.day().month().hour().minute()))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            Spacer()
            
            // Sağdaki yönlendirme oku
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary.opacity(0.2))
        }
        .padding(.vertical, 4)
        // ✅ HIZLI AKSİYON MENÜSÜ
        .contextMenu {
            Button(role: .destructive) {
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
