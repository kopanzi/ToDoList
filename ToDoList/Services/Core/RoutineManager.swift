import Foundation
import Combine
import SwiftUI

/// Yaver'in rutinleri yöneten, zamanı geldiğinde görev üreten arka plan beyni.
/// Senior Notu: Bildirim (Notification) motoru ve Oyunlaştırma (Gamification) özellikleri entegre edilmiştir.
@MainActor
final class RoutineManager: ObservableObject {
    static let shared = RoutineManager()
    
    // UI'ın anlık tepki verebilmesi için rutinleri @Published yapıyoruz.
    @Published var routines: [RoutineModel] = [] {
        didSet { saveRoutines() }
    }
    
    private let userDefaultsKey = "yaver_routines_v2"
    
    private init() {
        loadRoutines()
    }
    
    // MARK: - 💾 Veri Yönetimi
    private func loadRoutines() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([RoutineModel].self, from: data) {
            self.routines = decoded
        }
    }
    
    private func saveRoutines() {
        if let encoded = try? JSONEncoder().encode(routines) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - 🛠️ CRUD İşlemleri
    func addRoutine(_ routine: RoutineModel) {
        routines.append(routine)
        HapticManager.shared.triggerSuccess()
        
        // ✨ YENİ: Alarmı Kur (Uygulama kapalıyken bile çalışması için kuyruğa ekle)
        NotificationManager.shared.scheduleRoutineNotifications(for: routine)
    }
    
    func deleteRoutine(id: String) {
        routines.removeAll { $0.id == id }
        HapticManager.shared.triggerMediumImpact()
        
        // ✨ YENİ: Alarmları İptal Et
        NotificationManager.shared.cancelRoutineNotification(for: id)
    }
    
    func toggleRoutineActive(id: String) {
        if let index = routines.firstIndex(where: { $0.id == id }) {
            routines[index].isActive.toggle()
            
            if routines[index].isActive {
                routines[index].nextTriggerDate = Date()
                NotificationManager.shared.scheduleRoutineNotifications(for: routines[index])
            } else {
                NotificationManager.shared.cancelRoutineNotification(for: id)
            }
            
            HapticManager.shared.triggerLightImpact()
        }
    }
    
    // MARK: - 🎮 Oyunlaştırma (Gamification)
    
    /// Kullanıcı rutinden gelen bir görevi tiklediğinde seriyi artırır.
    func incrementStreak(for routineID: String) {
        if let index = routines.firstIndex(where: { $0.id == routineID }) {
            routines[index].streakCount += 1
            routines[index].lastCompletedDate = Date()
            saveRoutines()
        }
    }
    
    /// Kullanıcı XP'si ile seri dondurucu (Buz Küpü) satın alır.
    func buyFreeze(for routineID: String, taskViewModel: TaskViewModel) -> Bool {
        let freezeCost = 500
        guard taskViewModel.userXP >= freezeCost else { return false }
        
        if let index = routines.firstIndex(where: { $0.id == routineID }) {
            taskViewModel.userXP -= freezeCost
            routines[index].freezeCount += 1
            saveRoutines()
            HapticManager.shared.triggerSuccess()
            return true
        }
        return false
    }
    
    /// Kullanıcı "Bugünü Atla" dediğinde görevi siler ama seriyi bozmaz.
    func skipRoutineTask(_ task: TaskModel, taskViewModel: TaskViewModel) {
        withAnimation {
            taskViewModel.tasks.removeAll { $0.id == task.id }
            NotificationManager.shared.cancelNotification(for: task.id)
        }
        HapticManager.shared.triggerSuccess()
    }
    
    // MARK: - 👻 HAYALET ÇALIŞAN (Ghost Worker)
    /// Bu fonksiyon uygulama her aktif olduğunda veya ana ekrana dönüldüğünde çağrılır.
    func checkRoutines(with taskViewModel: TaskViewModel) {
        let now = Date()
        var hasChanges = false
        
        for i in 0..<routines.count {
            var routine = routines[i] // inout için geçici değişken
            
            // Eğer rutin pasifse hiç bulaşma
            guard routine.isActive else { continue }
            
            var missedCount = 0
            
            // Rutin zamanı gelmiş mi veya geçmiş mi? (Döngü sayesinde kaçırdığı tüm aralıkları sayarız)
            while routine.nextTriggerDate <= now {
                missedCount += 1
                routine.nextTriggerDate = calculateNextDate(from: routine.nextTriggerDate, interval: routine.interval, frequency: routine.frequency)
            }
            
            // Eğer zamanı geldiyse ve en az 1 kez kaçırıldıysa görev üret!
            if missedCount > 0 {
                processRoutineTask(routine: &routine, missedCount: missedCount, taskViewModel: taskViewModel)
                routines[i] = routine // Güncel değerleri (Buz kırılması vb.) kaydet
                hasChanges = true
                
                // ✨ YENİ: Yeni görev üretildikten sonra bildirim kuyruğunu tazele (Sıradaki alarmları kur)
                NotificationManager.shared.scheduleRoutineNotifications(for: routine)
            }
        }
        
        // Eğer yeni görev eklendiyse ufak bir titreşim ver ki kullanıcı "Bir şeyler geldi" desin.
        if hasChanges {
            HapticManager.shared.triggerLightImpact()
        }
    }
    
    // MARK: - 🥞 Akıllı Yığılma ve Buz Kırma
    private func processRoutineTask(routine: inout RoutineModel, missedCount: Int, taskViewModel: TaskViewModel) {
        // 1. KONTROL: Eğer görev hala ekrandaysa (tamamlanmamışsa), kullanıcı bir önceki döngüyü kaçırmıştır!
        if let existingTaskIndex = taskViewModel.tasks.firstIndex(where: { $0.routineID == routine.id && !$0.isCompleted }) {
            
            // 🧊 SERİ DONDURUCU KONTROLÜ
            if routine.freezeCount > 0 {
                routine.freezeCount -= 1 // Buz küpünü kır!
                // Not: Seri sıfırlanmadı, XP ile kendini kurtardı!
            } else {
                routine.streakCount = 0 // Seri acımasızca sıfırlanır :(
            }
            
            // Yığılma (Stacking) işlemi
            var existingTask = taskViewModel.tasks[existingTaskIndex]
            let newDelayedCount = (existingTask.delayedCount ?? 0) + missedCount
            existingTask.delayedCount = newDelayedCount
            
            // Başlığı uyarı formatına çevir ve aciliyetini artır
            existingTask.title = "\(routine.title) (🚨 \(newDelayedCount) Kez Gecikti)"
            existingTask.priority = .urgent
            
            // ViewModel'i güncelle
            withAnimation {
                taskViewModel.tasks[existingTaskIndex] = existingTask
            }
            
        } else {
            // 2. KONTROL: Eğer görev ekranda yoksa taptaze bir görev fırlatıyoruz
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
                routineID: routine.id, // ✨ Hangi rutinden geldiğini bağlıyoruz
                delayedCount: missedCount > 1 ? missedCount : 0
            )
            
            withAnimation {
                taskViewModel.tasks.append(newTask)
            }
        }
    }
    
    // MARK: - ⏱️ Zaman Motoru
    private func calculateNextDate(from date: Date, interval: Int, frequency: RoutineFrequency) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .hour:
            return calendar.date(byAdding: .hour, value: interval, to: date) ?? date
        case .day:
            return calendar.date(byAdding: .day, value: interval, to: date) ?? date
        case .week:
            return calendar.date(byAdding: .day, value: interval * 7, to: date) ?? date
        case .month:
            return calendar.date(byAdding: .month, value: interval, to: date) ?? date
        }
    }
}
