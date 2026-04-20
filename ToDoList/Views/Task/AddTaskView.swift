import SwiftUI

/// Yeni görev oluşturma formunu yöneten bağımsız View bileşeni.
/// Senior Notu: Takvimden gelen seçili tarih bilgisini (Context) algılar ve formu ona göre kurar.
struct AddTaskView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    var isPrivateDefault: Bool
    @Environment(\.dismiss) var dismiss
    
    // Form Verileri
    @State private var newTaskTitle = ""
    @State private var selectedPriority: Priority = .medium
    @State private var selectedCategory: Category = .personal
    @State private var isNewTaskPrivate = false
    
    // 🔔 Hatırlatıcı ve Tarih Durumları
    @State private var isReminderEnabled = false
    @State private var selectedDate: Date
    
    // MARK: - Init
    init(viewModel: TaskViewModel, isPrivateDefault: Bool) {
        self.viewModel = viewModel
        self.isPrivateDefault = isPrivateDefault
        
        // 1. Gizlilik tercihini üst görünümden al
        _isNewTaskPrivate = State(initialValue: isPrivateDefault)
        
        // 2. 🎯 TAKVİM ENTEGRASYONU:
        // Eğer Takvim ekranında bir tarih seçilip "+" butonuna basıldıysa,
        // defaultAdditionDate dolu gelir. Onu başlangıç tarihi yapıyoruz.
        let initialDate = viewModel.defaultAdditionDate ?? Date()
        _selectedDate = State(initialValue: initialDate)
        
        // 3. UX Geliştirmesi: Eğer seçilen tarih bugün değilse,
        // hatırlatıcıyı otomatik olarak açık başlatıyoruz (Kullanıcı kolaylığı).
        if viewModel.defaultAdditionDate != nil && !Calendar.current.isDateInToday(initialDate) {
            _isReminderEnabled = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. TEMEL BİLGİLER VE GİZLİLİK
                Section {
                    HStack {
                        TextField("Ne yapacaksın?", text: $newTaskTitle)
                            .submitLabel(.done)
                        
                        Button(action: {
                            withAnimation(.spring()) { isNewTaskPrivate.toggle() }
                        }) {
                            Image(systemName: isNewTaskPrivate ? "lock.fill" : "lock.open")
                                .foregroundColor(isNewTaskPrivate ? .orange : .gray)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if isNewTaskPrivate {
                        Text("Bu görev sadece Gizli Kasa'da görünecek.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } header: { Text("GÖREV TANIMI") }
                
                // 🔔 2. ZAMANLAMA VE HATIRLATICI
                Section {
                    Toggle(isOn: $isReminderEnabled.animation()) {
                        Label("Hatırlatıcı Ekle", systemImage: "bell.badge.fill")
                            .foregroundColor(isReminderEnabled ? .orange : .primary)
                    }
                    .tint(.orange)
                    
                    if isReminderEnabled {
                        DatePicker(
                            "Tarih ve Saat",
                            selection: $selectedDate,
                            in: Date.distantPast..., // Geçmişe görev eklemeye izin ver (Takvim için)
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                    }
                } header: { Text("ZAMANLAMA") }
                
                // 3. ÖNCELİK VE KATEGORİ
                Section {
                    Picker("Öncelik", selection: $selectedPriority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            HStack {
                                Circle().fill(priority.color).frame(width: 8)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                } header: { Text("DETAYLAR") }
            }
            .navigationTitle(isNewTaskPrivate ? "Yeni Gizli Görev" : "Yeni Görev")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        saveTaskAndDismiss()
                    }
                    .bold()
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // Ekran kapandığında hafızadaki geçici tarihi temizliyoruz
        .onDisappear {
            viewModel.defaultAdditionDate = nil
        }
    }
}

// MARK: - Logic
private extension AddTaskView {
    
    func saveTaskAndDismiss() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        
        // 🎯 SENIOR FIX: init içerisinde selectedDate zaten doğru tarihe kuruluyor.
        // Eğer kullanıcı hatırlatıcıyı kapatsa bile takvimden seçtiği gün korunmalı.
        let finalDate = selectedDate
        
        // TaskViewModel'deki addTask imzasına (6 parametre) tam uyumlu çağrı ✅
        viewModel.addTask(
            title: title,
            priority: selectedPriority,
            date: finalDate,
            category: selectedCategory,
            isPrivate: isNewTaskPrivate,
            isReminderEnabled: isReminderEnabled // Eksik olan parametre eklendi
        )
        
        HapticManager.shared.triggerSuccess()
        dismiss()
    }
}
