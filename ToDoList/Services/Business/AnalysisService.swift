import Foundation

/// Yaver'in kural tabanlı (Rule-Based) yerel analiz motoru.
/// Senior Notu: Gemini API bağımlılığını ortadan kaldırır. Kullanıcı istatistiklerini
/// milisaniyeler içinde yorumlayarak binlerce farklı kombinasyonda doğal dil raporları üretir.
final class AnalysisService {
    
    // MARK: - Singleton
    static let shared = AnalysisService()
    private init() {}
    
    // MARK: - Public API
    
    /// Kullanıcı verilerine göre kişiselleştirilmiş analiz raporu oluşturur.
    func generateReport(completionRate: Double, streak: Int, peakHour: Int, timeSavedInMinutes: Int) -> String {
        let statusPart = getStatusSentence(rate: completionRate)
        let streakPart = getStreakSentence(days: streak)
        let timePart = getTimeAnalysisSentence(hour: peakHour)
        let savingsPart = getSavingsSentence(minutes: timeSavedInMinutes)
        
        // ✨ SENIOR UX: Rastgele bağlaçlar ile her seferinde farklı bir insan yazmış gibi hissettirir.
        let separators = [
            " ",
            " Ayrıca, ",
            " Bununla birlikte, ",
            " Unutma ki; ",
            " Üstelik, ",
            " Şunu da ekleyelim: ",
            " Öte yandan, "
        ]
        
        return "\(statusPart)\(separators.randomElement() ?? " ")\(streakPart) \(timePart) \(savingsPart)"
    }
    
    // MARK: - 📊 1. Katman: Genel Durum (Bitirme Oranı)
    
    private func getStatusSentence(rate: Double) -> String {
        // ✨ FIX: Aralıklar arasında boşluk kalmaması için ..< yapısı kullanıldı.
        switch rate {
        case ..<0.11:
            return [
                "Bugün motorları ısıtmakta biraz zorlanıyoruz kanka. Ama sorun değil, en küçük adımla başlayalım.",
                "Yaver bugün biraz yalnız kalmış, görev listesi henüz el değmemiş duruyor.",
                "Sakin bir başlangıç... Bazen sadece izlemek gerekir ama bugün o gün değil!",
                "Sayfa bomboş, hadi bir yerden tutup Yaver'i sevindirelim."
            ].randomElement() ?? "Hadi kanka, ilk adımı atalım!"
            
        case 0.11..<0.36:
            return [
                "Isınma turları tamam, şimdi vites yükseltme zamanı. Tempo yavaş ama yön doğru.",
                "Fena değil, ilk engelleri aştık. Biraz daha odaklanırsan akıp gidecek.",
                "Yavaş yavaş ritim buluyoruz. Küçük adımlar büyük sonuçlara gebedir.",
                "Yolun başındasın ama ilerliyorsun. Bu hızı ikiye katlayabiliriz!"
            ].randomElement() ?? "İlerleme kaydediyoruz."
            
        case 0.36..<0.66:
            return [
                "Gayet iyi bir tempo! İşlerin neredeyse yarısını paketlemişsin, durmak yok.",
                "Orta saha mücadelesini kazandık, şimdi golü atma vakti. Verimliliğin artıyor.",
                "İstikrarlı bir ilerleyiş... Yaver bu tempoyu çok sevdi!",
                "Günün yarısı bitti, görevlerin de öyle. Harika bir denge kurmuşsun."
            ].randomElement() ?? "Güzel bir ivme yakaladık."
            
        case 0.66..<0.91:
            return [
                "Şov yapıyorsun kanka! Listenin bitmesine ramak kaldı, odak seviyen tavan yapmış.",
                "Tam bir verimlilik makinesine dönüştün. Kalan birkaç işi de çerez niyetine halledersin.",
                "Yaver bugün seninle gurur duyuyor. Neredeyse her şeyi temizledin!",
                "Üst düzey performans! Bugün bitirdiğin işler yarının yükünü şimdiden azalttı."
            ].randomElement() ?? "Zirveye çok yakınız."
            
        default: // %91 - %100 Arası
            return [
                "Kusursuz zafer! Listede bitmemiş tek bir nokta bile bırakmadın. Tam bir canavarsın!",
                "Bugün masadan galip ayrılan sensin. Bütün görevleri dize getirdin. 🚀",
                "Efsanevi bir gün! Odaklanma konusundaki ustalığını bir kez daha kanıtladın.",
                "Her şey bitti kanka! Şimdi arkana yaslan ve başarının tadını çıkar."
            ].randomElement() ?? "Harika bir gün finali!"
        }
    }
    
    // MARK: - 🔥 2. Katman: Seri (Streak Analizi)
    
    private func getStreakSentence(days: Int) -> String {
        if days == 0 {
            return "Seri başlatmak için bugün harika bir fırsat."
        } else if days < 3 {
            return "\(days) gündür sahadayız. Alışkanlıklar yavaş yavaş kemikleşiyor."
        } else if days < 7 {
            return "\(days) günlük seri! Haftalık hedefine ulaşmana az kaldı, bozma sakın."
        } else if days < 15 {
            return "Tam \(days) gündür durmuyorsun. Artık bu senin yaşam tarzın oldu."
        } else if days < 30 {
            return "Efsanevi bir \(days) günlük seri! Disiplin konusunda kimse eline su dökemez."
        } else {
            return "\(days) gündür süren bu maratonda sen artık bir idolsün kanka. 🔥"
        }
    }
    
    // MARK: - ⏰ 3. Katman: Zaman Analizi (Peak Hour)
    
    private func getTimeAnalysisSentence(hour: Int) -> String {
        switch hour {
        case 5...9:
            return "Sabahın sessizliğinde tam bir 'Early Bird' stratejisi izliyorsun."
        case 10...13:
            return "Öğle saatlerinin enerjisini mükemmel kullanıyorsun. Günün en verimli dilimi senin elinde."
        case 14...17:
            return "Öğleden sonra rehavetine kapılmadan çalışman takdire şayan."
        case 18...21:
            return "Akşam serinliğinde zihnin açılıyor gibi. Tempo düşmüyor."
        case 22...24, 0...4:
            return "Gece baykuşu modu aktif! Etraf sessizleşince senin asıl gücün ortaya çıkıyor kanka."
        default:
            return "Günün her saatinde hazır bir asker gibisin."
        }
    }
    
    // MARK: - ⏳ 4. Katman: Kazanç (Zaman Tasarrufu)
    
    private func getSavingsSentence(minutes: Int) -> String {
        if minutes <= 0 {
            return ""
        } else if minutes < 60 {
            return "Bugün kazandığın \(minutes) dakika, kendine ayırabileceğin en değerli ödül."
        } else {
            let hours = minutes / 60
            let extraMins = minutes % 60
            let timeString = extraMins > 0 ? "\(hours) saat \(extraMins) dk" : "\(hours) saat"
            return "Planlı çalışarak tam \(timeString) kazandın. Bunu hobilerinle değerlendir."
        }
    }
}
