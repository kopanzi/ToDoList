import SwiftUI
import PhotosUI
import AVFoundation
import UserNotifications

struct GorevDetayView: View {
    // MARK: - Değişkenler
    var gorev: GorevModel
    @ObservedObject var viewModel: GorevViewModel
    
    // 🍅 YENİ: MERKEZİ POMODORO YÖNETİCİSİ
    // Artık sayaç buradan yönetiliyor, sayfa kapansa da çalışır.
    @ObservedObject var pomodoro = PomodoroManager.shared
    
    // 🧠 GEMINI SERVİSİ
    private let geminiService = GeminiService()
    @State private var geminiYukleniyor = false
    
    // 🎤 Ses Yöneticisi
    @StateObject private var sesYoneticisi = SesYoneticisi()
    
    // 📝 Metin Girişi
    @State private var notMetni: String = ""
    @FocusState private var klavyeOdakli: Bool
    
    // 📸 Görsel İşlemleri
    @State private var secilenFotoItemleri: [PhotosPickerItem] = []
    @State private var ekrandakiGorseller: [UIImage] = []
    
    // 🎥 Kamera İşlemleri
    @State private var kameraAcik = false
    @State private var kameradanGelenResim: UIImage?
    
    // 🖼️ Tam Ekran Modu
    @State private var tamEkranAcik: Bool = false
    @State private var secilenGorselIndex: Int = 0
    
    // 🎨 Tema Rengi
    @AppStorage("secilenTema") private var secilenTemaStr = Tema.mavi.rawValue
    var temaRengi: Color { Tema(rawValue: secilenTemaStr)?.renk ?? .blue }
    
    // Yardımcı: Süre Formatı (05:00 gibi)
    func sureyiFormatla(_ saniye: TimeInterval) -> String {
        let dakika = Int(saniye) / 60
        let saniye = Int(saniye) % 60
        return String(format: "%02d:%02d", dakika, saniye)
    }

    // MARK: - Arayüz (Body)
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // --- 1. ÜST BİLGİ & SİHİRLİ DEĞNEK ✨ ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Text(gorev.baslik)
                            .font(.title).bold()
                            .strikethrough(gorev.tamamlandi)
                            .foregroundColor(gorev.tamamlandi ? .gray : .primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // ✨ GEMINI BUTONU
                        if !geminiYukleniyor {
                            Button(action: {
                                Task {
                                    geminiYukleniyor = true
                                    let oneri = await geminiService.oneriAl(gorevBasligi: gorev.baslik)
                                    notMetni += "\n\n🤖 Gemini Önerisi:\n" + oneri
                                    geminiYukleniyor = false
                                }
                            }) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .shadow(color: .purple.opacity(0.4), radius: 5, x: 0, y: 3)
                                    )
                            }
                        } else {
                            ProgressView().scaleEffect(1.2).tint(.purple)
                        }
                    }
                    
                    HStack {
                        Label(gorev.tarih.formatted(date: .long, time: .shortened), systemImage: "calendar")
                            .font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Text(gorev.onem.rawValue)
                            .font(.caption).bold().padding(.horizontal, 10).padding(.vertical, 5)
                            .background(gorev.onem.renk.opacity(0.15)).foregroundColor(gorev.onem.renk).clipShape(Capsule())
                    }
                    
                    if geminiYukleniyor {
                        Text("Yapay zeka düşünüyor... 🧠").font(.caption).italic().foregroundColor(.purple)
                    }
                }
                .padding().background(Color(.secondarySystemBackground)).cornerRadius(16).padding(.horizontal)
                
                // --- 🍅 2. POMODORO ODAKLANMA SAYACI (GÜNCELLENDİ) ---
                // Artık verileri PomodoroManager'dan (pomodoro değişkeni) alıyor.
                VStack(spacing: 15) {
                    HStack {
                        Label(pomodoro.molaModu ? "Mola Zamanı ☕️" : "Odaklanma Modu 🍅", systemImage: pomodoro.molaModu ? "cup.and.saucer.fill" : "timer")
                            .font(.headline)
                            .foregroundColor(pomodoro.molaModu ? .green : .orange)
                        
                        Spacer()
                        
                        // Eğer aktif görev bu değilse uyarı gösterebiliriz (Opsiyonel)
                        if pomodoro.calisiyor && pomodoro.aktifGorevId != nil && pomodoro.aktifGorevId != gorev.id {
                             Text("Başka görevde aktif")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack(spacing: 20) {
                        // HALKA GRAFİK
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(pomodoro.kalanSure) / CGFloat(pomodoro.toplamSure))
                                .stroke(pomodoro.molaModu ? Color.green : Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1), value: pomodoro.kalanSure)
                            
                            Text(sureyiFormatla(Double(pomodoro.kalanSure)))
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                        }
                        .frame(width: 100, height: 100)
                        
                        // KONTROLLER
                        VStack(spacing: 12) {
                            Button(action: {
                                if pomodoro.calisiyor {
                                    // Eğer bu görevde çalışıyorsa veya genel durdurma isteniyorsa
                                    pomodoro.durdur()
                                } else {
                                    // Bu görev için başlat
                                    pomodoro.baslat(gorevId: gorev.id)
                                }
                            }) {
                                Label(pomodoro.calisiyor ? "Durdur" : "Başlat", systemImage: pomodoro.calisiyor ? "pause.fill" : "play.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(pomodoro.calisiyor ? Color.red : (pomodoro.molaModu ? Color.green : Color.orange))
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                pomodoro.sifirla()
                            }) {
                                Text("Sıfırla")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // --- 3. SESLİ NOT ALANI 🎤 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sesli Not").font(.headline).padding(.horizontal)
                    
                    if let sesData = sesYoneticisi.sesVerisi {
                        // OYNATICI
                        HStack(spacing: 12) {
                            Button(action: {
                                if sesYoneticisi.oynatiliyor { sesYoneticisi.oynatmayiDurdur() }
                                else { sesYoneticisi.sesiOynat(data: sesData) }
                            }) {
                                Image(systemName: sesYoneticisi.oynatiliyor ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 32)).foregroundColor(temaRengi)
                            }
                            
                            VStack(spacing: 2) {
                                Slider(value: Binding(get: { sesYoneticisi.suankiSure }, set: { yeni in sesYoneticisi.zamanaGit(saniye: yeni) }), in: 0...(sesYoneticisi.toplamSure > 0 ? sesYoneticisi.toplamSure : 1)).tint(temaRengi)
                                HStack { Text(sureyiFormatla(sesYoneticisi.suankiSure)); Spacer(); Text(sureyiFormatla(sesYoneticisi.toplamSure)) }
                                    .font(.caption2).foregroundColor(.gray).monospacedDigit()
                            }
                            
                            Button(action: {
                                sesYoneticisi.sesVerisi = nil; sesYoneticisi.oynatmayiDurdur(); sesYoneticisi.suankiSure = 0
                            }) { Image(systemName: "trash").font(.caption).foregroundColor(.red).padding(8).background(Color.red.opacity(0.1)).clipShape(Circle()) }
                        }
                        .padding(12).background(Color(.secondarySystemBackground)).cornerRadius(12).padding(.horizontal)
                        .onAppear {
                            if let p = try? AVAudioPlayer(data: sesData) { sesYoneticisi.toplamSure = p.duration }
                        }
                    } else {
                        // KAYIT BUTONU
                        Button(action: {
                            if sesYoneticisi.kayitYapiliyor { sesYoneticisi.kaydiDurdur() }
                            else { sesYoneticisi.kaydiBaslat() }
                        }) {
                            HStack {
                                ZStack {
                                    Circle().fill(sesYoneticisi.kayitYapiliyor ? Color.red : temaRengi.opacity(0.1)).frame(width: 40, height: 40)
                                    Image(systemName: sesYoneticisi.kayitYapiliyor ? "stop.fill" : "mic.fill").foregroundColor(sesYoneticisi.kayitYapiliyor ? .white : temaRengi)
                                }
                                Text(sesYoneticisi.kayitYapiliyor ? "Kaydediliyor..." : "Ses Kaydı Ekle").fontWeight(.medium).foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(8).background(Color(.secondarySystemBackground)).cornerRadius(12).padding(.horizontal)
                        }
                    }
                }
                
                Divider()
                
                // --- 4. GÖRSELLER ALANI 👁️ ---
                VStack(alignment: .leading) {
                    Text("Görseller").font(.headline).padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            HStack(spacing: 25) {
                                Button(action: { kameraAcik = true }) {
                                    VStack {
                                        ZStack { Circle().fill(Color(.secondarySystemBackground)).frame(width: 60, height: 60); Image(systemName: "camera.fill").font(.title2).foregroundColor(temaRengi) }
                                        Text("Kamera").font(.caption).foregroundColor(.primary)
                                    }
                                }
                                PhotosPicker(selection: $secilenFotoItemleri, maxSelectionCount: 10, matching: .images) {
                                    VStack {
                                        ZStack { Circle().fill(Color(.secondarySystemBackground)).frame(width: 60, height: 60); Image(systemName: "photo.on.rectangle").font(.title2).foregroundColor(temaRengi) }
                                        Text("Galeri").font(.caption).foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.leading)
                            
                            Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 1, height: 60)
                            
                            ForEach(0..<ekrandakiGorseller.count, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: ekrandakiGorseller[index])
                                        .resizable().scaledToFill().frame(width: 110, height: 110).clipShape(RoundedRectangle(cornerRadius: 16))
                                        .onTapGesture { secilenGorselIndex = index; tamEkranAcik = true }
                                    
                                    Button(action: {
                                        Task {
                                            geminiYukleniyor = true
                                            let analiz = await geminiService.fotograftanAnalizYap(resim: ekrandakiGorseller[index])
                                            notMetni += "\n\n👁️ Fotoğraf Analizi:\n" + analiz
                                            geminiYukleniyor = false
                                        }
                                    }) {
                                        HStack(spacing: 4) { Image(systemName: "eye.fill"); Text("Analiz") }
                                            .font(.caption2).bold().foregroundColor(.white).padding(.horizontal, 8).padding(.vertical, 4).background(Color.black.opacity(0.6)).clipShape(Capsule())
                                    }
                                    .offset(y: -5).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom).padding(.bottom, 5)
                                    
                                    Button(action: { viewModel.gorselSil(gorev: gorev, gorselIndex: index); ekrandakiGorseller.remove(at: index) }) {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.red).background(Color.white.clipShape(Circle()))
                                    }.offset(x: 5, y: -5)
                                }
                            }
                        }
                        .padding(.vertical, 10).padding(.trailing)
                    }
                }
                
                Divider()
                
                // --- 5. NOT DEFTERİ ---
                VStack(alignment: .leading) {
                    Text("Notlar").font(.headline).padding(.horizontal)
                    ZStack(alignment: .topLeading) {
                        if notMetni.isEmpty {
                            Text("Detayları buraya yazın veya Gemini'ye sor...").foregroundColor(.gray.opacity(0.5)).padding(.top, 12).padding(.leading, 16)
                        }
                        TextEditor(text: $notMetni)
                            .focused($klavyeOdakli)
                            .frame(minHeight: 150)
                            .padding(4).scrollContentBackground(.hidden).background(Color(.secondarySystemBackground)).cornerRadius(12).padding(.horizontal)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationTitle("Detaylar")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $tamEkranAcik) { TamEkranGorselView(gorseller: ekrandakiGorseller, secilenIndex: $secilenGorselIndex) }
        .sheet(isPresented: $kameraAcik) { KameraView(secilenResim: $kameradanGelenResim) }
        .onAppear {
            // Verileri yükle
            notMetni = gorev.not
            ekrandakiGorseller = gorev.gorselListesi.compactMap { UIImage(data: $0) }
            sesYoneticisi.sesVerisi = gorev.sesKaydiData
        }
        .onDisappear {
            // Çıkarken verileri kaydet
            viewModel.notuGuncelle(gorev: gorev, yeniNot: notMetni)
            viewModel.sesKaydiniGuncelle(gorev: gorev, sesData: sesYoneticisi.sesVerisi)
            // DİKKAT: timer.invalidate() ARTIK YOK. PomodoroManager çalışmaya devam edecek. ✅
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Bitti") { klavyeOdakli = false } }
        }
        .onChange(of: secilenFotoItemleri) { _, yeni in
            Task {
                var resimler: [UIImage] = []
                for item in yeni { if let d = try? await item.loadTransferable(type: Data.self), let i = UIImage(data: d) { resimler.append(i) } }
                viewModel.gorselleriEkle(gorev: gorev, yeniGorseller: resimler); ekrandakiGorseller.append(contentsOf: resimler); secilenFotoItemleri = []
            }
        }
        .onChange(of: kameradanGelenResim) { _, yeni in
            if let r = yeni { viewModel.gorselleriEkle(gorev: gorev, yeniGorseller: [r]); ekrandakiGorseller.append(r); kameradanGelenResim = nil }
        }
    }
}
