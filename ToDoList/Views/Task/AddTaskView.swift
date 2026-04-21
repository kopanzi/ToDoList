import SwiftUI

/// Yeni görev oluşturma formunu yöneten bağımsız View bileşeni.
/// Senior Notu: Takvimden gelen seçili tarih bilgisini (Context) algılar ve formu ona göre kurar.
/// Ayrıca Kamera ve Çoklu Galeri (MultiImagePicker) entegrasyonu barındırır.
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
    
    // 📸 Medya Durumları (YENİ EKLENDİ)
    @State private var selectedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var showGallery = false
    
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
                            // ✨ FIX: iOS 17 withAnimation sarı uyarısı giderildi
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
                
                // 📸 2. MEDYA EKLEME (YENİ EKLENDİ)
                Section {
                    // ✨ SENIOR FIX: Daha minimal, yan yana zarif buton tasarımı
                    HStack(spacing: 15) {
                        Button(action: {
                            HapticManager.shared.triggerLightImpact()
                            showCamera = true
                        }) {
                            Label("Kamera", systemImage: "camera.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(appearance.accentColor.opacity(0.1))
                                .foregroundColor(appearance.accentColor)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            HapticManager.shared.triggerLightImpact()
                            showGallery = true
                        }) {
                            Label("Galeri", systemImage: "photo.on.rectangle.angled")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(appearance.accentColor.opacity(0.1))
                                .foregroundColor(appearance.accentColor)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                    
                    // Seçilen Resimlerin Canlı Önizlemesi
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<selectedImages.count, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        // Resim Kutusu
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 70, height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                        
                                        // Silme Butonu (X)
                                        Button(action: {
                                            HapticManager.shared.triggerLightImpact()
                                            // ✨ FIX: iOS 17 withAnimation uyarısı
                                            _ = withAnimation(.spring()) {
                                                selectedImages.remove(at: index)
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white).frame(width: 14, height: 14))
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                    .padding(.top, 6)
                                    .padding(.trailing, 6)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.leading, 4)
                        }
                    }
                } header: { Text("MEDYA EKLE (OPSİYONEL)") }
                
                // 🔔 3. ZAMANLAMA VE HATIRLATICI
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
                
                // 4. ÖNCELİK VE KATEGORİ
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
                    // ✨ SENIOR FIX: Başlık boş olsa bile eğer fotoğraf eklenmişse butonu aktif et!
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty && selectedImages.isEmpty)
                }
            }
            // ✨ MODAL EKRANLARI BURADA TETİKLENİYOR
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    // ✨ FIX: iOS 17 withAnimation uyarısı
                    withAnimation { selectedImages.append(image) }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showGallery) {
                MultiImagePicker(selectedImages: $selectedImages, isPresented: $showGallery, limit: 5)
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
        var title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        
        // ✨ SENIOR UX FIX: Sadece fotoğraf çekildiyse ve başlık boş bırakıldıysa otomatik isim atıyoruz.
        if title.isEmpty && !selectedImages.isEmpty {
            title = "Fotoğraflı Görev"
        }
        
        guard !title.isEmpty else { return }
        
        let finalDate = selectedDate
        
        // 🎯 SENIOR FIX: Tüm 7 parametre ViewModel'e gönderiliyor (Resimler dahil)
        viewModel.addTask(
            title: title,
            priority: selectedPriority,
            date: finalDate,
            category: selectedCategory,
            isPrivate: isNewTaskPrivate,
            isReminderEnabled: isReminderEnabled,
            images: selectedImages // 📸 Fotoğraflar bağlandı!
        )
        
        HapticManager.shared.triggerSuccess()
        dismiss()
    }
}
