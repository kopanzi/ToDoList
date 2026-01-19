import SwiftUI

struct AyarlarView: View {
    // MARK: - Ayarlar (AppStorage)
    // 1. DİL AYARI (YENİ EKLENDİ) 🌍
    @AppStorage("secilenDil") private var secilenDil = "tr"
    
    @AppStorage("secilenTema") private var secilenTemaStr = Tema.mavi.rawValue
    @AppStorage("arkaPlanCanlilik") private var canlilik = 0.4
    @AppStorage("arkaPlanOpaklik") private var opaklik = 0.45
    
    // Yardımcı: Şu anki tema nesnesi
    var aktifTema: Tema {
        Tema(rawValue: secilenTemaStr) ?? .mavi
    }
    
    var hesaplananArkaPlan: some View {
        aktifTema.renk
            .saturation(canlilik)
            .opacity(opaklik)
    }
    
    var body: some View {
        Form {
            // 🌍 0. BÖLÜM: DİL SEÇİMİ (EN TEPEYE EKLENDİ)
            Section(header: Text("Dil / Language")) {
                Picker("Dil Seçiniz", selection: $secilenDil) {
                    Text("🇹🇷 Türkçe").tag("tr")
                    Text("🇬🇧 English").tag("en")
                    Text("🇩🇪 Deutsch").tag("de")
                    Text("🇪🇸 Español").tag("es")
                    Text("🇫🇷 Français").tag("fr")
                    Text("🇮🇹 Italiano").tag("it")
                    Text("🇷🇺 Русский").tag("ru")
                    Text("🇯🇵 日本語").tag("ja")
                    Text("🇰🇷 한국어").tag("ko")
                    Text("🇸🇦 العربية").tag("ar")
                    Text("🇳🇱 Nederlands").tag("nl")
                    Text("🇧🇷 Português (Brasil)").tag("pt-BR")
                    Text("🇮🇳 हिन्दी (Hintçe)").tag("hi")
                    Text("🇨🇳 中文 (Basitleştirilmiş)").tag("zh-Hans")
                    Text("🇭🇰 中文 (Hong Kong)").tag("zh-HK")
                    Text("🇹🇼 中文 (Geleneksel)").tag("zh-Hant")
                }
                .pickerStyle(.menu) // Açılır menü şeklinde görünsün
            }
            
            // 🖼️ 1. BÖLÜM: CANLI ÖNİZLEME
            Section(header: Text("Canlı Önizleme")) {
                ZStack {
                    // Kullanıcının ayarladığı arka plan
                    hesaplananArkaPlan
                        .cornerRadius(12)
                    
                    // Örnek bir görev kartı görünümü
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading) {
                            Text("Örnek Görev")
                                .bold()
                                .foregroundColor(.primary)
                            Text("Görünüm böyle olacak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(10)
                    .padding(20)
                }
                .frame(height: 120)
                .listRowInsets(EdgeInsets())
            }
            
            // 🎨 2. BÖLÜM: TEMA SEÇİMİ
            Section(header: Text("Tema Rengi")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Tema.allCases) { tema in
                            VStack {
                                Circle()
                                    .fill(tema.renk)
                                    .frame(width: 45, height: 45)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: secilenTemaStr == tema.rawValue ? 3 : 0)
                                    )
                                    .shadow(radius: 2)
                                
                                Text(tema.isim)
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                            .onTapGesture {
                                withAnimation {
                                    secilenTemaStr = tema.rawValue
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            
            // 🎛️ 3. BÖLÜM: İNCE AYARLAR
            Section(header: Text("Arka Plan Ayarları")) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "paintpalette.fill").foregroundColor(.gray)
                        Text("Renk Yoğunluğu")
                        Spacer()
                        Text(String(format: "%.1f", canlilik))
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Slider(value: $canlilik, in: 0.0...2.0, step: 0.1)
                        .tint(aktifTema.renk)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "drop.fill").foregroundColor(.gray)
                        Text("Şeffafiyet")
                        Spacer()
                        Text("%\(Int(opaklik * 100))")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Slider(value: $opaklik, in: 0.0...1.0, step: 0.05)
                        .tint(aktifTema.renk)
                }
            }
            
            // ℹ️ 4. BÖLÜM: BİLGİ
            Section {
                HStack {
                    Text("Geliştirici")
                    Spacer()
                    Text("Kopanzi")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Versiyon")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Ayarlar") // Başlığı 'Görünüm'den 'Ayarlar'a çektim
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AyarlarView()
    }
}
