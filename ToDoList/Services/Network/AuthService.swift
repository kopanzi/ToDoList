import Foundation
import LocalAuthentication

/// FaceID, TouchID ve cihaz şifresi (Passcode) doğrulama işlemlerini yöneten merkezi servis.
/// Senior Notu: Sadece biyometriye bel bağlamak yerine, biyometri başarısız olduğunda
/// otomatik olarak cihaz şifresine (Fallback) geçiş yapan daha güvenli bir mimari kullanılmıştır.
final class AuthService {
    
    // MARK: - Singleton
    static let shared = AuthService()
    private init() {}
    
    // MARK: - Custom Errors
    enum AuthError: Error, LocalizedError {
        case notAvailable
        case failed
        case userCancelled
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .notAvailable: return "Biyometrik veya şifreli doğrulama bu cihazda ayarlanmamış."
            case .failed: return "Kimlik doğrulaması başarısız oldu."
            case .userCancelled: return "Kullanıcı doğrulama işlemini iptal etti."
            case .unknown(let msg): return msg
            }
        }
    }

    // MARK: - Public Methods
    
    /// Kullanıcıyı biyometrik veya cihaz şifresi ile doğrular.
    /// - Parameter reason: Kullanıcıya gösterilecek olan doğrulama nedeni (iOS tarafından ekranda basılır).
    /// - Returns: Doğrulama başarılı ise 'true', aksi halde hata fırlatır.
    func authenticate(reason: String) async throws -> Bool {
        // ✨ SENIOR TIP: Her doğrulama için yeni bir context oluşturmak, önceki oturumun
        // durum kalıntılarını temizler ve güvenliği artırır.
        let context = LAContext()
        context.localizedFallbackTitle = "Şifre Kullan" // Biyometri başarısız olursa çıkacak yazı
        
        var error: NSError?
        
        // 1. Politika Seçimi: deviceOwnerAuthentication biyometri + şifre desteği sağlar.
        // Bu sayede yüzü maskeli veya parmağı ıslak olan kullanıcı uygulamadan dışlanmaz.
        let policy: LAPolicy = .deviceOwnerAuthentication
        
        // 2. Destek Kontrolü
        guard context.canEvaluatePolicy(policy, error: &error) else {
            #if targetEnvironment(simulator)
            print("⚠️ Simülatörde geliştirici kolaylığı için doğrulama atlandı.")
            return true
            #else
            throw AuthError.notAvailable
            #endif
        }
        
        // 3. Doğrulamayı Başlat
        do {
            let success = try await context.evaluatePolicy(
                policy,
                localizedReason: reason
            )
            
            if success {
                return true
            } else {
                throw AuthError.failed
            }
        } catch let error as LAError {
            // ✨ SENIOR ERROR HANDLING: Apple'ın spesifik hata kodlarını yakala
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                throw AuthError.userCancelled
            case .biometryNotAvailable, .passcodeNotSet:
                throw AuthError.notAvailable
            case .authenticationFailed:
                throw AuthError.failed
            default:
                throw AuthError.unknown(error.localizedDescription)
            }
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
}
