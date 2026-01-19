import Foundation
import UIKit

class GeminiService {
    
    // Şifre temizliği
    private let apiKey = Secrets.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // ✅ ÇÖZÜM: Senin konsol listende GÖRDÜĞÜMÜZ ismi kullanıyoruz: 'gemini-flash-latest'
    // Bu model hem listede var (404 vermez) hem de bedava kotası geniştir (429 vermez).
    private let commonURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"
    
    // 🧠 1. GÖREV PARÇALAMA (Sihirli Değnek)
    func oneriAl(gorevBasligi: String) async -> String {
        let prompt = "'\(gorevBasligi)' görevini başarmam için 3 ile 5 madde arasında kısa, motive edici alt adımlar listele. Sadece maddeleri yaz."
        
        let jsonBody: [String: Any] = [
            "contents": [ ["parts": [["text": prompt]]] ]
        ]
        
        return await istekGonder(urlStr: commonURL, jsonBody: jsonBody)
    }
    
    // 👁️ 2. FOTOĞRAF ANALİZİ (Göz İkonu)
    func fotograftanAnalizYap(resim: UIImage) async -> String {
        // Resmi sıkıştır
        guard let gorselData = resim.jpegData(compressionQuality: 0.3) else { return "Resim verisi hatalı." }
        let base64String = gorselData.base64EncodedString()
        
        let prompt = "Bu fotoğrafta ne görüyorsun? Bunu bir yapılacaklar listesi (To-Do) görevi olarak kısaca özetle."
        
        let jsonBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        ["inline_data": ["mime_type": "image/jpeg", "data": base64String]]
                    ]
                ]
            ]
        ]
        
        return await istekGonder(urlStr: commonURL, jsonBody: jsonBody)
    }
    
    // 📡 İSTEK GÖNDERİCİ
    private func istekGonder(urlStr: String, jsonBody: [String: Any]) async -> String {
        if apiKey.isEmpty { return "🛑 HATA: Secrets dosyasında API Key yok." }
        
        guard let url = URL(string: "\(urlStr)?key=\(apiKey)") else { return "🛑 URL Oluşturulamadı." }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let hata = String(data: data, encoding: .utf8) ?? "Bilinmeyen hata"
                print("🚨 HATA (\(httpResponse.statusCode)): \(hata)")
                
                if httpResponse.statusCode == 404 {
                     return "🔍 Model ismi hala yanlış görünüyor. Lütfen konsol çıktısını tekrar kontrol et."
                }
                
                return "Bağlantı Hatası: \(httpResponse.statusCode)"
            }
            
            // Başarılı Cevap Çözümleme
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                return text
            }
            return "Cevap anlaşılamadı."
            
        } catch {
            return "İnternet Hatası: \(error.localizedDescription)"
        }
    }
}
