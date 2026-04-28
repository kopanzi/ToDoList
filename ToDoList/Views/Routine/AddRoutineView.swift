import SwiftUI

/// Kullanıcının yeni bir alışkanlık (Rutin) şablonu oluşturduğu form ekranı.
/// Senior Notu: Hazır şablonlar (Templates) ile hızlı ekleme desteği sunar ve
/// iOS 17+ standartlarında güvenli (uyarısız) animasyon tetikleyicileri kullanır.
struct AddRoutineView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appearance: AppearanceManager
    @ObservedObject private var routineManager = RoutineManager.shared
    
    // Form Verileri
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var selectedPriority: Priority = .medium
    @State private var selectedCategory: Category = .personal
    
    // Zamanlama Motoru Verileri
    @State private var startDate: Date = Date()
    @State private var interval: Int = 1
    @State private var frequency: RoutineFrequency = .day
    
    var body: some View {
        NavigationStack {
            Form {
                // 🚀 YENİ: HAZIR ŞABLONLAR (Yatay Kaydırılabilir Menü)
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(RoutineModel.templates) { template in
                                Button(action: { applyTemplate(template) }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(template.title)
                                                .font(.headline.bold())
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: template.category?.icon ?? "star.fill")
                                                .foregroundColor(template.category?.color ?? .orange)
                                        }
                                        
                                        Text("Her \(template.interval) \(template.frequency.rawValue)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .frame(width: 150)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("HAZIR ŞABLONLAR")
                }
                
                // 1. RUTİN TANIMI
                Section {
                    TextField("Rutin Adı (Örn: 30 Paragraf Çöz)", text: $title)
                        .submitLabel(.next)
                    
                    TextField("Not veya Motivasyon (Opsiyonel)", text: $note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("ALIŞKANLIK TANIMI")
                }
                
                // 2. ⏱️ ZAMANLAMA VE DÖNGÜ
                Section {
                    HStack {
                        Text("Tekrar Sıklığı:")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("Her")
                            .foregroundColor(.secondary)
                        
                        Picker("Sayı", selection: $interval) {
                            ForEach(1...90, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .tint(appearance.accentColor)
                        
                        Picker("Birim", selection: $frequency) {
                            ForEach(RoutineFrequency.allCases, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .tint(appearance.accentColor)
                    }
                    
                    DatePicker(
                        "Başlangıç Zamanı",
                        selection: $startDate,
                        in: Date()..., // Geçmişe rutin kurulamaz
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .tint(appearance.accentColor)
                    
                } header: {
                    Text("DÖNGÜ AYARLARI")
                }
                
                // 3. DETAYLAR VE ETİKETLER
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
                    Text("GÖREV DETAYLARI")
                }
            }
            .navigationTitle("Yeni Rutin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Oluştur") {
                        saveRoutine()
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Logic (İş Mantığı)
private extension AddRoutineView {
    
    /// Kullanıcı hazır şablona tıkladığında formu anında o şablona göre doldurur.
    func applyTemplate(_ template: RoutineModel) {
        HapticManager.shared.triggerSelection()
        withAnimation {
            title = template.title
            note = template.note
            interval = template.interval
            frequency = template.frequency
            selectedPriority = template.priority
            if let cat = template.category { selectedCategory = cat }
        }
    }
    
    /// Formdaki verilerle yeni bir rutin üretir, sisteme devreder ve arayüzü kapatır.
    func saveRoutine() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }
        
        // 1. Yeni Şablonu Kur
        let newRoutine = RoutineModel(
            title: cleanTitle,
            priority: selectedPriority,
            category: selectedCategory,
            note: note.trimmingCharacters(in: .whitespaces),
            startDate: startDate,
            interval: interval,
            frequency: frequency,
            isActive: true
        )
        
        // 2. Manager'a teslim et (Uyarısız Güvenli Animasyon)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            routineManager.addRoutine(newRoutine)
        }
        
        // 3. Arayüzü Kapat
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    AddRoutineView()
        .environmentObject(AppearanceManager.shared)
}
