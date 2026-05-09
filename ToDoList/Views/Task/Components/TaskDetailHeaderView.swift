import SwiftUI

/// Görevin ana başlığını gösteren minimalist bileşen.
/// Senior Notu: Tekrara düşen Kategori, Tarih ve Öncelik bilgileri (InfoView içindeki kutuda
/// zaten yer aldığı için) tamamen silinerek, Apple'ın minimalist "Sadece Odak" tasarım
/// prensibine uygun, çok daha ferah bir hale getirilmiştir.
struct TaskDetailHeaderView: View {
    // MARK: - Properties
    let task: TaskModel
    
    var body: some View {
        HStack(alignment: .top) {
            Text(task.title)
                // ✨ SENIOR FIX: Daha modern ve premium bir başlık fontu
                .font(.system(.largeTitle, design: .rounded))
                .bold()
                .strikethrough(task.isCompleted)
                // ✨ SENIOR FIX: Sabit .gray yerine Adaptive .primary.opacity
                .foregroundColor(task.isCompleted ? .primary.opacity(0.4) : .primary)
                // Başlık ne kadar uzun olursa olsun tam okunabilmesi için
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.bottom, 4) // Kutuyla arasında hafif bir nefes payı
    }
}

// MARK: - Preview
#Preview {
    TaskDetailHeaderView(task: TaskModel(
        title: "Senior seviyesinde yeni arayüz mimarisini incele",
        priority: .high,
        category: .project
    ))
    .padding()
}
