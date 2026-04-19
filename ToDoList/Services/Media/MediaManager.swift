import Foundation
import UIKit

/// Uygulamanın medya (Resim ve Ses) dosyalarını fiziksel diskte saklar ve Hafıza(RAM) yönetimini yapar.
/// Senior Notu: OOM (Out of Memory) çökmelerini önlemek için NSCache ve Downsampling eklendi.
final class MediaManager {
    static let shared = MediaManager()
    private let fileManager = FileManager.default
    
    // 🧠 RAM DOSTU: Resimleri bellekte tutan, dolduğunda iOS tarafından otomatik temizlenen özel Cache.
    private let imageCache = NSCache<NSString, UIImage>()
    
    /// Dökümanlar klasörünün yolunu döndürür.
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private init() {
        // Cache limitlerini belirliyoruz ki uygulama RAM'i sömürmesin
        imageCache.countLimit = 100 // Maksimum 100 resmi hafızada tut
        imageCache.totalCostLimit = 1024 * 1024 * 150 // Maksimum ~150 MB RAM kullan
    }
    
    // MARK: - Image Operations
    
    /// Resmi RAM dostu boyutlara küçültüp, JPEG formatında diske kaydeder.
    func saveImage(_ image: UIImage) -> String? {
        let id = UUID().uuidString
        
        // 🛠️ ANTI-OOM ÇÖZÜMÜ: Cihaz kamerasından gelen 4K devasa fotoğrafları makul bir boyuta çek.
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 1024, height: 1024))
        
        guard let data = resizedImage.jpegData(compressionQuality: 0.7) else { return nil }
        let fileURL = documentsDirectory.appendingPathComponent("\(id).jpg")
        
        do {
            try data.write(to: fileURL)
            // Kaydeder kaydetmez Cache'e de at ki hemen gösterilecekse disk yorulmasın
            imageCache.setObject(resizedImage, forKey: id as NSString)
            return id
        } catch {
            print("🛑 MediaManager Image Save Error: \(error)")
            return nil
        }
    }
    
    /// ID kullanarak resmi yükler (Önce Cache'e bakar, yoksa diskten okur).
    func loadImage(id: String) -> UIImage? {
        // 1. Önce RAM'de (Cache) var mı diye kontrol et (Işık hızında yüklenir)
        if let cachedImage = imageCache.object(forKey: id as NSString) {
            return cachedImage
        }
        
        // 2. RAM'de yoksa Diskten (Dosya Sisteminden) oku
        let fileURL = documentsDirectory.appendingPathComponent("\(id).jpg")
        guard let image = UIImage(contentsOfFile: fileURL.path) else { return nil }
        
        // 🛠️ Eğer bu resim güncelleme öncesinden kalan DEVASA bir resimse (eski veriler), onu yüklerken küçült
        let finalImage: UIImage
        if image.size.width > 1024 || image.size.height > 1024 {
            finalImage = resizeImage(image: image, targetSize: CGSize(width: 1024, height: 1024))
        } else {
            finalImage = image
        }
        
        // 3. Bir dahaki sefere hızlı yüklenmesi için Cache'e kaydet
        imageCache.setObject(finalImage, forKey: id as NSString)
        
        return finalImage
    }
    
    // MARK: - Image Resizing Engine
    
    /// Verilen resmi, en-boy oranını bozmadan hedeflenen maksimum boyuta küçültür.
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        // Eğer resim zaten hedef boyuttan küçükse hiç dokunma
        if size.width <= targetSize.width && size.height <= targetSize.height {
            return image
        }
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Orijinal en-boy (Aspect Ratio) oranını koru
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // Yeni boyutta resmi çiz
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
            return id
        } catch {
            print("🛑 MediaManager Audio Save Error: \(error)")
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
            // Eğer resim siliniyorsa RAM'den de uçur
            if fileExtension == "jpg" {
                imageCache.removeObject(forKey: id as NSString)
            }
            print("🗑️ Dosya silindi: \(id).\(fileExtension)")
        } catch {
            print("⚠️ Dosya silinemedi veya zaten yok: \(error)")
        }
    }
}
