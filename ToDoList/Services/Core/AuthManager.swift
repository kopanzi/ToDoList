import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import Combine

/// Yaver'in Kimlik Doğrulama (Authentication) Merkezi.
final class AuthManager: NSObject, ObservableObject { // ✨ SENIOR FIX 1: Özel butonlar için NSObject eklendi
    
    static let shared = AuthManager()
    
    @Published var userSession: FirebaseAuth.User?
    @Published var isLoading: Bool = false
    
    private var currentNonce: String?
    private var appleSignInContinuation: CheckedContinuation<Void, Error>? // ✨ SENIOR FIX 2: Özel Apple Butonu Bekleticisi
    
    private override init() { // ✨ SENIOR FIX 3: NSObject Override eklendi
        super.init()
        // Firebase giriş durumunu dinle
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
        }
    }
    
    // MARK: - 1. GOOGLE İLE GİRİŞ YAP
    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let rootViewController = Utilities.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = signInResult.user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        _ = try await Auth.auth().signIn(with: credential)
    }
    
    // MARK: - 2. APPLE İLE GİRİŞ (ÖZEL BUTONLAR İÇİN YENİ METOT) ✨
    @MainActor
    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            // Nonce üret ve request'e ekle
            let nonce = randomNonceString()
            self.currentNonce = nonce
            request.nonce = sha256(nonce)
            
            // Apple ekranını tetikle
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    // MARK: - 3. APPLE İLE GİRİŞ (ARKA PLAN İŞLEMLERİ)
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else { throw URLError(.userAuthenticationRequired) }
                guard let appleIDToken = appleIDCredential.identityToken else { throw URLError(.badServerResponse) }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { throw URLError(.badServerResponse) }
                
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )
                
                _ = try await Auth.auth().signIn(with: credential)
            }
        case .failure(let error):
            throw error
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
    
    // MARK: - CRYPTO HELPERS
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess { fatalError("Nonce üretilemedi.") }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign In Delegates (Özel Buton Adaptörü) ✨
extension AuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return Utilities.shared.topViewController()?.view.window ?? UIWindow()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            do {
                try await self.handleAppleCompletion(.success(authorization))
                self.appleSignInContinuation?.resume(returning: ())
                self.appleSignInContinuation = nil
            } catch {
                self.appleSignInContinuation?.resume(throwing: error)
                self.appleSignInContinuation = nil
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.appleSignInContinuation?.resume(throwing: error)
        self.appleSignInContinuation = nil
    }
}
