import Foundation

class GeminiService {
    // 👇 BURAYA KENDİ 'AIza' İLE BAŞLAYAN KODUNU YAPIŞTIR
    private let apiKey = Secrets.apiKey
    
    func oneriAl(gorevBasligi: String) async -> String? {
        
        // 1. Key Kontrolü
        if apiKey.contains("BURAYA_SENIN_KODUNU") || apiKey.isEmpty {
            return "🛑 HATA: API Key eksik. Lütfen kodu yapıştır."
        }
        
        // ✅ ÇÖZÜM: Listende görünen 'gemini-flash-latest' ismini kullanıyoruz.
        // Bu, hesabındaki en güncel ve çalışan Flash modelini otomatik seçer.
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return "🛑 URL Hatası" }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = "Kullanıcı görevi: \(gorevBasligi). Bu görev için 3 kısa, maddeler halinde tavsiye ver."
        
        let parameters: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Hata Kontrolü
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let hataMesaji = String(data: data, encoding: .utf8) ?? "Bilinmeyen hata"
                return "🛑 API HATASI (\(httpResponse.statusCode)): \(hataMesaji)"
            }
            
            // Cevabı Çözümle
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                return text
            } else {
                return "🛑 Cevap formatı bozuk. Gelen veri okunamadı."
            }
            
        } catch {
            return "🛑 Ağ Hatası: \(error.localizedDescription)"
        }
    }
}
