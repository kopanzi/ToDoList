import SwiftUI

struct GorevDetayView: View {
    let gorev: GorevModel
    @ObservedObject var viewModel: GorevViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Başlık
                Text(gorev.baslik)
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                Divider()
                
                // --- GEMINI YAPAY ZEKA ALANI ---
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Gemini Asistan")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                    }
                    
                    if viewModel.aiMesgulMu {
                        HStack {
                            Spacer()
                            ProgressView("Gemini düşünüyor...")
                            Spacer()
                        }
                        .padding()
                    } else if !viewModel.aiYaniti.isEmpty {
                        // Cevap Geldiğinde
                        Text(viewModel.aiYaniti)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    } else {
                        // Buton
                        Button(action: {
                            Task {
                                await viewModel.yapayZekayaDanis(gorev: gorev)
                            }
                        }) {
                            HStack {
                                Text("Tavsiye İste")
                                    .bold()
                                Image(systemName: "wand.and.stars")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(15)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Detaylar")
        .onDisappear {
            viewModel.aiYaniti = "" // Çıkınca cevabı temizle
        }
    }
}
