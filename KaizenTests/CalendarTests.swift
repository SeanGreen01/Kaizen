import Foundation
import Testing
@testable import Kaizen

struct CalendarTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }
    private func date(_ day: Int = 10, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    @Test func periodsRespectNoonAndEveningBoundaries() {
        #expect(AgendaPeriod.at(date(10, 11, 59), calendar: calendar) == .morning)
        #expect(AgendaPeriod.at(date(10, 12), calendar: calendar) == .afternoon)
        #expect(AgendaPeriod.at(date(10, 18), calendar: calendar) == .night)
    }

    @Test func overnightEventsAppearOnBothDaysButNotAfterTheirEnd() {
        let event = CalendarEvent(title: "Travel", category: .personal, start: date(10, 23), end: date(11, 2))
        #expect(event.occurs(on: date(10), calendar: calendar))
        #expect(event.occurs(on: date(11), calendar: calendar))
        #expect(!event.occurs(on: date(12), calendar: calendar))
        let row = AgendaEntry.entries(on: date(11), events: [event], tasks: [], calendar: calendar).first
        #expect(row?.start == date(11))
        #expect(row?.end == date(11, 2))
        let midnightEnd = CalendarEvent(title: "Dinner", category: .personal, start: date(10, 22), end: date(11))
        #expect(!midnightEnd.occurs(on: date(11), calendar: calendar))
    }

    @Test func agendaMergesAndSortsTimedTasksWhileLeavingUntimedTasksOut() {
        let event = CalendarEvent(title: "Meeting", category: .work, start: date(10, 10), end: date(10, 11))
        let timed = TaskItem(id: "timed", title: "Walk", tier: .a, createdAt: date(), isCompleted: false,
                             category: .health, scheduledDay: "2026-09-10", scheduledStart: date(10, 8), scheduledEnd: date(10, 9))
        let untimed = TaskItem(id: "untimed", title: "Read", tier: .c, createdAt: date(), isCompleted: false, scheduledDay: "2026-09-10")
        let entries = AgendaEntry.entries(on: date(), events: [event], tasks: [untimed, timed], calendar: calendar)
        #expect(entries.map(\.title) == ["Walk", "Meeting"])
        #expect(AgendaEntry.entries(on: date(11), events: [event], tasks: [untimed, timed], calendar: calendar).isEmpty)
    }

    @Test func taskTimesStayWithinTheirPlannedDay() {
        #expect(TaskSchedule.validationMessage(start: date(10, 23), end: date(11), day: date(), calendar: calendar) == nil)
        #expect(TaskSchedule.validationMessage(start: date(10, 23), end: date(11, 1), day: date(), calendar: calendar) != nil)
        #expect(TaskSchedule.validationMessage(start: date(10, 9), end: date(10, 8), day: date(), calendar: calendar) != nil)
    }

    @Test @MainActor func savingPlanPersistsScheduleAndKeepsExistingAppointments() async throws {
        let store = PreviewTaskStore(seed: false)
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = DayKey.tomorrow(from: today)
        let old = CalendarEvent(title: "Appointment", category: .health, start: tomorrow, end: tomorrow.addingTimeInterval(3600))
        store.events = [old]
        let source = TaskItem(id: "source", title: "Read", tier: .a, createdAt: today, isCompleted: false, category: .personal, isBackburner: true)
        store.tasks = [source]
        let model = TaskViewModel(service: store)
        await model.loadTasks()
        var task = source
        task.isBackburner = false; task.scheduledDay = DayKey.string(tomorrow)
        task.scheduledStart = tomorrow.addingTimeInterval(3600); task.scheduledEnd = tomorrow.addingTimeInterval(7200)
        let newEvent = CalendarEvent(title: "Lunch", category: .personal, start: tomorrow.addingTimeInterval(43200), end: tomorrow.addingTimeInterval(46800))
        let success = await model.savePlan(review: DailyReview(day: DayKey.string(today)), plan: [task], date: tomorrow, sourceIDs: ["source"], events: [newEvent])
        #expect(success)
        #expect(model.events.count == 2)
        #expect(model.backburner.isEmpty)
        #expect(model.scheduled(on: tomorrow).first?.scheduledStart == task.scheduledStart)
        #expect(store.reviews[DayKey.string(today)] != nil)
        await model.loadTasks()
        #expect(model.events.contains { $0.id == old.id })
        #expect(model.agenda(on: tomorrow).count == 3)
    }

    @Test @MainActor func failedPlanSaveDoesNotReplaceExistingState() async {
        let store = PreviewTaskStore(seed: false)
        let tomorrow = DayKey.tomorrow()
        store.tasks = [TaskItem(id: "existing", title: "Keep me", tier: .a, createdAt: Date(), isCompleted: false,
                               scheduledDay: DayKey.string(tomorrow))]
        let model = TaskViewModel(service: store)
        await model.loadTasks()
        store.failWrites = true
        let success = await model.savePlan(review: DailyReview(day: DayKey.string(Date())), plan: [], date: tomorrow, sourceIDs: [])
        #expect(!success)
        #expect(model.tasks.first?.title == "Keep me")
        #expect(model.errorMessage != nil)
        #expect(!model.isSaving)
    }
}
