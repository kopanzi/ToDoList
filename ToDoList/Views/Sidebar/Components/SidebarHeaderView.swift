import SwiftUI

/// Sidebar'ın en üstünde yer alan, kullanıcı profilini, rütbesini ve XP bilgisini gösteren premium bileşen.
/// Senior Notu: Statik beyaz/siyah ve neon renkler kaldırılarak Tema Motoruna (AppearanceManager)
/// ve Apple'ın Adaptive (Aydınlık/Karanlık mod) tasarım standartlarına geçirilmiştir.
struct SidebarHeaderView: View {
    // MARK: - Properties
    let rankName: String
    let rankIcon: String
    let xp: Int
    let progress: Double // 0.0 - 1.0 arası seviye ilerlemesi
    
    // ✨ SENIOR FIX: Uygulamanın aktif temasını dinler
    @EnvironmentObject var appearance: AppearanceManager
    
    // Kullanıcı adını anlık olarak cihaz hafızasından okuyoruz
    @AppStorage("userName") private var userName: String = "Yaver Kullanıcısı"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            
            // 1. KULLANICI PROFİLİ VE RÜTBE ROZETİ
            HStack(spacing: 16) {
                // Önceden yaptığımız Aura efektli Avatar bileşeni (Kendi içinde temaya uyumludur)
                AvatarView(size: 55, showAura: true)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Kullanıcı İsmi
                    Text(userName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary) // ✨ Adaptive
                        .lineLimit(1)
                    
                    // Şık Rütbe Rozeti (Badge)
                    HStack(spacing: 4) {
                        Image(systemName: rankIcon)
                            .font(.system(size: 10))
                        Text(rankName)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    // ✨ SENIOR FIX: Aydınlık ve karanlık moda uyumlu rozet arka planı
                    .background(Color.primary.opacity(0.05))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                }
            }
            
            // 2. XP VE TEMA RENKLİ İLERLEME ÇUBUĞU
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("\(xp) XP")
                    }
                    .font(.system(size: 12, weight: .bold))
                    // ✨ SENIOR FIX: Sabit renk yerine kullanıcının seçtiği Tema Rengi
                    .foregroundColor(appearance.accentColor)
                    
                    Spacer()
                    
                    Text("%\(Int(progress * 100))")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary) // ✨ Adaptive
                }
                
                // İlerleme Barı
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            // ✨ SENIOR FIX: Zemin rengi Adaptive yapıldı
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    // ✨ SENIOR FIX: Dolum efekti Tema Renginden beslenir
                                    colors: [appearance.accentColor, appearance.accentColor.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 6)
                            .shadow(color: appearance.accentColor.opacity(0.5), radius: 5, x: 0, y: 0)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.top, 60) // Çentik (Notch) payı
        .padding(.horizontal, 24)
        .padding(.bottom, 25)
        // ✨ YENİ: Adaptive Cam Efekti
        .background(
            Color.primary.opacity(0.02)
                .background(.ultraThinMaterial.opacity(0.6))
                // Alt kısımdan yumuşakça eriyerek kaybolan (fade out) ince bir ayraç çizgisi
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.primary.opacity(0.05)),
                    alignment: .bottom
                )
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Sistem arka planını simüle etmek için
        Color(uiColor: .systemBackground).ignoresSafeArea()
        
        VStack {
            SidebarHeaderView(
                rankName: "Usta Yaver",
                rankIcon: "star.fill",
                xp: 1250,
                progress: 0.65
            )
            Spacer()
        }
    }
    // ✨ SENIOR FIX: Preview'ın çökmemesi için
    .environmentObject(AppearanceManager.shared)
}
