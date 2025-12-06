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
        // Listen to auth state changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // Sign up with email and password
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        self.currentUser = result.user
        self.isAuthenticated = true
    }
    
    // Sign in with email and password
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
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
}

