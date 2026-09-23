//
//  AuthViewModel.swift
//  Kaizen
//
//  Created by Sean Green on 02/09/2026.
//

import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    
    @Published var currentUser: User? = Auth.auth().currentUser
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService()
    
    func register(
        email: String,
        password: String,
        confirmPassword: String
    ) async {
        
        guard !email.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter a password."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await authService.createUser(
                email: email,
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func login(
        email: String,
        password: String
    ) async {

        guard !email.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            currentUser = try await authService.signIn(
                email: email,
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func logout() {
        do {
            try authService.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount(password: String) async -> Bool {
        guard !password.isEmpty else {
            errorMessage = "Enter your password to delete your account."
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.deleteCurrentUser(password: password)
            currentUser = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
