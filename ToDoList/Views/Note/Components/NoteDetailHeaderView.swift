import SwiftUI

/// Not detay ekranının en üst kısmında yer alan, başlık ve oluşturulma tarihini gösteren bileşen.
struct NoteDetailHeaderView: View {
    // MARK: - Properties
    let title: String
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Not Başlığı
            Text(title)
                .font(.system(.largeTitle, design: .rounded))
                .bold()
                .foregroundColor(.primary)
            
            // Oluşturulma Tarihi (İkonlu)
            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text(date.formatted(date: .long, time: .shortened))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.top, 10)
    }
}

// MARK: - Preview
#Preview {
    NoteDetailHeaderView(
        title: "Senior Mimari Notları",
        date: Date()
    )
    .padding()
}
