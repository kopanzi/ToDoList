import Foundation
import UIKit
import FirebaseStorage // ✨ SENIOR FIX: Bulut Medya Kütüphanesi
import FirebaseAuth

/// Uygulamanın medya (Resim ve Ses) dosyalarını fiziksel diskte ve BULUTTA (Firebase Storage) saklar.
final class MediaManager {
    static let shared = MediaManager()
    private let fileManager = FileManager.default
    private let imageCache = NSCache<NSString, UIImage>()
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private init() {
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 1024 * 1024 * 150
    }
    
    // MARK: - ☁️ CLOUD SYNC (MEDYA BULUT MOTORU)
    
    private func getCloudRef(id: String, ext: String) -> StorageReference? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        // Yol: artifacts/yaver-todo-app/users/{userId}/media/{id}.{ext}
        return Storage.storage().reference().child("artifacts/yaver-todo-app/users/\(userId)/media/\(id).\(ext)")
    }
    
    private func uploadMedia(id: String, data: Data, ext: String) {
        guard let ref = getCloudRef(id: id, ext: ext) else { return }
        let metadata = StorageMetadata()
        metadata.contentType = ext == "jpg" ? "image/jpeg" : "audio/m4a"
        
        // Arka planda sessizce yükle (UI donmaz)
        ref.putData(data, metadata: metadata) { _, error in
            if let error = error {
                print("🛑 Medya Bulut Yükleme Hatası (\(ext)): \(error.localizedDescription)")
            } else {
                print("☁️✅ Medya Buluta Uçtu: \(id).\(ext)")
            }
        }
    }
    
    private func deleteMediaFromCloud(id: String, ext: String) {
        guard let ref = getCloudRef(id: id, ext: ext) else { return }
        ref.delete { _ in
            print("🗑️☁️ Medya Buluttan Silindi: \(id).\(ext)")
        }
    }
    
    /// Eksik olan dosyayı buluttan cihaza indirir.
    func downloadMediaIfNeeded(id: String, ext: String) async {
        let fileURL = documentsDirectory.appendingPathComponent("\(id).\(ext)")
        if fileManager.fileExists(atPath: fileURL.path) { return } // Telefonda zaten var, indirmeye gerek yok!
        
        guard let ref = getCloudRef(id: id, ext: ext) else { return }
        
        do {
            // Maksimum 50 MB'a kadar olan dosyaları indir
            let data = try await ref.data(maxSize: 50 * 1024 * 1024)
            try data.write(to: fileURL)
            print("☁️⬇️ Medya Buluttan Telefona İndi: \(id).\(ext)")
        } catch {
            print("🛑 Medya İndirme Hatası (\(id)): \(error.localizedDescription)")
        }
    }
    
    /// Başka cihazdan gelen yeni notların medyalarını arka planda telefona çeker.
    func syncMissingMedia(from notes: [NotModel]) {
        Task {
            for note in notes {
                for imgId in note.gorselIDListesi {
                    await downloadMediaIfNeeded(id: imgId, ext: "jpg")
                }
                for audioId in note.tumSesler {
                    await downloadMediaIfNeeded(id: audioId, ext: "m4a")
                }
            }
        }
    }
    
    // MARK: - Image Operations
    
    func saveImage(_ image: UIImage) -> String? {
        let id = UUID().uuidString
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 1024, height: 1024))
        guard let data = resizedImage.jpegData(compressionQuality: 0.7) else { return nil }
        let fileURL = documentsDirectory.appendingPathComponent("\(id).jpg")
        
        do {
            try data.write(to: fileURL)
            imageCache.setObject(resizedImage, forKey: id as NSString)
            
            // ✨ YENİ: Diske kaydeder kaydetmez buluta da fırlat!
            uploadMedia(id: id, data: data, ext: "jpg")
            
            return id
        } catch {
            return nil
        }
    }
    
    func loadImage(id: String) -> UIImage? {
        if let cachedImage = imageCache.object(forKey: id as NSString) { return cachedImage }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(id).jpg")
        guard let image = UIImage(contentsOfFile: fileURL.path) else { return nil }
        
        let finalImage: UIImage
        if image.size.width > 1024 || image.size.height > 1024 {
            finalImage = resizeImage(image: image, targetSize: CGSize(width: 1024, height: 1024))
        } else {
            finalImage = image
        }
        
        imageCache.setObject(finalImage, forKey: id as NSString)
        return finalImage
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        if size.width <= targetSize.width && size.height <= targetSize.height { return image }
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        let rect = CGRect(origin: .zero, size: newSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
    
    // MARK: - Audio Operations
    
    func saveAudio(data: Data) -> String? {
        let id = UUID().uuidString
        let fileURL = documentsDirectory.appendingPathComponent("\(id).m4a")
        do {
            try data.write(to: fileURL)
            
            // ✨ YENİ: Diske kaydeder kaydetmez buluta da fırlat!
            uploadMedia(id: id, data: data, ext: "m4a")
            
            return id
        } catch {
            return nil
        }
    }
    
    func loadAudio(id: String) -> Data? {
        let fileURL = documentsDirectory.appendingPathComponent("\(id).m4a")
        return try? Data(contentsOf: fileURL)
    }
    
    // MARK: - Deletion
    
    func deleteFile(id: String, fileExtension: String) {
        let fileURL = documentsDirectory.appendingPathComponent("\(id).\(fileExtension)")
        do {
            try fileManager.removeItem(at: fileURL)
            if fileExtension == "jpg" { imageCache.removeObject(forKey: id as NSString) }
            
            // ✨ YENİ: Diskten silinince buluttan da sil!
            deleteMediaFromCloud(id: id, ext: fileExtension)
            
        } catch { }
    }
}
