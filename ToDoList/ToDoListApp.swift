import SwiftUI

@main
struct ToDoListApp: App {
    // Kullanıcının dil tercihi (Varsayılan: TR)
    @AppStorage("selectedLanguage") var selectedLanguage = "tr"
    
    // Açılış Ekranı Durumu
    @State private var isLaunchScreenActive = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 1. ANA UYGULAMA
                ContentView()
                    .environment(\.locale, Locale(identifier: selectedLanguage))
                    .environment(\.layoutDirection, selectedLanguage == "ar" ? .rightToLeft : .leftToRight)
                
                // 2. AÇILIŞ EKRANI (Launch Screen)
                if isLaunchScreenActive {
                    LaunchScreenView()
                        .zIndex(1)
                        .transition(.opacity)
                        .onAppear {
                            // 1.5 saniye sonra açılış ekranını kaldır
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    isLaunchScreenActive = false
                                }
                            }
                        }
                }
            }
        }
    }
}
