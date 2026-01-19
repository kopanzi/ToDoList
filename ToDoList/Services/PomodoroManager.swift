import Foundation
import SwiftUI
import Combine

class PomodoroManager: ObservableObject {
    // Singleton: Uygulamanın her yerinden ulaşılabilen tek patron.
    static let shared = PomodoroManager()
    
    // YAYIN YAPILAN DEĞİŞKENLER (UI bunları dinleyecek)
    @Published var kalanSure: TimeInterval = 25 * 60
    @Published var toplamSure: TimeInterval = 25 * 60
    @Published var calisiyor: Bool = false
    @Published var molaModu: Bool = false
    
    // Hangi görev üzerinde çalışıyoruz? (Opsiyonel)
    @Published var aktifGorevId: String? = nil
    
    private var bitisZamani: Date?
    private var timer: Timer?
    
    // Arka planda bildirim atmak için
    private let notificationManager = NotificationManager.shared
    
    private init() {} // Başkası kafasına göre yeni manager oluşturamasın.
    
    // --- FONKSİYONLAR ---
    
    func baslat(gorevId: String?) {
        // Eğer zaten çalışıyorsa dokunma
        guard !calisiyor else { return }
        
        calisiyor = true
        aktifGorevId = gorevId
        
        // Hedef saati belirliyoruz (Şu an + Kalan Süre)
        bitisZamani = Date().addingTimeInterval(kalanSure)
        
        // Sayacı başlat
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.zamanKontrol()
        }
    }
    
    func durdur() {
        calisiyor = false
        timer?.invalidate()
        timer = nil
        // Durdurduğumuzda kalan süreyi sabitliyoruz, böylece devam edince oradan başlar.
    }
    
    func sifirla() {
        durdur()
        molaModu = false
        toplamSure = 25 * 60
        kalanSure = 25 * 60
        aktifGorevId = nil
    }
    
    private func zamanKontrol() {
        guard let bitis = bitisZamani else { return }
        let simdi = Date()
        
        if simdi >= bitis {
            // SÜRE BİTTİ!
            sureBitti()
        } else {
            // Kalan süreyi güncelle
            kalanSure = bitis.timeIntervalSince(simdi)
        }
    }
    
    private func sureBitti() {
        durdur()
        kalanSure = 0
        
        // Bildirim Gönder 🔔
        let baslik = molaModu ? "Mola Bitti! ☕️" : "Odaklanma Tamamlandı! 🍅"
        let icerik = molaModu ? "Hadi işe geri dön." : "Harikasın! Şimdi kısa bir mola ver."
        notificationManager.anlikBildirimGonder(baslik: baslik, icerik: icerik)
        
        // Otomatik Mod Değişimi
        if !molaModu {
            // Çalışma bitti -> Molaya geç
            molaModu = true
            toplamSure = 5 * 60
            kalanSure = 5 * 60
            // İstersen molayı otomatik başlatabilirsin veya kullanıcının basmasını bekleyebilirsin.
            // Biz kullanıcının basmasını bekleyelim.
        } else {
            // Mola bitti -> Çalışmaya dön
            molaModu = false
            toplamSure = 25 * 60
            kalanSure = 25 * 60
        }
    }
}
