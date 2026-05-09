import SwiftUI

/// Kullanıcının silinen görev ve notlarını gördüğü, kurtarabildiği veya tamamen sildiği ekran.
/// Senior Notu: Sabit beyaz/siyah renkler kaldırılarak Aydınlık/Karanlık mod (Adaptive UI)
/// uyumu sağlanmış ve Glassmorphism kart tasarımları modernize edilmiştir.
struct TrashView: View {
    @ObservedObject var taskVM: TaskViewModel
    @ObservedObject var noteVM: NoteViewModel
    var onMenuTap: () -> Void
    
    @StateObject private var trashManager = TrashManager.shared
    @EnvironmentObject var appearance: AppearanceManager
    
    @State private var showingEmptyAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.ignoresSafeArea()
                
                if trashManager.items.isEmpty {
                    EmptyStateView(
                        title: "Çöp Kutusu Boş",
                        icon: "trash",
                        description: "Silinen görevleriniz ve notlarınız burada saklanır."
                    )
                } else {
                    List {
                        ForEach(trashManager.items) { item in
                            TrashRowView(item: item)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowSeparator(.hidden)
                                
                                // SAĞA KAYDIRMA: Kurtar (Geri Yükle)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        restoreItem(item)
                                    } label: {
                                        Label("Kurtar", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.green)
                                }
                                
                                // SOLA KAYDIRMA: Kalıcı Sil
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        HapticManager.shared.triggerMediumImpact()
                                        trashManager.permanentlyDelete(item)
                                    } label: {
                                        Label("Kalıcı Sil", systemImage: "xmark.bin.fill")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Çöp Kutusu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // SOL: Hamburger Menü
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onMenuTap) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.primary) // ✨ Adaptive
                    }
                }
                
                // SAĞ: Temizlik ve Ayarlar Menüsü
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            HapticManager.shared.triggerWarning()
                            showingEmptyAlert = true
                        }) {
                            Label("Tümünü Temizle", systemImage: "trash.slash.fill")
                        }
                        
                        Divider()
                        
                        Text("Otomatik Temizleme")
                        
                        Picker("Otomatik Temizleme", selection: $trashManager.autoEmptyDays) {
                            Text("7 Gün Sonra Sil").tag(7)
                            Text("30 Gün Sonra Sil").tag(30)
                            Text("90 Gün Sonra Sil").tag(90)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(appearance.accentColor) // ✨ Tema Rengi
                    }
                }
            }
            .alert("Kutuyu Boşalt", isPresented: $showingEmptyAlert) {
                Button("İptal", role: .cancel) { }
                Button("Tümünü Sil", role: .destructive) {
                    trashManager.emptyTrash()
                    HapticManager.shared.triggerHeavyImpact()
                }
            } message: {
                Text("Çöp kutusundaki tüm öğeler kalıcı olarak silinecek. Bu işlem geri alınamaz.")
            }
        }
    }
    
    // MARK: - Logic
    private func restoreItem(_ item: TrashItem) {
        if let task = item.task {
            taskVM.restoreTask(task)
        } else if let note = item.note {
            noteVM.restoreNote(note)
        }
        trashManager.removeItem(item)
    }
}

// MARK: - Tekil Çöp Satırı Tasarımı
struct TrashRowView: View {
    let item: TrashItem
    
    var body: some View {
        HStack(spacing: 16) {
            // İkon Kutusu
            ZStack {
                Circle()
                    .fill(Color(hex: item.colorHex).opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.icon)
                    .foregroundColor(Color(hex: item.colorHex))
            }
            
            // Bilgiler
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .strikethrough() // Çöpte olduğunu hissettiren üstü çizili tasarım
                    .foregroundColor(.primary.opacity(0.6)) // ✨ Adaptive: Karanlıkta/Aydınlıkta okunaklı
                    .lineLimit(1)
                
                Text("Silinme: \(item.deletedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary) // ✨ Adaptive
            }
            
            Spacer()
            
            // Kalan Gün Sayacı (Zeka Göstergesi)
            let daysPassed = Calendar.current.dateComponents([.day], from: item.deletedAt, to: Date()).day ?? 0
            let daysLeft = max(0, TrashManager.shared.autoEmptyDays - daysPassed)
            
            VStack {
                Text("\(daysLeft) Gün")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .clipShape(Capsule()) // ✨ Şık kapsül (Pill) tasarımı
            }
        }
        .padding(16)
        // ✨ GLASSMORPHISM (Adaptive UI)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                // ✨ SENIOR FIX: .white yerine .primary ile aydınlık/karanlık mod uyumu
                .fill(Color.primary.opacity(0.03))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
