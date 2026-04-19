import SwiftUI

/// Yaver'in oyunlaştırılmış ve esnek Odak Sayacı (Pomodoro) ekranı.
/// Senior Notu: "Odak" ve "Mola" olmak üzere iki farklı State Machine mantığıyla çalışır.
/// Mola modunda renkler ve UI tamamen "Zen" (rahatlatıcı) bir atmosfere bürünür.
struct FocusTimerView: View {
    // MARK: - Properties
    @ObservedObject var taskVM: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    // Mod Yönetimi
    enum TimerMode { case focus, rest }
    @State private var currentMode: TimerMode = .focus
    
    // Sayaç Durumları
    @State private var totalTime: Int = 25 * 60
    @State private var timeRemaining: Int = 25 * 60
    
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var timer: Timer? = nil
    
    // Süre Ayarlama (Picker) State'leri
    @State private var showTimePicker = false
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 25
    
    // Görsel Efektler ve Kutlamalar
    @State private var isPulsing = false
    @State private var showRewardScreen = false
    @State private var showBreakFinishedScreen = false
    @State private var earnedXP: Int = 0
    
    // Tematik Renk Paletleri (Moda göre değişir)
    private var activeColor: Color {
        currentMode == .focus ? .orange : Color(hex: "0df2cc")
    }
    
    private var activeGradient: Gradient {
        if currentMode == .focus {
            return Gradient(colors: [.red, .orange, .yellow, .orange, .red])
        } else {
            return Gradient(colors: [.blue, Color(hex: "0df2cc"), .mint, Color(hex: "0df2cc"), .blue])
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. ARKA PLAN
            Color(hex: "050505").ignoresSafeArea()
            
            // Nefes Alan Arka Plan Işığı (Aura)
            Circle()
                .fill(activeColor.opacity(isRunning ? 0.15 : 0.05))
                .frame(width: 350, height: 350)
                .blur(radius: 50)
                .scaleEffect(isPulsing ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
            
            VStack(spacing: 40) {
                
                // ÜST BAR
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        
                        // ✨ SENIOR FIX: Mola modundayken çarpıya basılırsa tamamen çıkma, Odak Moduna geri dön!
                        if currentMode == .rest {
                            stopTimer()
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentMode = .focus
                                totalTime = 25 * 60 // Varsayılan Pomodoro süresine dön
                                timeRemaining = totalTime
                                selectedHours = 0
                                selectedMinutes = 25
                            }
                        } else {
                            // Odak modundaysa ana menüye dön
                            stopTimer()
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // BAŞLIK
                VStack(spacing: 8) {
                    Text(currentMode == .focus ? "MUTLAK ODAK" : "ZİHİNSEL MOLA")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(activeColor)
                        .tracking(6)
                        .animation(.easeInOut, value: currentMode)
                    
                    Text(currentMode == .focus ? "Dünyayı sessize alıp masada kal." : "Gözlerini dinlendir ve derin nefes al.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut, value: currentMode)
                }
                
                Spacer()
                
                // ANA SAYAÇ HALKASI
                ZStack {
                    // Dış İz (Track)
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 15)
                    
                    // İlerleme (Progress)
                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(max(1, totalTime)))
                        .stroke(
                            AngularGradient(gradient: activeGradient, center: .center),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)
                        .shadow(color: isRunning ? activeColor.opacity(0.6) : .clear, radius: 15, x: 0, y: 0)
                    
                    // Metin: Dakika ve Saniye
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: timeRemaining >= 3600 ? 55 : 70, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: isRunning ? activeColor.opacity(0.5) : .clear, radius: 10, x: 0, y: 0)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 20)
                }
                .frame(width: 280, height: 280)
                
                // SÜRE AYARLAMA KISAYOLLARI (Sadece sayaç dururken ve Odak modundaysa)
                if !isRunning && !isPaused && currentMode == .focus {
                    HStack(spacing: 15) {
                        Button(action: {
                            HapticManager.shared.triggerLightImpact()
                            showTimePicker = true
                        }) {
                            HStack {
                                Image(systemName: "clock.fill")
                                Text("Süreyi Ayarla")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                        
                        Button(action: {
                            HapticManager.shared.triggerSelection()
                            selectedHours = 0
                            selectedMinutes = 25
                            syncTimeFromPickers()
                        }) {
                            HStack {
                                Text("🍅")
                                Text("Pomodoro")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                        }
                    }
                    .padding(.top, 10)
                    .transition(.opacity)
                } else {
                    Color.clear.frame(height: 44).padding(.top, 10)
                }
                
                Spacer()
                
                // AKSİYON BUTONLARI
                HStack(spacing: 30) {
                    if !isRunning && !isPaused {
                        Button(action: startTimer) {
                            actionButtonLabel(title: "BAŞLA", icon: "play.fill", color: activeColor)
                        }
                    } else {
                        Button(action: {
                            if isRunning { pauseTimer() } else { resumeTimer() }
                        }) {
                            actionButtonLabel(
                                title: isRunning ? "DURAKLAT" : "DEVAM ET",
                                icon: isRunning ? "pause.fill" : "play.fill",
                                color: isRunning ? .yellow : activeColor
                            )
                        }
                        
                        Button(action: resetTimer) {
                            actionButtonLabel(title: "VAZGEÇ", icon: "stop.fill", color: .red)
                        }
                    }
                }
                .padding(.bottom, 60)
            }
            .disabled(showRewardScreen || showBreakFinishedScreen)
            .blur(radius: (showRewardScreen || showBreakFinishedScreen) ? 10 : 0)
            
            // ODAK BİTİMİ (XP VE MOLA TEKLİFİ)
            if showRewardScreen {
                rewardPopup
            }
            
            // MOLA BİTİMİ (YENİDEN ODAK TEKLİFİ)
            if showBreakFinishedScreen {
                breakFinishedPopup
            }
        }
        .onAppear {
            isPulsing = true
            selectedHours = totalTime / 3600
            selectedMinutes = (totalTime % 3600) / 60
        }
        .onDisappear {
            stopTimer()
        }
        .sheet(isPresented: $showTimePicker) {
            timePickerSheet
        }
    }
}

// MARK: - Sub-Views & Logic
private extension FocusTimerView {
    
    // MARK: - Popups
    
    /// Odak seansı bittiğinde çıkan XP Ödülü ve Mola Teklifi Ekranı
    var rewardPopup: some View {
        ZStack {
            Color.black.opacity(0.5).background(.ultraThinMaterial).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "0df2cc"))
                    .shadow(color: Color(hex: "0df2cc").opacity(0.4), radius: 10, x: 0, y: 5)
                    .padding(.top, 10)
                
                VStack(spacing: 12) {
                    Text("Seans Tamamlandı")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("Harika bir iş çıkardın. Bu emeğin için Yaver sana \(earnedXP) XP kazandırdı. Şimdi zihnini dinlendirme vakti.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 10)
                }
                
                VStack(spacing: 12) {
                    // MOLA BAŞLAT BUTONU
                    Button(action: {
                        HapticManager.shared.triggerSuccess()
                        startBreakMode(minutes: 5)
                    }) {
                        Text("☕️ 5 Dakika Mola Ver")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "10221f"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "0df2cc"))
                            .cornerRadius(14)
                    }
                    
                    // ÇIKIŞ BUTONU
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        dismiss()
                    }) {
                        Text("Çıkış Yap")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 10)
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: "1a1612").opacity(0.85)))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 40)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .zIndex(100)
    }
    
    /// Mola bittiğinde çıkan "Hadi tekrar başlayalım" ekranı
    var breakFinishedPopup: some View {
        ZStack {
            Color.black.opacity(0.5).background(.ultraThinMaterial).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 5)
                    .padding(.top, 10)
                
                VStack(spacing: 12) {
                    Text("Mola Bitti")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("Zihnini tazeledin. Enerjini topladıysan yeni bir odak seansına geçebiliriz.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 10)
                }
                
                VStack(spacing: 12) {
                    // YENİ ODAK BAŞLAT BUTONU
                    Button(action: {
                        HapticManager.shared.triggerHeavyImpact()
                        startFocusMode()
                    }) {
                        Text("🔥 Yeni Seans (25 Dk)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                    }
                    
                    // ÇIKIŞ BUTONU
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        dismiss()
                    }) {
                        Text("Şimdilik Yeterli")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 10)
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: "1a1612").opacity(0.85)))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 40)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .zIndex(100)
    }
    
    // MARK: - Mode Switchers
    
    func startBreakMode(minutes: Int) {
        withAnimation(.easeInOut(duration: 0.5)) {
            showRewardScreen = false
            currentMode = .rest
            totalTime = minutes * 60
            timeRemaining = totalTime
        }
        // Molayı otomatik başlat
        startTimer()
    }
    
    func startFocusMode() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showBreakFinishedScreen = false
            currentMode = .focus
            totalTime = 25 * 60 // Standart Pomodoro
            timeRemaining = totalTime
            
            selectedHours = 0
            selectedMinutes = 25
        }
        // Odak seansını kullanıcı kendi başlatsın (Hazırlanması için)
    }
    
    // MARK: - Pickers & Tools
    
    var timePickerSheet: some View {
        ZStack {
            Color(hex: "1a1612").ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Odaklanma Süresi")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.top, 25)
                
                HStack {
                    Picker("Saat", selection: $selectedHours) {
                        ForEach(0..<13) { i in Text("\(i) Saat").tag(i) }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("Dakika", selection: $selectedMinutes) {
                        ForEach(0..<60) { i in Text("\(i) Dk").tag(i) }
                    }
                    .pickerStyle(.wheel)
                }
                .padding(.horizontal)
                
                Button(action: {
                    HapticManager.shared.triggerSelection()
                    syncTimeFromPickers()
                    showTimePicker = false
                }) {
                    Text("Zamanı Ayarla")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "0df2cc"))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.visible)
    }
    
    func actionButtonLabel(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 70, height: 70)
                Image(systemName: icon).font(.system(size: 24, weight: .bold)).foregroundColor(color)
            }
            .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 2))
            
            Text(title).font(.system(size: 11, weight: .black)).foregroundColor(color).tracking(1)
        }
    }
    
    // MARK: - Logic & Actions
    
    func syncTimeFromPickers() {
        var newTime = (selectedHours * 3600) + (selectedMinutes * 60)
        if newTime == 0 { newTime = 60; selectedMinutes = 1 }
        totalTime = newTime
        timeRemaining = newTime
    }
    
    func timeString(from seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
    
    func startTimer() {
        HapticManager.shared.triggerHeavyImpact()
        isRunning = true
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                finishTimer()
            }
        }
    }
    
    func pauseTimer() {
        HapticManager.shared.triggerLightImpact()
        isRunning = false
        isPaused = true
        timer?.invalidate()
    }
    
    func resumeTimer() { startTimer() }
    
    func resetTimer() {
        HapticManager.shared.triggerWarning()
        stopTimer()
        
        // ✨ SENIOR FIX: "VAZGEÇ" butonuna basıldığında da Mola modundaysa Odak ekranına döner.
        if currentMode == .rest {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentMode = .focus
                totalTime = 25 * 60
                timeRemaining = totalTime
                selectedHours = 0
                selectedMinutes = 25
            }
        } else {
            timeRemaining = totalTime
        }
    }
    
    func stopTimer() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
    }
    
    func finishTimer() {
        stopTimer()
        HapticManager.shared.triggerSuccess()
        
        DispatchQueue.main.async {
            // Eğer biten şey bir "Odak (Focus)" seansıysa:
            if currentMode == .focus {
                let calculatedXP = (totalTime / 60) * 2
                self.earnedXP = max(10, calculatedXP)
                taskVM.userXP += self.earnedXP
                taskVM.showConfetti = true
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showRewardScreen = true
                }
            }
            // Eğer biten şey bir "Mola (Rest)" seansıysa:
            else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showBreakFinishedScreen = true
                }
            }
        }
    }
}
