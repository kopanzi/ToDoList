import WidgetKit
import SwiftUI

// 1. ZAMAN ÇİZELGESİ
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // Önizleme için sahte veri
        let ornekGorev = GorevModel(baslik: "Örnek Görev", onem: .yuksek, kategori: .isYeri, tarih: Date(), gizliMi: false)
        return SimpleEntry(date: Date(), xp: 150, rutbe: "Usta", ikon: "star.fill", gorevler: [ornekGorev])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(veriOku())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = veriOku()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    func veriOku() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.kopanzi.yaver")
        let xp = userDefaults?.integer(forKey: "kullaniciXP") ?? 0
        
        // Görevleri JSON'dan Oku
        var widgetGorevleri: [GorevModel] = []
        if let data = userDefaults?.data(forKey: "widgetGorevler") {
            if let decoded = try? JSONDecoder().decode([GorevModel].self, from: data) {
                widgetGorevleri = decoded
            }
        }
        
        // Rütbe Hesabı
        var rutbeIsim = "Çırak"; var rutbeIkon = "hammer.fill"
        switch xp {
        case 0..<50: rutbeIsim = "Çırak"; rutbeIkon = "hammer.fill"
        case 50..<150: rutbeIsim = "Kalfa"; rutbeIkon = "wrench.and.screwdriver.fill"
        case 150..<300: rutbeIsim = "Usta"; rutbeIkon = "star.fill"
        case 300..<600: rutbeIsim = "Efsane"; rutbeIkon = "crown.fill"
        default: rutbeIsim = "Tosun Paşa"; rutbeIkon = "trophy.fill"
        }
        
        return SimpleEntry(date: Date(), xp: xp, rutbe: rutbeIsim, ikon: rutbeIkon, gorevler: widgetGorevleri)
    }
}

// 2. MODEL
struct SimpleEntry: TimelineEntry {
    let date: Date
    let xp: Int
    let rutbe: String
    let ikon: String
    let gorevler: [GorevModel] // ✨ Artık görevleri de taşıyor
}

// 3. GÖRÜNÜM
struct YaverWidgetEntryView : View {
    var entry: Provider.Entry
    let temaRengi = Color.indigo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Üst Bar: Rütbe ve XP
            HStack {
                Image(systemName: entry.ikon)
                    .foregroundColor(temaRengi)
                Text(entry.rutbe)
                    .font(.caption)
                    .bold()
                    .foregroundColor(temaRengi)
                
                Spacer()
                
                Text("\(entry.xp) XP")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(temaRengi.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.bottom, 8)
            
            Divider().background(temaRengi.opacity(0.3))
            
            // Görev Listesi
            if entry.gorevler.isEmpty {
                // Görev Yoksa
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("Her şey tamam!")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                // Görev Varsa (Liste)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.gorevler.prefix(3)) { gorev in
                        HStack(spacing: 6) {
                            // Öncelik Çizgisi
                            Capsule()
                                .fill(gorev.onem.renk)
                                .frame(width: 3, height: 12)
                            
                            Text(gorev.baslik)
                                .font(.caption)
                                .lineLimit(1)
                                .strikethrough(gorev.tamamlandi)
                            
                            Spacer()
                            
                            // Saat
                            Text(gorev.tarih.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .containerBackground(Color(uiColor: .systemBackground), for: .widget)
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
        .configurationDisplayName("Yaver Görevleri")
        .description("Rütben ve yaklaşan görevlerin.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
