import Foundation
import SwiftUI
import AVFoundation
import Combine
import LocalAuthentication
import EventKit
import WidgetKit // ✅ Widget kütüphanesi şart

class GorevViewModel: ObservableObject {
    
    @Published var gorevler: [GorevModel] = [] {
        didSet {
            dataService.kaydet(gorevler: gorevler)
            widgetiGuncelle() // ✨ YENİ: Görev listesi değişince Widget'a haber ver
        }
    }
    
    private let dataService = DataService()
    
    // 🎮 GAMIFICATION & WIDGET ENTEGRASYONU
    @Published var kullaniciXP: Int {
        didSet {
            // 1. Standart Hafızaya Kaydet
            UserDefaults.standard.set(kullaniciXP, forKey: "kullaniciXP")
            
            // 2. Widget'ı Güncelle (XP değişince de güncelle ki rütbe artsın)
            widgetiGuncelle()
        }
    }
    
    // 🔒 GİZLİ KASA DURUMU
    @Published var kasaAcik: Bool = false
    
    // RÜTBE HESAPLAMA
    var rutbe: (isim: String, ikon: String, renk: Color) {
        switch kullaniciXP {
        case 0..<50: return ("Çırak", "hammer.fill", .gray)
        case 50..<150: return ("Kalfa", "wrench.and.screwdriver.fill", .blue)
        case 150..<300: return ("Usta", "star.fill", .orange)
        case 300..<600: return ("Efsane", "crown.fill", .purple)
        default: return ("Tosun Paşa", "trophy.fill", .yellow)
        }
    }
    
    var rutbeIlerlemesi: Double {
        let xp = Double(kullaniciXP)
        switch xp {
        case 0..<50: return xp / 50.0
        case 50..<150: return (xp - 50) / 100.0
        case 150..<300: return (xp - 150) / 150.0
        case 300..<600: return (xp - 300) / 300.0
        default: return 1.0
        }
    }
    
    init() {
        self.kullaniciXP = UserDefaults.standard.integer(forKey: "kullaniciXP")
        verileriYukle()
    }
    
    // --- 🔒 FACEID İŞLEMLERİ ---
    func kasaKilidiniAc() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let sebep = "Gizli görevlerinizi görmek için kimliğinizi doğrulayın."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: sebep) { basarili, authenticationError in
                DispatchQueue.main.async {
                    if basarili {
                        self.kasaAcik = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { self.kasaAcik = false }
                    } else { self.kasaAcik = false }
                }
            }
        } else {
            print("FaceID kullanılamıyor.")
            self.kasaAcik = true
        }
    }
    
    func kasayiKilitle() {
        withAnimation { self.kasaAcik = false }
    }
    
    // --- TEMEL İŞLEVLER ---
    func gorevEkle(baslik: String, onem: OnemDerecesi, tarih: Date, gizliMi: Bool, kategori: Kategori? = nil) {
        let yeniGorev = GorevModel(
            baslik: baslik,
            onem: onem,
            kategori: kategori,
            tarih: tarih,
            gizliMi: gizliMi
        )
        gorevler.append(yeniGorev)
    }
    
    func gorevSil(at offsets: IndexSet) {
        gorevler.remove(atOffsets: offsets)
    }
    
    func gorevTasi(from source: IndexSet, to destination: Int) {
        gorevler.move(fromOffsets: source, toOffset: destination)
    }
    
    func durumDegistir(gorev: GorevModel) -> Bool {
        if let index = gorevler.firstIndex(where: { $0.id == gorev.id }) {
            gorevler[index].tamamlandi.toggle()
            if gorevler[index].tamamlandi {
                kullaniciXP += 10
                return true
            } else {
                kullaniciXP = max(0, kullaniciXP - 10)
                return false
            }
        }
        return false
    }
    
    func pomodoroBonusuVer() -> Bool {
        kullaniciXP += 20
        return true
    }
    
    // --- EKSTRALAR ---
    func notuGuncelle(gorev: GorevModel, yeniNot: String) {
        if let index = gorevler.firstIndex(where: { $0.id == gorev.id }) { gorevler[index].not = yeniNot }
    }
    func gorselleriEkle(gorev: GorevModel, yeniGorseller: [UIImage]) {
        if let index = gorevler.firstIndex(where: { $0.id == gorev.id }) {
            for g in yeniGorseller { if let d = g.jpegData(compressionQuality: 0.5) { gorevler[index].gorselListesi.append(d) } }
        }
    }
    func gorselSil(gorev: GorevModel, gorselIndex: Int) {
        if let index = gorevler.firstIndex(where: { $0.id == gorev.id }), gorselIndex < gorevler[index].gorselListesi.count {
            gorevler[index].gorselListesi.remove(at: gorselIndex)
        }
    }
    func sesKaydiniGuncelle(gorev: GorevModel, sesData: Data?) {
        if let index = gorevler.firstIndex(where: { $0.id == gorev.id }) { gorevler[index].sesKaydiData = sesData }
    }
    
    // --- KAYIT SİSTEMİ ---
    func kaydet() {
        dataService.kaydet(gorevler: gorevler)
    }
    
    func verileriYukle() {
        gorevler = dataService.yukle()
    }
    
    // --- 📡 WIDGET GÜNCELLEME (YENİ EKLENDİ) ---
    func widgetiGuncelle() {
        // 1. Ortak Kasayı (App Group) Aç
        // BURASI ÇOK ÖNEMLİ: Xcode'da "Signing & Capabilities" kısmında eklediğin Group ID ile AYNI olmalı.
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.kopanzi.yaver") else { return }
        
        // 2. XP'yi Ortak Alana Yaz
        sharedDefaults.set(kullaniciXP, forKey: "kullaniciXP")
        
        // 3. Görevleri Hazırla (Tamamlanmamış, En önemli 3 tanesi)
        let widgetGorevleri = gorevler
            .filter { !$0.tamamlandi && !$0.gizliMi } // Gizlileri ve bitmişleri ele
            .sorted { $0.tarih < $1.tarih } // Tarihe göre sırala (En yakın en üstte)
            .prefix(3) // Sadece ilk 3 tanesini al
            .map { $0 } // Array slice'ı Array'e çevir
            
        // 4. JSON'a Çevirip Kaydet
        if let encoded = try? JSONEncoder().encode(widgetGorevleri) {
            sharedDefaults.set(encoded, forKey: "widgetGorevler")
        }
        
        // 5. Widget'ı Dürt (Yenilenmesini sağla)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // --- 📅 TAKVİM ENTEGRASYONU ---
    func takvimeEkle(gorev: GorevModel) {
        let eventStore = EKEventStore()
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { (granted, error) in
                if granted && error == nil { self.olusturVeKaydet(store: eventStore, gorev: gorev) }
            }
        } else {
            eventStore.requestAccess(to: .event) { (granted, error) in
                if granted && error == nil { self.olusturVeKaydet(store: eventStore, gorev: gorev) }
            }
        }
    }
    
    private func olusturVeKaydet(store: EKEventStore, gorev: GorevModel) {
        let event = EKEvent(eventStore: store)
        event.title = gorev.baslik
        event.startDate = gorev.tarih
        event.endDate = gorev.tarih.addingTimeInterval(3600)
        
        var notIcerigi = "Bu görev YAVER üzerinden eklendi. 🦁"
        if let kat = gorev.kategori {
            notIcerigi += "\nKategori: \(kat.rawValue)"
        }
        event.notes = notIcerigi
        
        event.calendar = store.defaultCalendarForNewEvents
        
        do {
            try store.save(event, span: .thisEvent)
            print("✅ Takvime başarıyla eklendi!")
        } catch let error as NSError {
            print("🛑 Takvim hatası: \(error.localizedDescription)")
        }
    }
}
