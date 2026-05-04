import Foundation
import SwiftUI
import Combine

/// Notlar üzerindeki tüm iş mantığını ve medya kayıt süreçlerini yöneten ana ViewModel.
/// Senior Notu: View katmanının model dizisine ve disk işlemlerine doğrudan müdahale etmesini engellemek
/// için tam MVVM izolasyonu sağlanmıştır. Gemini AI bağımlılıkları tamamen temizlenmiştir.
@MainActor
final class NoteViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var notes: [NotModel] = [] {
        didSet {
            DataService.shared.saveNotes(notes)
        }
    }
    
    @Published var isUnlocked: Bool = false
    
    // MARK: - Services
    private let authService = AuthService.shared
    private let mediaManager = MediaManager.shared
    let audioManager = AudioManager.shared // Ses oynatıcıya View'dan doğrudan erişim için
    private let hapticManager = HapticManager.shared
    
    // MARK: - Init
    init() {
        loadNotes()
    }
    
    func loadNotes() {
        self.notes = DataService.shared.loadNotes()
    }
    
    // MARK: - Core İşlemler (CRUD)
    
    /// Yeni bir not ekler ve medyaları diske kaydeder.
    func addNote(title: String, content: String, isPrivate: Bool, images: [UIImage] = [], audioData: Data? = nil) {
        // 1. Resimleri Kaydet
        var savedImageIDs: [String] = []
        for img in images {
            if let id = mediaManager.saveImage(img) {
                savedImageIDs.append(id)
            }
        }
        
        // 2. Ses Kaydını Kaydet
        var savedAudioID: String? = nil
        if let audio = audioData {
            savedAudioID = mediaManager.saveAudio(data: audio)
        }
        
        // 3. Modeli Oluştur
        let newNote = NotModel(
            baslik: title,
            icerik: content,
            tarih: Date(),
            isPrivate: isPrivate,
            gorselIDListesi: savedImageIDs,
            sesID: savedAudioID
        )
        
        // 4. Listeye Ekle
        notes.insert(newNote, at: 0)
        hapticManager.triggerSuccess()
    }
    
    /// Var olan bir notu günceller (Senior MVVM Refactoring)
    /// NoteDetailView'in yükünü tamamen üzerine alır. Disk işlemlerini yönetir.
    func updateNote(id: String, newTitle: String, newContent: String, isPrivate: Bool, removedImageIDs: Set<String>, newImages: [UIImage]) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        let currentNote = notes[index]
        
        // 1. Silinen Resimleri Diskten Temizle
        for imageID in removedImageIDs {
            mediaManager.deleteFile(id: imageID, fileExtension: "jpg")
        }
        
        // Kalan eski resimlerin listesi
        var finalImageIDs = currentNote.gorselIDListesi.filter { !removedImageIDs.contains($0) }
        
        // 2. Yeni Eklenen Resimleri Diske Kaydet
        for img in newImages {
            if let newID = mediaManager.saveImage(img) {
                finalImageIDs.append(newID)
            }
        }
        
        // 3. Modeli Güncelle ve Kaydet
        let updatedNote = NotModel(
            id: currentNote.id,
            baslik: newTitle,
            icerik: newContent,
            tarih: currentNote.tarih, // Orijinal tarihi koru
            isPrivate: isPrivate,
            gorselIDListesi: finalImageIDs,
            sesID: currentNote.sesID
        )
        
        notes[index] = updatedNote
        hapticManager.triggerSuccess()
    }
    
    /// Notu silmek yerine Çöp Kutusuna taşır.
    func deleteNote(at offsets: IndexSet) {
        offsets.forEach { index in
            let note = notes[index]
            // ✨ YENİ: Medyaları diskten hemen temizleme, sadece çöpe yolla.
            TrashManager.shared.moveToTrash(note: note)
        }
        notes.remove(atOffsets: offsets)
        hapticManager.triggerMediumImpact()
    }
    
    /// Çöp Kutusundan geri getirilen notu listeye ekler.
    func restoreNote(_ note: NotModel) {
        notes.insert(note, at: 0) // En başa ekle
        hapticManager.triggerSuccess()
    }
    
    /// Notların sırasını değiştirme işlemi.
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
        
        withAnimation {
            notes.move(fromOffsets: IndexSet(sourceIndices), toOffset: realDestination)
            hapticManager.triggerLightImpact()
        }
    }
    
    // MARK: - Medya Yardımcıları
    
    /// Diskten görsel yükler.
    func loadImage(id: String) -> UIImage? {
        return mediaManager.loadImage(id: id)
    }
    
    /// Hızlıca ses dinlemek için (Eski arayüz destekleyicisi)
    func playNoteAudio(note: NotModel) {
        guard let audioID = note.sesID,
              let data = mediaManager.loadAudio(id: audioID) else { return }
        audioManager.playAudio(data: data)
    }
    
    // MARK: - Güvenlik (FaceID Entegrasyonu)
    
    /// Gizli notlara erişim için biyometrik doğrulama ister.
    func authenticateForPrivateNotes() {
        Task {
            do {
                let success = try await authService.authenticate(reason: "Gizli notlarınıza erişmek için doğrulama gerekli.")
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
    
    /// Sekme değiştiğinde veya menü kapandığında Gizli Notlar kasasını kilitler.
    func lockVault() {
        isUnlocked = false
    }
}
