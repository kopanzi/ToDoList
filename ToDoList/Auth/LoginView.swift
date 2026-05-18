import SwiftUI
import AuthenticationServices // Apple ile giriş butonu için şart

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appearance: AppearanceManager
    
    // ✨ SENIOR FIX 1: Sistemin aydınlık/karanlık mod durumunu dinleyen Apple'ın yerel değişkeni
    @Environment(\.colorScheme) var colorScheme
    
    // ✨ YENİ: Az önce yazdığımız Kimlik Doğrulama Motorunu (AuthManager) bu sayfaya bağlıyoruz
    @ObservedObject private var authManager = AuthManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            
            // ÜST KISIM: İkon ve Başlık
            VStack(spacing: 15) {
                // Uygulama ikonu veya havalı bir sembol
                Image(systemName: "icloud.and.arrow.up.fill")
                    .font(.system(size: 60))
                    .foregroundColor(appearance.accentColor)
                    .padding(.top, 40)
                
                Text("Bulut Senkronizasyonu")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Verilerini güvence altına al. Rütbeni, XP'ni ve görevlerini tüm cihazlarında eşzamanla.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // ALT KISIM: Giriş Butonları
            VStack(spacing: 16) {
                
                // 1. APPLE İLE GİRİŞ BUTONU (Özel Tasarım ve Ortak Motor)
                Button(action: {
                    Task {
                        do {
                            // ✨ SENIOR FIX: Artık yeni ortak motorumuzu (signInWithApple) kullanıyoruz!
                            try await authManager.signInWithApple()
                            dismiss() // Başarılı olursa ekranı kapat ve geri dön
                        } catch {
                            print("Apple Giriş Hatası: \(error.localizedDescription)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title2)
                        Text("Apple ile Devam Et")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    // Aydınlık/Karanlık moda göre Apple standart renkleri
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // 2. GOOGLE İLE GİRİŞ BUTONU (Özel Tasarım)
                Button(action: {
                    // ✨ Motoru Tetikle (Safari/Google ekranını aç ve Firebase'e bağlan)
                    Task {
                        do {
                            try await AuthManager.shared.signInWithGoogle()
                            dismiss() // Başarılı olursa ekranı kapat
                        } catch {
                            print("Google Giriş Hatası: \(error.localizedDescription)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill") // Google logosu yerine geçici ikon
                            .font(.title2)
                        Text("Google ile Devam Et")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    // Google'ın marka renklerine uygun standart tasarım
                    .background(Color(UIColor.systemBackground))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        // ✨ YENİ: Motor çalışırken (internet yavaşsa vs.) butona çift tıklanmasını engelle ve yükleniyor ikonu göster
        .disabled(authManager.isLoading)
        .overlay {
            if authManager.isLoading {
                ZStack {
                    Color(uiColor: .systemBackground).opacity(0.8)
                        .ignoresSafeArea()
                    ProgressView("Giriş yapılıyor...")
                        .tint(appearance.accentColor)
                }
            }
        }
        .presentationDetents([.fraction(0.55)]) // Ekranın sadece %55'ini kaplayan havalı Sheet
        .presentationDragIndicator(.visible) // Üstteki küçük kaydırma çubuğu
    }
}

#Preview {
    LoginView()
        .environmentObject(AppearanceManager.shared)
}
