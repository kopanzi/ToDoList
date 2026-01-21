import Foundation

class DataService {
    
    // MARK: - Anahtarlar (Keys)
    private let gorevKayitAnahtari = "gorev_listesi_v1"
    private let notKayitAnahtari = "not_listesi_v1"
    
    // MARK: - Generic Yardımcı Fonksiyonlar (Clean Code 🌟)
    // Bu iki fonksiyon, her türlü veriyi (Görev, Not, vs.) kaydetmek için kullanılabilir.
    
    private func veriyiKaydet<T: Codable>(items: [T], key: String) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: key)
            print("💾 DataService: \(items.count) öğe (\(key)) başarıyla kaydedildi.")
        } catch {
            print("🛑 DataService Kayıt Hatası (\(key)): \(error.localizedDescription)")
        }
    }
    
    private func veriyiYukle<T: Codable>(key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            print("📂 DataService: \(key) için veri bulunamadı, boş liste dönülüyor.")
            return []
        }
        do {
            let items = try JSONDecoder().decode([T].self, from: data)
            print("📂 DataService: \(items.count) öğe (\(key)) yüklendi.")
            return items
        } catch {
            print("🛑 DataService Okuma Hatası (\(key)): \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Görev İşlemleri (Mevcut Yapı Korundu)
    func kaydet(gorevler: [GorevModel]) {
        veriyiKaydet(items: gorevler, key: gorevKayitAnahtari)
    }
    
    func yukle() -> [GorevModel] {
        return veriyiYukle(key: gorevKayitAnahtari)
    }
    
    // MARK: - Not İşlemleri (YENİ ✅)
    // ViewModel artık bu fonksiyonları kullanacak
    func notlariKaydet(notlar: [NotModel]) {
        veriyiKaydet(items: notlar, key: notKayitAnahtari)
    }
    
    func notlariYukle() -> [NotModel] {
        return veriyiYukle(key: notKayitAnahtari)
    }
}
