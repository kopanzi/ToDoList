import Foundation
import SwiftUI
import Combine // ✨ SENIOR FIX: @Published ve ObservableObject hatalarını çözer

/// Çöp kutusundaki her bir öğeyi temsil eden sarmalayıcı (Wrapper) model.
struct TrashItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    let task: TaskModel?
    let note: NotModel?
    let deletedAt: Date
    
    // UI için yardımcı değişkenler
    var title: String { task?.title ?? note?.baslik ?? "İsimsiz Öğeyi Kurtar" }
    var icon: String { task != nil ? "checklist" : "note.text" }
    var colorHex: String { task != nil ? "f27f0d" : "3b82f6" } // Görevse Turuncu, Notsa Mavi
}

/// Silinen öğeleri geçici olarak saklayan, geri yükleyen ve zamanı gelince diskten temizleyen servis.
@MainActor
final class TrashManager: ObservableObject {
    static let shared = TrashManager()
    private let storageKey = "yaver_trash_items"
    
    @Published var items: [TrashItem] = []
    
    // Kullanıcının otomatik temizleme tercihi (Varsayılan: 30 Gün)
    @Published var autoEmptyDays: Int {
        didSet {
            UserDefaults.standard.set(autoEmptyDays, forKey: "trashAutoEmptyDays")
            cleanUpOldItems()
        }
    }
    
    private init() {
        self.autoEmptyDays = UserDefaults.standard.object(forKey: "trashAutoEmptyDays") as? Int ?? 30
        loadItems()
        cleanUpOldItems() // Uygulama açıldığında süresi dolanları otomatik temizle
    }
    
    // MARK: - Core Functions
    
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TrashItem].self, from: data) else { return }
        self.items = decoded
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    // MARK: - Çöpe Gönderme İşlemleri
    
    func moveToTrash(task: TaskModel) {
        let item = TrashItem(task: task, note: nil, deletedAt: Date())
        items.insert(item, at: 0) // En yeni silinen en üste gelsin
        saveItems()
    }
    
    func moveToTrash(note: NotModel) {
        let item = TrashItem(task: nil, note: note, deletedAt: Date())
        items.insert(item, at: 0)
        saveItems()
    }
    
    // MARK: - Geri Yükleme ve Kalıcı Silme
    
    /// Öğeyi çöp kutusu listesinden çıkarır (Geri yüklendiğinde çalışır)
    func removeItem(_ item: TrashItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    /// Öğeyi ve ona bağlı tüm ağır medyaları diskten "KALICI" olarak siler.
    func permanentlyDelete(_ item: TrashItem) {
        // Medya Temizliği (Storage Anti-Leak)
        if let task = item.task {
            task.imageIDs.forEach { MediaManager.shared.deleteFile(id: $0, fileExtension: "jpg") }
            if let audioID = task.audioID { MediaManager.shared.deleteFile(id: audioID, fileExtension: "m4a") }
        } else if let note = item.note {
            note.gorselIDListesi.forEach { MediaManager.shared.deleteFile(id: $0, fileExtension: "jpg") }
            if let audioID = note.sesID { MediaManager.shared.deleteFile(id: audioID, fileExtension: "m4a") }
        }
        
        removeItem(item)
    }
    
    /// Kullanıcı manuel olarak 'Tümünü Temizle' dediğinde çalışır.
    func emptyTrash() {
        items.forEach { permanentlyDelete($0) }
    }
    
    /// Ayarlanan süreyi (Örn: 30 Gün) aşan öğeleri otomatik tespit eder ve sessizce yok eder.
    func cleanUpOldItems() {
        guard autoEmptyDays > 0 else { return } // 0 ise hiçbir zaman silme demek (Ekstra ayar)
        let thresholdDate = Calendar.current.date(byAdding: .day, value: -autoEmptyDays, to: Date()) ?? Date()
        
        let itemsToDelete = items.filter { $0.deletedAt < thresholdDate }
        itemsToDelete.forEach { permanentlyDelete($0) }
    }
}
