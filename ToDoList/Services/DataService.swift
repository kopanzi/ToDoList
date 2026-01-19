import Foundation

class DataService {
    
    // 🔑 KRİTİK: ViewModel'deki anahtarın AYNISINI kullanıyoruz.
    // Bunu değiştirirsek eski verilerin ve sihirli değnekle eklediğin notların görünmez!
    private let kayitAnahtari = "gorev_listesi_v1"
    
    // Verileri Kaydet
    func kaydet(gorevler: [GorevModel]) {
        do {
            let encodedData = try JSONEncoder().encode(gorevler)
            UserDefaults.standard.set(encodedData, forKey: kayitAnahtari)
            // Debug için log (İstersen silebilirsin)
            print("💾 DataService: \(gorevler.count) görev başarıyla diske yazıldı.")
        } catch {
            print("🛑 DataService Kayıt Hatası: \(error.localizedDescription)")
        }
    }
    
    // Verileri Yükle
    func yukle() -> [GorevModel] {
        guard let data = UserDefaults.standard.data(forKey: kayitAnahtari) else {
            print("📂 DataService: Kayıtlı veri bulunamadı, boş liste dönülüyor.")
            return []
        }
        
        do {
            let decodedGorevler = try JSONDecoder().decode([GorevModel].self, from: data)
            print("📂 DataService: \(decodedGorevler.count) görev yüklendi.")
            return decodedGorevler
        } catch {
            print("🛑 DataService Okuma Hatası: \(error.localizedDescription)")
            return []
        }
    }
}
