import SwiftUI

/// Görevin üst bilgilerini (Kategori, Tarih, Başlık ve Öncelik) gösteren bileşen.
struct TaskDetailHeaderView: View {
    let task: TaskModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 1. Kategori ve Tarih
            HStack {
                if let category = task.category {
                    Label(category.rawValue, systemImage: category.icon)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(category.color.opacity(0.2))
                        .foregroundColor(category.color)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Text(task.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 2. Ana Başlık ve Önem Durumu
            HStack(alignment: .top) {
                Text(task.title)
                    .font(.largeTitle)
                    .bold()
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(task.priority.color)
                    Text(task.priority.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(task.priority.color)
                }
            }
        }
    }
}
