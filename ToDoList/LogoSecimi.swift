import SwiftUI

struct LogoSecimi: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Hangi 'Tosun App' Logosu?")
                    .font(.title)
                    .bold()
                    .padding(.top)
                
                // SEÇENEK 1: TOSUN PAŞA (Kraliyet)
                // Tema: Rütbe, Güç, Liderlik
                VStack {
                    Text("1. Tosun Paşa").font(.headline)
                    ZStack {
                        LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "crown.fill") // Taç İkonu
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .foregroundColor(.yellow)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                    }
                    .frame(width: 150, height: 150)
                    .cornerRadius(30) // App İkonu şekli
                    .shadow(radius: 10)
                }
                
                // SEÇENEK 2: ODAKLANMA (Productivity)
                // Tema: İş bitirici, Tik Atma, Başarı
                VStack {
                    Text("2. İş Bitirici").font(.headline)
                    ZStack {
                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "checkmark.circle.fill") // Tik İkonu
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                    .frame(width: 150, height: 150)
                    .cornerRadius(30)
                    .shadow(radius: 10)
                }
                
                // SEÇENEK 3: EFSANE (Yıldız)
                // Tema: Hedef, Zirve, Popülerlik
                VStack {
                    Text("3. Efsane").font(.headline)
                    ZStack {
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "star.fill") // Yıldız İkonu
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                    .frame(width: 150, height: 150)
                    .cornerRadius(30)
                    .shadow(radius: 10)
                }
                
                // SEÇENEK 4: MİNİMALİST (Modern)
                // Tema: Sade, Temiz, Profesyonel
                VStack {
                    Text("4. Minimalist").font(.headline)
                    ZStack {
                        Color.black // Simsiyah
                        Image(systemName: "list.bullet.circle.fill") // Liste İkonu
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .foregroundColor(.white)
                    }
                    .frame(width: 150, height: 150)
                    .cornerRadius(30)
                    .shadow(radius: 10)
                }
            }
            .padding()
        }
    }
}

#Preview {
    LogoSecimi()
}
