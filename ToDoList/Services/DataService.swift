import Foundation

class DataService {
    
    // Verileri kaydettiğimiz "Kasa Anahtarı"
    private let kayitAnahtari = "gorevler_listesi"
    
    // Verileri Kaydet
    func kaydet(gorevler: [GorevModel]) {
        // 1. Veriyi JSON'a çevir (Encode)
        if let encodedData = try? JSONEncoder().encode(gorevler) {
            // 2. Diske yaz
            UserDefaults.standard.set(encodedData, forKey: kayitAnahtari)
            print("Veriler başarıyla kaydedildi! Adet: \(gorevler.count)")
        }
    }
    
    // Verileri Yükle
    func yukle() -> [GorevModel] {
        // 1. Diskten veriyi oku
        guard let data = UserDefaults.standard.data(forKey: kayitAnahtari) else {
            return [] // Eğer veri yoksa boş liste dön
        }
        
        // 2. JSON'u modele çevir (Decode)
        if let decodedGorevler = try? JSONDecoder().decode([GorevModel].self, from: data) {
            return decodedGorevler
        }
        
        return []
    }
}
