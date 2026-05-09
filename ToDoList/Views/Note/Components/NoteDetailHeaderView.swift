import SwiftUI

/// Not detay ekranının en üst kısmında yer alan, başlık ve oluşturulma tarihini gösteren bileşen.
/// Senior Notu: Tipografi güçlendirildi ve tarih ikonuna dinamik tema rengi (AppearanceManager) bağlandı.
struct NoteDetailHeaderView: View {
    // MARK: - Properties
    let title: String
    let date: Date
    
    // ✨ SENIOR FIX: Uygulamanın aktif temasını dinler
    @EnvironmentObject var appearance: AppearanceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Boşluk 5'ten 8'e çıkarılarak ferahlatıldı
            // Not Başlığı
            Text(title)
                .font(.system(.largeTitle, design: .rounded))
                .bold()
                .foregroundColor(.primary)
            
            // Oluşturulma Tarihi (İkonlu)
            HStack(spacing: 6) {
                // ✨ SENIOR FIX: Düz ikon yerine içi dolu ve tema renkli ikon
                Image(systemName: "clock.fill")
                    .foregroundColor(appearance.accentColor)
                
                Text(date.formatted(date: .long, time: .shortened))
            }
            // ✨ SENIOR FIX: Basit .caption yerine daha okunaklı ve yuvarlak font
            .font(.system(.subheadline, design: .rounded).weight(.medium))
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
    // ✨ SENIOR FIX: Preview'da (Önizleme) uygulamanın çökmemesi için environment ekliyoruz
    .environmentObject(AppearanceManager.shared)
}
