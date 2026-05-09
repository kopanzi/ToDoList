import SwiftUI

/// Notların listelendiği ana orkestratör ekran.
/// Senior Notu: Standart liste görünümünden kurtulup "Havada Süzülen Cam Kartlar" (Floating Glass Cards)
/// tasarımına geçiş yapılması için liste ayarları (separator, insets) optimize edilmiştir.
struct NoteListView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: NoteViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    var showPrivateOnly: Bool = false
    var onMenuTap: () -> Void
    
    @State private var showingAddNote = false
    @State private var searchText: String = ""
    @Environment(\.editMode) private var editMode
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Şeffaf arka plan katmanı (ContentView'daki Mesh Gradient'in görünmesi için)
                Color.clear.ignoresSafeArea()
                
                mainListContent
            }
            .navigationTitle(showPrivateOnly ? "Gizli Notlar" : "Notlarım")
            .searchable(text: $searchText, prompt: "Notlarda ara...")
            // ✨ SENIOR FIX: Navigasyon barına da buzlu cam efekti vererek arkaplanla bütünleştiriyoruz.
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar { toolbarContent }
            // ✅ BAĞIMSIZ SUNUM: AddNoteView sheet olarak sorunsuzca çağrılır.
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(viewModel: viewModel, isPrivateDefault: showPrivateOnly)
            }
        }
    }
}

// MARK: - Sub-Views & Logic Layer
private extension NoteListView {
    
    /// Arama ve gizlilik filtreleri uygulanmış, her an güncel not dizisi.
    var filteredNotes: [NotModel] {
        let visibleNotes = viewModel.notes.filter { $0.isPrivate == showPrivateOnly }
        
        if searchText.isEmpty {
            return visibleNotes
        } else {
            return visibleNotes.filter {
                $0.baslik.localizedCaseInsensitiveContains(searchText) ||
                $0.icerik.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    /// Ana liste veya "Boş Durum" ekranını çizen yapı.
    @ViewBuilder
    var mainListContent: some View {
        if filteredNotes.isEmpty {
            EmptyStateView(
                title: showPrivateOnly ? "Gizli Kasa Boş" : "Not Bulunmadı",
                icon: showPrivateOnly ? "lock.rectangle.stack" : "note.text",
                description: searchText.isEmpty
                    ? "Yeni bir not ekleyerek başlayabilirsin."
                    : "Aramana uygun bir not bulamadık."
            )
        } else {
            List {
                ForEach(filteredNotes) { note in
                    NavigationLink(destination: NoteDetailView(note: note, viewModel: viewModel)) {
                        NoteRowView(note: note, viewModel: viewModel)
                    }
                    // ✨ SENIOR FIX 1: O çirkin standart liste ayraç çizgilerini kaldırıyoruz!
                    .listRowSeparator(.hidden)
                    // ✨ SENIOR FIX 2: NoteRowView'ın kendi cam efektini gösterebilmesi için satır zeminini şeffaf yapıyoruz.
                    .listRowBackground(Color.clear)
                    // ✨ SENIOR FIX 3: Kartların arasına ve kenarlarına nefes almaları için boşluk ekliyoruz.
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete(perform: deleteNoteWithHaptics)
                .onMove(perform: moveNoteWithHaptics)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            // Liste her değiştiğinde yumuşak geçiş animasyonu uygular
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredNotes.count)
        }
    }
    
    /// Üst menü (Toolbar) butonlarını çizen temiz yapı.
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // SOL MENÜ (Hamburger veya Düzenleme Modu Onayı)
        ToolbarItem(placement: .topBarLeading) {
            if editMode?.wrappedValue.isEditing == true {
                EditButton()
            } else {
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    onMenuTap()
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
            }
        }
        
        // SAĞ MENÜ (Düzenle ve Yeni Ekle)
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 15) {
                if !viewModel.notes.isEmpty {
                    EditButton()
                }
                
                Button(action: {
                    HapticManager.shared.triggerLightImpact()
                    showingAddNote = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .foregroundColor(appearance.accentColor)
                }
            }
        }
    }
    
    // MARK: - Aksiyonlar (Actions)
    
    /// Not silme işlemini haptic geri bildirimle süsler.
    func deleteNoteWithHaptics(at offsets: IndexSet) {
        HapticManager.shared.triggerMediumImpact()
        viewModel.deleteNote(at: offsets)
    }
    
    /// Not taşıma (sıralama) işlemini haptic geri bildirimle süsler.
    func moveNoteWithHaptics(source: IndexSet, destination: Int) {
        HapticManager.shared.triggerSelection()
        viewModel.moveNote(from: source, to: destination, currentItems: filteredNotes)
    }
}
