import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import Combine // ✨ FIX 1: ObservableObject için şart

/// Yaver'in Kimlik Doğrulama (Authentication) Merkezi.
final class AuthManager: ObservableObject {
    
    static let shared = AuthManager()
    
    @Published var userSession: FirebaseAuth.User?
    @Published var isLoading: Bool = false
    
    private var currentNonce: String?
    
    private init() {
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
        
        // ✨ FIX 2: GIDSignIn.shared yerine sharedInstance kullanıyoruz
        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = signInResult.user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        _ = try await Auth.auth().signIn(with: credential)
    }
    
    // MARK: - 2. APPLE İLE GİRİŞ (HAZIRLIK)
    func handleAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    // MARK: - 3. APPLE İLE GİRİŞ (BİTİŞ)
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async throws {
        isLoading = true
        defer { isLoading = false }
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else { throw URLError(.userAuthenticationRequired) }
                guard let appleIDToken = appleIDCredential.identityToken else { throw URLError(.badServerResponse) }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { throw URLError(.badServerResponse) }
                
                // ✨ FIX 3: Yeni Firebase 11 metodu
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
        GIDSignIn.sharedInstance.signOut() // ✨ FIX 4: sharedInstance
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
