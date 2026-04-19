import SwiftUI

/// Kullanıcının fotoğrafını, emojisini veya baş harflerini gösteren akıllı bileşen.
/// ✨ Senior Notu: 20 Seviyelik yeni rütbe sistemine (XP) göre dinamik ve animasyonlu "Aura" (Enerji Halesi) eklendi.
struct AvatarView: View {
    // MARK: - Properties
    var size: CGFloat = 44
    var showAura: Bool = true // İstenirse dışarıdan kapatılabilir
    
    // Cihaz hafızasındaki verileri anlık olarak dinler
    @AppStorage("userName") private var userName: String = "Yaver Kullanıcısı"
    @AppStorage("userAvatarID") private var userAvatarID: String = ""
    @AppStorage("userAvatarEmoji") private var userAvatarEmoji: String = ""
    @AppStorage("userXP") private var userXP: Int = 0 // ✨ Rütbe için XP dinleniyor
    
    // Animasyon Durumları (Aura için)
    @State private var isPulsing = false
    @State private var isRotating = false
    
    // Güncel Rütbe
    private var currentRank: Rank {
        XPService.shared.getCurrentRank(for: userXP)
    }
    
    var body: some View {
        ZStack {
            // 1. KATMAN: Arka Plan (Fotoğraf yoksa Mesh görünür)
            if userAvatarID.isEmpty {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0df2cc"), Color(hex: "3b82f6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // 2. KATMAN: İçerik Önceliği
            if !userAvatarID.isEmpty, let uiImage = MediaManager.shared.loadImage(id: userAvatarID) {
                // Öncelik 1: Gerçek Fotoğraf
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            }
            else if !userAvatarEmoji.isEmpty {
                // Öncelik 2: Kullanıcı Özel Emoji Seçmişse
                Text(userAvatarEmoji)
                    .font(.system(size: size * 0.55))
            }
            else {
                // Öncelik 3: Hiçbiri yoksa İsmin Baş Harfleri (Initials)
                Text(getInitials(from: userName))
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .frame(width: size, height: size)
        // İnce sınır çizgisi de rütbe rengine göre şekillenir
        .overlay(Circle().stroke(currentRank.color.opacity(0.5), lineWidth: 1.5))
        // ✨ 3. KATMAN: AURA (HALE) EFEKTİ
        .background(
            Group {
                // İlk seviye (Odak Yolcusu) hariç hepsinde aura gösterilir
                if showAura && currentRank != .odakYolcusu {
                    auraEffect
                }
            }
        )
        // Animasyonları başlat
        .onAppear {
            startAuraAnimations()
        }
    }
}

// MARK: - Sub-Views & Helpers
private extension AvatarView {
    
    // ✨ Rütbeye Göre Aura Efekti Çizimi
    @ViewBuilder
    var auraEffect: some View {
        ZStack {
            // Dış ve geniş parlama (Sadece en üst düzey Faz 4 ve Faz 5 rütbeleri için)
            if currentRank.rawValue >= Rank.stratejiDehasi.rawValue {
                Circle()
                    .fill(currentRank.color.opacity(0.3))
                    .frame(width: size * 1.5, height: size * 1.5)
                    .blur(radius: 10)
                    .scaleEffect(isPulsing ? 1.1 : 0.9)
            }
            
            // Ana Aura Çemberi (Dönen Angular Gradient)
            Circle()
                .fill(
                    AngularGradient(
                        colors: auraColors,
                        center: .center,
                        angle: .zero
                    )
                )
                .frame(width: size * 1.18, height: size * 1.18) // Avatardan bir tık büyük
                .blur(radius: isPulsing ? 4 : 2) // Nefes alan pus efekti
                .scaleEffect(isPulsing ? 1.03 : 0.97)
                // 🛠️ SENIOR FIX: Dönüş animasyonunu gradient'e değil direkt View'a uyguluyoruz ki kusursuz dönsün!
                .rotationEffect(.degrees(isRotating ? 360 : 0))
        }
    }
    
    // 🛠️ Rütbeye özel aura renk paletleri (Seviye yükseldikçe renkler ısınır ve havalı olur)
    var auraColors: [Color] {
        let baseColor = currentRank.color
        
        switch currentRank {
        case .odakYolcusu, .farkindalikKasifi:
            return [.clear] // Çok düşük seviyelerde dönen aura yok
            
        case .duzenCiragi, .iradeSahibi, .planKurucu, .rutinMimari:
            // Mavi/Cyan ağırlıklı sakin aura
            return [baseColor, .cyan.opacity(0.1), baseColor.opacity(0.4), baseColor]
            
        case .isBitirici, .momentumSurucusu, .sistemMuhendisi, .berrakZihin:
            // Yeşil/Teal ağırlıklı akış aurası
            return [baseColor, .mint.opacity(0.1), baseColor.opacity(0.5), baseColor]
            
        case .akisUstasi, .zamanBukucu, .stratejiDehasi, .verimMimari:
            // Mor/Indigo ağırlıklı zihin aurası
            return [baseColor, .pink.opacity(0.1), .indigo, baseColor]
            
        case .zihinMimari, .uretkenlikUstasi, .mutlakOdak, .zenUstasi:
            // Kırmızı/Turuncu ağırlıklı aydınlanma aurası
            return [baseColor, .yellow.opacity(0.1), .red, baseColor]
            
        case .safPotansiyel, .zihninZirvesi:
            // Altın/Elmas parıltısı (Zirve seviye)
            return [.yellow, .white.opacity(0.3), .orange, .yellow, .white]
        }
    }
    
    // Animasyonları tetikleyen fonksiyon
    func startAuraAnimations() {
        // Nefes alma (büyüyüp küçülme) animasyonu
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
        
        // Kendi etrafında dönme animasyonu (Rütbe arttıkça dönüş hızı artar)
        // 20. Seviye (Zihnin Zirvesi) 2 saniyede, ilk seviyeler 4 saniyede döner
        let speedMultiplier = 1.0 - (Double(currentRank.rawValue) / Double(Rank.zihninZirvesi.rawValue) * 0.5)
        let rotationSpeed: Double = 4.0 * max(0.5, speedMultiplier)
        
        withAnimation(.linear(duration: rotationSpeed).repeatForever(autoreverses: false)) {
            isRotating = true
        }
    }
    
    // İsimden baş harf çıkarma mantığı
    func getInitials(from name: String) -> String {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanName.isEmpty { return "Y" }
        
        let words = cleanName.components(separatedBy: " ").filter { !$0.isEmpty }
        if words.count >= 2 {
            let first = words[0].prefix(1)
            let last = words[words.count - 1].prefix(1)
            return String(first + last).uppercased()
        } else if let firstWord = words.first {
            return String(firstWord.prefix(2)).uppercased()
        }
        return "Y"
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "020807").ignoresSafeArea()
        
        VStack(spacing: 40) {
            AvatarView(size: 60)
            AvatarView(size: 80)
        }
    }
}
