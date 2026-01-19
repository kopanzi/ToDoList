import SwiftUI
import Charts

struct IstatistikView: View {
    @ObservedObject var viewModel: GorevViewModel
    
    // Animasyon için state
    @State private var animasyonBaslat = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 🏆 1. BÖLÜM: OYUNCU PROFİLİ (Burası ekran görüntünde eksik olan kısım)
                rutbeVeSeviyeKarti
                    .padding(.horizontal)
                
                // 📊 2. BÖLÜM: GENEL SAYILAR
                HStack(spacing: 16) {
                    OzetKarti(baslik: "Toplam", sayi: viewModel.gorevler.count, ikon: "list.bullet", renk: .blue)
                    OzetKarti(baslik: "Biten", sayi: tamamlananSayisi, ikon: "checkmark.circle.fill", renk: .green)
                    OzetKarti(baslik: "Kalan", sayi: kalanSayisi, ikon: "hourglass", renk: .orange)
                }
                .padding(.horizontal)
                
                // 🍩 3. BÖLÜM: DURUM ANALİZİ
                VStack(alignment: .leading, spacing: 10) {
                    Text("Durum Analizi")
                        .font(.headline)
                        .padding(.leading, 5)
                    
                    if viewModel.gorevler.isEmpty {
                        bosVeriMesaji
                    } else {
                        Chart {
                            SectorMark(
                                angle: .value("Durum", tamamlananSayisi),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(Color.green.gradient)
                            .cornerRadius(5)
                            
                            SectorMark(
                                angle: .value("Durum", kalanSayisi),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(Color.orange.gradient)
                            .cornerRadius(5)
                        }
                        .frame(height: 220)
                        .chartBackground { proxy in
                            GeometryReader { geo in
                                VStack {
                                    Text("%\(basariOrani)")
                                        .font(.title).bold()
                                    Text("Başarı")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                .frame(width: geo.size.width, height: geo.size.height)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .padding(.horizontal)
                
                // 📊 4. BÖLÜM: ÖNEM DAĞILIMI
                VStack(alignment: .leading, spacing: 10) {
                    Text("Öncelik Dağılımı")
                        .font(.headline)
                        .padding(.leading, 5)
                    
                    if viewModel.gorevler.isEmpty {
                        bosVeriMesaji
                    } else {
                        Chart {
                            ForEach(OnemDerecesi.allCases, id: \.self) { onem in
                                let adet = viewModel.gorevler.filter { $0.onem == onem }.count
                                
                                BarMark(
                                    x: .value("Önem", onem.rawValue),
                                    y: .value("Adet", adet)
                                )
                                .foregroundStyle(onem.renk.gradient)
                            }
                        }
                        .frame(height: 200)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .padding(.horizontal)
                
                Spacer().frame(height: 50)
            }
            .padding(.top)
        }
        .navigationTitle("İstatistikler")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withAnimation(.spring(duration: 1.5)) {
                animasyonBaslat = true
            }
        }
    }
    
    // MARK: - ALT GÖRÜNÜMLER
    
    // 🏆 Rütbe Kartı Tasarımı (Ekran görüntünde olmayan kısım burası)
    var rutbeVeSeviyeKarti: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: viewModel.rutbe.ikon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(viewModel.rutbe.renk)
                    .padding(10)
                    .background(viewModel.rutbe.renk.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.rutbe.isim)
                        .font(.title2)
                        .bold()
                    Text("Toplam XP: \(viewModel.kullaniciXP)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "medal.fill")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                    .shadow(color: .orange.opacity(0.5), radius: 5, x: 0, y: 5)
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Sonraki Seviye")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("%\(Int(viewModel.rutbeIlerlemesi * 100))")
                        .font(.caption)
                        .bold()
                        .foregroundColor(viewModel.rutbe.renk)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        Capsule()
                            .fill(LinearGradient(colors: [viewModel.rutbe.renk, .purple], startPoint: .leading, endPoint: .trailing))
                            .frame(width: animasyonBaslat ? max(0, geometry.size.width * viewModel.rutbeIlerlemesi) : 0, height: 12)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(20)
        .background(Color(.systemBackground)) // Dark mode uyumlu
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    var bosVeriMesaji: some View {
        Text("Veri yok").font(.caption).foregroundColor(.gray)
    }
    
    // MARK: - HESAPLAMALAR
    var tamamlananSayisi: Int { viewModel.gorevler.filter { $0.tamamlandi }.count }
    var kalanSayisi: Int { viewModel.gorevler.filter { !$0.tamamlandi }.count }
    
    var basariOrani: Int {
        guard !viewModel.gorevler.isEmpty else { return 0 }
        return Int((Double(tamamlananSayisi) / Double(viewModel.gorevler.count)) * 100)
    }
}

// 📦 Küçük Kart Bileşeni
struct OzetKarti: View {
    let baslik: String
    let sayi: Int
    let ikon: String
    let renk: Color
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: ikon)
                    .font(.caption)
                Text(baslik)
                    .font(.caption)
                    .bold()
            }
            .foregroundColor(renk.opacity(0.8))
            
            Text("\(sayi)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(renk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
