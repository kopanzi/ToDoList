import SwiftUI

struct NotListView: View {
    @StateObject var viewModel = NotViewModel()
    @State private var yeniNotEkleGoster = false
    
    // Not Verileri
    @State private var yeniBaslik = ""
    @State private var yeniIcerik = ""
    @State private var secilenGorseller: [UIImage] = []
    
    // Kamera/Galeri Yönetimi
    @State private var kameradanGelenGorsel: UIImage?
    @State private var showCamera = false
    @State private var showGallery = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.notlar) { not in
                    NavigationLink(destination: NotDetayView(not: not, viewModel: viewModel)) {
                        HStack(spacing: 15) {
                            if let ilkData = not.gorselVerileri.first, let uiImage = UIImage(data: ilkData) {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFill()
                                    .frame(width: 60, height: 60).cornerRadius(8).clipped()
                            } else {
                                ZStack {
                                    Color.gray.opacity(0.1)
                                    Image(systemName: "note.text").font(.title2).foregroundColor(.gray)
                                }.frame(width: 60, height: 60).cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(not.baslik).font(.headline).lineLimit(1)
                                Text(not.icerik).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
                                HStack {
                                    if !not.gorselVerileri.isEmpty {
                                        Image(systemName: "photo.stack").font(.caption2).foregroundColor(.purple)
                                        Text("\(not.gorselVerileri.count)").font(.caption2).foregroundColor(.purple)
                                    }
                                    if not.sesData != nil {
                                        Image(systemName: "mic.fill").font(.caption2).foregroundColor(.blue)
                                    }
                                    Text(not.tarih.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2).foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: viewModel.notSil)
            }
            .navigationTitle("Not Defteri 📒")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        yeniBaslik = ""
                        yeniIcerik = ""
                        secilenGorseller = []
                        viewModel.kaydiIptalEt()
                        yeniNotEkleGoster = true
                    }) {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            // 🛡️ FORM VE PENCERELER
            .sheet(isPresented: $yeniNotEkleGoster) {
                NavigationStack {
                    Form {
                        Section { TextField("Başlık", text: $yeniBaslik).font(.headline) }
                        
                        // 📸 GÖRSELLER
                        Section("Görseller (\(secilenGorseller.count)/10)") {
                            if !secilenGorseller.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(0..<secilenGorseller.count, id: \.self) { index in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: secilenGorseller[index])
                                                    .resizable().scaledToFill()
                                                    .frame(width: 100, height: 100).cornerRadius(8).clipped()
                                                
                                                Button(action: { secilenGorseller.remove(at: index) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red).background(Circle().fill(.white))
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }.padding(.vertical, 5)
                                }
                            }
                            
                            HStack(spacing: 15) {
                                // 🎥 KAMERA BUTONU (Nükleer Yöntem: Button yerine onTapGesture)
                                ZStack {
                                    Color.blue.opacity(0.1)
                                    VStack {
                                        Image(systemName: "camera.fill").font(.title2)
                                        Text("Kamera").font(.caption).fontWeight(.semibold)
                                    }
                                    .foregroundColor(.blue)
                                    .padding()
                                }
                                .cornerRadius(10)
                                .onTapGesture {
                                    print("📸 KAMERA TIKLANDI (Gesture)")
                                    showGallery = false
                                    // Gecikmeli tetikleme (SwiftUI'a nefes aldırır)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showCamera = true
                                    }
                                }
                                
                                // 🖼️ GALERİ BUTONU
                                ZStack {
                                    Color.purple.opacity(0.1)
                                    VStack {
                                        Image(systemName: "photo.on.rectangle.angled").font(.title2)
                                        Text("Galeri").font(.caption).fontWeight(.semibold)
                                    }
                                    .foregroundColor(.purple)
                                    .padding()
                                }
                                .cornerRadius(10)
                                .onTapGesture {
                                    print("🖼️ GALERİ TIKLANDI (Gesture)")
                                    showCamera = false
                                    showGallery = true
                                }
                            }
                        }
                        
                        // 🎙️ SES KAYDI
                        Section("Ses Kaydı") {
                            if viewModel.kayitDurumu == 0 {
                                Button(action: { viewModel.kayitIsleminiBaslat() }) {
                                    Image(systemName: "mic.circle.fill").font(.system(size: 44)).foregroundColor(.red).frame(maxWidth: .infinity)
                                }.buttonStyle(.plain)
                            } else if viewModel.kayitDurumu == 1 {
                                HStack {
                                    Image(systemName: "waveform.circle.fill").font(.title).foregroundColor(.red).symbolEffect(.pulse.byLayer, options: .repeating, isActive: !viewModel.kayitDuraklatildiMi)
                                    Spacer()
                                    Text(viewModel.sureMetni).font(.title2).monospacedDigit().bold()
                                    Spacer()
                                    HStack(spacing: 20) {
                                        Button(action: { viewModel.kaydiDuraklatVeyaDevamEt() }) {
                                            Image(systemName: viewModel.kayitDuraklatildiMi ? "play.fill" : "pause.fill").font(.title2).padding(10).background(Color.orange.opacity(0.2)).clipShape(Circle()).foregroundColor(.orange)
                                        }.buttonStyle(.plain)
                                        Button(action: { viewModel.kaydiBitir() }) {
                                            Image(systemName: "stop.fill").font(.title2).padding(10).background(Color.red.opacity(0.2)).clipShape(Circle()).foregroundColor(.red)
                                        }.buttonStyle(.plain)
                                    }
                                }.padding(.vertical, 8)
                            } else if viewModel.kayitDurumu == 2 {
                                HStack(spacing: 15) {
                                    Button(action: { viewModel.sesiOynatVeyaDurdur() }) {
                                        Image(systemName: viewModel.oynatiliyorMu ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 34)).foregroundColor(.green)
                                    }.buttonStyle(.plain)
                                    Slider(value: Binding(get: { viewModel.suankiSure }, set: { viewModel.suankiSure = $0 }), in: 0...max(viewModel.toplamSure, 0.1), onEditingChanged: { editing in viewModel.sliderIleOynuyorMu = editing; if !editing { viewModel.zamanaGit(saniye: viewModel.suankiSure) } }).accentColor(.green)
                                    Button(action: { viewModel.kaydiIptalEt() }) {
                                        Image(systemName: "trash.circle.fill").font(.system(size: 34)).foregroundColor(.red)
                                    }.buttonStyle(.plain)
                                }.padding(.vertical, 8)
                            }
                        }
                        
                        Section("Not İçeriği") { TextEditor(text: $yeniIcerik).frame(height: 150) }
                    }
                    .navigationTitle("Yeni Not")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("İptal") { yeniNotEkleGoster = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Kaydet") {
                                if !yeniBaslik.isEmpty {
                                    viewModel.notEkle(baslik: yeniBaslik, icerik: yeniIcerik, gorseller: secilenGorseller, ses: viewModel.geciciSesData)
                                    yeniNotEkleGoster = false
                                }
                            }
                        }
                    }
                }
                // 🛡️ PENCERELER BURADA (Sheet'in kendisine bağlı)
                .fullScreenCover(isPresented: $showCamera) {
                    CameraPicker(selectedImage: $kameradanGelenGorsel, isPresented: $showCamera)
                        .ignoresSafeArea()
                        .onDisappear {
                            if let foto = kameradanGelenGorsel {
                                secilenGorseller.append(foto)
                                kameradanGelenGorsel = nil
                            }
                        }
                }
                .sheet(isPresented: $showGallery) {
                    MultiImagePicker(selectedImages: $secilenGorseller, isPresented: $showGallery, limit: 10)
                }
            }
        }
    }
}
