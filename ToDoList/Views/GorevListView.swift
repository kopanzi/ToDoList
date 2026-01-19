import SwiftUI

struct GorevListView: View {
    // MARK: - 1. Değişkenler ve Durum Yönetimi
    @StateObject private var viewModel = GorevViewModel()
    
    // UI Durumları
    @State private var yeniGorevBaslik = ""
    @State private var secilenOnem: OnemDerecesi = .orta
    @State private var secilenTarih = Date()
    @State private var gizliGorevOlsun = false
    @FocusState private var klavyeOdakli: Bool
    
    // 🏷️ FİLTRELEME İÇİN SEÇİLEN KATEGORİ
    @State private var filtreKategori: Kategori? = nil
    
    // ✨ YENİ GÖREV EKLERKEN SEÇİLEN KATEGORİ (Opsiyonel)
    @State private var yeniGorevKategori: Kategori? = nil
    
    // Arama Durumu
    @State private var aramaMetni = ""
    
    // Oyunlaştırma
    @State private var showKonfeti = false
    @State private var kazanilanXPGoster = false
    
    // Ayarlar
    @AppStorage("secilenTema") private var secilenTemaStr = Tema.indigo.rawValue
    @AppStorage("arkaPlanCanlilik") private var canlilik = 1.0
    @AppStorage("arkaPlanOpaklik") private var opaklik = 0.2

    // MARK: - 2. Computed Properties
    
    var temaRengi: Color { Tema(rawValue: secilenTemaStr)?.renk ?? .indigo }
    
    var arkaPlanRengi: some View {
        let anaRenk = Tema(rawValue: secilenTemaStr)?.renk ?? .indigo
        return anaRenk.saturation(canlilik).opacity(opaklik)
    }
    
    var filtrelenmisGorevler: [GorevModel] {
        var liste = viewModel.gorevler.filter { gorev in
            !gorev.gizliMi || viewModel.kasaAcik
        }
        
        // Kategori Filtresi
        if let kategori = filtreKategori {
            liste = liste.filter { $0.kategori == kategori }
        }
        
        // Arama Filtresi
        if !aramaMetni.isEmpty {
            liste = liste.filter { gorev in
                gorev.baslik.localizedCaseInsensitiveContains(aramaMetni)
            }
        }
        
        return liste
    }

    // MARK: - 3. Ana Görünüm (Body)
    
    var body: some View {
        NavigationStack {
            ZStack {
                arkaPlanRengi.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    rutbeKartiSection
                    
                    // 🏷️ Kategori Filtre Çubuğu (Üstte)
                    kategoriFiltreCubugu
                    
                    gorevEklemeSection
                    gorevListesiSection
                }
                
                efektKatmani
            }
            .navigationTitle("Yapılacaklar")
            .searchable(text: $aramaMetni, prompt: "Görev ara...")
            .toolbar { toolbarSolMenu }
            .toolbar { toolbarSagMenu }
        }
    }
}

// MARK: - 4. Alt Görünümler

private extension GorevListView {
    
    // 🏷️ Kategori Filtre Çubuğu
    @ViewBuilder
    var kategoriFiltreCubugu: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "Tümü" Butonu
                Button(action: { withAnimation { filtreKategori = nil } }) {
                    HStack {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Tümü")
                    }
                    .font(.subheadline).bold()
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(filtreKategori == nil ? Color.primary : Color.gray.opacity(0.15))
                    .foregroundColor(filtreKategori == nil ? Color(.systemBackground) : Color.primary)
                    .cornerRadius(20)
                }
                
                // Kategori Butonları
                ForEach(Kategori.allCases) { kat in
                    Button(action: {
                        withAnimation {
                            if filtreKategori == kat { filtreKategori = nil }
                            else { filtreKategori = kat }
                        }
                    }) {
                        HStack {
                            Image(systemName: kat.ikon)
                            Text(kat.rawValue)
                        }
                        .font(.subheadline).bold()
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(filtreKategori == kat ? kat.renk : Color.gray.opacity(0.15))
                        .foregroundColor(filtreKategori == kat ? .white : Color.primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
    
    // 🏆 Rütbe Kartı (Kısaltıldı, senin kodun aynısı)
    @ViewBuilder
    var rutbeKartiSection: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.rutbe.ikon).foregroundColor(viewModel.rutbe.renk)
                    Text(viewModel.rutbe.isim).font(.headline).bold()
                }
                Spacer()
                Text("\(viewModel.kullaniciXP) XP").font(.subheadline).bold().foregroundColor(temaRengi)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(colors: [temaRengi, viewModel.rutbe.renk], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geometry.size.width * viewModel.rutbeIlerlemesi), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding().background(.ultraThinMaterial).cornerRadius(16).shadow(radius: 2)
        .padding(.horizontal).padding(.top, 10)
    }
    
    // ➕ GÖREV EKLEME ALANI (GÜNCELLENDİ)
    @ViewBuilder
    var gorevEklemeSection: some View {
        if aramaMetni.isEmpty {
            VStack(spacing: 12) {
                // 1. Satır: Input, Kategori Seçici ve Kilit
                HStack(spacing: 10) {
                    
                    // 🏷️ KATEGORİ SEÇİM BUTONU (MENU)
                    Menu {
                        Button("Kategori Yok", action: { yeniGorevKategori = nil })
                        Divider()
                        ForEach(Kategori.allCases) { kat in
                            Button {
                                yeniGorevKategori = kat
                            } label: {
                                Label(kat.rawValue, systemImage: kat.ikon)
                            }
                        }
                    } label: {
                        // Seçiliyse o kategorinin ikonunu ve rengini göster
                        Image(systemName: yeniGorevKategori?.ikon ?? "tag.fill")
                            .font(.title3)
                            .foregroundColor(yeniGorevKategori?.renk ?? .gray)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    TextField("Bugün ne yapacaksın?", text: $yeniGorevBaslik)
                        .textFieldStyle(.roundedBorder)
                        .focused($klavyeOdakli)
                        .submitLabel(.done)
                        .onSubmit { gorevEkleIslemi() }
                    
                    Button(action: { withAnimation { gizliGorevOlsun.toggle() } }) {
                        Image(systemName: gizliGorevOlsun ? "lock.fill" : "lock.open")
                            .foregroundColor(gizliGorevOlsun ? .red : .gray)
                            .frame(width: 44, height: 44) // Biraz büyüttüm
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // 2. Satır: Tarih, Önem ve Ekle
                HStack {
                    DatePicker("", selection: $secilenTarih).labelsHidden().scaleEffect(0.85)
                    
                    Picker("Önem", selection: $secilenOnem) {
                        ForEach(OnemDerecesi.allCases, id: \.self) { o in Text(o.rawValue).tag(o) }
                    }
                    .pickerStyle(.menu).tint(temaRengi).fixedSize()
                    
                    Spacer()
                    
                    Button(action: gorevEkleIslemi) {
                        Image(systemName: "plus")
                            .bold().foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(yeniGorevBaslik.isEmpty ? Color.gray : temaRengi)
                            .clipShape(Circle()).shadow(radius: 2)
                    }
                    .disabled(yeniGorevBaslik.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding(.vertical).background(.ultraThinMaterial)
            .padding(.top, 10)
        }
    }
    
    // 📋 LİSTE GÖRÜNÜMÜ
    @ViewBuilder
    var gorevListesiSection: some View {
        List {
            ForEach(filtrelenmisGorevler) { gorev in
                tekGorevSatiri(gorev: gorev)
                    .listRowBackground(Color(.systemBackground).opacity(0.8))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { silmeIslemi(id: gorev.id) } label: { Label("Sil", systemImage: "trash") }
                    }
            }
            .onDelete { indexSet in
                if aramaMetni.isEmpty && filtreKategori == nil { viewModel.gorevSil(at: indexSet) }
            }
            .onMove { source, destination in
                if aramaMetni.isEmpty && filtreKategori == nil { viewModel.gorevTasi(from: source, to: destination) }
            }
        }
        .listStyle(.plain).scrollContentBackground(.hidden)
    }
    
    // 🏗️ TEK SATIR (ROZET AYARI)
    @ViewBuilder
    func tekGorevSatiri(gorev: GorevModel) -> some View {
        HStack {
            Button(action: { tamamlaVeEfektVer(gorev: gorev) }) {
                Image(systemName: gorev.tamamlandi ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(gorev.tamamlandi ? .green : .gray.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: GorevDetayView(gorev: gorev, viewModel: viewModel)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gorev.baslik)
                            .strikethrough(gorev.tamamlandi)
                            .foregroundColor(gorev.tamamlandi ? .gray : .primary)
                        
                        HStack {
                            // SADECE KATEGORİ VARSA GÖSTER
                            if let kat = gorev.kategori {
                                HStack(spacing: 4) {
                                    Image(systemName: kat.ikon).font(.caption2)
                                    Text(kat.rawValue).font(.caption2).bold()
                                }
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(kat.renk.opacity(0.2))
                                .foregroundColor(kat.renk)
                                .cornerRadius(4)
                            }
                            
                            if !gorev.tamamlandi {
                                Text(gorev.onem.rawValue)
                                    .font(.caption2).bold()
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(gorev.onem.renk.opacity(0.2))
                                    .foregroundColor(gorev.onem.renk)
                                    .cornerRadius(4)
                            }
                            Text(gorev.tarih.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if gorev.gizliMi {
                        Image(systemName: "lock.fill").font(.caption).foregroundColor(.red.opacity(0.6))
                    }
                }
            }
        }
    }
    
    // 🎉 Efektler
    @ViewBuilder
    var efektKatmani: some View {
        if showKonfeti { KonfetiView().allowsHitTesting(false) }
        if kazanilanXPGoster {
            Text("+10 XP").font(.largeTitle).bold().foregroundColor(.yellow)
                .shadow(color: .black.opacity(0.5), radius: 2)
                .transition(.move(edge: .bottom).combined(with: .opacity)).zIndex(100)
        }
    }
    
    // Menüler
    var toolbarSolMenu: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 16) {
                NavigationLink(destination: AyarlarView()) { Image(systemName: "gearshape.fill") }
                NavigationLink(destination: IstatistikView(viewModel: viewModel)) { Image(systemName: "chart.pie.fill") }
            }
            .foregroundColor(temaRengi)
        }
    }
    
    var toolbarSagMenu: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                Button(action: kilitIslemi) {
                    Image(systemName: viewModel.kasaAcik ? "lock.open.fill" : "lock.fill")
                        .foregroundColor(viewModel.kasaAcik ? .green : .primary)
                }
                EditButton().foregroundColor(temaRengi)
            }
        }
    }
    
    // MARK: - Fonksiyonlar
    func gorevEkleIslemi() {
        guard !yeniGorevBaslik.isEmpty else { return }
        
        let analizSonucu = yeniGorevBaslik.tarihAlgila()
        let sonTarih = analizSonucu.date ?? secilenTarih
        let sonBaslik = analizSonucu.temizMetin.isEmpty ? yeniGorevBaslik : analizSonucu.temizMetin
        
        withAnimation {
            // Seçilen kategoriyi (veya nil) gönderiyoruz
            viewModel.gorevEkle(baslik: sonBaslik, onem: secilenOnem, tarih: sonTarih, gizliMi: gizliGorevOlsun, kategori: yeniGorevKategori)
        }
        
        triggerHaptic(type: .success)
        sifirla()
    }
    
    func silmeIslemi(id: String) {
        if let index = viewModel.gorevler.firstIndex(where: { $0.id == id }) {
            viewModel.gorevSil(at: IndexSet(integer: index))
        }
    }
    
    func tamamlaVeEfektVer(gorev: GorevModel) {
        withAnimation(.spring()) {
            if viewModel.durumDegistir(gorev: gorev) { patlatKonfeti() }
            let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
        }
    }
    
    func kilitIslemi() { viewModel.kasaAcik ? viewModel.kasayiKilitle() : viewModel.kasaKilidiniAc() }
    
    func patlatKonfeti() {
        showKonfeti = true; withAnimation(.spring()) { kazanilanXPGoster = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { showKonfeti = false; kazanilanXPGoster = false } }
    }
    
    func sifirla() {
        yeniGorevBaslik = ""
        secilenOnem = .orta
        secilenTarih = Date()
        gizliGorevOlsun = false
        // Ekleme yapıldıktan sonra kategori seçimini de sıfırla (etiket ikonuna dönsün)
        yeniGorevKategori = nil
        klavyeOdakli = false
    }
    
    func triggerHaptic(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// Extension String (Tarih Algılama)
extension String {
    func tarihAlgila() -> (date: Date?, temizMetin: String) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return (nil, self) }
        let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        if let match = matches.first, let date = match.date, let range = Range(match.range, in: self) {
            var temizMetin = self.replacingCharacters(in: range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (date, temizMetin)
        }
        return (nil, self)
    }
}
