import SwiftUI // 👈 İşte eksik olan parça buydu!
import Foundation
import Combine

class NotViewModel: ObservableObject {
    @Published var notlar: [NotModel] = []
    private let dataService = DataService()
    
    init() {
        notlariGetir()
    }
    
    func notlariGetir() {
        notlar = dataService.notlariYukle()
    }
    
    func notEkle(baslik: String, icerik: String) {
        let yeniNot = NotModel(baslik: baslik, icerik: icerik)
        notlar.append(yeniNot)
        dataService.notlariKaydet(notlar: notlar)
    }
    
    func notSil(indexSet: IndexSet) {
        notlar.remove(atOffsets: indexSet)
        dataService.notlariKaydet(notlar: notlar)
    }
}
