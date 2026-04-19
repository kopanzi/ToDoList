import Foundation

/// Veri saklama (Persistence) işlemlerini yöneten merkezi servis.
/// Senior Notu: NoteModel ismi NotModel olarak güncellenmiş ve tip güvenliği sağlanmıştır.
final class DataService {
    static let shared = DataService()
    
    // Anahtarlar (Keys) - Veritabanındaki tablo isimleri gibi düşünebilirsin.
    private let taskKey = "yaver_tasks_v2"
    private let noteKey = "yaver_notes_v2"
    private let achievementKey = "yaver_achievements_v1" // 🆕 Rozetler için yeni anahtar
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Task (Görev) İşlemleri
    
    /// Görev listesini JSON formatına çevirip diske kaydeder.
    func saveTasks(_ tasks: [TaskModel]) {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: taskKey)
        }
    }
    
    /// Diskteki görev verilerini yükler.
    func loadTasks() -> [TaskModel] {
        guard let data = userDefaults.data(forKey: taskKey),
              let decoded = try? JSONDecoder().decode([TaskModel].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // MARK: - Not (NotModel) İşlemleri
    
    /// Not listesini (NotModel) JSON formatına çevirip diske kaydeder.
    func saveNotes(_ notes: [NotModel]) {
        if let encoded = try? JSONEncoder().encode(notes) {
            userDefaults.set(encoded, forKey: noteKey)
        }
    }
    
    /// Diskteki not verilerini yükleyip 'NotModel' dizisine çevirir.
    func loadNotes() -> [NotModel] {
        guard let data = userDefaults.data(forKey: noteKey),
              let decoded = try? JSONDecoder().decode([NotModel].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // MARK: - 🏆 Başarı (Achievement) İşlemleri
    
    /// Kullanıcının rozetlerini (kilitli/açık durumlarıyla) diske kaydeder.
    func saveAchievements(_ achievements: [Achievement]) {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: achievementKey)
        }
    }
    
    /// Diskteki rozetleri yükler.
    func loadAchievements() -> [Achievement] {
        guard let data = userDefaults.data(forKey: achievementKey),
              let decoded = try? JSONDecoder().decode([Achievement].self, from: data) else {
            return [] // Eğer hiç kayıt yoksa boş döner (ViewModel varsayılanları yükleyecek)
        }
        return decoded
    }
}
