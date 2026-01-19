import Foundation
import AVFoundation
import Combine

class SesYoneticisi: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var sesKayitCihazi: AVAudioRecorder?
    var sesOynatici: AVAudioPlayer?
    private var zamanlayici: Timer? // ⏱ Slider'ı ilerletmek için
    
    @Published var kayitYapiliyor = false
    @Published var oynatiliyor = false
    @Published var sesVerisi: Data? = nil
    
    // 🆕 YENİ ÖZELLİKLER
    @Published var suankiSure: TimeInterval = 0.0
    @Published var toplamSure: TimeInterval = 0.0
    @Published var oynatmaHizi: Float = 1.0
    
    override init() {
        super.init()
    }
    
    // --- MİKROFON / KAYIT KISMI (AYNI) ---
    func kaydiBaslat() {
        if #available(iOS 17.0, *) {
            let permission = AVAudioApplication.shared.recordPermission
            if permission == .granted { self.kaydiGerceklestir() }
            else {
                AVAudioApplication.requestRecordPermission { granted in
                    if granted { DispatchQueue.main.async { self.kaydiGerceklestir() } }
                }
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            if session.recordPermission == .granted { self.kaydiGerceklestir() }
            else {
                session.requestRecordPermission { granted in
                    if granted { DispatchQueue.main.async { self.kaydiGerceklestir() } }
                }
            }
        }
    }
    
    private func kaydiGerceklestir() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
            
            let dosyaAdi = getDocumentsDirectory().appendingPathComponent("gecici_kayit.m4a")
            let ayarlar = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            sesKayitCihazi = try AVAudioRecorder(url: dosyaAdi, settings: ayarlar)
            sesKayitCihazi?.delegate = self
            
            if sesKayitCihazi?.record() == true {
                DispatchQueue.main.async {
                    self.kayitYapiliyor = true
                    // Kayıt başlarken eski verileri sıfırla
                    self.suankiSure = 0
                    self.toplamSure = 0
                }
            }
        } catch { print("Hata: \(error)") }
    }
    
    func kaydiDurdur() {
        sesKayitCihazi?.stop()
        kayitYapiliyor = false
        
        let dosyaUrl = getDocumentsDirectory().appendingPathComponent("gecici_kayit.m4a")
        do {
            sesVerisi = try Data(contentsOf: dosyaUrl)
        } catch { print("Veri hatası: \(error)") }
    }
    
    // --- OYNATMA KISMI (GÜNCELLENDİ) 🚀 ---
    
    func sesiOynat(data: Data) {
        do {
            // Eğer zaten varsa ve duraklatılmışsa devam ettir
            if let oynatici = sesOynatici, !oynatici.isPlaying {
                oynatici.play()
                oynatiliyor = true
                zamanlayiciyiBaslat()
                return
            }
            
            // Sıfırdan başlatma
            sesOynatici = try AVAudioPlayer(data: data)
            sesOynatici?.delegate = self
            sesOynatici?.enableRate = true // ⚠️ Hız değişimi için şart!
            sesOynatici?.rate = oynatmaHizi
            sesOynatici?.prepareToPlay()
            sesOynatici?.play()
            
            toplamSure = sesOynatici?.duration ?? 0.0
            oynatiliyor = true
            zamanlayiciyiBaslat()
            
        } catch { print("Oynatma hatası: \(error)") }
    }
    
    func oynatmayiDurdur() {
        sesOynatici?.pause()
        oynatiliyor = false
        zamanlayici?.invalidate() // Timer'ı durdur
    }
    
    // ⏩ Sardırma Fonksiyonu
    func zamanaGit(saniye: TimeInterval) {
        sesOynatici?.currentTime = saniye
        suankiSure = saniye // UI anlık güncellensin
    }
    
    // 🐇 Hız Değiştirme
    func hiziAyarla(hiz: Float) {
        oynatmaHizi = hiz
        if let oynatici = sesOynatici, oynatici.enableRate {
            oynatici.rate = hiz
            // Eğer çalıyorsa hızı anında uygular
            if oynatiliyor { oynatici.play() }
        }
    }
    
    // ⏱ Timer: Slider'ı her saniye ilerletir
    private func zamanlayiciyiBaslat() {
        zamanlayici?.invalidate()
        zamanlayici = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let oynatici = self.sesOynatici {
                self.suankiSure = oynatici.currentTime
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        oynatiliyor = false
        suankiSure = 0
        zamanlayici?.invalidate()
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
