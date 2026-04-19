import Foundation
import AVFoundation
import Combine

/// Ses kayıt ve oynatma işlemlerini yöneten merkezi servis.
/// Senior Notu: Slider ile saniyeler arası geçiş (seeking) yeteneği eklenmiştir.
final class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentProgress: Double = 0
    @Published var totalDuration: Double = 0
    
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    private override init() { super.init() }
    
    // MARK: - Playback Control
    
    func playAudio(data: Data) {
        do {
            // Eğer zaten başka bir şey çalıyorsa durdur
            if isPlaying { stopPlayback() }
            
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            
            isPlaying = true
            totalDuration = player?.duration ?? 0
            startTimer()
        } catch {
            print("🛑 Playback Error: \(error)")
        }
    }
    
    func stopPlayback() {
        player?.stop()
        isPlaying = false
        currentProgress = 0
        stopTimer()
    }
    
    func togglePause() {
        guard let player = player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    /// 🎚️ Slider üzerinden saniyeye atlama (Instagram/Spotify tarzı)
    func seek(to time: Double) {
        player?.currentTime = time
        currentProgress = time
    }
    
    // MARK: - Recording Logic
    
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
            
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("temp.m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
            startTimer()
        } catch {
            print("🛑 Recording Error: \(error)")
        }
    }
    
    func stopRecording() -> Data? {
        recorder?.stop()
        isRecording = false
        stopTimer()
        if let url = recorder?.url {
            return try? Data(contentsOf: url)
        }
        return nil
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isRecording {
                self.currentProgress = self.recorder?.currentTime ?? 0
            } else if self.isPlaying {
                self.currentProgress = self.player?.currentTime ?? 0
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentProgress = 0
        stopTimer()
    }
}
