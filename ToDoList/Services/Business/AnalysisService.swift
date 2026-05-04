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
    /// - Parameters:
    ///   - completionRate: Görev tamamlama oranı (0.0 ile 1.0 arası)
    ///   - streak: Peş peşe görev tamamlanan gün sayısı
    ///   - peakHour: En verimli olunan saatin başlangıcı (Örn: 9, 14, 22)
    ///   - timeSavedInMinutes: Kazanılan toplam zaman (Dakika cinsinden)
    /// - Returns: Birleştirilmiş, akıcı ve motive edici Yaver tavsiyesi.
    func generateReport(completionRate: Double, streak: Int, peakHour: Int, timeSavedInMinutes: Int) -> String {
        let statusPart = getStatusSentence(rate: completionRate)
        let streakPart = getStreakSentence(days: streak)
        let timePart = getTimeAnalysisSentence(hour: peakHour)
        let savingsPart = getSavingsSentence(minutes: timeSavedInMinutes)
        
        // Rastgele birleştirme bağlaçları kullanarak doğal dil akışı (Natural Language Flow) sağlarız.
        // Bu sayede aynı cümleler yan yana gelse bile her seferinde farklı bir insan yazmış gibi hissettirir.
        let separators = [
            " ",
            " Ayrıca, ",
            " Bununla birlikte, ",
            " Unutma ki; ",
            " Üstelik, ",
            " Şunu da ekleyelim: "
        ]
        
        return "\(statusPart)\(separators.randomElement() ?? " ")\(streakPart) \(timePart) \(savingsPart)"
    }
    
    // MARK: - 📊 1. Katman: Genel Durum (Bitirme Oranı)
    
    private func getStatusSentence(rate: Double) -> String {
        switch rate {
        case 0...0.1:
            return [
                "Bugün motorları ısıtmakta biraz zorlanıyoruz kanka. Ama sorun değil, en küçük adımla başlayalım.",
                "Yaver bugün biraz yalnız kalmış, görev listesi henüz el değmemiş duruyor.",
                "Sakin bir başlangıç... Bazen sadece izlemek gerekir ama bugün o gün değil!",
                "Sayfa bomboş, hadi bir yerden tutup Yaver'i sevindirelim."
            ].randomElement()!
            
        case 0.11...0.35:
            return [
                "Isınma turları tamam, şimdi vites yükseltme zamanı. Tempo yavaş ama yön doğru.",
                "Fena değil, ilk engelleri aştık. Biraz daha odaklanırsan akıp gidecek.",
                "Yavaş yavaş ritim buluyoruz. Küçük adımlar büyük sonuçlara gebedir.",
                "Yolun başındasın ama ilerliyorsun. Bu hızı ikiye katlayabiliriz!"
            ].randomElement()!
            
        case 0.36...0.65:
            return [
                "Gayet iyi bir tempo! İşlerin neredeyse yarısını paketlemişsin, durmak yok.",
                "Orta saha mücadelesini kazandık, şimdi golü atma vakti. Verimliliğin artıyor.",
                "İstikrarlı bir ilerleyiş... Yaver bu tempoyu çok sevdi!",
                "Günün yarısı bitti, görevlerin de öyle. Harika bir denge kurmuşsun."
            ].randomElement()!
            
        case 0.66...0.90:
            return [
                "Şov yapıyorsun kanka! Listenin bitmesine ramak kaldı, odak seviyen tavan yapmış.",
                "Tam bir verimlilik makinesine dönüştün. Kalan birkaç işi de çerez niyetine halledersin.",
                "Yaver bugün seninle gurur duyuyor. Neredeyse her şeyi temizledin!",
                "Üst düzey performans! Bugün bitirdiğin işler yarının yükünü şimdiden azalttı."
            ].randomElement()!
            
        default:
            return [
                "Kusursuz zafer! Listede bitmemiş tek bir nokta bile bırakmadın. Tam bir canavarsın!",
                "Bugün masadan galip ayrılan sensin. Bütün görevleri dize getirdin. 🚀",
                "Efsanevi bir gün! Odaklanma konusundaki ustalığını bir kez daha kanıtladın.",
                "Her şey bitti kanka! Şimdi arkana yaslan ve başarının tadını çıkar."
            ].randomElement()!
        }
    }
    
    // MARK: - 🔥 2. Katman: Seri (Streak Analizi)
    
    private func getStreakSentence(days: Int) -> String {
        if days == 0 {
            return [
                "Seri başlatmak için bugün harika bir fırsat.",
                "Yeni bir serinin ilk ateşini bugün yakabilirsin."
            ].randomElement()!
        } else if days < 3 {
            return [
                "\(days) gündür sahadayız. Alışkanlıklar yavaş yavaş kemikleşiyor.",
                "İvme kazanıyoruz. \(days) günlük bu mini seriyi korumaya odaklan."
            ].randomElement()!
        } else if days < 7 {
            return [
                "\(days) günlük seri! Haftalık hedefine ulaşmana az kaldı, bozma sakın.",
                "Durdurulamaz bir momentum. \(days) gündür ateş ediyorsun."
            ].randomElement()!
        } else if days < 15 {
            return [
                "Tam \(days) gündür durmuyorsun. Artık bu senin yaşam tarzın oldu.",
                "İnanılmaz bir disiplin. \(days) günlük seri herkesin yapabileceği bir şey değil."
            ].randomElement()!
        } else if days < 30 {
            return [
                "Efsanevi bir \(days) günlük seri! Disiplin konusunda kimse eline su dökemez.",
                "Artık alışkanlıkların beton gibi sağlam. \(days) gün dile kolay!"
            ].randomElement()!
        } else {
            return [
                "\(days) gündür süren bu maratonda sen artık bir idolsün kanka. 🔥",
                "Bu seviyedeki bir seri (\(days) gün) sadece ustalara özgüdür. Saygılar!"
            ].randomElement()!
        }
    }
    
    // MARK: - ⏰ 3. Katman: Zaman Analizi (Zirve Saati)
    
    private func getTimeAnalysisSentence(hour: Int) -> String {
        switch hour {
        case 5...9:
            return [
                "Sabahın sessizliğinde tam bir 'Early Bird' stratejisi izliyorsun. En zor işleri bu saatte bitirmen dâhice.",
                "Erken kalkan yol alır sözünün canlı kanıtısın. Sabah enerjini mükemmel kullanıyorsun."
            ].randomElement()!
        case 10...13:
            return [
                "Öğle saatlerinin enerjisini mükemmel kullanıyorsun. Günün en verimli dilimi senin elinde.",
                "Güne tam oturmuş bir tempo. Öğle vakti odaklanma gücün zirveye ulaşıyor."
            ].randomElement()!
        case 14...17:
            return [
                "Öğleden sonra rehavetine kapılmadan çalışman takdire şayan. Odaklanma eşiğin çok yüksek.",
                "Günün yorucu kısmında bile ivmeni kaybetmiyorsun. Harika bir dayanıklılık."
            ].randomElement()!
        case 18...21:
            return [
                "Akşam serinliğinde zihnin açılıyor gibi. Günün yorgunluğuna rağmen tempo düşmüyor.",
                "Çoğu kişi dinlenirken sen fark yaratıyorsun. Akşam mesaisi sana çok yarıyor."
            ].randomElement()!
        case 22...24, 0...4:
            return [
                "Gece baykuşu modu aktif! Etraf sessizleşince senin asıl gücün ortaya çıkıyor kanka.",
                "Karanlıkta parlayan bir zihin... Gece saatleri senin üretim depon olmuş."
            ].randomElement()!
        default:
            return "Günün her saatinde hazır bir asker gibisin."
        }
    }
    
    // MARK: - ⏳ 4. Katman: Kazanç (Zaman Tasarrufu)
    
    private func getSavingsSentence(minutes: Int) -> String {
        if minutes == 0 {
            return ""
        } else if minutes < 60 {
            return [
                "Bugün kazandığın \(minutes) dakika, kendine ayırabileceğin en değerli ödül.",
                "Odaklanarak tam \(minutes) dakika tasarruf ettin. Bu süreyi bir kahveyle taçlandır!"
            ].randomElement()!
        } else {
            let hours = minutes / 60
            let extraMins = minutes % 60
            let timeString = extraMins > 0 ? "\(hours) saat \(extraMins) dk" : "\(hours) saat"
            
            return [
                "Planlı çalışarak tam \(timeString) kazandın. Bu devasa zamanı ister dinlenerek, ister hobilerinle değerlendir.",
                "Zamanı büküyorsun! Kazandığın bu \(timeString) senin organizasyon gücünün en büyük ispatı."
            ].randomElement()!
        }
    }
}
