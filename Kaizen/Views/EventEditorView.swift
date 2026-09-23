import SwiftUI

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var event: CalendarEvent
    @State private var saving = false
    @State private var errorMessage: String?
    @State private var confirmDelete = false
    @State private var confirmDiscard = false
    private let original: CalendarEvent
    let isNew: Bool
    let onSave: (CalendarEvent) async -> Bool
    var onDelete: ((CalendarEvent) async -> Bool)? = nil
    var failureMessage: () -> String? = { nil }

    init(event: CalendarEvent, isNew: Bool, onSave: @escaping (CalendarEvent) async -> Bool,
         onDelete: ((CalendarEvent) async -> Bool)? = nil, failureMessage: @escaping () -> String? = { nil }) {
        _event = State(initialValue: event)
        original = event
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
        self.failureMessage = failureMessage
    }

    private var dirty: Bool {
        event.title != original.title || event.start != original.start || event.end != original.end ||
        event.category != original.category || event.isAllDay != original.isAllDay || event.notes != original.notes
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Event title", text: $event.title, axis: .vertical).font(.title3).accessibilityIdentifier("eventTitle")
                    Picker("Category", selection: $event.category) {
                        ForEach(TaskCategory.allCases) { Text($0.rawValue).tag($0) }
                    }
                }.listRowBackground(Color.clear)
                Section {
                    Toggle("All day", isOn: $event.isAllDay)
                    DatePicker("Starts", selection: $event.start, displayedComponents: event.isAllDay ? [.date] : [.date, .hourAndMinute])
                    DatePicker(event.isAllDay ? "Last day" : "Ends", selection: allDayEnd, displayedComponents: event.isAllDay ? [.date] : [.date, .hourAndMinute])
                }.listRowBackground(Color.clear)
                Section("Notes") {
                    TextField("Location, details, or a little context", text: $event.notes, axis: .vertical).lineLimit(3...8)
                }.listRowBackground(Color.clear)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).listRowBackground(Color.clear) }
                if let message = event.validationMessage, !event.title.isEmpty {
                    Text(message).foregroundStyle(KaizenTheme.muted).listRowBackground(Color.clear)
                }
                if onDelete != nil {
                    Button("Delete event", role: .destructive) { confirmDelete = true }.listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden).background(KaizenTheme.background)
            .disabled(saving)
            .navigationTitle(isNew ? "New event" : "Edit event").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { if dirty { confirmDiscard = true } else { dismiss() } }.disabled(saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") {
                        Task {
                            saving = true
                            var cleaned = event
                            cleaned.title = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
                            if await onSave(cleaned) { dismiss() }
                            else { errorMessage = failureMessage() ?? "Could not save. Please try again." }
                            saving = false
                        }
                    }.disabled(saving || event.validationMessage != nil)
                }
            }
            .onChange(of: event.isAllDay) { _, allDay in
                if allDay {
                    event.start = Calendar.current.startOfDay(for: event.start)
                    event.end = DayKey.tomorrow(from: max(event.start, event.end.addingTimeInterval(-1)))
                }
            }
            .confirmationDialog("Delete this event?", isPresented: $confirmDelete) {
                Button("Delete event", role: .destructive) {
                    Task {
                        saving = true
                        if let onDelete, await onDelete(event) { dismiss() }
                        else { errorMessage = failureMessage() ?? "Could not delete. Please try again." }
                        saving = false
                    }
                }
            }
            .confirmationDialog("Discard event changes?", isPresented: $confirmDiscard) {
                Button("Discard changes", role: .destructive) { dismiss() }
            }
            .interactiveDismissDisabled(saving || dirty)
        }.tint(KaizenTheme.accent).preferredColorScheme(.dark)
    }

    // All-day storage uses an exclusive end; the editor presents an inclusive last day.
    private var allDayEnd: Binding<Date> {
        Binding(get: { event.isAllDay ? event.end.addingTimeInterval(-1) : event.end },
                set: { event.end = event.isAllDay ? DayKey.tomorrow(from: $0) : $0 })
    }
}

struct TaskScheduleEditor: View {
    let task: TaskItem
    let day: Date
    let agenda: [AgendaEntry]
    let onSave: (TaskItem) async -> Bool
    var failureMessage: () -> String? = { nil }
    @Environment(\.dismiss) private var dismiss
    @State private var start: Date
    @State private var end: Date
    @State private var saving = false
    @State private var errorMessage: String?

    init(task: TaskItem, day: Date, agenda: [AgendaEntry], onSave: @escaping (TaskItem) async -> Bool,
         failureMessage: @escaping () -> String? = { nil }) {
        self.task = task; self.day = day; self.agenda = agenda; self.onSave = onSave; self.failureMessage = failureMessage
        let start = task.scheduledStart ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day)!
        _start = State(initialValue: start)
        _end = State(initialValue: task.scheduledEnd ?? start.addingTimeInterval(3600))
    }

    private var conflicts: [AgendaEntry] {
        agenda.filter { !$0.allDay && ($0.event != nil || $0.task?.id != task.id) && start < $0.end && end > $0.start }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(task.title).font(.title3)
                    Text("\(task.resolvedCategory.rawValue) · Tier \(task.tier.rawValue)").foregroundStyle(KaizenTheme.muted)
                }.listRowBackground(Color.clear)
                Section(day.formatted(date: .complete, time: .omitted)) {
                    DatePicker("Starts", selection: $start, in: Calendar.current.startOfDay(for: day)...DayKey.tomorrow(from: day).addingTimeInterval(-1), displayedComponents: [.hourAndMinute])
                    DatePicker("Ends", selection: $end, in: Calendar.current.startOfDay(for: day)...DayKey.tomorrow(from: day), displayedComponents: [.date, .hourAndMinute])
                }.listRowBackground(Color.clear)
                if let message = TaskSchedule.validationMessage(start: start, end: end, day: day) {
                    Text(message).foregroundStyle(KaizenTheme.muted).listRowBackground(Color.clear)
                }
                if !conflicts.isEmpty {
                    Section("At the same time") {
                        ForEach(conflicts) { Text($0.title).font(.subheadline) }
                        Text("Overlaps are allowed. Keep this time if it works for you.").font(.caption).foregroundStyle(KaizenTheme.muted)
                    }.listRowBackground(Color.clear)
                }
                Section {
                    Button(task.isCompleted ? "Mark incomplete" : "Mark complete") {
                        var updated = task; updated.isCompleted.toggle(); persist(updated)
                    }
                    if task.scheduledStart != nil {
                        Button("Leave untimed") {
                            var updated = task; updated.scheduledStart = nil; updated.scheduledEnd = nil; persist(updated)
                        }
                    }
                }.listRowBackground(Color.clear)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).listRowBackground(Color.clear) }
            }
            .scrollContentBackground(.hidden).background(KaizenTheme.background).disabled(saving)
            .navigationTitle("Schedule task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Done") {
                        var updated = task; updated.scheduledStart = start; updated.scheduledEnd = end; persist(updated)
                    }.disabled(saving || TaskSchedule.validationMessage(start: start, end: end, day: day) != nil)
                }
            }
            .interactiveDismissDisabled(saving)
        }.tint(KaizenTheme.accent).preferredColorScheme(.dark)
    }

    private func persist(_ updated: TaskItem) {
        Task {
            saving = true
            if await onSave(updated) { dismiss() }
            else { errorMessage = failureMessage() ?? "Could not save. Please try again." }
            saving = false
        }
    }
}
