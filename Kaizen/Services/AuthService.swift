//
//  AuthService.swift
//  Kaizen
//
//  Created by Sean Green on 02/09/2026.
//


import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    private let db = Firestore.firestore()
    
    func createUser(
        email: String,
        password: String
    ) async throws -> User {
        
        let result = try await Auth.auth().createUser(
            withEmail: email,
            password: password
        )
        
        return result.user
    }
    
    func signIn(
        email: String,
        password: String
    ) async throws -> User {
        
        let result = try await Auth.auth().signIn(
            withEmail: email,
            password: password
        )
        
        return result.user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func deleteCurrentUser(password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }
        guard let email = user.email, !email.isEmpty else {
            throw AuthServiceError.emailCredentialUnavailable
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)

        // Remove the user-owned collections before deleting the Auth record.
        // Firestore rules still require the authenticated UID while this runs.
        let userDocument = db.collection("users").document(user.uid)
        for collectionName in ["tasks", "events", "reviews"] {
            let snapshot = try await userDocument.collection(collectionName).getDocuments()
            for chunkStart in stride(from: 0, to: snapshot.documents.count, by: 450) {
                let batch = db.batch()
                let chunkEnd = min(chunkStart + 450, snapshot.documents.count)
                for document in snapshot.documents[chunkStart..<chunkEnd] {
                    batch.deleteDocument(document.reference)
                }
                try await batch.commit()
            }
        }
        try await userDocument.delete()
        try await user.delete()
    }
}

enum AuthServiceError: LocalizedError {
    case notAuthenticated, emailCredentialUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "No signed-in account was found."
        case .emailCredentialUnavailable: return "This account cannot be reauthenticated with an email password."
        }
    }
}
