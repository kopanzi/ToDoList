import SwiftUI

/// Kullanıcının tüm rutinlerini yönettiği, alevlerini (streak) ve zamanlamalarını gördüğü ana kontrol paneli.
/// Senior Notu: Glassmorphism (Buzlu Cam) UI prensipleriyle güncellendi ve performansı artırıldı.
struct RoutinesView: View {
    // MARK: - Properties
    @StateObject private var routineManager = RoutineManager.shared
    @EnvironmentObject var appearance: AppearanceManager
    @EnvironmentObject var taskVM: TaskViewModel // XP Harcamak için
    
    // Geri Dönüş Aksiyonu
    var onBackTap: () -> Void
    
    @State private var showingAddRoutine = false
    
    // Satın Alma (Buz Küpü) Durumları
    @State private var showingFreezeAlert = false
    @State private var showXPError = false
    @State private var selectedRoutineForFreeze: RoutineModel? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Şeffaf arka plan (ContentView'daki mesh gradient'in görünmesi için)
                Color.clear.ignoresSafeArea()
                
                if routineManager.routines.isEmpty {
                    emptyStateView
                } else {
                    routinesList
                }
            }
            .navigationTitle("🔁 Rutinlerim")
            .navigationBarTitleDisplayMode(.inline)
            // Koyu temayı zorla (Mesh gradient üzerinde kusursuz durması için)
            .preferredColorScheme(.dark)
            .toolbar {
                // SOL: Geri Dönüş Butonu
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        onBackTap()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.title3.bold())
                            Text("Görevler")
                                .font(.headline)
                        }
                        .foregroundColor(appearance.accentColor)
                    }
                }
                
                // SAĞ: Yeni Ekle Butonu
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        showingAddRoutine = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(appearance.accentColor)
                            // Butona hafif bir glow (parlama) efekti
                            .shadow(color: appearance.accentColor.opacity(0.5), radius: 5, x: 0, y: 0)
                    }
                }
            }
            .sheet(isPresented: $showingAddRoutine) {
                AddRoutineView()
                    .environmentObject(appearance)
            }
            // 🧊 SATIN ALMA ALERTİ
            .alert("Seri Dondurucu (🧊)", isPresented: $showingFreezeAlert) {
                Button("Vazgeç", role: .cancel) { }
                Button("500 XP ile Satın Al") {
                    if let routine = selectedRoutineForFreeze {
                        let success = routineManager.buyFreeze(for: routine.id, taskViewModel: taskVM)
                        if !success {
                            // XP Yetersiz ise gecikmeli hata alertini tetikle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showXPError = true }
                        }
                    }
                }
            } message: {
                Text("500 XP karşılığında bu rutin için 1 adet Seri Dondurucu alabilirsiniz. Bir görevi kaçırdığınızda seriniz sıfırlanmak yerine 1 dondurucu harcanır.")
            }
            // 🛑 XP YETERSİZ ALERTİ
            .alert("Yetersiz XP", isPresented: $showXPError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("Seri dondurucu almak için en az 500 XP'ye ihtiyacınız var. Görev tamamlayarak XP kazanabilirsiniz.")
            }
        }
    }
}

// MARK: - Subviews & Layouts
private extension RoutinesView {
    
    /// Hiç rutin yoksa gösterilecek motive edici boş ekran tasarımı
    var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "repeat.circle")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(appearance.accentColor.opacity(0.8))
                    .shadow(color: appearance.accentColor.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            
            VStack(spacing: 12) {
                Text("Rutin Bulunmadı")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Her gün veya belirlediğin aralıklarla tekrarlanan alışkanlıklar ekleyerek serini (🔥) başlat!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            
            Button(action: {
                HapticManager.shared.triggerLightImpact()
                showingAddRoutine = true
            }) {
                Text("İlk Rutinini Oluştur")
                    .font(.headline)
                    .foregroundColor(Color(hex: "10221f")) // Koyu kontrast metin
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(appearance.accentColor)
                    .cornerRadius(16)
                    .shadow(color: appearance.accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .padding(.top, 10)
        }
    }
    
    /// Rutinlerin listelendiği ana alan
    var routinesList: some View {
        List {
            // Şeffaf üst boşluk
            Color.clear.frame(height: 10)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            
            ForEach(routineManager.routines) { routine in
                RoutineCardView(
                    routine: routine,
                    manager: routineManager,
                    onBuyFreeze: { r in
                        HapticManager.shared.triggerLightImpact()
                        selectedRoutineForFreeze = r
                        showingFreezeAlert = true
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    let routineId = routineManager.routines[index].id
                    routineManager.deleteRoutine(id: routineId)
                }
            }
            
            // Şeffaf alt boşluk
            Color.clear.frame(height: 50)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Routine Card View (Özel Glassmorphism Hücre Tasarımı)
/// Her bir rutinin listede nasıl görüneceğini belirleyen premium kart tasarımı
struct RoutineCardView: View {
    let routine: RoutineModel
    @ObservedObject var manager: RoutineManager
    @EnvironmentObject var appearance: AppearanceManager
    
    var onBuyFreeze: (RoutineModel) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. SOL TARAF: Döngü İkonu (Aktif/Pasif durumuna göre renklenir)
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(routine.isActive ? appearance.accentColor.opacity(0.15) : Color.white.opacity(0.05))
                    .frame(width: 54, height: 54)
                
                Image(systemName: routine.isActive ? "repeat.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(routine.isActive ? appearance.accentColor : .white.opacity(0.4))
            }
            
            // 2. ORTA TARAF: Başlık ve Bilgiler
            VStack(alignment: .leading, spacing: 6) {
                Text(routine.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(routine.isActive ? .white : .white.opacity(0.5))
                    .strikethrough(!routine.isActive, color: .white.opacity(0.4))
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    // Sıklık Etiketi
                    Label("\(routine.interval) \(routine.frequency.rawValue)", systemImage: "clock")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Alev (Streak) Etiketi
                    if routine.streakCount > 0 {
                        Text("🔥 \(routine.streakCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    // Buz Küpü (Dondurucu) Etiketi
                    if routine.freezeCount > 0 {
                        Text("🧊 \(routine.freezeCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                }
                
                // Sonraki Tetiklenme Zamanı
                if routine.isActive {
                    Text("Sıradaki: \(formatDate(routine.nextTriggerDate))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(appearance.accentColor.opacity(0.8))
                } else {
                    Text("Duraklatıldı")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            
            Spacer()
            
            // 3. SAĞ TARAF: Aktif/Pasif Anahtarı ve Satın Alma Butonu
            VStack(alignment: .trailing, spacing: 12) {
                Toggle("", isOn: Binding(
                    get: { routine.isActive },
                    set: { _ in
                        // Animasyonla kapatılıp açılması için
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            manager.toggleRoutineActive(id: routine.id)
                        }
                    }
                ))
                .labelsHidden()
                .tint(appearance.accentColor)
                .scaleEffect(0.85) // Biraz küçültüp daha zarif durmasını sağladık
                
                // XP ile Buz Satın Alma Butonu
                Button(action: { onBuyFreeze(routine) }) {
                    HStack(spacing: 4) {
                        Text("🧊")
                            .font(.system(size: 10))
                        Text(routine.freezeCount > 0 ? "Al" : "Satın Al")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.15))
                    .foregroundColor(.cyan)
                    .clipShape(Capsule())
                    // İnce bir stroke (sınır) ekledik
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(BouncyGlassButtonStyle(color: .cyan)) // Özel tıklama stili
            }
        }
        .padding(16)
        // ✨ GLASSMORPHISM EFEKTİ
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(routine.isActive ? 0.04 : 0.01))
                .background(.ultraThinMaterial.opacity(routine.isActive ? 0.8 : 0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(routine.isActive ? 0.08 : 0.03), lineWidth: 1)
        )
        .opacity(routine.isActive ? 1.0 : 0.6)
    }
    
    // Tarihi okunaklı formata çeviren yardımcı fonksiyon
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Bugün' HH:mm"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "'Yarın' HH:mm"
        } else {
            formatter.dateFormat = "d MMM HH:mm"
        }
        return formatter.string(from: date)
    }
}
