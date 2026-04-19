import Foundation
import SwiftUI
import Combine

/// Takvim modülünün beyni. Günleri hesaplar, ısı haritası üretir ve görevleri günlere göre filtreler.
/// Senior Notu: View katmanını sade tutmak için tüm tarih hesaplamaları, Drag & Drop ve
/// Apple Takvim (EventKit) iş mantığı buraya izole edilmiştir.
@MainActor
final class CalendarViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var selectedDate: Date = Date()
    @Published var currentWeekOffset: Int = 0 // Sağa/sola kaydırıldığında hafta değişimi
    @Published var isSyncing: Bool = false
    
    // MARK: - Dependencies
    // TaskViewModel'deki verilere doğrudan erişim sağlamak için (Dependency Injection)
    private var taskVM: TaskViewModel
    private let hapticManager = HapticManager.shared
    
    // Yaver'in Apple Takvim servisi ile konuşacağı köprü
    private let calendarService = CalendarService.shared
    
    // MARK: - Init
    init(taskVM: TaskViewModel) {
        self.taskVM = taskVM
    }
    
    // MARK: - Enum & Modeller
    
    /// Günün yoğunluğunu belirten Isı Haritası (Heatmap) seviyeleri
    enum HeatmapLevel {
        case none, low, medium, high
        
        var opacity: Double {
            switch self {
            case .none: return 0.0
            case .low: return 0.2
            case .medium: return 0.6
            case .high: return 1.0
            }
        }
    }
    
    // MARK: - Core Date Engine (Tarih Motoru)
    
    /// Ekranda gösterilecek 14 günlük (2 Haftalık) kaydırılabilir tarih şeridini üretir.
    func generateCompactWeeks() -> [Date] {
        let calendar = Calendar.current
        // Offset'e göre referans gününü bul
        let referenceDate = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: Date()) ?? Date()
        
        // Referans gününün bulunduğu haftanın Pazartesi gününü bul
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
        components.weekday = 2 // Pazartesi (1: Pazar, 2: Pazartesi)
        
        guard let startOfWeek = calendar.date(from: components) else { return [] }
        
        // O haftadan itibaren 14 gün ileri git
        var dates: [Date] = []
        for i in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }
    
    /// Takvimde bir sonraki/önceki haftaya geçiş
    func changeWeek(by value: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentWeekOffset += value
            hapticManager.triggerLightImpact()
        }
    }
    
    // MARK: - Task Filtering & Heatmap (Veri Analizi)
    
    /// Seçili güne ait "Today's Flow" (Günün Akışı) görevlerini getirir.
    func getDailyFlow(for date: Date) -> [TaskModel] {
        let allTasks = taskVM.tasks
        let calendar = Calendar.current
        
        var dailyTasks = allTasks.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
        
        // Eğer gizli kasa kapalıysa, gizli görevleri (isPrivate == true) listeden sakla!
        if !taskVM.isUnlocked {
            dailyTasks = dailyTasks.filter { !$0.isPrivate }
        }
        
        // Saate göre sırala
        return dailyTasks.sorted { $0.createdAt < $1.createdAt }
    }
    
    /// O gün gizli kasa görevi olup olmadığını kontrol eder (Takvimde 🔒 ikonu göstermek için).
    func hasHiddenTasks(on date: Date) -> Bool {
        let calendar = Calendar.current
        return taskVM.tasks.contains { $0.isPrivate && calendar.isDate($0.createdAt, inSameDayAs: date) }
    }
    
    /// Günün yoğunluk derecesini hesaplar (Isı Haritası).
    func getHeatmapLevel(for date: Date) -> HeatmapLevel {
        let calendar = Calendar.current
        // Sadece tamamlanmamış ve gizli olmayan görevleri say (Gizliler ısı haritasını ifşa etmesin)
        let activeTasks = taskVM.tasks.filter {
            !$0.isCompleted && !$0.isPrivate && calendar.isDate($0.createdAt, inSameDayAs: date)
        }
        
        let count = activeTasks.count
        
        if count == 0 { return .none }
        if count <= 2 { return .low }
        if count <= 5 { return .medium }
        return .high
    }
    
    // MARK: - Drag & Drop Zaman Yolculuğu
    
    /// Görevi takvim üzerinde başka bir güne sürükleyip bıraktığında çalışır.
    func moveTask(_ task: TaskModel, to newDate: Date) {
        guard let index = taskVM.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let calendar = Calendar.current
        let oldDate = taskVM.tasks[index].createdAt
        
        // Saati ve dakikayı koru, sadece Yıl/Ay/Gün değiştir
        let oldComponents = calendar.dateComponents([.hour, .minute, .second], from: oldDate)
        var newComponents = calendar.dateComponents([.year, .month, .day], from: newDate)
        newComponents.hour = oldComponents.hour
        newComponents.minute = oldComponents.minute
        newComponents.second = oldComponents.second
        
        if let updatedDate = calendar.date(from: newComponents) {
            taskVM.tasks[index].createdAt = updatedDate
            
            // Eğer görevin bildirimi varsa onu da yeni güne göre güncelle
            NotificationManager.shared.cancelNotification(for: task.id)
            if !taskVM.tasks[index].isCompleted {
                NotificationManager.shared.scheduleNotification(for: taskVM.tasks[index])
            }
            
            hapticManager.triggerSuccess()
        }
    }
    
    // MARK: - Yerel Takvim (Apple Calendar) Senkronizasyonu
    
    /// Görevi cihazın yerel takvimine ekler.
    /// Senior Notu: Yeni CalendarService kullanılarak async/await mimarisine uyarlanmıştır.
    func exportToAppleCalendar(task: TaskModel) async {
        isSyncing = true
        // İşlem bitince mutlaka false'a dönmesini garantiliyoruz
        defer { isSyncing = false }
        
        do {
            // Önce yetki iste (iOS 17 uyumlu servis metodu)
            let hasAccess = try await calendarService.requestAccess()
            
            if hasAccess {
                // Sadece Task objesini yollamamız yeterli (overload metodu kullandık)
                try calendarService.saveTaskToCalendar(task: task)
                hapticManager.triggerHeavyImpact()
            } else {
                // Kullanıcı izin vermedi
                print("🛑 Kullanıcı takvim iznini reddetti.")
                hapticManager.triggerError()
            }
        } catch {
            print("🛑 Takvime eklenirken hata: \(error.localizedDescription)")
            hapticManager.triggerError()
        }
    }
}
