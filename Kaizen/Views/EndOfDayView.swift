import SwiftUI

private struct PlanEntry: Identifiable {
    let id = UUID()
    var task: TaskItem
    var sourceID: String? = nil
}

struct EndOfDayView: View {
    @ObservedObject var model: TaskViewModel
    let today: Date
    @Environment(\.dismiss) private var dismiss
    @State private var review = DailyReview(day: "")
    @State private var entries: [PlanEntry] = []
    @State private var category: TaskCategory = .health
    @State private var tier: TaskTier = .a
    @State private var newTitle = ""
    @State private var step = 0
    @State private var editor: PlanningEditor?
    @State private var eventChanges: [CalendarEvent] = []
    @State private var loading = true
    @State private var loadFailed = false
    @State private var confirmDiscard = false
    @State private var dirty = false
    private var tomorrow: Date { DayKey.tomorrow(from: today) }
    private var slotEntries: [PlanEntry] {
        entries.filter { $0.task.resolvedCategory == category && $0.task.tier == tier }
    }
    private var candidates: [TaskItem] {
        let selectedIDs = Set(entries.compactMap(\.sourceID))
        return model.tasks.filter {
            !$0.isCompleted && $0.resolvedCategory == category &&
            ($0.inBackburner || $0.resolvedDay <= DayKey.string(today)) &&
            !selectedIDs.contains($0.id ?? "")
        }.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(step == 2 ? "Shape your day." : step == 1 ? "Choose what matters." : "A moment for today.")
                        .font(.system(size: 30, weight: .medium))
                    Text(step == 2 ? "Your commitments are already here. Give tasks a time, add a little detail, or leave space open." : step == 1 ? "Health, work, and personal. Up to three tasks in each tier." : today.formatted(date: .complete, time: .omitted))
                        .foregroundStyle(KaizenTheme.muted)
                    if loading {
                        ProgressView("Loading your reflection…")
                    } else if loadFailed {
                        Button("Retry loading reflection") { Task { await load() } }
                    } else if step == 2 {
                        schedule
                    } else if step == 1 {
                        planner
                    } else {
                        reflection
                    }
                }.padding(24).frame(maxWidth: 700).frame(maxWidth: .infinity)
            }
            .background(KaizenTheme.background)
            .navigationTitle(step == 2 ? "03 / Schedule" : step == 1 ? "02 / Priorities" : "01 / Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        if dirty { confirmDiscard = true } else { dismiss() }
                    }.disabled(model.isSaving)
                }
                if step > 0 {
                    ToolbarItem(placement: .primaryAction) { Button("Back") { step -= 1 }.disabled(model.isSaving) }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !loading && !loadFailed {
                    Button {
                        if step == 2 {
                            Task {
                                if await model.savePlan(review: review, plan: entries.map(\.task), date: tomorrow,
                                                        sourceIDs: Set(entries.compactMap(\.sourceID).filter { id in model.backburner.contains { $0.id == id } }), events: eventChanges) {
                                    dismiss()
                                }
                            }
                        } else { step += 1 }
                    } label: {
                        Text(model.isSaving ? "Saving…" : step == 2 ? "Save tomorrow’s plan" : step == 1 ? "Schedule your day →" : "Choose tomorrow’s tasks →")
                    }
                    .buttonStyle(PrimaryButtonStyle()).disabled(model.isSaving)
                    .padding().background(KaizenTheme.background)
                }
            }
            .interactiveDismissDisabled(dirty || model.isSaving)
            .confirmationDialog("Discard unsaved reflection and plan?", isPresented: $confirmDiscard) {
                Button("Discard changes", role: .destructive) { dismiss() }
            }
            .sheet(item: $editor) { editor in
                switch editor {
                case .task(let id):
                    if let entry = entries.first(where: { $0.id == id }) {
                        TaskScheduleEditor(task: entry.task, day: tomorrow, agenda: tomorrowAgenda) { updated in
                            if let index = entries.firstIndex(where: { $0.id == id }) {
                                entries[index].task = updated; dirty = true; return true
                            }
                            return false
                        }
                    }
                case .event(let event):
                    EventEditorView(event: event, isNew: !model.events.contains { $0.id == event.id }, onSave: { updated in
                        eventChanges.removeAll { $0.id == updated.id }
                        eventChanges.append(updated); dirty = true; return true
                    }, onDelete: model.events.contains { $0.id == event.id } ? nil : { deleted in
                        eventChanges.removeAll { $0.id == deleted.id }; dirty = true; return true
                    })
                }
            }
            .task { await load() }
            .modifier(TaskErrorModifier(model: model))
        }.tint(KaizenTheme.accent).preferredColorScheme(.dark)
    }

    private var reflection: some View {
        VStack(alignment: .leading, spacing: 22) {
            if !model.agenda(on: today).isEmpty {
                AgendaList(entries: model.agenda(on: today))
                Divider().padding(.vertical, 8)
            }
            Label("\(review.completed) of \(review.total) tasks completed", systemImage: "checkmark.circle")
                .font(.headline).foregroundStyle(KaizenTheme.accent)
            Text("How did you feel?").font(.headline)
            Picker("How did you feel?", selection: $review.mood) {
                ForEach(["Drained", "Low", "Okay", "Good", "Great"], id: \.self) { Text($0).tag($0) }
            }.pickerStyle(.menu).onChange(of: review.mood) { _, _ in dirty = true }
            reflectionField("What went well?", prompt: "A win, however small…", text: $review.wentWell)
            reflectionField("What could be better?", prompt: "One thing to try differently…", text: $review.improve)
            reflectionField("Tomorrow’s focus", prompt: "What deserves your attention?", text: $review.focus)
            VStack(alignment: .leading, spacing: 12) {
                Label("Your daily perspective", systemImage: "leaf").font(.headline)
                Text(review.feedback).font(.subheadline).foregroundStyle(KaizenTheme.muted)
                Text("Based on your task progress and reflections.").font(.caption2).foregroundStyle(KaizenTheme.muted)
            }.padding(.vertical, 20).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func reflectionField(_ title: String, prompt: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            TextField(prompt, text: text, axis: .vertical).lineLimit(3...6).padding(.vertical, 12)
                .overlay(alignment: .bottom) { Divider() }
                .onChange(of: text.wrappedValue) { _, _ in dirty = true }
        }
    }

    private var planner: some View {
        VStack(alignment: .leading, spacing: 20) {
            CategoryTabs(selection: $category)
            Text("\(entries.filter { $0.task.resolvedCategory == category }.count) of 9 \(category.rawValue.lowercased()) tasks selected")
                .font(.subheadline).foregroundStyle(KaizenTheme.muted)
            Picker("Priority", selection: $tier) {
                ForEach(TaskTier.allCases) { Text("Tier \($0.rawValue)").tag($0) }
            }.pickerStyle(.segmented)
            Text(tier.subtitle).font(.headline)
            ForEach(slotEntries) { entry in
                HStack {
                    Text(entry.task.title)
                    Spacer()
                    Button("Remove", systemImage: "minus.circle") {
                        entries.removeAll { $0.id == entry.id }; dirty = true
                    }.labelStyle(.iconOnly).accessibilityLabel("Remove \(entry.task.title) from plan")
                }.padding(.vertical, 12)
            }
            if slotEntries.count < 3 {
                HStack {
                    TextField("Add a new task", text: $newTitle, axis: .vertical)
                    Button("Add", systemImage: "plus.circle.fill") { add(title: newTitle); newTitle = "" }
                        .labelStyle(.iconOnly).font(.title2)
                        .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }.padding(.vertical, 12)
                Text("From your backburner & unfinished tasks").font(.headline)
                if candidates.isEmpty {
                    Text("Nothing waiting here. Add a new task above.").foregroundStyle(KaizenTheme.muted)
                }
                ForEach(candidates) { task in
                    Button { add(title: task.title, source: task) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(task.title).foregroundStyle(.white)
                                Text(task.inBackburner ? "Backburner" : "Unfinished · \(task.resolvedDay)")
                                    .font(.caption).foregroundStyle(KaizenTheme.muted)
                            }
                            Spacer()
                            Image(systemName: "plus.circle")
                        }.padding(.vertical, 10)
                    }
                }
            } else {
                Label("This tier is ready. Choose another tier or category.", systemImage: "checkmark.circle")
                    .foregroundStyle(KaizenTheme.accent)
            }
        }.disabled(model.isSaving)
    }

    private var tomorrowAgenda: [AgendaEntry] {
        let changedIDs = Set(eventChanges.map(\.id))
        let events = model.events.filter { !changedIDs.contains($0.id) } + eventChanges
        return AgendaEntry.entries(on: tomorrow, events: events, tasks: entries.map(\.task))
    }

    private var schedule: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                Text(tomorrow.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                    .font(.subheadline).foregroundStyle(KaizenTheme.muted)
                Spacer()
                Button("Add event", systemImage: "plus") {
                    let start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
                    editor = .event(CalendarEvent(title: "", category: category, start: start, end: start.addingTimeInterval(3600)))
                }.font(.caption)
            }
            AgendaList(entries: tomorrowAgenda) { row in
                if let event = row.event { editor = .event(event) }
                else if let entry = entries.first(where: { $0.task.id == row.task?.id }) { editor = .task(entry.id) }
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("Anytime").font(.system(size: 19, weight: .medium))
                Text("Untimed tasks stay on your plan. Tap one to choose a start and end time.")
                    .font(.caption).foregroundStyle(KaizenTheme.muted)
                ForEach(entries.filter { $0.task.scheduledStart == nil }) { entry in
                    Button { editor = .task(entry.id) } label: {
                        HStack(spacing: 11) {
                            Rectangle().fill(entry.task.resolvedCategory.color).frame(width: 2, height: 20)
                            Text(entry.task.title).font(.subheadline).foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "clock.badge.plus").font(.caption).foregroundStyle(KaizenTheme.muted)
                        }.frame(minHeight: 40)
                    }
                }
                if entries.allSatisfy({ $0.task.scheduledStart != nil }) {
                    Text(entries.isEmpty ? "No tasks selected. You can go back to add some, or just save your events." : "Every selected task has a time.")
                        .font(.subheadline).foregroundStyle(KaizenTheme.muted)
                }
            }
        }.disabled(model.isSaving)
    }

    private func add(title: String, source: TaskItem? = nil) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, slotEntries.count < 3 else { return }
        let task = TaskItem(id: UUID().uuidString, title: clean, tier: tier, createdAt: Date(), isCompleted: false,
                            category: category, scheduledDay: DayKey.string(tomorrow), isBackburner: false, sourceTaskID: source?.id)
        entries.append(PlanEntry(task: task, sourceID: source?.id))
        dirty = true
    }

    private func load() async {
        loading = true
        loadFailed = false
        defer { loading = false }
        do {
            review = try await model.review(for: today) ?? DailyReview(day: DayKey.string(today))
            let tasks = model.scheduled(on: today)
            review.completed = tasks.filter(\.isCompleted).count
            review.total = tasks.count
            entries = model.scheduled(on: tomorrow).map { PlanEntry(task: $0, sourceID: $0.sourceTaskID) }
            eventChanges = []
            dirty = false
        } catch {
            loadFailed = true
            model.errorMessage = error.localizedDescription
        }
    }
}


private enum PlanningEditor: Identifiable {
    case task(UUID), event(CalendarEvent)
    var id: String {
        switch self {
        case .task(let id): return id.uuidString
        case .event(let event): return event.id
        }
    }
}
