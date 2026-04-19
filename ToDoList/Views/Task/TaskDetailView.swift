import SwiftUI
import PhotosUI

/// Görev notlarını düzenleme ve AI özelliklerini yöneten detay ekranı.
struct TaskDetailView: View {
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    @EnvironmentObject var appearance: AppearanceManager
    
    @State private var noteText: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showCamera = false
    @State private var selectedImage: UIImage? = nil
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // 1. BAŞLIK VE DURUM
                TaskDetailHeaderView(task: task)
                
                // 2. BİLGİ KARTI
                TaskDetailInfoView(task: task)
                
                // 3. EDİTÖR (DÜZENLEME ALANI Geri Geldi ✅)
                TaskDetailEditorView(noteText: $noteText)
                
                // 4. MEDYA
                TaskDetailMediaView(
                    task: task,
                    viewModel: viewModel,
                    selectedItem: $selectedItem,
                    onCameraTap: { showCamera = true }
                )
                
                // 5. AI ÖNERİSİ
                aiButton
            }
            .padding()
        }
        .onAppear { noteText = task.note }
        .onDisappear {
            // Çıkarken otomatik kaydet ✅
            viewModel.updateTaskNote(task: task, newNote: noteText)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var aiButton: some View {
        Button(action: {
            Task {
                if let suggestion = await viewModel.generateAISuggestions(for: task) {
                    withAnimation { noteText += "\n\n🤖 AI Planı:\n\(suggestion)" }
                    HapticManager.shared.triggerSuccess()
                }
            }
        }) {
            Label("Yaver AI ile Planla", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(15)
        }
    }
}
