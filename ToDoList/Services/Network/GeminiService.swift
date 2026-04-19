import Foundation

/// Google AI Studio (Gemini) üzerinden yapay zeka işlemleri yapan güncel servis.
/// Senior Notu: 429 (Rate Limit) hatalarını aşmak için 'Exponential Backoff' algoritması eklenmiştir.
final class GeminiService {
    
    // API anahtarını Secrets dosyasından anlık okur
    private var apiKey: String {
        return Secrets.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Google'ın en güncel ve zeki modeli
    private let modelName = "gemini-2.5-flash"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/"
    
    // MARK: - Google API Response Models
    struct GeminiResponse: Decodable {
        let candidates: [Candidate]?
        struct Candidate: Decodable { let content: Content? }
        struct Content: Decodable { let parts: [Part]? }
        struct Part: Decodable { let text: String? }
    }
    
    /// Görev başlığına göre öneri alır. Hata durumunda (Özellikle 429) otomatik tekrar dener.
    func oneriAl(gorevBasligi: String) async -> String {
        if apiKey.isEmpty || apiKey.contains("BURAYA") {
            return "⚠️ Yaver AI Uyuyor: Lütfen Secrets.swift dosyasına Google AI Studio anahtarınızı girin."
        }
        
        let prompt = """
        Sen 'Yaver' adında, kullanıcının hayatını organize eden zeki ve motive edici bir üretkenlik asistanısın.
        Görev veya Not: "\(gorevBasligi)"
        Lütfen bana kısa, enerjik ve hemen uygulanabilir 3 maddelik bir tavsiye ver. Sadece maddeleri yaz.
        """
        
        // 🛠️ SENIOR FIX: EXPONENTIAL BACKOFF (Kademeli Tekrar Deneme)
        let maxRetries = 3
        var currentDelay = 2.0 // İlk denemede 2 saniye bekle
        
        for attempt in 0...maxRetries {
            let result = await fetchFromGoogle(prompt: prompt)
            
            switch result {
            case .success(let text):
                return text // 🎉 Başarılıysa direkt cevabı dön
                
            case .rateLimitError:
                if attempt < maxRetries {
                    print("⚠️ [Gemini] 429 Kotası. Yaver \(currentDelay) saniye bekleyip tekrar deniyor... (Deneme: \(attempt + 1)/\(maxRetries))")
                    // Bekleme süresi: 2s -> 4s -> 8s
                    try? await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
                    currentDelay *= 2.0
                    continue // Döngüyü kırma, tekrar dene
                } else {
                    return "Yaver şu an dünyadaki diğer insanlara yardım etmekle çok meşgul. Lütfen 1 dakika sonra tekrar tıkla ⏱️"
                }
                
            case .failure(let errorMsg):
                return errorMsg // Diğer hataları (400, İnternet vs.) direkt göster
            }
        }
        
        return "Bilinmeyen bir hata oluştu."
    }
    
    // MARK: - Network Helper
    
    private enum APIResult {
        case success(String)
        case rateLimitError
        case failure(String)
    }
    
    private func fetchFromGoogle(prompt: String) async -> APIResult {
        guard let url = URL(string: "\(baseURL)\(modelName):generateContent?key=\(apiKey)") else {
            return .failure("URL Hatası")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let bundleID = Bundle.main.bundleIdentifier {
            request.addValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
        
        let jsonBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    let text = decoded.candidates?.first?.content?.parts?.first?.text ?? "Yaver cevabı işleyemedi."
                    return .success(text)
                    
                } else if httpResponse.statusCode == 429 {
                    // Sinyali Exponential Backoff sistemine gönder
                    return .rateLimitError
                    
                } else if httpResponse.statusCode == 400 {
                    return .failure("Yaver: API Anahtarı geçersiz veya hatalı kopyalanmış.")
                    
                } else {
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorDict = errorJson["error"] as? [String: Any],
                       let message = errorDict["message"] as? String {
                        return .failure("Google AI Hatası: \(message)")
                    }
                    return .failure("Google AI Bağlantı Hatası: \(httpResponse.statusCode)")
                }
            }
        } catch {
            return .failure("İnternet bağlantınızı kontrol edin.")
        }
        
        return .failure("Bilinmeyen bir bağlantı hatası oluştu.")
    }
}
