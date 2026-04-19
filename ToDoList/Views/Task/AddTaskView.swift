import SwiftUI

/// Yeni görev oluşturma formunu yöneten bağımsız View bileşeni.
struct AddTaskView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: TaskViewModel
    var isPrivateDefault: Bool
    @Environment(\.dismiss) var dismiss
    
    // Form Verileri
    @State private var newTaskTitle = ""
    @State private var selectedPriority: Priority = .medium
    @State private var selectedCategory: Category = .personal
    @State private var isNewTaskPrivate = false
    
    // 🔔 YENİ: Hatırlatıcı Durumları
    @State private var isReminderEnabled = false
    @State private var selectedDate = Date()
    
    // MARK: - Init
    init(viewModel: TaskViewModel, isPrivateDefault: Bool) {
        self.viewModel = viewModel
        self.isPrivateDefault = isPrivateDefault
        // Üst görünümden gelen gizlilik tercihini varsayılan olarak atıyoruz
        _isNewTaskPrivate = State(initialValue: isPrivateDefault)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. TEMEL BİLGİLER VE GİZLİLİK
                Section {
                    HStack {
                        TextField("Ne yapacaksın?", text: $newTaskTitle)
                            .submitLabel(.done)
                        
                        // Kilit Butonu (Animasyonlu)
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
                } header: {
                    Text("GÖREV TANIMI")
                }
                
                // 🔔 2. ZAMANLAMA VE HATIRLATICI BÖLÜMÜ
                Section {
                    Toggle(isOn: $isReminderEnabled.animation()) {
                        Label("Hatırlatıcı Ekle", systemImage: "bell.badge.fill")
                            .foregroundColor(isReminderEnabled ? .orange : .primary)
                    }
                    .tint(.orange)
                    .onChange(of: isReminderEnabled) { _, newValue in
                        if newValue {
                            // Kullanıcıdan bildirim izni iste
                            viewModel.requestNotificationPermission()
                        }
                    }
                    
                    if isReminderEnabled {
                        DatePicker("Tarih ve Saat", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                } header: {
                    Text("ZAMANLAMA")
                }
                
                // 3. ÖNCELİK VE KATEGORİ SEÇİMİ
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
                } header: {
                    Text("DETAYLAR")
                }
            }
            .navigationTitle(isNewTaskPrivate ? "Yeni Gizli Görev" : "Yeni Görev")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // SOL: İptal
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                
                // SAĞ: Ekle
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        saveTaskAndDismiss()
                    }
                    .bold()
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        // iPhone'da yarım ekran (Sheet) olarak açıldığında şık durması için
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Logic
private extension AddTaskView {
    
    /// Görevi kaydeder ve ekranı kapatır.
    func saveTaskAndDismiss() {
        // Boşlukları temizleyerek kontrol ediyoruz
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        
        // ViewModel üzerinden ekleme yapıyoruz
        viewModel.addTask(
            title: title,
            priority: selectedPriority,
            date: isReminderEnabled ? selectedDate : Date(), // 🔔 Hatırlatıcı seçildiyse o tarihi kullan
            category: selectedCategory,
            isPrivate: isNewTaskPrivate,
            isReminderEnabled: isReminderEnabled // 🔔 Yeni parametre eklendi
        )
        
        // Haptic geri bildirim (ViewModel içinde yoksa buraya da eklenebilir)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    AddTaskView(viewModel: TaskViewModel(), isPrivateDefault: false)
}
