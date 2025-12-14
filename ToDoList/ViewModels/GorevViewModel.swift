import SwiftUI
import Combine

class GorevViewModel: ObservableObject {
    @Published var gorevler: [GorevModel] = [] {
        didSet {
            dataService.kaydet(gorevler: gorevler)
        }
    }
    
    // AI Değişkenleri
    @Published var aiYaniti: String = ""
    @Published var aiMesgulMu: Bool = false
    
    private let dataService = DataService()
    private let notificationManager = NotificationManager.shared
    
    // YENİ: Gemini Servisini çağırıyoruz
    private let geminiService = GeminiService()
    
    init() {
        let kayitliGorevler = dataService.yukle()
        gorevler = kayitliGorevler.isEmpty ? [] : kayitliGorevler
        notificationManager.izinIste()
    }
    
    func gorevEkle(baslik: String, onem: OnemDerecesi, tarih: Date) {
        let yeni = GorevModel(baslik: baslik, onem: onem, tarih: tarih)
        gorevler.append(yeni)
        sirala()
        notificationManager.bildirimPlanla(gorev: yeni)
    }
    
    func gorevSil(at offsets: IndexSet) {
        offsets.forEach { index in
            let gorev = gorevler[index]
            notificationManager.bildirimIptalEt(id: gorev.id)
        }
        gorevler.remove(atOffsets: offsets)
    }
    
    func durumDegistir(gorev: GorevModel) {
        if let index = gorevler.firstIndex(where: { $0.id == gorev.id }) {
            gorevler[index].tamamlandi.toggle()
            dataService.kaydet(gorevler: gorevler)
            
            if gorevler[index].tamamlandi {
                notificationManager.bildirimIptalEt(id: gorev.id)
            } else {
                notificationManager.bildirimPlanla(gorev: gorevler[index])
            }
        }
    }
    
    private func sirala() {
        gorevler.sort { $0.tarih < $1.tarih }
    }
    
    // AI Fonksiyonu
    @MainActor
    func yapayZekayaDanis(gorev: GorevModel) async {
        aiMesgulMu = true
        aiYaniti = ""
        
        if let cevap = await geminiService.oneriAl(gorevBasligi: gorev.baslik) {
            aiYaniti = cevap
        } else {
            aiYaniti = "Bağlantı hatası. İnternetini kontrol et."
        }
        
        aiMesgulMu = false
    }
}
