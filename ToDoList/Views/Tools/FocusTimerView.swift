import SwiftUI

/// Yaver'in oyunlaştırılmış ve esnek Odak Sayacı (Pomodoro) ekranı.
/// Senior Notu: Apple HIG standartlarına (Sistem Arkaplanı + Tema Rengi) geçirilmiştir.
/// "Odak" modu kullanıcının seçtiği tema rengini kullanırken, "Mola" modu Zen etkisini korur.
struct FocusTimerView: View {
    // MARK: - Properties
    @ObservedObject var taskVM: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
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
    
    // ✨ SENIOR FIX: Renkler artık tamamen Dinamik Tema ve Mod uyumludur.
    private var activeColor: Color {
        currentMode == .focus ? appearance.accentColor : .green
    }
    
    private var activeGradient: Gradient {
        Gradient(colors: [activeColor, activeColor.opacity(0.6), activeColor])
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. ADAPTIVE ARKA PLAN
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // Nefes Alan Arka Plan Işığı (Aura)
            Circle()
                .fill(activeColor.opacity(isRunning ? 0.12 : 0.04))
                .frame(width: 350, height: 350)
                .blur(radius: 60)
                .scaleEffect(isPulsing ? 1.15 : 0.85)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isPulsing)
            
            VStack(spacing: 40) {
                
                // ÜST BAR
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        if currentMode == .rest {
                            handleModeResetToFocus()
                        } else {
                            stopTimer()
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.primary.opacity(0.2))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // BAŞLIK
                VStack(spacing: 10) {
                    Text(currentMode == .focus ? "MUTLAK ODAK" : "ZİHİNSEL MOLA")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(activeColor)
                        .tracking(6)
                    
                    Text(currentMode == .focus ? "Dünyayı sessize alıp masada kal." : "Gözlerini dinlendir ve derin nefes al.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // ANA SAYAÇ HALKASI
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.05), lineWidth: 15)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(max(1, totalTime)))
                        .stroke(
                            AngularGradient(gradient: activeGradient, center: .center),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)
                        .shadow(color: isRunning ? activeColor.opacity(0.4) : .clear, radius: 15)
                    
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: timeRemaining >= 3600 ? 55 : 72, weight: .black, design: .monospaced))
                        .foregroundColor(.primary)
                        .shadow(color: activeColor.opacity(isRunning ? 0.3 : 0), radius: 10)
                }
                .frame(width: 280, height: 280)
                
                // SÜRE AYARLAMA KISAYOLLARI
                if !isRunning && !isPaused && currentMode == .focus {
                    HStack(spacing: 16) {
                        pickerShortcutButton(title: "Süreyi Ayarla", icon: "clock.fill", color: .primary) {
                            showTimePicker = true
                        }
                        
                        pickerShortcutButton(title: "Pomodoro", icon: "bolt.fill", color: appearance.accentColor) {
                            selectedHours = 0
                            selectedMinutes = 25
                            syncTimeFromPickers()
                        }
                    }
                    .padding(.top, 10)
                } else {
                    Color.clear.frame(height: 44).padding(.top, 10)
                }
                
                Spacer()
                
                // AKSİYON BUTONLARI
                HStack(spacing: 30) {
                    if !isRunning && !isPaused {
                        controlButton(title: "BAŞLA", icon: "play.fill", color: activeColor, action: startTimer)
                    } else {
                        controlButton(
                            title: isRunning ? "DURAKLAT" : "DEVAM ET",
                            icon: isRunning ? "pause.fill" : "play.fill",
                            color: isRunning ? .orange : activeColor,
                            action: { if isRunning { pauseTimer() } else { resumeTimer() } }
                        )
                        
                        controlButton(title: "VAZGEÇ", icon: "stop.fill", color: .red, action: resetTimer)
                    }
                }
                .padding(.bottom, 60)
            }
            .disabled(showRewardScreen || showBreakFinishedScreen)
            .blur(radius: (showRewardScreen || showBreakFinishedScreen) ? 8 : 0)
            
            if showRewardScreen { rewardPopup }
            if showBreakFinishedScreen { breakFinishedPopup }
        }
        .onAppear {
            isPulsing = true
            selectedHours = totalTime / 3600
            selectedMinutes = (totalTime % 3600) / 60
        }
        .onDisappear { stopTimer() }
        .sheet(isPresented: $showTimePicker) { timePickerSheet }
    }
}

// MARK: - Sub-Views & Helper Components
private extension FocusTimerView {
    
    func pickerShortcutButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.triggerSelection()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 13, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color.opacity(0.08))
            .foregroundColor(color.opacity(0.8))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    func controlButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: 74, height: 74)
                    Image(systemName: icon).font(.system(size: 26, weight: .bold)).foregroundColor(color)
                }
                .overlay(Circle().stroke(color.opacity(0.2), lineWidth: 1.5))
                
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(color)
                    .tracking(1.5)
            }
        }
        .buttonStyle(SquishButtonStyle())
    }
    
    var rewardPopup: some View {
        popupOverlay(
            icon: "sparkles",
            iconColor: appearance.accentColor,
            title: "Seans Tamamlandı",
            message: "Harika bir iş çıkardın kanka! Bu emek karşılıksız kalmaz; Sİo sana tam \(earnedXP) XP kazandırdı. Şimdi bir kahve molasını hak ettin.",
            primaryBtnTitle: "☕️ 5 Dakika Mola Ver",
            primaryBtnAction: { startBreakMode(minutes: 5) },
            secondaryBtnTitle: "Kapat",
            secondaryBtnAction: { dismiss() }
        )
    }
    
    var breakFinishedPopup: some View {
        popupOverlay(
            icon: "bolt.fill",
            iconColor: .green,
            title: "Mola Bitti",
            message: "Zihnini tazeledin, enerjini topladın. Yeni bir odak seansına geçmek için hazırsan masaya dönelim mi?",
            primaryBtnTitle: "🔥 Yeni Seans Başlat",
            primaryBtnAction: { startFocusMode() },
            secondaryBtnTitle: "Şimdilik Yeterli",
            secondaryBtnAction: { dismiss() }
        )
    }
    
    func popupOverlay(icon: String, iconColor: Color, title: String, message: String, primaryBtnTitle: String, primaryBtnAction: @escaping () -> Void, secondaryBtnTitle: String, secondaryBtnAction: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: icon).font(.system(size: 44)).foregroundColor(iconColor).shadow(color: iconColor.opacity(0.4), radius: 10)
                VStack(spacing: 8) {
                    Text(title).font(.title3.bold()).foregroundColor(.primary)
                    Text(message).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).lineSpacing(4)
                }
                VStack(spacing: 12) {
                    Button(action: {
                        HapticManager.shared.triggerSuccess()
                        withAnimation { primaryBtnAction() }
                    }) {
                        Text(primaryBtnTitle).font(.headline).foregroundColor(Color(uiColor: .systemBackground)).frame(maxWidth: .infinity).padding(.vertical, 16).background(iconColor).cornerRadius(16)
                    }
                    Button(action: {
                        HapticManager.shared.triggerLightImpact()
                        secondaryBtnAction()
                    }) {
                        Text(secondaryBtnTitle).font(.subheadline.bold()).foregroundColor(.secondary)
                    }
                }
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 30).fill(Color(uiColor: .secondarySystemGroupedBackground)).background(.regularMaterial))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.primary.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 40)
        }
    }
    
    var timePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Picker("Saat", selection: $selectedHours) { ForEach(0..<13) { i in Text("\(i) Saat").tag(i) } }.pickerStyle(.wheel)
                    Picker("Dakika", selection: $selectedMinutes) { ForEach(0..<60) { i in Text("\(i) Dk").tag(i) } }.pickerStyle(.wheel)
                }.padding(.horizontal)
                Button(action: {
                    HapticManager.shared.triggerSelection()
                    syncTimeFromPickers(); showTimePicker = false
                }) {
                    Text("Zamanı Ayarla").font(.headline.bold()).foregroundColor(Color(uiColor: .systemBackground)).frame(maxWidth: .infinity).padding().background(appearance.accentColor).cornerRadius(14)
                }.padding(.horizontal, 30).padding(.bottom, 30)
            }
            .navigationTitle("Odaklanma Süresi").navigationBarTitleDisplayMode(.inline)
        }.presentationDetents([.height(360)]).presentationDragIndicator(.visible)
    }
}

// MARK: - Logic & Actions
private extension FocusTimerView {
    func startBreakMode(minutes: Int) { showRewardScreen = false; currentMode = .rest; totalTime = minutes * 60; timeRemaining = totalTime; startTimer() }
    func startFocusMode() { showBreakFinishedScreen = false; currentMode = .focus; totalTime = 25 * 60; timeRemaining = totalTime; selectedHours = 0; selectedMinutes = 25 }
    func handleModeResetToFocus() { stopTimer(); withAnimation(.easeInOut(duration: 0.5)) { currentMode = .focus; totalTime = 25 * 60; timeRemaining = totalTime } }
    func syncTimeFromPickers() { var newTime = (selectedHours * 3600) + (selectedMinutes * 60); if newTime == 0 { newTime = 60; selectedMinutes = 1 }; totalTime = newTime; timeRemaining = newTime }
    func timeString(from seconds: Int) -> String { let h = seconds / 3600; let m = (seconds % 3600) / 60; let s = seconds % 60; if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }; return String(format: "%02d:%02d", m, s) }
    func startTimer() { HapticManager.shared.triggerHeavyImpact(); isRunning = true; isPaused = false; timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in if timeRemaining > 0 { timeRemaining -= 1 } else { finishTimer() } } }
    func pauseTimer() { HapticManager.shared.triggerLightImpact(); isRunning = false; isPaused = true; timer?.invalidate() }
    func resumeTimer() { startTimer() }
    func resetTimer() { HapticManager.shared.triggerWarning(); stopTimer(); if currentMode == .rest { handleModeResetToFocus() } else { timeRemaining = totalTime } }
    func stopTimer() { isRunning = false; isPaused = false; timer?.invalidate(); timer = nil }
    
    // ✨ SENIOR FIX: Sayaç bitince Odaklanılan Süre (FocusSession) veritabanına kaydedilir
    func finishTimer() {
        stopTimer()
        HapticManager.shared.triggerSuccess()
        
        DispatchQueue.main.async {
            if currentMode == .focus {
                let minutes = totalTime / 60
                
                // 1. Odak seansını veritabanına (TaskVM) kaydet!
                taskVM.addFocusSession(minutes: minutes)
                
                // 2. Kazanılan XP'yi hesapla (Dakika başı 2 XP)
                let calculatedXP = minutes * 2
                self.earnedXP = max(10, calculatedXP) // En az 10 XP garantisi
                taskVM.userXP += self.earnedXP
                
                // 3. Konfetileri ve ödül ekranını patlat
                taskVM.showConfetti = true
                withAnimation(.spring(response: 0.5)) {
                    showRewardScreen = true
                }
            } else {
                // Mola bitiş ekranı
                withAnimation(.spring(response: 0.5)) {
                    showBreakFinishedScreen = true
                }
            }
        }
    }
}

// MARK: - Styles
/// Butonlara tıklandığında hafifçe küçülme ve şeffaflaşma efekti veren stil.
struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
