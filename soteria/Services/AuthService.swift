//
//  AuthService.swift
//  soteria
//
//  Authentication service using AWS Cognito (replaces Firebase Auth)
//

import Foundation
import Combine

class AuthService: ObservableObject {
    private let cognitoService = CognitoAuthService.shared
    
    @Published var currentUser: CognitoUser? = nil
    @Published var isAuthenticated: Bool = false
    @Published var isCheckingAuth: Bool = true
    
    // Helper properties for compatibility with Firebase-style access
    var currentUserEmail: String? {
        return currentUser?.email
    }
    
    var currentUserId: String? {
        return currentUser?.userId
    }
    
    init() {
        print("🔍 [AuthService] init() started")
        self.isCheckingAuth = true
        self.isAuthenticated = false
        
        // Check auth state asynchronously
        Task {
            await cognitoService.checkAuthState()
            await MainActor.run {
                self.updateAuthState()
                self.isCheckingAuth = false
                print("✅ [AuthService] Auth check completed")
            }
        }
        
        // Listen to Cognito auth state changes
        cognitoService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAuthState()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateAuthState() {
        self.isAuthenticated = cognitoService.isAuthenticated
        if let cognitoUser = cognitoService.currentUser {
            // Wrap CognitoUser in a way that maintains compatibility
            self.currentUser = cognitoUser
        } else {
            self.currentUser = nil
        }
    }
    
    // Sign up with email and password
    func signUp(email: String, password: String) async throws {
        try await cognitoService.signUp(email: email, password: password)
        await MainActor.run {
            self.updateAuthState()
        }
    }
    
    // Sign in with email and password
    func signIn(email: String, password: String) async throws {
        try await cognitoService.signIn(email: email, password: password)
        await MainActor.run {
            self.updateAuthState()
        }
    }
    
    // Sign out
    func signOut() throws {
        cognitoService.signOut()
        updateAuthState()
    }
    
    // Get current ID token string for API calls
    func getIDToken() async throws -> String? {
        return try await cognitoService.getIDToken()
    }
    
    // Get current user ID
    func getUserId() -> String? {
        return cognitoService.getUserId()
    }
    
    // Send password reset email
    func resetPassword(email: String) async throws {
        try await cognitoService.resetPassword(email: email)
    }
}
