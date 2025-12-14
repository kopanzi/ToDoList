import SwiftUI

struct GorevListView: View {
    @StateObject private var viewModel = GorevViewModel()
    
    @State private var yeniGorevBaslik = ""
    @State private var secilenOnem: OnemDerecesi = .orta
    @State private var secilenTarih = Date()

    var body: some View {
        NavigationStack {
            VStack {
                // --- EKLEME ALANI ---
                VStack(spacing: 12) {
                    TextField("Bugün ne yapacaksın?", text: $yeniGorevBaslik)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    HStack {
                        DatePicker("", selection: $secilenTarih)
                            .labelsHidden()
                        
                        Picker("Önem", selection: $secilenOnem) {
                            ForEach(OnemDerecesi.allCases, id: \.self) { onem in
                                Text(onem.rawValue).tag(onem)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Spacer()
                        
                        Button(action: gorevEkle) {
                            Text("Ekle")
                                .bold()
                                .frame(width: 70, height: 30)
                                .background(yeniGorevBaslik.isEmpty ? Color.gray : Color.indigo)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(yeniGorevBaslik.isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.1))
                
                // --- LİSTE ALANI ---
                List {
                    ForEach(viewModel.gorevler) { gorev in
                        // Detay sayfasına giderken viewModel'i de gönderiyoruz
                        NavigationLink(destination: GorevDetayView(gorev: gorev, viewModel: viewModel)) {
                            HStack {
                                Image(systemName: gorev.tamamlandi ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(gorev.tamamlandi ? .green : .gray)
                                    .onTapGesture {
                                        viewModel.durumDegistir(gorev: gorev)
                                    }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(gorev.baslik)
                                        .strikethrough(gorev.tamamlandi)
                                        .foregroundColor(gorev.tamamlandi ? .gray : .primary)
                                    
                                    HStack {
                                        Text(gorev.onem.rawValue)
                                            .font(.caption)
                                            .padding(4)
                                            .background(gorev.onem.renk.opacity(0.2))
                                            .foregroundColor(gorev.onem.renk)
                                            .cornerRadius(4)
                                        
                                        Text(gorev.tarih.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: viewModel.gorevSil)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Yapılacaklar")
            // ✅ YENİ EKLENEN KISIM: İstatistik Butonu
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: IstatistikView(viewModel: viewModel)) {
                        Image(systemName: "chart.pie.fill") // Grafik ikonu
                            .foregroundColor(.indigo)
                    }
                }
            }
        }
    }
    
    func gorevEkle() {
        viewModel.gorevEkle(baslik: yeniGorevBaslik, onem: secilenOnem, tarih: secilenTarih)
        yeniGorevBaslik = ""
        secilenOnem = .orta
        secilenTarih = Date()
    }
}

#Preview {
    GorevListView()
}
