import WidgetKit
import SwiftUI

// 1. ZAMAN ÇİZELGESİ GİRDİSİ
struct SimpleEntry: TimelineEntry {
    let date: Date
    let xp: Int
    let rankName: String
    let rankIcon: String
    let tasks: [TaskModel]
}

// 2. VERİ SAĞLAYICI
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // Önizleme verisi
        let sampleTask = TaskModel(title: "Yaver Hazır", priority: .high, category: .personal, createdAt: Date(), isPrivate: false)
        return SimpleEntry(date: Date(), xp: 100, rankName: "Çırak", rankIcon: "hammer.fill", tasks: [sampleTask])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(readData())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = readData()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // Veri Okuma
    func readData() -> SimpleEntry {
        // ⚠️ App Group ID'nizin 'Signing & Capabilities' sekmesindekiyle AYNI olduğundan emin ol.
        let userDefaults = UserDefaults(suiteName: "group.com.kopanzi.yaver")
        let xp = userDefaults?.integer(forKey: "userXP") ?? 0
        
        var rankInfo: (name: String, icon: String) = ("Çırak", "hammer.fill")
        if xp >= 50 { rankInfo = ("Kalfa", "wrench.and.screwdriver.fill") }
        if xp >= 150 { rankInfo = ("Usta", "star.fill") }
        if xp >= 300 { rankInfo = ("Efsane", "crown.fill") }
        
        var widgetTasks: [TaskModel] = []
        if let data = userDefaults?.data(forKey: "yaver_tasks_v2") {
            if let decoded = try? JSONDecoder().decode([TaskModel].self, from: data) {
                let filtered = decoded.filter { !$0.isCompleted }
                widgetTasks = Array(filtered.prefix(3))
            }
        }
        
        return SimpleEntry(date: Date(), xp: xp, rankName: rankInfo.name, rankIcon: rankInfo.icon, tasks: widgetTasks)
    }
}

// 3. WIDGET ARAYÜZÜ
struct YaverWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // Üst Kısım
            HStack {
                Image(systemName: entry.rankIcon)
                    .foregroundColor(.yellow)
                VStack(alignment: .leading) {
                    Text(entry.rankName)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                    Text("\(entry.xp) XP")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "list.bullet.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Divider().overlay(Color.white.opacity(0.3))
            
            // Liste Kısımı
            if entry.tasks.isEmpty {
                VStack {
                    Spacer()
                    Text("Görevler Tamam! 🎉")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    // 🛠️ SENIOR FIX: id'yi açıkça belirtiyoruz ve Closure parametresini tipliyoruz.
                    ForEach(entry.tasks, id: \.id) { (task: TaskModel) in
                        HStack(spacing: 6) {
                            // Renk Çubuğu
                            // .fill yerine .foregroundColor kullanmak Widgetlarda daha stabildir.
                            Capsule()
                                .foregroundColor(task.priority.color)
                                .frame(width: 4, height: 14)
                            
                            Text(task.title)
                                .font(.caption)
                                .lineLimit(1)
                                .strikethrough(task.isCompleted)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .containerBackground(Color.black, for: .widget)
    }
}

// 4. MAIN
@main
struct YaverWidget: Widget {
    let kind: String = "YaverWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YaverWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Yaver")
        .description("Görevlerini takip et.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
