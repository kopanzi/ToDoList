import Foundation

class DataService {
    
    // --- GÖREVLER İÇİN ANAHTAR ---
    private let gorevKayitAnahtari = "gorev_listesi_v1"
    
    // --- NOTLAR İÇİN YENİ ANAHTAR ---
    private let notKayitAnahtari = "not_listesi_v1"
    
    // MARK: - GÖREV İŞLEMLERİ (MEVCUT SİSTEM)
    func kaydet(gorevler: [GorevModel]) {
        do {
            let encodedData = try JSONEncoder().encode(gorevler)
            UserDefaults.standard.set(encodedData, forKey: gorevKayitAnahtari)
            print("💾 DataService: \(gorevler.count) görev başarıyla diske yazıldı.")
        } catch {
            print("🛑 DataService Görev Kayıt Hatası: \(error.localizedDescription)")
        }
    }
    
    func yukle() -> [GorevModel] {
        guard let data = UserDefaults.standard.data(forKey: gorevKayitAnahtari) else {
            return []
        }
        do {
            let decodedGorevler = try JSONDecoder().decode([GorevModel].self, from: data)
            return decodedGorevler
        } catch {
            print("🛑 DataService Görev Okuma Hatası: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - NOT İŞLEMLERİ (YENİ SİSTEM) 📝
    func notlariKaydet(notlar: [NotModel]) {
        do {
            let encodedData = try JSONEncoder().encode(notlar)
            UserDefaults.standard.set(encodedData, forKey: notKayitAnahtari)
            print("💾 DataService: \(notlar.count) not başarıyla diske yazıldı.")
        } catch {
            print("🛑 DataService Not Kayıt Hatası: \(error.localizedDescription)")
        }
    }
    
    func notlariYukle() -> [NotModel] {
        guard let data = UserDefaults.standard.data(forKey: notKayitAnahtari) else {
            return []
        }
        do {
            let decodedNotlar = try JSONDecoder().decode([NotModel].self, from: data)
            return decodedNotlar
        } catch {
            print("🛑 DataService Not Okuma Hatası: \(error.localizedDescription)")
            return []
        }
    }
}
