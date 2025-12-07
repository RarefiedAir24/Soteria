//
//  AuthService.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import Foundation
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        print("✅ [AuthService] Starting initialization...")
        // Listen to auth state changes
        // Use a delay to ensure Firebase is fully configured
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { 
                print("❌ [AuthService] Self is nil in async block")
                return 
            }
            self.authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.isAuthenticated = user != nil
                    print("✅ [AuthService] Auth state changed - isAuthenticated: \(user != nil)")
                }
            }
            print("✅ [AuthService] Initialized and listening to auth state")
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // Sign up with email and password
    func signUp(email: String, password: String) async throws {
        // Ensure email is trimmed and lowercase for consistency
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email and password cannot be empty"])
        }
        
        let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword)
        self.currentUser = result.user
        self.isAuthenticated = true
    }
    
    // Sign in with email and password
    func signIn(email: String, password: String) async throws {
        // Ensure email is trimmed and lowercase for consistency
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email and password cannot be empty"])
        }
        
        let result = try await Auth.auth().signIn(withEmail: trimmedEmail, password: trimmedPassword)
        self.currentUser = result.user
        self.isAuthenticated = true
    }
    
    // Sign out
    func signOut() throws {
        try Auth.auth().signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // Get current ID token string for API calls
    func getIDToken() async throws -> String? {
        return try await currentUser?.getIDToken()
    }
    
    // Send password reset email
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}

