import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol TaskStore {
    func fetchTasks() async throws -> [TaskItem]
    func saveTask(_ task: TaskItem) async throws -> TaskItem
    func deleteTask(_ task: TaskItem) async throws
    func fetchEvents() async throws -> [CalendarEvent]
    func saveEvent(_ event: CalendarEvent) async throws
    func deleteEvent(_ event: CalendarEvent) async throws
    func fetchReview(day: String) async throws -> DailyReview?
    func savePlan(review: DailyReview, tasks: [TaskItem], replacing: [TaskItem], sourceIDs: Set<String>, events: [CalendarEvent]) async throws -> [TaskItem]
}

final class TaskService: TaskStore {
    private let db = Firestore.firestore()

    private func userDocument() throws -> DocumentReference {
        guard let uid = Auth.auth().currentUser?.uid else { throw TaskServiceError.notAuthenticated }
        return db.collection("users").document(uid)
    }

    func fetchTasks() async throws -> [TaskItem] {
        let snapshot = try await userDocument().collection("tasks").getDocuments()
        return try snapshot.documents.map { try $0.data(as: TaskItem.self) }
    }

    func saveTask(_ task: TaskItem) async throws -> TaskItem {
        let collection = try userDocument().collection("tasks")
        let document = task.id.map { collection.document($0) } ?? collection.document()
        try await document.setData(Firestore.Encoder().encode(task))
        var saved = task
        saved.id = document.documentID
        return saved
    }

    func deleteTask(_ task: TaskItem) async throws {
        guard let id = task.id else { throw TaskServiceError.missingTaskId }
        try await userDocument().collection("tasks").document(id).delete()
    }

    func fetchEvents() async throws -> [CalendarEvent] {
        let snapshot = try await userDocument().collection("events").getDocuments()
        return try snapshot.documents.map { document in
            var event = try document.data(as: CalendarEvent.self)
            event.id = document.documentID
            return event
        }
    }

    func saveEvent(_ event: CalendarEvent) async throws {
        try await userDocument().collection("events").document(event.id)
            .setData(Firestore.Encoder().encode(event))
    }

    func deleteEvent(_ event: CalendarEvent) async throws {
        try await userDocument().collection("events").document(event.id).delete()
    }

    func fetchReview(day: String) async throws -> DailyReview? {
        let snapshot = try await userDocument().collection("reviews").document(day).getDocument()
        return snapshot.exists ? try snapshot.data(as: DailyReview.self) : nil
    }

    // The review and tomorrow's plan are committed together, including backburner promotions.
    func savePlan(review: DailyReview, tasks: [TaskItem], replacing: [TaskItem], sourceIDs: Set<String>, events: [CalendarEvent]) async throws -> [TaskItem] {
        let user = try userDocument()
        let collection = user.collection("tasks")
        let batch = db.batch()
        for id in Set(replacing.compactMap(\.id)).union(sourceIDs) {
            batch.deleteDocument(collection.document(id))
        }
        var saved: [TaskItem] = []
        for task in tasks {
            let document = collection.document()
            try batch.setData(from: task, forDocument: document)
            var item = task
            item.id = document.documentID
            saved.append(item)
        }
        for event in events {
            try batch.setData(from: event, forDocument: user.collection("events").document(event.id))
        }
        try batch.setData(from: review, forDocument: user.collection("reviews").document(review.day))
        try await batch.commit()
        return saved
    }
}

enum TaskServiceError: LocalizedError {
    case notAuthenticated, missingTaskId
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in to manage your tasks."
        case .missingTaskId: return "This task could not be found. Refresh and try again."
        }
    }
}
