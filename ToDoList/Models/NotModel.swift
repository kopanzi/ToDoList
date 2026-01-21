import Foundation

struct NotModel: Identifiable, Codable {
    let id: String
    let baslik: String
    let icerik: String
    let tarih: Date
    
    init(id: String = UUID().uuidString, baslik: String, icerik: String, tarih: Date = Date()) {
        self.id = id
        self.baslik = baslik
        self.icerik = icerik
        self.tarih = tarih
    }
}
