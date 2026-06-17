import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Yaver'in Bulut Veritabanı (Firestore) Motoru
/// Senior Notu: Hem Görevler (Tasks) hem de Notlar (Notes) için tüm bulut işlemleri buradadır.
final class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
    // Uygulamanın ana veritabanı klasörü
    private let appId = "yaver-todo-app"
    
    private init() {}
    
    // MARK: - 🚀 GÖREVLER (TASKS) ODASI
    
    private func tasksCollection() throws -> CollectionReference {
        guard let userId = Auth.auth().currentUser?.uid else { throw URLError(.userAuthenticationRequired) }
        return db.collection("artifacts").document(appId).collection("users").document(userId).collection("tasks")
    }
    
    func fetchTasks() async throws -> [TaskModel] {
        let snapshot = try await tasksCollection().getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TaskModel.self) }
    }
    
    func saveTask(_ task: TaskModel) async throws {
        let collection = try tasksCollection()
        try collection.document(task.id).setData(from: task)
    }
    
    func deleteTask(id: String) async throws {
        let collection = try tasksCollection()
        try await collection.document(id).delete()
    }
    
    func syncLocalTasksToCloud(tasks: [TaskModel]) async {
        for task in tasks {
            try? await saveTask(task)
        }
    }
    

    
    private func notesCollection() throws -> CollectionReference {
        guard let userId = Auth.auth().currentUser?.uid else { throw URLError(.userAuthenticationRequired) }
        return db.collection("artifacts").document(appId).collection("users").document(userId).collection("notes")
    }
    
    func fetchNotes() async throws -> [NotModel] {
        let snapshot = try await notesCollection().getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: NotModel.self) }
    }
    
    func saveNote(_ note: NotModel) async throws {
        let collection = try notesCollection()
        try collection.document(note.id).setData(from: note)
    }
    
    func deleteNote(id: String) async throws {
        let collection = try notesCollection()
        try await collection.document(id).delete()
    }
    
    func syncLocalNotesToCloud(notes: [NotModel]) async {
        for note in notes {
            try? await saveNote(note)
        }
    }
    
    // MARK: - 🏆 PROFİL VE BAŞARILAR ODASI
    
    private func profileDocument() throws -> DocumentReference {
        guard let userId = Auth.auth().currentUser?.uid else { throw URLError(.userAuthenticationRequired) }
        // Yol: artifacts/yaver-todo-app/users/{userId}/profile/achievements
        return db.collection("artifacts").document(appId).collection("users").document(userId).collection("profile").document("achievements")
    }
    
    // Firestore dizileri doğrudan kaydetmeyi sevmediği için şık bir sarmalayıcı (Wrapper) kullanıyoruz
    struct AchievementWrapper: Codable {
        let list: [Achievement]
    }
    
    func saveAchievements(_ achievements: [Achievement]) async throws {
        let doc = try profileDocument()
        try doc.setData(from: AchievementWrapper(list: achievements))
    }
    
    func fetchAchievements() async throws -> [Achievement] {
        let doc = try profileDocument()
        let snapshot = try await doc.getDocument()
        
        // Eğer bulutta henüz başarı rozeti verisi yoksa boş dizi dön (Çökmeyi önler)
        guard snapshot.exists else { return [] }
        
        let wrapper = try snapshot.data(as: AchievementWrapper.self)
        return wrapper.list
    }
    
    // MARK: - ⚙️ AYARLAR (SETTINGS) ODASI
    
    private func settingsDocument() throws -> DocumentReference {
        guard let userId = Auth.auth().currentUser?.uid else { throw URLError(.userAuthenticationRequired) }
        // Yol: artifacts/yaver-todo-app/users/{userId}/settings/preferences
        return db.collection("artifacts").document(appId).collection("users").document(userId).collection("settings").document("preferences")
    }
    
    // Firestore için şık bir sarmalayıcı (Wrapper)
    struct SettingsWrapper: Codable {
        let theme: Theme
        let language: String
    }
    
    func saveSettings(theme: Theme, language: String) async throws {
        let doc = try settingsDocument()
        try doc.setData(from: SettingsWrapper(theme: theme, language: language))
    }
    
    func fetchSettings() async throws -> SettingsWrapper? {
        let doc = try settingsDocument()
        let snapshot = try await doc.getDocument()
        
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: SettingsWrapper.self)
    }
    
    // MARK: - 🔁 RUTİNLER (ROUTINES) ODASI
    
    private func routinesCollection() throws -> CollectionReference {
        guard let userId = Auth.auth().currentUser?.uid else { throw URLError(.userAuthenticationRequired) }
        // Yol: artifacts/yaver-todo-app/users/{userId}/routines
        return db.collection("artifacts").document(appId).collection("users").document(userId).collection("routines")
    }
    
    func saveRoutine(_ routine: RoutineModel) async throws {
        let collection = try routinesCollection()
        try collection.document(routine.id).setData(from: routine)
    }
    
    func fetchRoutines() async throws -> [RoutineModel] {
        let collection = try routinesCollection()
        let snapshot = try await collection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: RoutineModel.self) }
    }
    
    func deleteRoutine(id: String) async throws {
        let collection = try routinesCollection()
        try await collection.document(id).delete()
    }
    
    func syncLocalRoutinesToCloud(routines: [RoutineModel]) async {
        for routine in routines {
            try? await saveRoutine(routine)
        }
    }
}
