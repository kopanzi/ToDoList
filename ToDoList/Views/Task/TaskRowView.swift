import SwiftUI

/// Görev listesindeki tekil satır. Tailwind tasarımına göre "Glass" görünüme geçirildi.
struct TaskRowView: View {
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. CHECKBOX (Hollow Circle)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.toggleCompletion(task: task)
                }
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(task.isCompleted ? Color(hex: "0df2cc") : Color.gray.opacity(0.6), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.isCompleted {
                        Circle()
                            .fill(Color(hex: "0df2cc"))
                            .frame(width: 12, height: 12)
                            .transition(.scale)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // 2. BAŞLIK VE DETAYLAR
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .white.opacity(0.4) : .white)
                        .lineLimit(1)
                    
                    // Gizlilik İkonu
                    if task.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }
                
                // Saat veya Ek Bilgi
                HStack(spacing: 4) {
                    // 🔔 SENIOR DOKUNUŞU: Eğer görev tarihi şu andan ileriyse (hatırlatıcıysa) zil ikonu göster
                    if task.createdAt > Date() && !task.isCompleted {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 10))
                    }
                    
                    // ✨ SENIOR FIX: Göreceli Zaman Gösterimi
                    Text(relativeTimeString(for: task.createdAt))
                        .foregroundColor(timeColor(for: task.createdAt, isCompleted: task.isCompleted))
                        .fontWeight(task.createdAt < Date() && !task.isCompleted ? .bold : .regular)
                    
                    if !task.note.isEmpty {
                        Text("• Not var")
                            .foregroundColor(.white.opacity(0.5)) // Özel olarak bu metne uyguladık
                    }
                }
                .font(.system(size: 12))
            }
            
            Spacer()
            
            // 3. KATEGORİ BADGE (Pill Design)
            if let category = task.category {
                Text(category.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1) // Harf arası boşluk
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(category.color.opacity(0.15))
                    .foregroundColor(category.color.opacity(0.9))
                    .overlay(
                        Capsule().stroke(category.color.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        // ✨ GÖREV KARTI GLASSMORPHISM
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .background(.ultraThinMaterial.opacity(0.5)) // Hafif blur
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .opacity(task.isCompleted ? 0.6 : 1.0) // Tamamlananları biraz soldur
        // Tasarımdaki listeler arası boşluk için margin yerine padding kullanıp listRowInsets sıfırlanacak
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Relative Time Helpers
    
    /// Yaver'in insan gibi saat okumasını sağlayan zeki fonksiyon
    private func relativeTimeString(for date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let timeStr = date.formatted(date: .omitted, time: .shortened)
            
            // Gelecekteki aynı gün görevleri için "kalan süreyi" hesapla
            if date > Date() {
                let diffComponents = calendar.dateComponents([.hour, .minute], from: Date(), to: date)
                if let hours = diffComponents.hour, let minutes = diffComponents.minute {
                    if hours == 0 && minutes < 60 {
                        return "🔥 \(minutes) dk kaldı" // Çok acil hissi
                    } else if hours < 3 {
                        return "Yaklaşan (\(timeStr))"
                    }
                }
            }
            return "Bugün, \(timeStr)"
        } else if calendar.isDateInYesterday(date) {
            return "⚠️ Dün"
        } else if calendar.isDateInTomorrow(date) {
            return "Yarın, \(date.formatted(date: .omitted, time: .shortened))"
        } else {
            // Çok eskiden veya çok ilerideyse normal format
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
    
    /// Görevin zaman durumuna göre rengini belirler (Aciliyet hissi için)
    private func timeColor(for date: Date, isCompleted: Bool) -> Color {
        if isCompleted {
            return .white.opacity(0.5) // Biten işlerin saati soluk olur
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInYesterday(date) || (date < now && !calendar.isDateInToday(date)) {
            return .red.opacity(0.8) // Gecikmiş işler uyarısı
        } else if calendar.isDateInToday(date) && date > now {
            // Bugün ama gelecekte
            let diff = calendar.dateComponents([.hour], from: now, to: date).hour ?? 0
            if diff < 2 {
                return .orange // Yaklaşan işlere turuncu uyarı
            }
        }
        
        return .white.opacity(0.5) // Varsayılan renk
    }
}
