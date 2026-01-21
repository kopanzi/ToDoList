import SwiftUI

@main
struct ToDoListApp: App {
    
    // YENİ: Kullanıcının seçtiği dili hafızada tutuyoruz (Varsayılan: TR)
    @AppStorage("secilenDil") var secilenDil = "tr"
    
    init() {
        NotificationManager.shared.izinIste()
    }
    
    // Açılış ekranı değişkenleri (Seninkilerle aynı)
    @State private var launchScreenAktif = true
    @State private var launchScreenOpaklik = 1.0
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 1. ANA UYGULAMA (Altta hazır bekliyor)
                ContentView()
                    // KRİTİK EKLEME: Seçilen dili bütün sayfalara buradan zorluyoruz!
                    .environment(\.locale, Locale(identifier: secilenDil))
                    // Arapça seçilirse ekranı ters çevir (Sağdan Sola)
                    .environment(\.layoutDirection, secilenDil == "ar" ? .rightToLeft : .leftToRight)
                
                // 2. AÇILIŞ EKRANI (Üstte - Senin kodun aynısı)
                if launchScreenAktif {
                    LaunchScreenView()
                        .opacity(launchScreenOpaklik)
                        .zIndex(1)
                        .onAppear {
                            // 1.3 saniye bekle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                                
                                // Perdeyi kaldır (Fade-out)
                                withAnimation(.easeOut(duration: 1.0)) {
                                    launchScreenOpaklik = 0.0
                                }
                                
                                // View'ı tamamen yok et
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    launchScreenAktif = false
                                }
                            }
                        }
                }
            }
        }
    }
}
