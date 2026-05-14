import Foundation
import Combine
import SwiftUI
import FirebaseAuth // ✨ SENIOR FIX: Bulut bağlantısı için eklendi

/// Yaver'in rutinleri yöneten, zamanı geldiğinde görev üreten ve serileri takip eden arka plan beyni.
/// Senior Notu: Hayalet Çalışan (Ghost Worker) mimarisi korunmuş, Firestore Cloud Sync eklenmiştir.
@MainActor
final class RoutineManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = RoutineManager()
    
    // MARK: - Constants
    private let storageKey = "yaver_routines_v2"
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Published State
    @Published private(set) var routines: [RoutineModel] = []
    
    // MARK: - Initialization
    private init() {
        loadRoutines()
        
        // ✨ SENIOR FIX: Kullanıcı giriş yaptığını algıla ve buluttaki rutinleri telefona çek
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.syncRoutinesWithCloud()
            }
        }
    }
    
    // MARK: - CLOUD SYNC (BULUT MOTORU) ✨
    
    private func syncRoutinesWithCloud() {
        Task {
            do {
                let cloudRoutines = try await FirestoreManager.shared.fetchRoutines()
                
                if cloudRoutines.isEmpty && !self.routines.isEmpty {
                    await FirestoreManager.shared.syncLocalRoutinesToCloud(routines: self.routines)
                } else if !cloudRoutines.isEmpty {
                    var merged = self.routines
                    for cloudR in cloudRoutines {
                        if let index = merged.firstIndex(where: { $0.id == cloudR.id }) {
                            merged[index] = cloudR
                        } else {
                            merged.append(cloudR)
                        }
                    }
                    self.routines = merged
                    saveRoutines() // Yereli de güncelle
                    await FirestoreManager.shared.syncLocalRoutinesToCloud(routines: merged)
                }
            } catch {
                print("🛑 Rutinler Bulut Senkronizasyon Hatası: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveRoutineToCloud(_ routine: RoutineModel) {
            guard Auth.auth().currentUser != nil else {
                print("🛑 HATA: Kullanıcı giriş yapmamış, rutin buluta gidemez!")
                return
            }
            Task {
                do {
                    try await FirestoreManager.shared.saveRoutine(routine)
                    print("✅ RUTİN BAŞARIYLA BULUTA GİTTİ: \(routine.title)")
                } catch {
                    print("🛑 RUTİN BULUT HATASI: \(error.localizedDescription)")
                    print("🛑 DETAYLI HATA: \(error)")
                }
            }
        }
    
    private func deleteRoutineFromCloud(id: String) {
        guard Auth.auth().currentUser != nil else { return }
        Task { try? await FirestoreManager.shared.deleteRoutine(id: id) }
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
        // ✨ Buluta Kaydet
        saveRoutineToCloud(routine)
        
        HapticManager.shared.triggerSuccess()
        NotificationManager.shared.scheduleRoutineNotifications(for: routine)
    }
    
    func deleteRoutine(id: String) {
        withAnimation(.easeOut) {
            routines.removeAll { $0.id == id }
            saveRoutines()
        }
        // ✨ Buluttan Sil
        deleteRoutineFromCloud(id: id)
        
        HapticManager.shared.triggerMediumImpact()
        NotificationManager.shared.cancelRoutineNotification(for: id)
    }
    
    func toggleRoutineActive(id: String) {
        guard let index = routines.firstIndex(where: { $0.id == id }) else { return }
        
        withAnimation(.spring()) {
            routines[index].isActive.toggle()
            if routines[index].isActive {
                routines[index].nextTriggerDate = Date()
                NotificationManager.shared.scheduleRoutineNotifications(for: routines[index])
            } else {
                NotificationManager.shared.cancelRoutineNotification(for: id)
            }
            saveRoutines()
            // ✨ Değişikliği Buluta Yolla
            saveRoutineToCloud(routines[index])
            HapticManager.shared.triggerLightImpact()
        }
    }
    
    // MARK: - Gamification (Oyunlaştırma)
    
    func incrementStreak(for routineID: String) {
        guard let index = routines.firstIndex(where: { $0.id == routineID }) else { return }
        routines[index].streakCount += 1
        routines[index].lastCompletedDate = Date()
        saveRoutines()
        // ✨ Seriyi Buluta Yolla
        saveRoutineToCloud(routines[index])
    }
    
    func buyFreeze(for routineID: String, taskViewModel: TaskViewModel) -> Bool {
        let freezeCost = 500
        guard taskViewModel.userXP >= freezeCost else { return false }
        guard let index = routines.firstIndex(where: { $0.id == routineID }) else { return false }
        
        taskViewModel.userXP -= freezeCost
        routines[index].freezeCount += 1
        saveRoutines()
        // ✨ Yeni Kalkanı Buluta Yolla
        saveRoutineToCloud(routines[index])
        
        HapticManager.shared.triggerSuccess()
        return true
    }
    
    func skipRoutineTask(_ task: TaskModel, taskViewModel: TaskViewModel) {
        withAnimation {
            taskViewModel.tasks.removeAll { $0.id == task.id }
            NotificationManager.shared.cancelNotification(for: task.id)
        }
        // Görevin silinmesi TaskViewModel tarafında zaten buluta senkronize edilecek.
        HapticManager.shared.triggerSuccess()
    }
    
    // MARK: - 👻 Ghost Worker (Hayalet Çalışan Motoru)
    
    func checkRoutines(with taskViewModel: TaskViewModel) {
        let now = Date()
        var hasAnyTaskProduced = false
        
        for i in 0..<routines.count {
            var routine = routines[i]
            guard routine.isActive else { continue }
            
            var missedCycles = 0
            while routine.nextTriggerDate <= now {
                missedCycles += 1
                routine.nextTriggerDate = calculateNextDate(from: routine.nextTriggerDate, interval: routine.interval, frequency: routine.frequency)
            }
            
            if missedCycles > 0 {
                processRoutineTask(routine: &routine, missedCount: missedCycles, taskViewModel: taskViewModel)
                routines[i] = routine
                hasAnyTaskProduced = true
                
                NotificationManager.shared.scheduleRoutineNotifications(for: routine)
                // ✨ Güncel Döngüyü Buluta Yolla (Seri bozulmuş veya kalkan kullanılmış olabilir)
                saveRoutineToCloud(routine)
            }
        }
        
        if hasAnyTaskProduced {
            saveRoutines()
            HapticManager.shared.triggerLightImpact()
        }
    }
    
    // MARK: - 🥞 Akıllı Yığılma (Stacking) Algoritması
    
    private func processRoutineTask(routine: inout RoutineModel, missedCount: Int, taskViewModel: TaskViewModel) {
        if let existingIndex = taskViewModel.tasks.firstIndex(where: { $0.routineID == routine.id && !$0.isCompleted }) {
            if routine.freezeCount > 0 {
                routine.freezeCount -= 1
            } else {
                routine.streakCount = 0
            }
            
            var existingTask = taskViewModel.tasks[existingIndex]
            let newDelayedCount = (existingTask.delayedCount ?? 0) + missedCount
            existingTask.delayedCount = newDelayedCount
            existingTask.title = "\(routine.title) (🚨 \(newDelayedCount) Kez Gecikti)"
            existingTask.priority = .urgent
            
            withAnimation {
                taskViewModel.tasks[existingIndex] = existingTask
            }
            // Not: existingTask'in güncellenmesi, TaskViewModel tarafından zaten dinlenip buluta atılacak.
        } else {
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
