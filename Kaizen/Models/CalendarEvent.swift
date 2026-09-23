import Foundation
import FirebaseFirestore

struct CalendarEvent: Identifiable, Codable {
    // Client-generated IDs keep draft events stable through editing and a single batch save.
    var id: String = UUID().uuidString
    var title: String
    var category: TaskCategory
    var start: Date
    var end: Date
    var isAllDay = false
    var notes = ""

    var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Please enter an event title." }
        if end <= start { return "The end must be after the start." }
        return nil
    }

    func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = DayKey.tomorrow(from: date, calendar: calendar)
        return start < dayEnd && end > dayStart
    }
}

enum AgendaPeriod: String, CaseIterable, Identifiable {
    case morning = "Morning", afternoon = "Afternoon", night = "Night"
    var id: String { rawValue }
    var rangeLabel: String {
        switch self {
        case .morning: return "12am to 12pm"
        case .afternoon: return "12pm to 6pm"
        case .night: return "6pm to 12am"
        }
    }
    static func at(_ date: Date, calendar: Calendar = .current) -> Self {
        switch calendar.component(.hour, from: date) {
        case 0..<12: return .morning
        case 12..<18: return .afternoon
        default: return .night
        }
    }
}

struct AgendaEntry: Identifiable {
    var id: String
    var title: String
    var category: TaskCategory
    var start: Date
    var end: Date
    var allDay: Bool
    var completed: Bool = false
    var event: CalendarEvent?
    var task: TaskItem?

    static func entries(on date: Date, events: [CalendarEvent], tasks: [TaskItem], calendar: Calendar = .current) -> [Self] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = DayKey.tomorrow(from: date, calendar: calendar)
        let eventRows = events.filter { $0.occurs(on: date, calendar: calendar) }.map { event in
            Self(id: "event-\(event.id)", title: event.title, category: event.category,
                 start: max(event.start, dayStart), end: min(event.end, dayEnd), allDay: event.isAllDay, event: event)
        }
        let taskRows: [Self] = tasks.compactMap { task in
            guard !task.inBackburner, task.resolvedDay == DayKey.string(date, calendar: calendar),
                  let start = task.scheduledStart, let end = task.scheduledEnd else { return nil }
            return Self(id: "task-\(task.id ?? task.sourceTaskID ?? task.title)", title: task.title,
                        category: task.resolvedCategory, start: start, end: end, allDay: false,
                        completed: task.isCompleted, task: task)
        }
        return (eventRows + taskRows).sorted {
            if $0.start != $1.start { return $0.start < $1.start }
            return $0.id < $1.id
        }
    }

    func overlaps(_ other: Self) -> Bool {
        !allDay && !other.allDay && id != other.id && start < other.end && end > other.start
    }
}

enum TaskSchedule {
    static func validationMessage(start: Date, end: Date, day: Date, calendar: Calendar = .current) -> String? {
        guard end > start else { return "The end must be after the start." }
        guard start >= calendar.startOfDay(for: day), start < DayKey.tomorrow(from: day, calendar: calendar),
              end <= DayKey.tomorrow(from: day, calendar: calendar) else {
            return "Keep this task within its planned day. Use a calendar event for overnight plans."
        }
        return nil
    }
}
