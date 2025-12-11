//
//  AuthService.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isCheckingAuth: Bool = true // Track if we're still checking auth state
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        print("✅ [AuthService] Starting initialization...")
        
        // Always start with checking state
        self.isCheckingAuth = true
        
        // Check if Firebase is configured before using Auth
        // AuthService is initialized before SoteriaApp.init() runs, so Firebase might not be ready
        guard FirebaseApp.app() != nil else {
            print("⚠️ [AuthService] Firebase not configured yet - deferring auth check")
            self.isAuthenticated = false
            // Check again after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.checkAuthState()
            }
            return
        }
        
        // Firebase is configured - check auth state immediately
        checkAuthState()
    }
    
    private func checkAuthState() {
        // Check auth state immediately (synchronously if possible)
        // Firebase Auth.currentUser is available immediately after FirebaseApp.configure()
        guard FirebaseApp.app() != nil else {
            print("⚠️ [AuthService] Firebase still not configured in checkAuthState - will retry")
            // Retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.checkAuthState()
            }
            return
        }
        
        if let user = Auth.auth().currentUser {
            print("✅ [AuthService] Found existing user: \(user.email ?? "no email")")
            self.currentUser = user
            self.isAuthenticated = true
            // Set checking to false after a brief delay to allow splash screen to render
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isCheckingAuth = false
                print("✅ [AuthService] isCheckingAuth set to false (user found)")
            }
        } else {
            print("📱 [AuthService] No current user found")
            self.isAuthenticated = false
            // Set checking to false after a brief delay to allow splash screen to render
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isCheckingAuth = false
                print("✅ [AuthService] isCheckingAuth set to false (no user)")
            }
        }
        
        // Set up listener for auth state changes (async, but doesn't block)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { 
                print("❌ [AuthService] Self is nil in async block")
                return 
            }
            // Only set up listener if Firebase is configured
            guard FirebaseApp.app() != nil else {
                print("⚠️ [AuthService] Firebase not configured - skipping auth listener")
                return
            }
            self.authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.currentUser = user
                    self.isAuthenticated = user != nil
                    // Don't set isCheckingAuth to false here if we already set it
                    // The initial check should have already set it
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

