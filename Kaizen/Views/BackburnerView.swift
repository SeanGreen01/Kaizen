import SwiftUI

struct BackburnerView: View {
    @ObservedObject var model: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    @State private var pendingDelete: TaskItem?
    private var overdue: [TaskItem] {
        model.tasks.filter { !$0.inBackburner && !$0.isCompleted && $0.resolvedDay < DayKey.string(Date()) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("A place for later. Pick tasks from here when you plan tomorrow.")
                        .foregroundStyle(KaizenTheme.muted).listRowBackground(Color.clear)
                }
                if model.backburner.isEmpty {
                    ContentUnavailableView("A little breathing room", systemImage: "tray",
                                           description: Text("Capture an idea or task with the + button."))
                        .listRowBackground(Color.clear)
                }
                ForEach(TaskCategory.allCases) { category in
                    let items = model.backburner.filter { $0.resolvedCategory == category }
                    if !items.isEmpty {
                        Section(category.rawValue) {
                            ForEach(items) { task in row(task) }
                        }
                    }
                }
                if !overdue.isEmpty {
                    Section("Unfinished from earlier days") {
                        ForEach(overdue) { task in
                            VStack(alignment: .leading, spacing: 8) {
                                row(task)
                                Button("Move to backburner") { Task { await model.moveToBackburner(task) } }
                                    .font(.caption)
                            }.listRowBackground(Color.clear)
                        }
                    }
                }
            }
            .disabled(model.isSaving)
            .scrollContentBackground(.hidden).background(KaizenTheme.background)
            .navigationTitle("Backburner")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add task", systemImage: "plus") { adding = true }
                }
            }
            .sheet(isPresented: $adding) {
                AddTaskView(model: model, tier: .c, date: Date(), backburner: true, category: .personal)
            }
            .confirmationDialog("Delete this task?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
                Button("Delete task", role: .destructive) {
                    if let task = pendingDelete { Task { await model.deleteTask(task) } }
                    pendingDelete = nil
                }
            }
            .modifier(TaskErrorModifier(model: model))
        }.tint(KaizenTheme.accent).preferredColorScheme(.dark)
    }

    private func row(_ task: TaskItem) -> some View {
        HStack {
            Button { Task { await model.toggleCompletion(task) } } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").frame(width: 32, height: 44)
            }.buttonStyle(.borderless)
                .accessibilityLabel(task.isCompleted ? "Mark \(task.title) incomplete" : "Complete \(task.title)")
            Text(task.title).strikethrough(task.isCompleted)
            Spacer()
            Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = task }
                .labelStyle(.iconOnly).buttonStyle(.borderless)
        }.listRowBackground(Color.clear)
    }
}
