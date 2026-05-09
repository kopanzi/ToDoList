import Foundation
import SwiftUI
import Combine

/// Notlar üzerindeki tüm iş mantığını ve medya kayıt süreçlerini yöneten ana ViewModel.
/// Senior Notu: View katmanının model dizisine doğrudan müdahale etmesini engellemek için
/// tam MVVM izolasyonu sağlanmıştır. Çoklu Ses desteği (Multi-Audio) eklenmiştir.
@MainActor
final class NoteViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    
    /// Tüm notların listesi. Herhangi bir değişiklik olduğunda otomatik olarak diske kaydedilir.
    @Published var notes: [NotModel] = [] {
        didSet {
            DataService.shared.saveNotes(notes)
        }
    }
    
    /// Gizli Kasa'nın açık olup olmadığını takip eden biyometrik kilit durumu.
    @Published var isUnlocked: Bool = false
    
    // MARK: - Services (Bağımlılıklar)
    private let authService = AuthService.shared
    private let mediaManager = MediaManager.shared
    let audioManager = AudioManager.shared // Ses oynatıcıya View'dan doğrudan erişim için public bırakıldı
    private let hapticManager = HapticManager.shared
    
    // MARK: - Initialization
    init() {
        loadNotes()
    }
    
    /// Diskteki not verilerini yükler.
    func loadNotes() {
        self.notes = DataService.shared.loadNotes()
    }
    
    // MARK: - Core İşlemler (CRUD)
    
    /// Yeni bir not ekler ve medyaları asenkron mantığı bozmadan diske kaydeder.
    /// ✨ SENIOR FIX: Çoklu ses desteği (audios: [Data]) eklendi.
    func addNote(title: String, content: String, isPrivate: Bool, images: [UIImage] = [], audios: [Data] = []) {
        // 1. Resimleri Disk'e Kaydet
        var savedImageIDs: [String] = []
        for img in images {
            if let id = mediaManager.saveImage(img) {
                savedImageIDs.append(id)
            }
        }
        
        // 2. Ses Kayıtlarını Disk'e Kaydet
        var savedAudioIDs: [String] = []
        for audio in audios {
            if let id = mediaManager.saveAudio(data: audio) {
                savedAudioIDs.append(id)
            }
        }
        
        // 3. Veri Modelini Oluştur
        let newNote = NotModel(
            baslik: title,
            icerik: content,
            createdAt: Date(), // ✨ SENIOR FIX: 'tarih' yerine 'createdAt' kullanıldı
            isPrivate: isPrivate,
            gorselIDListesi: savedImageIDs,
            sesID: nil, // Eski tekil yapı boş kalır
            sesIDListesi: savedAudioIDs // Yeni çoklu liste dolar
        )
        
        // 4. ✨ SENIOR FIX: Listeye eklemeyi animasyonla sarmalıyoruz (Yaylanarak gelir)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            notes.insert(newNote, at: 0)
        }
        hapticManager.triggerSuccess()
    }
    
    /// Var olan bir notu günceller (Senior MVVM Refactoring)
    /// NoteDetailView'in ağır medya yükünü tamamen üzerine alır ve disk işlemlerini senkronize eder.
    /// ✨ SENIOR FIX: Çoklu ses silme ve ekleme işlemleri yönetilir.
    func updateNote(id: String, newTitle: String, newContent: String, isPrivate: Bool, removedImageIDs: Set<String>, newImages: [UIImage], removedAudioIDs: Set<String>, newAudios: [Data]) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        let currentNote = notes[index]
        
        // 1. Kullanıcının sildiği resimleri cihazın diskinden kalıcı olarak temizle (Anti-Leak)
        for imageID in removedImageIDs {
            mediaManager.deleteFile(id: imageID, fileExtension: "jpg")
        }
        
        // 2. Kalan eski resimlerin listesi
        var finalImageIDs = currentNote.gorselIDListesi.filter { !removedImageIDs.contains($0) }
        
        // 3. Yeni Eklenen resimleri diske kaydet ve listeye ekle
        for img in newImages {
            if let newID = mediaManager.saveImage(img) {
                finalImageIDs.append(newID)
            }
        }
        
        // 4. Kullanıcının sildiği sesleri temizle
        for audioID in removedAudioIDs {
            mediaManager.deleteFile(id: audioID, fileExtension: "m4a")
        }
        
        // Eski 'sesID' ve yeni 'sesIDListesi' karmasını 'tumSesler' üzerinden filtreliyoruz
        var finalAudioIDs = currentNote.tumSesler.filter { !removedAudioIDs.contains($0) }
        
        // Yeni Eklenen sesleri diske kaydet ve listeye ekle
        for audio in newAudios {
            if let newID = mediaManager.saveAudio(data: audio) {
                finalAudioIDs.append(newID)
            }
        }
        
        // 5. Modeli Güncelle
        let updatedNote = NotModel(
            id: currentNote.id,
            baslik: newTitle,
            icerik: newContent,
            createdAt: currentNote.createdAt, // ✨ SENIOR FIX: 'tarih' yerine 'createdAt' kullanıldı (orijinal tarihi bozmuyoruz)
            isPrivate: isPrivate,
            gorselIDListesi: finalImageIDs,
            sesID: nil, // Yeni yapıda nil kalır
            sesIDListesi: finalAudioIDs
        )
        
        // ✨ SENIOR FIX: Arayüzdeki (UI) metinlerin/resimlerin yumuşakça değişmesi için
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            notes[index] = updatedNote
        }
        hapticManager.triggerSuccess()
    }
    
    /// Notu silmek yerine akıllıca Çöp Kutusuna (TrashManager) taşır.
    func deleteNote(at offsets: IndexSet) {
        offsets.forEach { index in
            let note = notes[index]
            // Medyaları diskten temizlemiyoruz, sadece çöpe yolluyoruz.
            // Kararı ileride TrashManager (Kalıcı Sil) verecek.
            TrashManager.shared.moveToTrash(note: note)
        }
        
        // ✨ SENIOR FIX: Animasyonlu yumuşak silinme
        withAnimation(.easeOut(duration: 0.2)) {
            notes.remove(atOffsets: offsets)
        }
        hapticManager.triggerMediumImpact()
    }
    
    /// Çöp Kutusundan geri getirilen notu listeye geri ekler.
    func restoreNote(_ note: NotModel) {
        // ✨ SENIOR FIX: Yaylanarak listeye geri düşme efekti
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            notes.insert(note, at: 0)
        }
        hapticManager.triggerSuccess()
    }
    
    /// Sürükle ve bırak ile notların sırasını manuel olarak değiştirme işlemi.
    func moveNote(from source: IndexSet, to destination: Int, currentItems: [NotModel]) {
        let movingItemsIDs = source.map { currentItems[$0].id }
        let targetID = destination < currentItems.count ? currentItems[destination].id : nil
        
        let sourceIndices = movingItemsIDs.compactMap { id in
            notes.firstIndex(where: { $0.id == id })
        }
        
        let realDestination: Int
        if let targetID = targetID {
            realDestination = notes.firstIndex(where: { $0.id == targetID }) ?? notes.count
        } else {
            realDestination = notes.count
        }
        
        // Bu yapı halihazırda animasyonlu (sorunsuz)
        withAnimation {
            notes.move(fromOffsets: IndexSet(sourceIndices), toOffset: realDestination)
            hapticManager.triggerLightImpact()
        }
    }
    
    // MARK: - Medya Yardımcıları
    
    /// Diskten görsel (Image) yükler. UI (View) katmanının MediaManager ile doğrudan muhatap olmasını engeller.
    func loadImage(id: String) -> UIImage? {
        return mediaManager.loadImage(id: id)
    }
    
    /// Notun içindeki ses kaydını (varsa) oynatır.
    func playNoteAudio(note: NotModel) {
        // Not: Çoklu ses yapısına geçildiği için bu metod artık kullanılmıyor,
        // oynatma mantığı View (Arayüz) tarafında index/id bazlı yönetiliyor.
        guard let audioID = note.tumSesler.first,
              let data = mediaManager.loadAudio(id: audioID) else { return }
        audioManager.playAudio(data: data)
    }
    
    // MARK: - Güvenlik (FaceID Entegrasyonu)
    
    /// Gizli notlara (Kasa) erişim için biyometrik doğrulama ister.
    func authenticateForPrivateNotes() {
        Task {
            do {
                let success = try await authService.authenticate(reason: "Gizli notlarınıza erişmek için doğrulama gerekli.")
                // MainActor garantisinde olduğumuz için direkt atama yapabiliriz
                self.isUnlocked = success
                if success {
                    hapticManager.triggerSuccess()
                }
            } catch {
                self.isUnlocked = false
                hapticManager.triggerError()
            }
        }
    }
    
    /// Kullanıcı sekme değiştirdiğinde veya menü kapandığında Gizli Notlar kasasını anında kilitler.
    func lockVault() {
        if isUnlocked {
            isUnlocked = false
        }
    }
}
