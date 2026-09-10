//
//  AuthService.swift
//  Kaizen
//
//  Created by Sean Green on 02/09/2026.
//


import FirebaseAuth

final class AuthService {
    
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
}
