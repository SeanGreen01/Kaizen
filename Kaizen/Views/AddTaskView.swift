import SwiftUI

struct AddTaskView: View {
    @ObservedObject var model: TaskViewModel
    let tier: TaskTier
    let date: Date
    let backburner: Bool
    @State var category: TaskCategory
    @State private var title = ""
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("What’s on your mind?") {
                    TextField("Task name", text: $title, axis: .vertical)
                        .focused($focused).lineLimit(1...4)
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                if !backburner {
                    Text("Tier \(tier.rawValue) · \(date.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            .scrollContentBackground(.hidden).background(KaizenTheme.background)
            .navigationTitle(backburner ? "Save for later" : "New task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(model.isSaving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.isSaving ? "Saving…" : "Save") {
                        Task {
                            if await model.addTask(title: title, category: category, tier: tier, date: date, backburner: backburner) { dismiss() }
                        }
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isSaving)
                }
            }
            .task { focused = true }
            .interactiveDismissDisabled(model.isSaving)
            .modifier(TaskErrorModifier(model: model))
        }.tint(KaizenTheme.accent).preferredColorScheme(.dark)
    }
}
