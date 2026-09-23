import SwiftUI

struct TaskTierPanel: View {
    let tier: TaskTier
    let tasks: [TaskItem]
    let onAdd: () -> Void
    let onToggle: (TaskItem) -> Void
    let onBackburner: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void
    var onSchedule: ((TaskItem) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Tier \(tier.rawValue)").font(.system(size: 20, weight: .medium))
                    Text(tier.subtitle).font(.caption).foregroundStyle(KaizenTheme.muted)
                }
                Spacer()
                Text("\(tasks.count)/3").font(.caption.monospacedDigit()).foregroundStyle(KaizenTheme.muted)
            }
            ForEach(tasks) { task in
                HStack(alignment: .top, spacing: 12) {
                    Button { onToggle(task) } label: {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2).frame(minWidth: 32, minHeight: 44)
                    }
                    .accessibilityLabel(task.isCompleted ? "Mark \(task.title) incomplete" : "Complete \(task.title)")
                    Text(task.title).strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? KaizenTheme.muted : .white)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 11)
                    Menu {
                        if let onSchedule { Button("Schedule task", systemImage: "clock") { onSchedule(task) } }
                        Button("Move to backburner", systemImage: "tray") { onBackburner(task) }
                        Button("Delete task", systemImage: "trash", role: .destructive) { onDelete(task) }
                    } label: { Image(systemName: "ellipsis").frame(width: 32, height: 44) }
                    .accessibilityLabel("Options for \(task.title)")
                }
                Divider().overlay(KaizenTheme.muted.opacity(0.15))
            }
            ForEach(0..<max(0, 3 - tasks.count), id: \.self) { index in
                Button(action: onAdd) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle").font(.title2)
                        Text(index == 0 ? "Add a task" : "Room for something meaningful").font(.subheadline)
                        Spacer(minLength: 0)
                    }.foregroundStyle(KaizenTheme.muted).padding(.vertical, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
