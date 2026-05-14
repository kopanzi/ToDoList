import Foundation
import SwiftUI
import Combine
import FirebaseAuth // ✨ SENIOR FIX: Bulut bağlantısı için eklendi

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
    let audioManager = AudioManager.shared
    private let hapticManager = HapticManager.shared
    
    // MARK: - Initialization
    init() {
        loadNotes()
        
        // ✨ SENIOR FIX: Giriş yapıldığında notları bulutla eşitle
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.syncWithCloud()
            }
        }
    }
    
    func loadNotes() {
        self.notes = DataService.shared.loadNotes()
    }
    
    // MARK: - CLOUD SYNC (BULUT MOTORU) ✨
    private func syncWithCloud() {
        Task {
            do {
                let cloudNotes = try await FirestoreManager.shared.fetchNotes()
                
                if cloudNotes.isEmpty && !self.notes.isEmpty {
                    await FirestoreManager.shared.syncLocalNotesToCloud(notes: self.notes)
                } else if !cloudNotes.isEmpty {
                    var mergedNotes = self.notes
                    for cloudNote in cloudNotes {
                        if let index = mergedNotes.firstIndex(where: { $0.id == cloudNote.id }) {
                            mergedNotes[index] = cloudNote
                        } else {
                            mergedNotes.append(cloudNote)
                        }
                    }
                    // Tarihe göre yeniden sırala
                    mergedNotes.sort { $0.createdAt > $1.createdAt }
                    self.notes = mergedNotes
                    await FirestoreManager.shared.syncLocalNotesToCloud(notes: mergedNotes)
                    
                    // ✨ SENIOR FIX: Yeni inen notların içinde resim/ses varsa onları da arkadan indir!
                    MediaManager.shared.syncMissingMedia(from: mergedNotes)
                }
            } catch {
                print("🛑 Notlar Bulut Senkronizasyon Hatası: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveNoteToCloud(_ note: NotModel) {
        guard Auth.auth().currentUser != nil else { return }
        Task { try? await FirestoreManager.shared.saveNote(note) }
    }
    
    private func deleteNoteFromCloud(id: String) {
        guard Auth.auth().currentUser != nil else { return }
        Task { try? await FirestoreManager.shared.deleteNote(id: id) }
    }
    
    // MARK: - Core İşlemler (CRUD)
    
    func addNote(title: String, content: String, isPrivate: Bool, images: [UIImage] = [], audios: [Data] = []) {
        var savedImageIDs: [String] = []
        for img in images {
            if let id = mediaManager.saveImage(img) { savedImageIDs.append(id) }
        }
        
        var savedAudioIDs: [String] = []
        for audio in audios {
            if let id = mediaManager.saveAudio(data: audio) { savedAudioIDs.append(id) }
        }
        
        let newNote = NotModel(
            baslik: title, icerik: content, createdAt: Date(),
            isPrivate: isPrivate, gorselIDListesi: savedImageIDs,
            sesID: nil, sesIDListesi: savedAudioIDs
        )
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            notes.insert(newNote, at: 0)
        }
        
        // ✨ Buluta Kaydet
        saveNoteToCloud(newNote)
        hapticManager.triggerSuccess()
    }
    
    func updateNote(id: String, newTitle: String, newContent: String, isPrivate: Bool, removedImageIDs: Set<String>, newImages: [UIImage], removedAudioIDs: Set<String>, newAudios: [Data]) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        let currentNote = notes[index]
        
        for imageID in removedImageIDs { mediaManager.deleteFile(id: imageID, fileExtension: "jpg") }
        var finalImageIDs = currentNote.gorselIDListesi.filter { !removedImageIDs.contains($0) }
        for img in newImages {
            if let newID = mediaManager.saveImage(img) { finalImageIDs.append(newID) }
        }
        
        for audioID in removedAudioIDs { mediaManager.deleteFile(id: audioID, fileExtension: "m4a") }
        var finalAudioIDs = currentNote.tumSesler.filter { !removedAudioIDs.contains($0) }
        for audio in newAudios {
            if let newID = mediaManager.saveAudio(data: audio) { finalAudioIDs.append(newID) }
        }
        
        let updatedNote = NotModel(
            id: currentNote.id, baslik: newTitle, icerik: newContent,
            createdAt: currentNote.createdAt, isPrivate: isPrivate,
            gorselIDListesi: finalImageIDs, sesID: nil, sesIDListesi: finalAudioIDs
        )
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            notes[index] = updatedNote
        }
        
        // ✨ Buluta Güncelle
        saveNoteToCloud(updatedNote)
        hapticManager.triggerSuccess()
    }
    
    func deleteNote(at offsets: IndexSet) {
        offsets.forEach { index in
            let note = notes[index]
            TrashManager.shared.moveToTrash(note: note)
            // ✨ Buluttan Sil
            deleteNoteFromCloud(id: note.id)
        }
        withAnimation(.easeOut(duration: 0.2)) {
            notes.remove(atOffsets: offsets)
        }
        hapticManager.triggerMediumImpact()
    }
    
    func restoreNote(_ note: NotModel) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            notes.insert(note, at: 0)
        }
        // ✨ Çöpten döndü, buluta geri yükle
        saveNoteToCloud(note)
        hapticManager.triggerSuccess()
    }
    
    func moveNote(from source: IndexSet, to destination: Int, currentItems: [NotModel]) {
        let movingItemsIDs = source.map { currentItems[$0].id }
        let targetID = destination < currentItems.count ? currentItems[destination].id : nil
        let sourceIndices = movingItemsIDs.compactMap { id in notes.firstIndex(where: { $0.id == id }) }
        
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
    func loadImage(id: String) -> UIImage? { return mediaManager.loadImage(id: id) }
    
    func playNoteAudio(note: NotModel) {
        guard let audioID = note.tumSesler.first, let data = mediaManager.loadAudio(id: audioID) else { return }
        audioManager.playAudio(data: data)
    }
    
    // MARK: - Güvenlik (FaceID)
    func authenticateForPrivateNotes() {
        Task {
            do {
                let success = try await authService.authenticate(reason: "Gizli notlarınıza erişmek için doğrulama gerekli.")
                self.isUnlocked = success
                if success { hapticManager.triggerSuccess() }
            } catch {
                self.isUnlocked = false
                hapticManager.triggerError()
            }
        }
    }
    
    func lockVault() { if isUnlocked { isUnlocked = false } }
}
