import SwiftUI

struct ContentView: View {
    // Hangi sekmenin seçili olduğunu tutar (Varsayılan 0: Görevler)
    @State private var seciliSekme = 0
    
    var body: some View {
        TabView(selection: $seciliSekme) {
            
            // 1. SEKME: Senin Mevcut Görev Listen
            GorevListView()
                .tabItem {
                    Label("Görevler", systemImage: "checklist")
                }
                .tag(0)
            
            // 2. SEKME: Yeni Yaptığımız Not Defteri
            NotListView()
                .tabItem {
                    Label("Notlar", systemImage: "note.text")
                }
                .tag(1)
            
        }
        .tint(.blue) // Sekme rengini mavi yapar
    }
}

#Preview {
    ContentView()
}
