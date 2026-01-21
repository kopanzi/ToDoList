import SwiftUI
import Foundation
import Combine
import AVFoundation

// 🛠️ DÜZELTME 1: Enum'ı Sınıfın DIŞINA aldık. Artık herkes onu tanıyor.
enum TimerModu {
    case kayit
    case oynatma
}

@MainActor
class NotViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    @Published var notlar: [NotModel] = []
    
    // 🚦 Durum Yönetimi
    // 0: Boş, 1: Kayıt Yapılıyor, 2: Kayıt Bitti
    @Published var kayitDurumu: Int = 0
    
    @Published var kayitDuraklatildiMi = false
    @Published var oynatiliyorMu = false
    
    @Published var sureMetni = "00:00"
    @Published var suankiSure: TimeInterval = 0.0
    @Published var toplamSure: TimeInterval = 0.0
    
    @Published var geciciSesData: Data?
    @Published var sliderIleOynuyorMu = false
    
    private var sesKayitCihazi: AVAudioRecorder?
    private var sesOynatici: AVAudioPlayer?
    private var zamanlayici: Timer?
    private let dataService = DataService()
    
    override init() {
        super.init()
        notlariGetir()
    }
    
    func notlariGetir() {
        notlar = dataService.notlariYukle()
    }
    
    // MARK: - Not Veri İşlemleri
    func notEkle(baslik: String, icerik: String, gorseller: [UIImage], ses: Data?) {
        var gorselVerileri: [Data] = []
        for resim in gorseller {
            if let data = resim.jpegData(compressionQuality: 0.5) {
                gorselVerileri.append(data)
            }
        }
        
        let yeniNot = NotModel(baslik: baslik, icerik: icerik, gorselVerileri: gorselVerileri, sesData: ses)
        notlar.append(yeniNot)
        dataService.notlariKaydet(notlar: notlar)
    }
    
    func notSil(indexSet: IndexSet) {
        notlar.remove(atOffsets: indexSet)
        dataService.notlariKaydet(notlar: notlar)
    }
    
    // MARK: - 🎙️ Ses Kayıt Motoru
    
    func kayitIsleminiBaslat() {
        if #available(iOS 17.0, *) {
            let permission = AVAudioApplication.shared.recordPermission
            if permission == .granted {
                Task { await self.gercekKaydiBaslat() }
            } else {
                AVAudioApplication.requestRecordPermission { granted in
                    if granted { Task { await self.gercekKaydiBaslat() } }
                }
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            if session.recordPermission == .granted {
                Task { await self.gercekKaydiBaslat() }
            } else {
                session.requestRecordPermission { granted in
                    if granted { Task { await self.gercekKaydiBaslat() } }
                }
            }
        }
    }
    
    private func gercekKaydiBaslat() async {
        let session = AVAudioSession.sharedInstance()
        do {
            // 🛠️ DÜZELTME 2: Bluetooth ayarı modern ve sade hale getirildi.
            // .allowBluetooth A2DP (Yüksek Kalite) için genelde yeterlidir.
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            
            let dosyaYolu = FileManager.default.temporaryDirectory.appendingPathComponent("gecici_not_kaydi.m4a")
            
            let ayarlar: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            sesKayitCihazi = try AVAudioRecorder(url: dosyaYolu, settings: ayarlar)
            sesKayitCihazi?.delegate = self
            
            if sesKayitCihazi?.record() == true {
                withAnimation {
                    self.kayitDurumu = 1
                    self.kayitDuraklatildiMi = false
                }
                self.geciciSesData = nil
                self.suankiSure = 0
                self.sureMetni = "00:00"
                // 🛠️ DÜZELTME 3: Enum artık dışarıda olduğu için .kayit diyebiliyoruz
                self.zamanlayiciyiBaslat(mod: .kayit)
                print("🎤 Kayıt Başladı")
            }
        } catch {
            print("🛑 Kayıt Hatası: \(error)")
        }
    }
    
    func kaydiDuraklatVeyaDevamEt() {
        guard let cihaz = sesKayitCihazi else { return }
        if cihaz.isRecording {
            cihaz.pause()
            kayitDuraklatildiMi = true
            zamanlayici?.invalidate()
        } else {
            cihaz.record()
            kayitDuraklatildiMi = false
            zamanlayiciyiBaslat(mod: .kayit)
        }
    }
    
    func kaydiBitir() {
        sesKayitCihazi?.stop()
        zamanlayici?.invalidate()
        
        let dosyaYolu = FileManager.default.temporaryDirectory.appendingPathComponent("gecici_not_kaydi.m4a")
        do {
            geciciSesData = try Data(contentsOf: dosyaYolu)
            let tmpPlayer = try AVAudioPlayer(data: geciciSesData!)
            toplamSure = tmpPlayer.duration
            suankiSure = 0
            
            withAnimation {
                self.kayitDurumu = 2
                self.kayitDuraklatildiMi = false
                self.oynatiliyorMu = false
            }
            print("✅ Kayıt Bitti")
        } catch { print("Veri Hatası: \(error)") }
    }
    
    func kaydiIptalEt() {
        sesKayitCihazi?.stop()
        sesOynatici?.stop()
        zamanlayici?.invalidate()
        
        withAnimation {
            self.kayitDurumu = 0
            self.kayitDuraklatildiMi = false
            self.oynatiliyorMu = false
            self.geciciSesData = nil
            self.suankiSure = 0
            self.toplamSure = 0
            self.sureMetni = "00:00"
        }
    }
    
    // MARK: - 🔊 Oynatma Motoru
    
    func sesiOynatVeyaDurdur() {
        guard let data = geciciSesData else { return }
        oynatmaMantigi(data: data)
    }
    
    func hariciSesiOynat(data: Data) {
        oynatmaMantigi(data: data)
    }
    
    private func oynatmaMantigi(data: Data) {
        if oynatiliyorMu {
            sesOynatici?.pause()
            oynatiliyorMu = false
            zamanlayici?.invalidate()
        } else {
            do {
                if sesOynatici?.data != data {
                    try AVAudioSession.sharedInstance().setCategory(.playback)
                    try AVAudioSession.sharedInstance().setActive(true)
                    sesOynatici = try AVAudioPlayer(data: data)
                    sesOynatici?.delegate = self
                    sesOynatici?.prepareToPlay()
                }
                sesOynatici?.play()
                oynatiliyorMu = true
                toplamSure = sesOynatici?.duration ?? 0.0
                zamanlayiciyiBaslat(mod: .oynatma)
            } catch { print("Oynatma Hatası: \(error)") }
        }
    }
    
    func zamanaGit(saniye: TimeInterval) {
        sesOynatici?.currentTime = saniye
        suankiSure = saniye
    }
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.oynatiliyorMu = false
            self.suankiSure = 0
            self.zamanlayici?.invalidate()
            self.sesOynatici?.currentTime = 0
        }
    }
    
    // MARK: - ⏱ Timer Logic
    
    private func zamanlayiciyiBaslat(mod: TimerModu) {
        zamanlayici?.invalidate()
        zamanlayici = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.sliderIleOynuyorMu { return }
                
                if mod == .kayit, let cihaz = self.sesKayitCihazi {
                    self.suankiSure = cihaz.currentTime
                    self.sureMetni = self.timeString(time: cihaz.currentTime)
                } else if let oynatici = self.sesOynatici {
                    self.suankiSure = oynatici.currentTime
                }
            }
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        let dakika = Int(time) / 60
        let saniye = Int(time) % 60
        return String(format: "%02d:%02d", dakika, saniye)
    }
}
