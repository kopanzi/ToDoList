import Foundation

/// Veri saklama (Persistence) işlemlerini yöneten merkezi servis.
/// Senior Notu: Jenerik (Generic) metodlar kullanılarak kod tekrarı önlenmiş,
/// hata yönetimi 'do-catch' ile profesyonel seviyeye taşınmıştır.
final class DataService {
    
    // MARK: - Singleton
    static let shared = DataService()
    private init() {}
    
    // MARK: - Storage Keys
    private enum Keys: String {
        case tasks = "yaver_tasks_v2"
        case notes = "yaver_notes_v2"
        case achievements = "yaver_achievements_v1"
    }
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - 🧠 Generic Persistence Engine
    
    /// Herhangi bir 'Codable' veriyi diske güvenli bir şekilde kaydeder.
    private func save<T: Encodable>(_ data: T, forKey key: Keys) {
        do {
            let encoded = try JSONEncoder().encode(data)
            userDefaults.set(encoded, forKey: key.rawValue)
        } catch {
            print("🛑 DataService Save Error [\(key.rawValue)]: \(error.localizedDescription)")
        }
    }
    
    /// Diskteki veriyi istenen tipe (Decodable) güvenli bir şekilde çevirir.
    private func load<T: Decodable>(forKey key: Keys) -> [T] {
        guard let data = userDefaults.data(forKey: key.rawValue) else { return [] }
        
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("🛑 DataService Load Error [\(key.rawValue)]: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Task (Görev) İşlemleri
    
    func saveTasks(_ tasks: [TaskModel]) {
        save(tasks, forKey: .tasks)
    }
    
    func loadTasks() -> [TaskModel] {
        load(forKey: .tasks)
    }
    
    // MARK: - Not (NotModel) İşlemleri
    
    func saveNotes(_ notes: [NotModel]) {
        save(notes, forKey: .notes)
    }
    
    func loadNotes() -> [NotModel] {
        load(forKey: .notes)
    }
    
    // MARK: - 🏆 Başarı (Achievement) İşlemleri
    
    func saveAchievements(_ achievements: [Achievement]) {
        save(achievements, forKey: .achievements)
    }
    
    func loadAchievements() -> [Achievement] {
        load(forKey: .achievements)
    }
}
