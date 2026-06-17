import SwiftUI

/// Sidebar'ın en üstünde yer alan, kullanıcı profilini, rütbesini ve XP bilgisini gösteren premium bileşen.
/// Senior Notu: Lokal "Yama" cam efekti temizlenerek, SidebarView'daki bütünsel cam paneline
/// (Unified Frosted Glass) tam uyum sağlaması için şeffaflaştırılmıştır.
struct SidebarHeaderView: View {
    // MARK: - Properties
    let rankName: String
    let rankIcon: String
    let xp: Int
    let progress: Double // 0.0 - 1.0 arası seviye ilerlemesi
    
    // Uygulamanın aktif temasını dinler
    @EnvironmentObject var appearance: AppearanceManager
    
    // Kullanıcı adını anlık olarak cihaz hafızasından okuyoruz
    @AppStorage("userName") private var userName: String = "Sio Kullanıcısı"
    
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
                        .foregroundColor(.primary) // Adaptive
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
                    .foregroundColor(appearance.accentColor)
                    
                    Spacer()
                    
                    Text("%\(Int(progress * 100))")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary) // Adaptive
                }
                
                // İlerleme Barı
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
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
        // ✨ SENIOR FIX: Lokal `.background(ultraThinMaterial)` buradan tamamen SİLİNDİ!
        // Artık zemin %100 şeffaf, SidebarView'daki dev panelle birleşecek.
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Sistem arka planını simüle etmek için
        Color(uiColor: .systemBackground).ignoresSafeArea()
        
        VStack {
            SidebarHeaderView(
                rankName: "Usta Sio",
                rankIcon: "star.fill",
                xp: 1250,
                progress: 0.65
            )
            Spacer()
        }
    }
    .environmentObject(AppearanceManager.shared)
}
