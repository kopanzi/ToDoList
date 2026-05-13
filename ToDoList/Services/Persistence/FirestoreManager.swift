import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Yaver'in Bulut Depolama (Firestore) Yönetim Merkezi.
final class FirestoreManager {
    
    // Singleton: Uygulama boyunca tek bir merkezden yönetilir
    static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    
    // ✨ SENIOR FIX 1: Hatalı JavaScript kodunu sildik, yerine sabit bir ID koyduk.
    private let appId = "yaver-todo-app"
    
    private init() {}
    
    // MARK: - PATH YARDIMCISI (RULE 1)
    /// Kullanıcıya özel görevler klasörünün yolunu verir.
    private func tasksCollection() throws -> CollectionReference {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // ✨ SENIOR KURAL 1: Güvenli yol yapısı (Sadece kendi verisine erişim)
        // Yol: artifacts/{appId}/users/{userId}/tasks
        return db.collection("artifacts")
            .document(appId)
            .collection("users")
            .document(userId)
            .collection("tasks")
    }
    
    // MARK: - 1. GÖREV EKLE VEYA GÜNCELLE
    func saveTask(_ task: TaskModel) async throws {
        let collection = try tasksCollection()
        
        // TaskModel 'Codable' olduğu için Firestore bunu otomatik olarak JSON'a çevirebilir.
        // Veriyi gönderirken döküman ID'si olarak görevin kendi id'sini kullanıyoruz.
        try collection.document(task.id).setData(from: task)
    }
    
    // MARK: - 2. TÜM GÖREVLERİ ÇEK
    func fetchTasks() async throws -> [TaskModel] {
        let collection = try tasksCollection()
        
        // RULE 2: Karmaşık sorgu yerine basitçe tüm dökümanları çekiyoruz.
        let snapshot = try await collection.getDocuments()
        
        // Gelen dökümanları TaskModel nesnelerine geri çeviriyoruz.
        return snapshot.documents.compactMap { document in
            try? document.data(as: TaskModel.self)
        }
    }
    
    // MARK: - 3. GÖREV SİL
    func deleteTask(id: String) async throws {
        let collection = try tasksCollection()
        try await collection.document(id).delete()
    }
    
    // MARK: - 4. TOPLU EŞZAMANLAMA (SYCHRONIZE)
    /// Yerel hafızadaki tüm görevleri bir kerede buluta yükler.
    func syncLocalTasksToCloud(tasks: [TaskModel]) async {
        for task in tasks {
            // Hata olsa bile döngü bozulmasın diye try? kullanıyoruz.
            try? await saveTask(task)
        }
    }
}
