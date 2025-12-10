import SwiftUI

// 1. ADIM: Sadece yazı değil, detaylı bir "Görev" modeli oluşturuyoruz.
struct GorevModeli: Identifiable {
    let id = UUID() // Her görevin benzersiz bir kimliği olur
    var baslik: String
    var tamamlandi: Bool = false // Başlangıçta tamamlanmamış olsun
}

struct ContentView: View {
    // String listesi yerine artık kendi modelimizin listesini tutuyoruz
    @State private var gorevler = [
        GorevModeli(baslik: "SwiftUI Öğren"),
        GorevModeli(baslik: "Spor Yap", tamamlandi: true), // Örnek dolu gelsin
        GorevModeli(baslik: "Kahve İç")
    ]
    @State private var yeniGorev = ""

    var body: some View {
        VStack {
            Text("Pro Planlayıcı")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.indigo)
                .padding(.top)

            // Ekleme Kısmı (Tasarımı güzelleştirdik)
            HStack {
                TextField("Bugün ne yapacaksın?", text: $yeniGorev)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                Button(action: gorevEkle) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .disabled(yeniGorev.isEmpty) // Boşsa buton çalışmasın
            }
            .padding()

            // Liste Kısmı
            List {
                ForEach($gorevler) { $gorev in // $ işareti veriyi değiştirebilmek için
                    HStack {
                        // Tıklanabilir İkon
                        Image(systemName: gorev.tamamlandi ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(gorev.tamamlandi ? .green : .gray)
                            .font(.title2)
                            .onTapGesture {
                                // Animasyonlu geçiş
                                withAnimation {
                                    gorev.tamamlandi.toggle()
                                }
                            }
                        
                        // Görev Yazısı
                        Text(gorev.baslik)
                            .strikethrough(gorev.tamamlandi) // Tamamlandıysa üstünü çiz
                            .foregroundColor(gorev.tamamlandi ? .gray : .primary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: silmeIslemi)
            }
            .listStyle(.plain) // Daha temiz bir görünüm
        }
    }
    
    func gorevEkle() {
        let yeni = GorevModeli(baslik: yeniGorev)
        withAnimation {
            gorevler.append(yeni)
        }
        yeniGorev = ""
    }
    
    func silmeIslemi(at offsets: IndexSet) {
        withAnimation {
            gorevler.remove(atOffsets: offsets)
        }
    }
}

#Preview {
    ContentView()
}
