import SwiftUI

/// Sidebar'ın en üstünde yer alan, kullanıcı profilini, rütbesini ve XP bilgisini gösteren premium bileşen.
/// Senior Notu: Mevcut yapın tamamen korunarak AvatarView ve dinamik isim (AppStorage) ile zenginleştirildi.
struct SidebarHeaderView: View {
    // MARK: - Properties
    let rankName: String
    let rankIcon: String
    let xp: Int
    let progress: Double // 0.0 - 1.0 arası seviye ilerlemesi
    
    // ✨ SENIOR DOKUNUŞU: Kullanıcı adını anlık olarak cihaz hafızasından okuyoruz
    @AppStorage("userName") private var userName: String = "Yaver Kullanıcısı"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            
            // 1. KULLANICI PROFİLİ VE RÜTBE ROZETİ
            HStack(spacing: 16) {
                // Önceden yaptığımız Aura efektli Avatar bileşeni
                AvatarView(size: 55, showAura: true)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Kullanıcı İsmi
                    Text(userName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
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
                    .background(Color.white.opacity(0.12))
                    .foregroundColor(.white.opacity(0.9))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
            
            // 2. XP VE NEON İLERLEME ÇUBUĞU
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("\(xp) XP")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "0df2cc")) // Neon Teal
                    
                    Spacer()
                    
                    Text("%\(Int(progress * 100))")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // İlerleme Barı (Senin GeometryReader mantığınla)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "0df2cc"), .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 6)
                            .shadow(color: Color(hex: "0df2cc").opacity(0.5), radius: 5, x: 0, y: 0)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.top, 60) // Çentik (Notch) payı
        .padding(.horizontal, 24)
        .padding(.bottom, 25)
        // ✨ YENİ: Arka plana çok hafif bir cam efekti koyuyoruz ki menüden ayrılsın
        .background(
            Color.white.opacity(0.02)
                .background(.ultraThinMaterial.opacity(0.4))
                // Alt kısımdan yumuşakça eriyerek kaybolan (fade out) ince bir çizgi
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.white.opacity(0.05)),
                    alignment: .bottom
                )
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Sidebar arka planını simüle etmek için
        Color(hex: "020807").ignoresSafeArea()
        
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
}
