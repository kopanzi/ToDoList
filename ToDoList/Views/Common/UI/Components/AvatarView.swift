import SwiftUI

/// Kullanıcının fotoğrafını, emojisini veya baş harflerini gösteren akıllı bileşen.
/// ✨ Senior Notu: 20 Seviyelik rütbe sistemine (XP) göre dinamik "Aura" (Enerji Halesi) korunmuş,
/// Kare (Bıçak gibi kesilme) sınır hatası çözülmüş ve Instagram tarzı (Buzlu Camlı) Tam Ekran Önizleme eklenmiştir.
struct AvatarView: View {
    // MARK: - Properties
    var size: CGFloat = 44
    var showAura: Bool = true // İstenirse dışarıdan kapatılabilir
    
    // Uygulamanın renk paletine (Tema) uyum sağlar.
    @EnvironmentObject var appearance: AppearanceManager
    
    // Cihaz hafızasındaki verileri anlık olarak dinler
    @AppStorage("userName") private var userName: String = "Sio Kullanıcısı"
    @AppStorage("userAvatarID") private var userAvatarID: String = ""
    @AppStorage("userAvatarEmoji") private var userAvatarEmoji: String = ""
    @AppStorage("userXP") private var userXP: Int = 0 // Rütbe için XP dinleniyor
    
    // Animasyon Durumları (Aura için)
    @State private var isPulsing = false
    @State private var isRotating = false
    
    // Tam Ekran Önizleme (Instagram Style) Durumu
    @State private var showFullscreenPreview = false
    
    // Güncel Rütbe
    private var currentRank: Rank {
        XPService.shared.getCurrentRank(for: userXP)
    }
    
    var body: some View {
        ZStack {
            // ✨ 1. KATMAN: AURA (HALE) EFEKTİ
            // Senior Fix: Aura'yı .background içine hapsetmek yerine ZStack'te
            // bağımsız bir katman yaptık. Böylece dışa doğru özgürce taşabilir.
            if showAura && currentRank != .odakYolcusu {
                auraEffect
            }
            
            // ✨ 2. KATMAN: AVATAR GÖVDESİ VE İÇERİĞİ
            ZStack {
                // A) Arka Plan (Fotoğraf yoksa Gradient görünür)
                if userAvatarID.isEmpty {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [appearance.accentColor, appearance.accentColor.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // B) İçerik (Resim, Emoji veya Baş Harf)
                if !userAvatarID.isEmpty, let uiImage = MediaManager.shared.loadImage(id: userAvatarID) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
                else if !userAvatarEmoji.isEmpty {
                    Text(userAvatarEmoji)
                        .font(.system(size: size * 0.55))
                }
                else {
                    Text(getInitials(from: userName))
                        .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                }
            }
            .frame(width: size, height: size)
            // ✨ KESİN MASKELEME: İçeriğin köşelerden taşmasını önler, kusursuz daire yapar.
            .clipShape(Circle())
            // ✨ SINIR ÇİZGİSİ (Stroke): En üstte rütbeye göre renklenen dış çerçeve
            .overlay(Circle().stroke(currentRank.color.opacity(0.5), lineWidth: 1.5))
        }
        // Tüm component'in listede/sayfada kaplayacağı fiziksel alan
        .frame(width: size, height: size)
        .onAppear {
            startAuraAnimations()
        }
        // ✨ İNSTAGRAM STYLE: Avatara tıklanınca büyütme efekti
        .onTapGesture {
            HapticManager.shared.triggerMediumImpact()
            showFullscreenPreview = true
        }
        // ✨ IOS 16+ Şeffaf FullScreenCover Sunumu
        .fullScreenCover(isPresented: $showFullscreenPreview) {
            AvatarFullscreenPreview(
                imageID: userAvatarID,
                emoji: userAvatarEmoji,
                initials: getInitials(from: userName),
                rankColor: currentRank.color,
                themeColor: appearance.accentColor
            )
            .presentationBackground(.clear) // Arkadaki ekranın buzlu camdan görünmesini sağlar
        }
    }
}

// MARK: - Sub-Views & Helpers
private extension AvatarView {
    
    // ✨ Rütbeye Göre Aura Efekti Çizimi
    @ViewBuilder
    var auraEffect: some View {
        ZStack {
            if currentRank.rawValue >= Rank.stratejiDehasi.rawValue {
                Circle()
                    .fill(currentRank.color.opacity(0.3))
                    .frame(width: size * 1.5, height: size * 1.5)
                    .blur(radius: 10)
                    .scaleEffect(isPulsing ? 1.1 : 0.9)
            }
            
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
                .rotationEffect(.degrees(isRotating ? 360 : 0))
        }
    }
    
    // 🛠️ Rütbeye özel aura renk paletleri
    var auraColors: [Color] {
        let baseColor = currentRank.color
        
        switch currentRank {
        case .odakYolcusu, .farkindalikKasifi:
            return [.clear]
            
        case .duzenCiragi, .iradeSahibi, .planKurucu, .rutinMimari:
            return [baseColor, .cyan.opacity(0.1), baseColor.opacity(0.4), baseColor]
            
        case .isBitirici, .momentumSurucusu, .sistemMuhendisi, .berrakZihin:
            return [baseColor, .mint.opacity(0.1), baseColor.opacity(0.5), baseColor]
            
        case .akisUstasi, .zamanBukucu, .stratejiDehasi, .verimMimari:
            return [baseColor, .pink.opacity(0.1), .indigo, baseColor]
            
        case .zihinMimari, .uretkenlikUstasi, .mutlakOdak, .zenUstasi:
            return [baseColor, .yellow.opacity(0.1), .red, baseColor]
            
        case .safPotansiyel, .zihninZirvesi:
            return [.yellow, .white.opacity(0.3), .orange, .yellow, .white]
        }
    }
    
    // Animasyonları tetikleyen fonksiyon
    func startAuraAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
        
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

// MARK: - ✨ INSTAGRAM STYLE: Tam Ekran Profil Görüntüleyici
/// Kullanıcı profile tıkladığında ekranı karartıp fotoğrafı kocaman gösteren bağımsız bileşen.
struct AvatarFullscreenPreview: View {
    let imageID: String
    let emoji: String
    let initials: String
    let rankColor: Color
    let themeColor: Color
    
    @Environment(\.dismiss) var dismiss
    
    // Animasyon ve Sürükleme Durumları
    @State private var backgroundOpacity: Double = 0.0
    @State private var contentScale: CGFloat = 0.6
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // ✨ 1. SİNEMATİK ARKA PLAN (İnce Buzlu Cam)
            ZStack {
                // Arkadaki ekranı gösteren en ince ve şeffaf Apple cam efekti
                Color.clear
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark) // Yine asil dursun ama çok boğmasın
                
                // Tam istediğin gibi %20 oranında çok hafif bir karartma
                Color.black.opacity(0.2)
            }
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            // Arka plana tıklanınca da kapatır
            .onTapGesture { dismissWithAnimation() }
            
            // 2. Dev Avatar İçeriği
            ZStack {
                // Arka Plan Rengi
                if imageID.isEmpty {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeColor, themeColor.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // İçerik
                if !imageID.isEmpty, let uiImage = MediaManager.shared.loadImage(id: imageID) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if !emoji.isEmpty {
                    Text(emoji).font(.system(size: 130))
                } else {
                    Text(initials)
                        .font(.system(size: 100, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 2)
                }
            }
            .frame(width: 260, height: 260)
            .clipShape(Circle())
            // Rütbe rengiyle dev bir parlama efekti (Premium Hissiyat)
            .overlay(Circle().stroke(rankColor.opacity(0.8), lineWidth: 4))
            .shadow(color: rankColor.opacity(0.5), radius: 30, x: 0, y: 10)
            
            // Sürükleme ve Açılış Animasyon Bağlantıları
            .scaleEffect(contentScale)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Parmağı takip et, ekranı biraz şeffaflaştır
                        dragOffset = value.translation
                        backgroundOpacity = 1.0 - Double(abs(value.translation.height) / 500)
                    }
                    .onEnded { value in
                        // Eğer aşağı/yukarı yeterince sürüklendiyse ekranı kapat
                        if abs(value.translation.height) > 120 {
                            dismissWithAnimation()
                        } else {
                            // Yeterli sürüklenmediyse yerine geri yaylan (Snap back)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                dragOffset = .zero
                                backgroundOpacity = 1.0
                            }
                        }
                    }
            )
        }
        // Ekran açıldığında "Pop" efektiyle belirme
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                backgroundOpacity = 1.0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                contentScale = 1.0
            }
        }
    }
    
    // Ekranı kapatırken yumuşakça küçülmesini ve kaybolmasını sağlar
    private func dismissWithAnimation() {
        HapticManager.shared.triggerLightImpact()
        withAnimation(.easeIn(duration: 0.2)) {
            backgroundOpacity = 0.0
            contentScale = 0.7
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}
