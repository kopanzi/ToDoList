import Foundation
import LocalAuthentication

/// FaceID, TouchID ve biyometrik doğrulama işlemlerini yöneten servis.
/// Senior Notu: Callback yapısı yerine 'async/await' kullanılarak daha temiz ve güvenli bir akış sağlanmıştır.
final class AuthService {
    
    // MARK: - Singleton
    static let shared = AuthService()
    private init() {}
    
    // MARK: - Custom Errors
    enum AuthError: Error {
        case notAvailable
        case failed
        case userCancelled
        case unknown(String)
        
        var description: String {
            switch self {
            case .notAvailable: return "Biyometrik doğrulama bu cihazda kullanılamıyor."
            case .failed: return "Kimlik doğrulaması başarısız oldu."
            case .userCancelled: return "Kullanıcı işlemi iptal etti."
            case .unknown(let msg): return msg
            }
        }
    }

    // MARK: - Public Methods
    
    /// Kullanıcıyı biyometrik olarak doğrular.
    /// - Parameter reason: Kullanıcıya gösterilecek olan doğrulama nedeni.
    /// - Returns: Doğrulama başarılı ise 'true', aksi halde hata fırlatır.
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // 1. Cihazın biyometri desteğini kontrol et
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Simülatör veya desteklemeyen cihazlar için geliştirme kolaylığı:
            #if targetEnvironment(simulator)
            print("⚠️ Simülatörde otomatik doğrulama sağlandı.")
            return true
            #else
            throw AuthError.notAvailable
            #endif
        }
        
        // 2. Doğrulamayı başlat
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                return true
            } else {
                throw AuthError.failed
            }
        } catch let error as LAError {
            // Spesifik hata yönetimi
            switch error.code {
            case .userCancel:
                throw AuthError.userCancelled
            case .biometryNotAvailable:
                throw AuthError.notAvailable
            default:
                throw AuthError.unknown(error.localizedDescription)
            }
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
}
