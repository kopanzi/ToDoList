import SwiftUI
import Charts // Apple'ın grafik kütüphanesini içeri alıyoruz

struct IstatistikView: View {
    @ObservedObject var viewModel: GorevViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. KART: GENEL ÖZET (Büyük Sayılar)
                HStack(spacing: 20) {
                    OzetKarti(baslik: "Toplam", sayi: viewModel.gorevler.count, renk: .blue)
                    OzetKarti(baslik: "Biten", sayi: tamamlananSayisi, renk: .green)
                    OzetKarti(baslik: "Kalan", sayi: kalanSayisi, renk: .orange)
                }
                .padding(.horizontal)
                
                // 2. KART: TAMAMLANMA ORANI (Donut Grafik)
                VStack(alignment: .leading) {
                    Text("Durum Analizi")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    if viewModel.gorevler.isEmpty {
                        Text("Henüz veri yok.")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Chart {
                            // Tamamlanan Dilimi
                            SectorMark(
                                angle: .value("Durum", tamamlananSayisi),
                                innerRadius: .ratio(0.6), // Ortası delik (Donut)
                                angularInset: 2
                            )
                            .foregroundStyle(Color.green)
                            .annotation(position: .overlay) {
                                if tamamlananSayisi > 0 {
                                    Text("\(tamamlananSayisi)")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Kalan Dilimi
                            SectorMark(
                                angle: .value("Durum", kalanSayisi),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(Color.orange)
                            .annotation(position: .overlay) {
                                if kalanSayisi > 0 {
                                    Text("\(kalanSayisi)")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // 3. KART: ÖNEM DERECESİNE GÖRE (Çubuk Grafik)
                VStack(alignment: .leading) {
                    Text("Önem Dağılımı")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    if viewModel.gorevler.isEmpty {
                        Text("Henüz veri yok.")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Chart {
                            ForEach(OnemDerecesi.allCases, id: \.self) { onem in
                                // Her önem derecesi için kaç görev var sayalım
                                let adet = viewModel.gorevler.filter { $0.onem == onem }.count
                                
                                BarMark(
                                    x: .value("Önem", onem.rawValue),
                                    y: .value("Adet", adet)
                                )
                                .foregroundStyle(onem.renk) // Kendi rengini kullansın
                            }
                        }
                        .frame(height: 200)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("İstatistikler")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Yardımcı Hesaplamalar
    var tamamlananSayisi: Int {
        viewModel.gorevler.filter { $0.tamamlandi }.count
    }
    
    var kalanSayisi: Int {
        viewModel.gorevler.filter { !$0.tamamlandi }.count
    }
}

// Küçük Sayı Kartı Tasarımı
struct OzetKarti: View {
    let baslik: String
    let sayi: Int
    let renk: Color
    
    var body: some View {
        VStack {
            Text("\(sayi)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(renk)
            Text(baslik)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// Preview için sahte veri
#Preview {
    IstatistikView(viewModel: GorevViewModel())
}
