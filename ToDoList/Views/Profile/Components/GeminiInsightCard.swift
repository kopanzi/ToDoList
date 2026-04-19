import SwiftUI

/// Profil sayfasındaki AI Analiz ve Aktivite Grafiği bileşeni.
/// Senior Notu: Tekrara düşen veriler silindi, Apple Health tarzı premium bir aktivite grafiği eklendi.
struct GeminiInsightCard: View {
    // MARK: - Properties
    let userName: String
    let stats: UserStats
    let insight: String
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. ÜST BAŞLIK (Header)
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.purple.opacity(0.2))
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.purple)
                    }
                    .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("GEMINI ANALYTICAL INSIGHT")
                            .font(.system(size: 11, weight: .black))
                            .tracking(0.5)
                        
                        Text("OPTIMIZATION ENGINE FOR \(userName.uppercased())")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("Active")
                    .font(.system(size: 9, weight: .black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "0df2cc").opacity(0.1))
                    .foregroundColor(Color(hex: "0df2cc"))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(hex: "0df2cc").opacity(0.2), lineWidth: 1))
            }
            
            // 2. AI TAVSİYE ALANI (Ana Odak Noktası)
            VStack(alignment: .leading, spacing: 14) {
                if isLoading {
                    ProgressView()
                        .tint(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                } else {
                    Text("\"\(insight)\"")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
            
            Divider()
                .background(Color.white.opacity(0.05))
                .padding(.horizontal, 10)
            
            // 3. YENİ: GENİŞLETİLMİŞ 7 GÜNLÜK RİTİM GRAFİĞİ
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("SON 7 GÜNLÜK RİTİM")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                        .tracking(1)
                    
                    Spacer()
                    
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color(hex: "0df2cc").opacity(0.7))
                        .font(.system(size: 12))
                }
                
                HStack(alignment: .bottom, spacing: 0) {
                    // 7 Günü çiz (0: 6 gün önce, 6: Bugün)
                    ForEach(0..<7, id: \.self) { i in
                        // Dizinin dışına çıkmamak için güvenlik kontrolü
                        let intensity = (i < stats.weeklyMoodIntensity.count) ? stats.weeklyMoodIntensity[i] : 0.0
                        
                        // ✨ SENIOR FIX: Çubukların minimum 6 piksel boyu olacak (Nokta gibi duracak).
                        // Görev yapmadığında grafiğin kırık görünmesini engeller.
                        let barHeight = CGFloat(intensity * 35) + 6
                        
                        VStack(spacing: 8) {
                            Capsule()
                                // Bugünün rengini neon yeşil, geçmiş günleri beyazımsı transparan yap
                                .fill(i == 6 ? Color(hex: "0df2cc") : Color.white.opacity(0.1))
                                .frame(width: 24, height: barHeight)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: intensity)
                            
                            // Alt kısımdaki gün isimleri (PZT, SAL, ÇAR vb.)
                            Text(dayName(for: i))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(i == 6 ? Color(hex: "0df2cc") : .secondary)
                        }
                        .frame(maxWidth: .infinity) // Tüm genişliğe eşit olarak yay
                    }
                }
                .frame(height: 60, alignment: .bottom) // Grafik alanı sabit yükseklikte kalır
            }
        }
        .padding(24)
        // ✨ STITCH GLASSMORPHISM ARKA PLAN
        .background(
            ZStack {
                Color(hex: "0a1412").opacity(0.7)
                LinearGradient(
                    colors: [Color.clear, Color.purple.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .background(.ultraThinMaterial)
        )
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Helpers
    
    /// Gün indeksine (0=6 gün önce, 6=Bugün) göre kısa gün adını bulur (PZT, SAL vb.)
    private func dayName(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        if let date = Calendar.current.date(byAdding: .day, value: -(6 - index), to: Date()) {
            let weekdayIndex = Calendar.current.component(.weekday, from: date) - 1
            return String(formatter.shortWeekdaySymbols[weekdayIndex].prefix(3)).uppercased()
        }
        return ""
    }
}
