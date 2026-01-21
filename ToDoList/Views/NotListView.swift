import SwiftUI

struct NotListView: View {
    @StateObject var viewModel = NotViewModel()
    @State private var yeniNotEkleGoster = false
    
    // Yeni not için geçici değişkenler
    @State private var yeniBaslik = ""
    @State private var yeniIcerik = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.notlar) { not in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(not.baslik)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(not.icerik)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(2) // Listede çok uzun görünmesin
                        
                        Text(not.tarih.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: viewModel.notSil)
            }
            .navigationTitle("Not Defteri 📒")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { yeniNotEkleGoster = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $yeniNotEkleGoster) {
                NavigationStack {
                    Form {
                        Section("Başlık") {
                            TextField("Örn: Proje Fikirleri", text: $yeniBaslik)
                        }
                        
                        Section("Notun") {
                            // TextEditor uzun yazılar yazmanı sağlar
                            TextEditor(text: $yeniIcerik)
                                .frame(height: 200)
                        }
                    }
                    .navigationTitle("Yeni Not")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("İptal") {
                                yeniNotEkleGoster = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Kaydet") {
                                if !yeniBaslik.isEmpty {
                                    viewModel.notEkle(baslik: yeniBaslik, icerik: yeniIcerik)
                                    // Temizlik
                                    yeniBaslik = ""
                                    yeniIcerik = ""
                                    yeniNotEkleGoster = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NotListView()
}
