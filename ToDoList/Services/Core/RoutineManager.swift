import Foundation
import Combine
import SwiftUI

/// Yaver'in rutinleri yöneten, zamanı geldiğinde görev üreten ve serileri takip eden arka plan beyni.
/// Senior Notu: Hayalet Çalışan (Ghost Worker) mimarisi ile uygulama kapalıyken kaçırılan
/// döngüleri tespit eder ve akıllı yığılma (Stacking) algoritması ile görev listesine enjekte eder.
@MainActor
final class RoutineManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = RoutineManager()
    
    // MARK: - Constants
    private let storageKey = "yaver_routines_v2"
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Published State
    /// Kayıtlı rutinlerin listesi. Dışarıdan sadece okunabilir, değişiklik manager üzerinden yapılır.
    @Published private(set) var routines: [RoutineModel] = []
    
    // MARK: - Initialization
    private init() {
        loadRoutines()
    }
    
    // MARK: - Persistence (Kalıcılık)
    
    private func loadRoutines() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        
        do {
            self.routines = try JSONDecoder().decode([RoutineModel].self, from: data)
        } catch {
            print("🛑 RoutineManager Load Error: \(error.localizedDescription)")
            self.routines = []
        }
    }
    
    private func saveRoutines() {
        do {
            let encoded = try JSONEncoder().encode(routines)
            userDefaults.set(encoded, forKey: storageKey)
        } catch {
            print("🛑 RoutineManager Save Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CRUD İşlemleri
    
    func addRoutine(_ routine: RoutineModel) {
        withAnimation(.spring()) {
            routines.append(routine)
            saveRoutines()
        }
        
        HapticManager.shared.triggerSuccess()
        // Bildirim kuyruğunu hazırla (Gelecek 5 tetiklenme)
        NotificationManager.shared.scheduleRoutineNotifications(for: routine)
    }
    
    func deleteRoutine(id: String) {
        withAnimation(.easeOut) {
            routines.removeAll { $0.id == id }
            saveRoutines()
        }
        
        HapticManager.shared.triggerMediumImpact()
        // Planlanmış bildirimleri temizle
        NotificationManager.shared.cancelRoutineNotification(for: id)
    }
    
    func toggleRoutineActive(id: String) {
        guard let index = routines.firstIndex(where: { $0.id == id }) else { return }
        
        withAnimation(.spring()) {
            routines[index].isActive.toggle()
            
            if routines[index].isActive {
                // Yeniden aktif edildiğinde süreci şimdiden başlat
                routines[index].nextTriggerDate = Date()
                NotificationManager.shared.scheduleRoutineNotifications(for: routines[index])
            } else {
                NotificationManager.shared.cancelRoutineNotification(for: id)
            }
            
            saveRoutines()
            HapticManager.shared.triggerLightImpact()
        }
    }
    
    // MARK: - Gamification (Oyunlaştırma)
    
    /// Rutin görev tamamlandığında seriyi (Streak) günceller.
    func incrementStreak(for routineID: String) {
        guard let index = routines.firstIndex(where: { $0.id == routineID }) else { return }
        
        routines[index].streakCount += 1
        routines[index].lastCompletedDate = Date()
        saveRoutines()
    }
    
    /// XP harcayarak seri koruma (Buz Küpü) satın alır.
    func buyFreeze(for routineID: String, taskViewModel: TaskViewModel) -> Bool {
        let freezeCost = 500
        guard taskViewModel.userXP >= freezeCost else { return false }
        
        guard let index = routines.firstIndex(where: { $0.id == routineID }) else { return false }
        
        taskViewModel.userXP -= freezeCost
        routines[index].freezeCount += 1
        saveRoutines()
        
        HapticManager.shared.triggerSuccess()
        return true
    }
    
    /// Rutinden gelen görevi seriyi bozmadan listeden kaldırır.
    func skipRoutineTask(_ task: TaskModel, taskViewModel: TaskViewModel) {
        withAnimation {
            taskViewModel.tasks.removeAll { $0.id == task.id }
            NotificationManager.shared.cancelNotification(for: task.id)
        }
        HapticManager.shared.triggerSuccess()
    }
    
    // MARK: - 👻 Ghost Worker (Hayalet Çalışan Motoru)
    
    /// Uygulama her ön plana geldiğinde kaçırılan rutin döngülerini kontrol eder.
    func checkRoutines(with taskViewModel: TaskViewModel) {
        let now = Date()
        var hasAnyTaskProduced = false
        
        for i in 0..<routines.count {
            var routine = routines[i]
            guard routine.isActive else { continue }
            
            var missedCycles = 0
            
            // Zaman yolculuğu kontrolü: Şimdiki zamana gelene kadar kaç döngü geçti?
            while routine.nextTriggerDate <= now {
                missedCycles += 1
                routine.nextTriggerDate = calculateNextDate(from: routine.nextTriggerDate, interval: routine.interval, frequency: routine.frequency)
            }
            
            if missedCycles > 0 {
                processRoutineTask(routine: &routine, missedCount: missedCycles, taskViewModel: taskViewModel)
                routines[i] = routine // Güncel verileri (nextTriggerDate, freezeCount vb.) geri yaz
                hasAnyTaskProduced = true
                
                // Bildirim kuyruğunu tazele
                NotificationManager.shared.scheduleRoutineNotifications(for: routine)
            }
        }
        
        if hasAnyTaskProduced {
            saveRoutines()
            HapticManager.shared.triggerLightImpact()
        }
    }
    
    // MARK: - 🥞 Akıllı Yığılma (Stacking) Algoritması
    
    private func processRoutineTask(routine: inout RoutineModel, missedCount: Int, taskViewModel: TaskViewModel) {
        // Eğer görev listede bitmemiş halde duruyorsa (Yığılma Durumu)
        if let existingIndex = taskViewModel.tasks.firstIndex(where: { $0.routineID == routine.id && !$0.isCompleted }) {
            
            // 🧊 SERİ DONDURUCU (Freeze) KONTROLÜ
            if routine.freezeCount > 0 {
                routine.freezeCount -= 1 // Kalkanı kullan
            } else {
                routine.streakCount = 0 // Kalkan yoksa seri acımasızca sıfırlanır
            }
            
            // Görevi güncelle ve aciliyet ata
            var existingTask = taskViewModel.tasks[existingIndex]
            let newDelayedCount = (existingTask.delayedCount ?? 0) + missedCount
            existingTask.delayedCount = newDelayedCount
            existingTask.title = "\(routine.title) (🚨 \(newDelayedCount) Kez Gecikti)"
            existingTask.priority = .urgent
            
            withAnimation {
                taskViewModel.tasks[existingIndex] = existingTask
            }
        } else {
            // Liste temizse yeni bir görev fırlat
            let title = missedCount > 1 ? "\(routine.title) (🚨 \(missedCount) Kez Gecikti)" : routine.title
            let priority: Priority = missedCount > 1 ? .urgent : routine.priority
            
            let newTask = TaskModel(
                title: title,
                isCompleted: false,
                priority: priority,
                category: routine.category,
                createdAt: Date(),
                isPrivate: false,
                note: routine.note,
                routineID: routine.id,
                delayedCount: missedCount > 1 ? missedCount : 0
            )
            
            withAnimation {
                taskViewModel.tasks.append(newTask)
            }
        }
    }
    
    // MARK: - ⏱️ Tarih Motoru
    
    private func calculateNextDate(from date: Date, interval: Int, frequency: RoutineFrequency) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .hour: return calendar.date(byAdding: .hour, value: interval, to: date) ?? date
        case .day: return calendar.date(byAdding: .day, value: interval, to: date) ?? date
        case .week: return calendar.date(byAdding: .day, value: interval * 7, to: date) ?? date
        case .month: return calendar.date(byAdding: .month, value: interval, to: date) ?? date
        }
    }
}
