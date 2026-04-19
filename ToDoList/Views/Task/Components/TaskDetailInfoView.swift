import SwiftUI

/// Görevin meta bilgilerini (Öncelik, Kategori ve Oluşturulma Tarihi) şık bir kart yapısında sunan bileşen.
struct TaskDetailInfoView: View {
    // MARK: - Properties
    let task: TaskModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 0) {
                // 1. Öncelik Sütunu
                infoColumn(
                    title: "ÖNCELİK",
                    value: task.priority.rawValue,
                    icon: "flag.fill",
                    color: task.priority.color
                )
                
                Divider()
                    .padding(.horizontal, 10)
                
                // 2. Kategori Sütunu
                if let category = task.category {
                    infoColumn(
                        title: "KATEGORİ",
                        value: category.rawValue,
                        icon: category.icon,
                        color: category.color
                    )
                } else {
                    infoColumn(
                        title: "KATEGORİ",
                        value: "Yok",
                        icon: "tag.slash.fill",
                        color: .secondary
                    )
                }
            }
            
            Divider()
            
            // 3. Tarih Bilgisi (Alt Şerit)
            HStack {
                Label("Oluşturulma:", systemImage: "calendar")
                Spacer()
                Text(task.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .fontWeight(.medium)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Private Helpers
private extension TaskDetailInfoView {
    
    /// Bilgi sütunları için şablon tasarım
    func infoColumn(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
                .tracking(1) // Harf arası boşluk (Senior dokunuşu)
            
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.footnote)
                Text(value)
                    .font(.subheadline)
                    .bold()
            }
            .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
#Preview {
    TaskDetailInfoView(task: TaskModel(
        title: "Örnek Görev",
        priority: .high,
        category: .project
    ))
    .padding()
}
