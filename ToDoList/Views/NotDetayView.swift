import SwiftUI

struct NotDetayView: View {
    let not: NotModel
    @ObservedObject var viewModel: NotViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 1. ÇOKLU RESİM GALERİSİ
                if !not.gorselVerileri.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(0..<not.gorselVerileri.count, id: \.self) { index in
                                if let uiImage = UIImage(data: not.gorselVerileri[index]) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 300, height: 250) // Biraz büyük ve şık
                                        .cornerRadius(12)
                                        .shadow(radius: 5)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                }
                
                // 2. SES OYNATICI
                if let sesData = not.sesData {
                    VStack {
                        HStack {
                            Image(systemName: "waveform").font(.title2).foregroundColor(.white).padding(10).background(Circle().fill(Color.blue))
                            VStack(alignment: .leading) {
                                Text("Ses Kaydı").font(.headline)
                                Text("Kayıt Eklendi").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: { viewModel.hariciSesiOynat(data: sesData) }) {
                                Image(systemName: viewModel.oynatiliyorMu ? "stop.circle.fill" : "play.circle.fill").font(.system(size: 40)).foregroundColor(.blue)
                            }
                        }
                        .padding().background(Color(.secondarySystemBackground)).cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Divider().padding(.horizontal)
                
                // 3. İÇERİK
                VStack(alignment: .leading, spacing: 10) {
                    Text(not.baslik).font(.largeTitle).fontWeight(.bold)
                    Text(not.tarih.formatted(date: .long, time: .shortened)).font(.subheadline).foregroundColor(.gray)
                    Text(not.icerik).font(.body).lineSpacing(5).padding(.top, 5)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Not Detayı")
        .navigationBarTitleDisplayMode(.inline)
    }
}
