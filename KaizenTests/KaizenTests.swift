import Foundation
import Testing
import FirebaseFirestore
@testable import Kaizen

struct KaizenTests {
    @Test func capacityIsScopedToDayCategoryAndTier() {
        let today = Date()
        let tasks = (0..<3).map { index in
            TaskItem(title: "Task \(index)", tier: .a, createdAt: today, isCompleted: index == 0,
                     category: .health, scheduledDay: DayKey.string(today), isBackburner: false)
        }
        #expect(!TaskCapacity.canAdd(to: tasks, category: .health, tier: .a, date: today))
        #expect(TaskCapacity.canAdd(to: tasks, category: .work, tier: .a, date: today))
        #expect(TaskCapacity.canAdd(to: tasks, category: .health, tier: .b, date: today))
        #expect(TaskCapacity.canAdd(to: tasks, category: .health, tier: .a, date: DayKey.tomorrow(from: today)))
        var backburner = tasks
        backburner[0].isBackburner = true
        #expect(TaskCapacity.canAdd(to: backburner, category: .health, tier: .a, date: today))
    }

    @Test func legacyDocumentsKeepTheirTasks() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let task = try Firestore.Decoder().decode(TaskItem.self, from: [
            "title": "Original task", "tier": "A", "createdAt": Timestamp(date: created), "isCompleted": false
        ], in: Firestore.firestore().document("testFixtures/legacy"))
        #expect(task.id == "legacy")
        #expect(task.title == "Original task")
        #expect(task.resolvedCategory == .personal)
        #expect(task.resolvedDay == DayKey.string(created))
        #expect(!task.inBackburner)
    }

    @Test func tomorrowUsesCalendarDayAcrossDaylightSaving() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 29, hour: 0))!
        let tomorrow = DayKey.tomorrow(from: date, calendar: calendar)
        #expect(DayKey.string(tomorrow, calendar: calendar) == "2026-03-30")
        #expect(tomorrow.timeIntervalSince(date) == 23 * 60 * 60)
    }

    @Test func tomorrowCrossesYearBoundary() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 23))!
        #expect(DayKey.string(DayKey.tomorrow(from: date, calendar: calendar), calendar: calendar) == "2027-01-01")
    }

    @Test func scheduledTaskRoundTripKeepsPlanningFields() throws {
        let task = TaskItem(title: "Walk", tier: .b, createdAt: Date(), isCompleted: false,
                            category: .health, scheduledDay: "2026-09-11", isBackburner: false, sourceTaskID: "original")
        let data = try Firestore.Encoder().encode(task)
        let decoded = try Firestore.Decoder().decode(TaskItem.self, from: data, in: Firestore.firestore().document("testFixtures/planned"))
        #expect(decoded.resolvedCategory == .health)
        #expect(decoded.resolvedDay == "2026-09-11")
        #expect(decoded.sourceTaskID == "original")
        #expect(!decoded.inBackburner)
    }

    @Test func feedbackSupportsLowEnergyAndIncludesFocus() {
        let review = DailyReview(day: "2026-09-10", mood: "Drained", wentWell: "Went outside",
                                 improve: "Start earlier", focus: "Finish the proposal", completed: 2, total: 6)
        #expect(review.feedback.contains("2 of 6"))
        #expect(review.feedback.contains("room to recover"))
        #expect(review.feedback.contains("Went outside"))
        #expect(review.feedback.contains("Start earlier"))
        #expect(review.feedback.contains("Finish the proposal"))
    }
}
