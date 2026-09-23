import Foundation
import Combine

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var hasLoaded = false
    @Published var errorMessage: String?
    private let service: any TaskStore

    init(service: any TaskStore = TaskService()) { self.service = service }

    func agenda(on date: Date) -> [AgendaEntry] {
        AgendaEntry.entries(on: date, events: events, tasks: tasks)
    }

    @discardableResult
    func saveEvent(_ event: CalendarEvent) async -> Bool {
        guard !isSaving, !isLoading else { return false }
        if let message = event.validationMessage { errorMessage = message; return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await service.saveEvent(event)
            events.removeAll { $0.id == event.id }
            events.append(event)
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func deleteEvent(_ event: CalendarEvent) async -> Bool {
        guard !isSaving, !isLoading else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await service.deleteEvent(event)
            events.removeAll { $0.id == event.id }
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    var backburner: [TaskItem] {
        tasks.filter { $0.inBackburner }.sorted { $0.createdAt > $1.createdAt }
    }

    func scheduled(on date: Date) -> [TaskItem] {
        tasks.filter { !$0.inBackburner && $0.resolvedDay == DayKey.string(date) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func tasks(category: TaskCategory, tier: TaskTier, on date: Date) -> [TaskItem] {
        scheduled(on: date).filter { $0.resolvedCategory == category && $0.tier == tier }
    }

    func loadTasks() async {
        guard !isLoading, !isSaving else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let loadedTasks = service.fetchTasks()
            async let loadedEvents = service.fetchEvents()
            let result = try await (loadedTasks, loadedEvents)
            tasks = result.0
            events = result.1
            hasLoaded = true
        } catch { errorMessage = error.localizedDescription }
    }

    func addTask(title: String, category: TaskCategory, tier: TaskTier, date: Date, backburner: Bool) async -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { errorMessage = "Please enter a task."; return false }
        guard backburner || TaskCapacity.canAdd(to: tasks, category: category, tier: tier, date: date) else {
            errorMessage = "Each category has room for three tasks per tier."; return false
        }
        let task = TaskItem(title: title, tier: tier, createdAt: Date(), isCompleted: false,
                            category: category, scheduledDay: DayKey.string(date), isBackburner: backburner)
        return await save(task)
    }

    @discardableResult
    func save(_ task: TaskItem) async -> Bool {
        guard !isSaving, !isLoading else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await service.saveTask(task)
            tasks.removeAll { $0.id == saved.id }
            tasks.append(saved)
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func toggleCompletion(_ task: TaskItem) async {
        var updated = task
        updated.isCompleted.toggle()
        await save(updated)
    }

    func moveToBackburner(_ task: TaskItem) async {
        var updated = task
        updated.isBackburner = true
        updated.scheduledStart = nil
        updated.scheduledEnd = nil
        updated.isCompleted = false
        await save(updated)
    }

    func deleteTask(_ task: TaskItem) async {
        guard !isSaving, !isLoading else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await service.deleteTask(task)
            tasks.removeAll { $0.id == task.id }
        } catch { errorMessage = error.localizedDescription }
    }

    func review(for date: Date) async throws -> DailyReview? {
        try await service.fetchReview(day: DayKey.string(date))
    }

    func savePlan(review: DailyReview, plan: [TaskItem], date: Date, sourceIDs: Set<String>, events draftEvents: [CalendarEvent] = []) async -> Bool {
        guard !isSaving, !isLoading else { return false }
        for event in draftEvents {
            if let message = event.validationMessage { errorMessage = message; return false }
        }
        for task in plan {
            guard !task.inBackburner, task.resolvedDay == DayKey.string(date) else {
                errorMessage = "Every planned task must belong to the selected day."; return false
            }
            if let start = task.scheduledStart, let end = task.scheduledEnd {
                if let message = TaskSchedule.validationMessage(start: start, end: end, day: date) {
                    errorMessage = message; return false
                }
            } else if task.scheduledStart != nil || task.scheduledEnd != nil {
                errorMessage = "Please set both a start and end time."; return false
            }
        }
        for category in TaskCategory.allCases {
            for tier in TaskTier.allCases {
                guard plan.filter({ $0.resolvedCategory == category && $0.tier == tier }).count <= 3 else {
                    errorMessage = "Each tier can hold at most three tasks per category."; return false
                }
            }
        }
        isSaving = true
        defer { isSaving = false }
        do {
            let old = scheduled(on: date)
            let saved = try await service.savePlan(review: review, tasks: plan, replacing: old, sourceIDs: sourceIDs, events: draftEvents)
            let removed = Set(old.compactMap(\.id)).union(sourceIDs)
            tasks.removeAll { $0.id.map { removed.contains($0) } ?? false }
            tasks.append(contentsOf: saved)
            let changedIDs = Set(draftEvents.map(\.id))
            events.removeAll { changedIDs.contains($0.id) }
            events.append(contentsOf: draftEvents)
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }
}
