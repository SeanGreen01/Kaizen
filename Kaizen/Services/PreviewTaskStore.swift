#if DEBUG
import Foundation

/// Local fixtures for previews and UI tests. Never used by a release build or a signed-in session.
final class PreviewTaskStore: TaskStore {
    var tasks: [TaskItem] = []
    var events: [CalendarEvent] = []
    var reviews: [String: DailyReview] = [:]
    var failWrites = false
    enum Failure: Error { case simulated }

    init(seed: Bool = true) {
        guard seed else { return }
        let today = Calendar.current.startOfDay(for: Date())
        func time(_ hour: Int, _ minute: Int = 0, on day: Date) -> Date {
            Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
        }
        events = [
            CalendarEvent(title: "Morning stretch", category: .health, start: time(7, on: today), end: time(7, 30, on: today)),
            CalendarEvent(title: "Coffee & a little reading", category: .personal, start: time(8, on: today), end: time(8, 30, on: today)),
            CalendarEvent(title: "Team catch-up", category: .work, start: time(9, on: today), end: time(9, 30, on: today)),
            CalendarEvent(title: "Focus time", category: .work, start: time(10, on: today), end: time(11, 30, on: today)),
            CalendarEvent(title: "Lunch with Alex", category: .personal, start: time(12, 30, on: today), end: time(13, 30, on: today)),
            CalendarEvent(title: "Project review", category: .work, start: time(14, on: today), end: time(15, on: today)),
            CalendarEvent(title: "A walk outside", category: .health, start: time(16, 30, on: today), end: time(17, on: today)),
            CalendarEvent(title: "Dinner at home", category: .personal, start: time(19, on: today), end: time(20, on: today)),
            CalendarEvent(title: "Wind down", category: .health, start: time(21, on: today), end: time(21, 30, on: today)),
            CalendarEvent(title: "Design review", category: .work, start: time(10, on: DayKey.tomorrow(from: today)), end: time(11, on: DayKey.tomorrow(from: today)))
        ]
        tasks = [TaskItem(id: "walk", title: "Morning walk", tier: .a, createdAt: today, isCompleted: false,
                          category: .health, scheduledDay: DayKey.string(today), isBackburner: true)]
    }
    func fetchTasks() async throws -> [TaskItem] { tasks }
    func fetchEvents() async throws -> [CalendarEvent] { events }
    func fetchReview(day: String) async throws -> DailyReview? { reviews[day] }
    func saveTask(_ task: TaskItem) async throws -> TaskItem {
        if failWrites { throw Failure.simulated }
        var saved = task; saved.id = task.id ?? UUID().uuidString
        tasks.removeAll { $0.id == saved.id }; tasks.append(saved)
        return saved
    }
    func deleteTask(_ task: TaskItem) async throws {
        if failWrites { throw Failure.simulated }
        tasks.removeAll { $0.id == task.id }
    }
    func saveEvent(_ event: CalendarEvent) async throws {
        if failWrites { throw Failure.simulated }
        events.removeAll { $0.id == event.id }; events.append(event)
    }
    func deleteEvent(_ event: CalendarEvent) async throws {
        if failWrites { throw Failure.simulated }
        events.removeAll { $0.id == event.id }
    }
    func savePlan(review: DailyReview, tasks plan: [TaskItem], replacing: [TaskItem], sourceIDs: Set<String>, events changes: [CalendarEvent]) async throws -> [TaskItem] {
        if failWrites { throw Failure.simulated }
        let deleted = Set(replacing.compactMap(\.id)).union(sourceIDs)
        tasks.removeAll { $0.id.map { deleted.contains($0) } ?? false }
        let saved = plan.map { task in var task = task; task.id = UUID().uuidString; return task }
        tasks.append(contentsOf: saved)
        for event in changes { events.removeAll { $0.id == event.id }; events.append(event) }
        reviews[review.day] = review
        return saved
    }
}
#endif
