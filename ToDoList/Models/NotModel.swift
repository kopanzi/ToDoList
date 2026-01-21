import Foundation

struct NotModel: Identifiable, Codable {
    let id: String
    let baslik: String
    let icerik: String
    let tarih: Date
    
    // 🆕 ARTIK LİSTE TUTUYORUZ (Eskiden 'gorselData' idi)
    let gorselVerileri: [Data]
    
    let sesData: Data?
    
    init(id: String = UUID().uuidString,
         baslik: String,
         icerik: String,
         tarih: Date = Date(),
         gorselVerileri: [Data] = [], // Varsayılan boş liste
         sesData: Data? = nil) {
        
        self.id = id
        self.baslik = baslik
        self.icerik = icerik
        self.tarih = tarih
        self.gorselVerileri = gorselVerileri
        self.sesData = sesData
    }
}
