import Foundation
import FirebaseFirestore

enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case health = "Health", work = "Work", personal = "Personal"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .health: return "heart"
        case .work: return "briefcase"
        case .personal: return "sparkles"
        }
    }
}

enum TaskTier: String, Codable, CaseIterable, Identifiable {
    case a = "A", b = "B", c = "C"
    var id: String { rawValue }
    var subtitle: String {
        switch self {
        case .a: return "Your essentials"
        case .b: return "Make progress"
        case .c: return "A little extra"
        }
    }
}

struct TaskItem: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var tier: TaskTier
    let createdAt: Date
    var isCompleted: Bool
    // Optional fields keep existing Firebase documents readable.
    var category: TaskCategory? = nil
    var scheduledDay: String? = nil
    var isBackburner: Bool? = nil
    var sourceTaskID: String? = nil
    var scheduledStart: Date? = nil
    var scheduledEnd: Date? = nil

    var resolvedCategory: TaskCategory { category ?? .personal }
    var resolvedDay: String { scheduledDay ?? DayKey.string(createdAt) }
    var inBackburner: Bool { isBackburner == true }
}

enum DayKey {
    static func string(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
    static func tomorrow(from date: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
    }
}

struct DailyReview: Codable {
    var day: String
    var mood = "Okay"
    var wentWell = ""
    var improve = ""
    var focus = ""
    var completed = 0
    var total = 0

    var feedback: String {
        var lines = [total == 0 ? "You made space to reflect today. That is progress too." : "You completed \(completed) of \(total) tasks today. Take a moment to recognise what moved forward."]
        if !wentWell.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Build on what worked: \(wentWell)")
        }
        if mood == "Low" || mood == "Drained" {
            lines.append("Give yourself room to recover. Keep tomorrow’s essentials manageable and leave space for rest.")
        } else if completed < total {
            lines.append("Choose the unfinished tasks that still matter; the rest can wait in your backburner.")
        }
        if !improve.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Try one small change tomorrow: \(improve)")
        }
        if !focus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Make room in Tier A for your focus: \(focus)")
        }
        return lines.joined(separator: "\n\n")
    }
}

/// Shared validation for each date/category/tier slot.
enum TaskCapacity {
    static func canAdd(to tasks: [TaskItem], category: TaskCategory, tier: TaskTier, date: Date) -> Bool {
        tasks.filter {
            !$0.inBackburner && $0.resolvedDay == DayKey.string(date) &&
            $0.resolvedCategory == category && $0.tier == tier
        }.count < 3
    }
}
