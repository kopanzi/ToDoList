import Foundation
import SwiftUI
import Combine

/// Çöp kutusundaki her bir öğeyi temsil eden sarmalayıcı (Wrapper) model.
/// Senior Notu: Codable ve Equatable olması, hem saklanmasını hem de liste güncellemelerini kolaylaştırır.
struct TrashItem: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    let task: TaskModel?
    let note: NotModel?
    let deletedAt: Date
    
    // UI yardımcıları
    var title: String { task?.title ?? note?.baslik ?? "İsimsiz Öğeyi Kurtar" }
    var icon: String { task != nil ? "checklist" : "note.text" }
    var colorHex: String { task != nil ? "f27f0d" : "3b82f6" }
    
    // Equatable uyumu için (Hız optimizasyonu)
    static func == (lhs: TrashItem, rhs: TrashItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Silinen öğeleri geçici olarak saklayan ve zamanı gelince diskten temizleyen merkezi servis.
/// Senior Notu: @MainActor ile işaretlenerek UI güncellemelerinde thread-safety (iş parçacığı güvenliği) sağlanmıştır.
@MainActor
final class TrashManager: ObservableObject {
    
    // MARK: - Singleton & Constants
    static let shared = TrashManager()
    private let storageKey = "yaver_trash_items_v2"
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Published State
    @Published private(set) var items: [TrashItem] = []
    
    /// Kullanıcının otomatik temizleme tercihi (Varsayılan: 30 Gün)
    @Published var autoEmptyDays: Int {
        didSet {
            userDefaults.set(autoEmptyDays, forKey: "trashAutoEmptyDays")
            cleanUpOldItems()
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Tercihleri ve öğeleri yükle
        self.autoEmptyDays = userDefaults.object(forKey: "trashAutoEmptyDays") as? Int ?? 30
        loadItems()
        
        // Uygulama her açıldığında arka planda eski çöpleri temizle
        cleanUpOldItems()
    }
    
    // MARK: - Core Persistence (Kalıcılık)
    
    private func loadItems() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        
        do {
            self.items = try JSONDecoder().decode([TrashItem].self, from: data)
        } catch {
            print("🛑 TrashManager Load Error: \(error.localizedDescription)")
            self.items = []
        }
    }
    
    private func saveItems() {
        do {
            let encoded = try JSONEncoder().encode(items)
            userDefaults.set(encoded, forKey: storageKey)
        } catch {
            print("🛑 TrashManager Save Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Çöpe Gönderme (Business Logic)
    
    func moveToTrash(task: TaskModel) {
        let item = TrashItem(task: task, note: nil, deletedAt: Date())
        withAnimation(.spring()) {
            items.insert(item, at: 0)
            saveItems()
        }
    }
    
    func moveToTrash(note: NotModel) {
        let item = TrashItem(task: nil, note: note, deletedAt: Date())
        withAnimation(.spring()) {
            items.insert(item, at: 0)
            saveItems()
        }
    }
    
    // MARK: - Geri Yükleme ve Temizlik
    
    /// Öğeyi çöp kutusu listesinden çıkarır (Geri yükleme durumunda).
    func removeItem(_ item: TrashItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    /// Öğeyi ve ona bağlı ağır medyaları (Görsel/Ses) diskten kalıcı olarak yok eder.
    /// Senior Notu: Storage Anti-Leak mekanizması burada çalışır.
    func permanentlyDelete(_ item: TrashItem) {
        let mediaManager = MediaManager.shared
        
        // 1. Göreve bağlı medyaları temizle
        if let task = item.task {
            task.imageIDs.forEach { mediaManager.deleteFile(id: $0, fileExtension: "jpg") }
            if let audioID = task.audioID { mediaManager.deleteFile(id: audioID, fileExtension: "m4a") }
        }
        // 2. Nota bağlı medyaları temizle
        else if let note = item.note {
            note.gorselIDListesi.forEach { mediaManager.deleteFile(id: $0, fileExtension: "jpg") }
            if let audioID = note.sesID { mediaManager.deleteFile(id: audioID, fileExtension: "m4a") }
        }
        
        // 3. Listeden ve bellekten uçur
        withAnimation(.easeOut) {
            removeItem(item)
        }
    }
    
    /// Çöp kutusundaki her şeyi tek hamlede temizler.
    func emptyTrash() {
        let allItems = items
        items.removeAll() // UI'ı anında hafiflet
        saveItems()
        
        // Ağır disk temizliğini arka arkaya yap
        allItems.forEach { permanentlyDelete($0) }
    }
    
    /// Süresi dolan çöpleri otomatik tespit eder (Örn: 30 günden eski olanlar).
    func cleanUpOldItems() {
        guard autoEmptyDays > 0 else { return }
        
        let calendar = Calendar.current
        guard let thresholdDate = calendar.date(byAdding: .day, value: -autoEmptyDays, to: Date()) else { return }
        
        // Kriterlere uyanları filtrele
        let itemsToDelete = items.filter { $0.deletedAt < thresholdDate }
        
        if !itemsToDelete.isEmpty {
            print("🧹 Otomatik Temizlik: \(itemsToDelete.count) adet eski öğe siliniyor.")
            itemsToDelete.forEach { permanentlyDelete($0) }
        }
    }
}
