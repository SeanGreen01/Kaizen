import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model: TaskViewModel
    @State private var category: TaskCategory = .health
    @State private var tier: TaskTier = .a
    @State private var date = Calendar.current.startOfDay(for: Date())
    @State private var priorities = true
    @State private var reviewDate = Date()
    @State private var sheet: DashboardSheet?
    @State private var pendingDelete: TaskItem?
    @State private var showingDeleteAccount = false
    @State private var showingPrivacyPolicy = false

    init() { _model = StateObject(wrappedValue: TaskViewModel()) }
    init(model: TaskViewModel) { _model = StateObject(wrappedValue: model) }
    private var dailyTasks: [TaskItem] { model.scheduled(on: date) }
    private var dayTitle: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.day().month(.wide))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CalendarDateStrip(selection: $date, events: model.events, tasks: model.tasks)
                Capsule().fill(Color(white: 0.24)).frame(width: 30, height: 2).padding(.top, 4).padding(.bottom, 24)
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(priorities ? "Priorities" : dayTitle).font(.system(size: 34, weight: .medium))
                                Text(date.formatted(.dateTime.month(.wide).year())).font(.caption).foregroundStyle(KaizenTheme.muted)
                            }
                            Spacer()
                            Button { sheet = priorities ? .add : .event(newEvent()) } label: {
                                Image(systemName: "plus").font(.system(size: 19, weight: .light)).frame(width: 36, height: 36)
                                    .background(KaizenTheme.surface, in: Circle()).frame(width: 44, height: 44)
                            }.accessibilityLabel(priorities ? "Add priority task" : "Add calendar event")
                                .disabled(!model.hasLoaded || model.isSaving)
                        }
                        if model.isLoading && !model.hasLoaded {
                            ProgressView("Loading your day…").frame(maxWidth: .infinity)
                        } else if !model.hasLoaded {
                            Button("Retry loading your day") { Task { await model.loadTasks() } }
                        } else if priorities {
                            priorityList
                        } else {
                            AgendaList(entries: model.agenda(on: date), onSelect: select)
                            untimedTasks
                        }
                        Button { reviewDate = Date(); sheet = .review } label: {
                            HStack {
                                Image(systemName: "moon")
                                Text("Review today & plan tomorrow")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }.font(.system(size: 13)).foregroundStyle(KaizenTheme.muted).padding(.vertical, 16)
                        }.accessibilityIdentifier("beginPlanning").disabled(!model.hasLoaded || model.isSaving || model.isLoading)
                    }.padding(.horizontal, 24).padding(.bottom, 20).frame(maxWidth: 700).frame(maxWidth: .infinity)
                }
                .refreshable { await model.loadTasks() }
            }
            .background(KaizenTheme.background)
            .safeAreaInset(edge: .bottom) { navigation }
            .toolbar(.hidden, for: .navigationBar)
            .task { await model.loadTasks() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await model.loadTasks() } } }
            .sheet(item: $sheet) { item in
                switch item {
                case .add, .quickAdd:
                    AddTaskView(model: model, tier: tier, date: date, backburner: item.id == "quickAdd", category: category)
                case .backburner: BackburnerView(model: model)
                case .review: EndOfDayView(model: model, today: reviewDate)
                case .event(let event):
                    EventEditorView(event: event, isNew: !model.events.contains { $0.id == event.id },
                                    onSave: { await model.saveEvent($0) },
                                    onDelete: model.events.contains { $0.id == event.id } ? { await model.deleteEvent($0) } : nil,
                                    failureMessage: takeError)
                case .task(let task):
                    TaskScheduleEditor(task: task, day: date, agenda: model.agenda(on: date),
                                       onSave: { await model.save($0) }, failureMessage: takeError)
                case .date:
                    NavigationStack {
                        DatePicker("Go to date", selection: $date, displayedComponents: [.date])
                            .datePickerStyle(.graphical).padding().background(KaizenTheme.background)
                            .navigationTitle("Go to date").navigationBarTitleDisplayMode(.inline)
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { sheet = nil } } }
                    }.preferredColorScheme(.dark).tint(.white)
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                NavigationStack {
                    PrivacyPolicyView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showingPrivacyPolicy = false }
                            }
                        }
                }.tint(KaizenTheme.accent)
            }
            .sheet(isPresented: $showingDeleteAccount) {
                DeleteAccountView().environmentObject(authViewModel)
            }
            .confirmationDialog("Delete this task?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
                Button("Delete task", role: .destructive) {
                    if let task = pendingDelete { Task { await model.deleteTask(task) } }
                    pendingDelete = nil
                }
            }
            .modifier(TaskErrorModifier(model: model))
            .alert("Account", isPresented: Binding(get: { authViewModel.errorMessage != nil }, set: { if !$0 { authViewModel.errorMessage = nil } })) {
                Button("OK") { authViewModel.errorMessage = nil }
            } message: { Text(authViewModel.errorMessage ?? "") }
        }.tint(KaizenTheme.accent).preferredColorScheme(.dark)
    }

    private var navigation: some View {
        HStack {
            Button { priorities = true } label: {
                Label("Priorities", systemImage: "checklist").font(.caption)
                    .foregroundStyle(priorities ? .white : KaizenTheme.muted).frame(minHeight: 44)
            }
            Spacer()
            Button { priorities = false } label: {
                Label("Agenda", systemImage: "calendar").font(.caption)
                    .foregroundStyle(!priorities ? .white : KaizenTheme.muted).frame(minHeight: 44)
            }
            Spacer()
            Button { sheet = .quickAdd } label: {
                Image(systemName: "tray.and.arrow.down").frame(width: 44, height: 44)
            }.accessibilityLabel("Quick add to backburner")
            Menu {
                Button("Go to date", systemImage: "calendar") { sheet = .date }
                Button("Jump to today", systemImage: "arrow.uturn.backward") { date = Calendar.current.startOfDay(for: Date()) }
                Button("Backburner", systemImage: "tray") { sheet = .backburner }
                Button("Quick add to backburner", systemImage: "plus") { sheet = .quickAdd }
                Button("Privacy Policy", systemImage: "hand.raised") { showingPrivacyPolicy = true }
                Button("Sign out", systemImage: "rectangle.portrait.and.arrow.right") { authViewModel.logout() }
                Button("Delete account", systemImage: "person.crop.circle.badge.minus", role: .destructive) {
                    showingDeleteAccount = true
                }
            } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.accessibilityLabel("More options")
        }.padding(.horizontal, 24).padding(.vertical, 5).background(KaizenTheme.background)
            .disabled(model.isSaving || model.isLoading)
    }

    @ViewBuilder private var untimedTasks: some View {
        let items = dailyTasks.filter { $0.scheduledStart == nil }
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Anytime").font(.system(size: 19, weight: .medium))
                    Spacer()
                    Text("\(items.count) untimed tasks").font(.caption2).foregroundStyle(KaizenTheme.muted)
                }
                ForEach(items) { task in
                    Button { sheet = .task(task) } label: {
                        HStack(spacing: 11) {
                            Rectangle().fill(task.resolvedCategory.color).frame(width: 2, height: 20)
                            Text(task.title).strikethrough(task.isCompleted).font(.subheadline)
                                .foregroundStyle(task.isCompleted ? KaizenTheme.muted : .white)
                            Spacer()
                            Image(systemName: task.isCompleted ? "checkmark" : "clock").font(.caption).foregroundStyle(KaizenTheme.muted)
                        }.frame(minHeight: 40).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var priorityList: some View {
        VStack(alignment: .leading, spacing: 24) {
            CategoryTabs(selection: $category, completion: categoryCompletion)
            let score = categoryCompletion(category)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(category.rawValue) completion").font(.caption)
                    Spacer()
                    Text(score.total == 0 ? "No tasks yet" : "\(score.completed) of \(score.total) complete")
                        .font(.caption).foregroundStyle(KaizenTheme.muted)
                }
                ProgressView(value: Double(score.completed), total: Double(max(score.total, 1)))
                    .tint(category.color)
            }
            ForEach(TaskTier.allCases) { item in
                TaskTierPanel(tier: item, tasks: model.tasks(category: category, tier: item, on: date),
                              onAdd: { tier = item; sheet = .add },
                              onToggle: { task in Task { await model.toggleCompletion(task) } },
                              onBackburner: { task in Task { await model.moveToBackburner(task) } },
                              onDelete: { pendingDelete = $0 }, onSchedule: { sheet = .task($0) })
            }
        }
        .disabled(model.isSaving || model.isLoading)
    }

    private func categoryCompletion(_ category: TaskCategory) -> (completed: Int, total: Int) {
        let tasks = dailyTasks.filter { $0.resolvedCategory == category }
        return (tasks.filter(\.isCompleted).count, tasks.count)
    }

    private func select(_ entry: AgendaEntry) {
        if let event = entry.event { sheet = .event(event) }
        else if let task = entry.task { sheet = .task(task) }
    }

    private func newEvent() -> CalendarEvent {
        let start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date)!
        return CalendarEvent(title: "", category: category, start: start, end: start.addingTimeInterval(3600))
    }

    private func takeError() -> String? {
        let message = model.errorMessage; model.errorMessage = nil; return message
    }
}

private enum DashboardSheet: Identifiable {
    case add, quickAdd, backburner, review, date, event(CalendarEvent), task(TaskItem)
    var id: String {
        switch self {
        case .add: return "add"
        case .quickAdd: return "quickAdd"
        case .backburner: return "backburner"
        case .review: return "review"
        case .date: return "date"
        case .event(let event): return "event-\(event.id)"
        case .task(let task): return "task-\(task.id ?? task.title)"
        }
    }
}
