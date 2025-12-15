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
    @Published var isCheckingAuth: Bool = false  // Start as false to allow immediate UI rendering
    
    // Helper properties for compatibility with Firebase-style access
    var currentUserEmail: String? {
        return currentUser?.email
    }
    
    var currentUserId: String? {
        return currentUser?.userId
    }
    
    init() {
        let initStart = Date()
        MainActorMonitor.shared.logOperation("AuthService.init() started")
        print("🔍 [AuthService] init() started")
        
        // CRITICAL: Check for cached tokens IMMEDIATELY (synchronously, before UI renders)
        // This prevents authenticated users from seeing the sign-in screen
        let beforeUserDefaults = Date()
        let storedIdToken = UserDefaults.standard.string(forKey: "cognito_id_token")
        let storedUserId = UserDefaults.standard.string(forKey: "cognito_user_id")
        let storedEmail = UserDefaults.standard.string(forKey: "cognito_user_email")
        let userDefaultsDuration = Date().timeIntervalSince(beforeUserDefaults)
        if userDefaultsDuration > 0.01 {
            MainActorMonitor.shared.logOperation("AuthService: UserDefaults read (SLOW)", duration: userDefaultsDuration)
            print("⚠️ [AuthService] UserDefaults read took \(String(format: "%.3f", userDefaultsDuration))s")
        }
        
        // If we have tokens, check if they're valid (fast, synchronous check)
        let beforeTokenCheck = Date()
        let hasValidToken = storedIdToken != nil && storedUserId != nil && storedEmail != nil && (storedIdToken.map { !isTokenExpiredSync($0) } ?? false)
        let tokenCheckDuration = Date().timeIntervalSince(beforeTokenCheck)
        if tokenCheckDuration > 0.01 {
            MainActorMonitor.shared.logOperation("AuthService: Token expiration check (SLOW)", duration: tokenCheckDuration)
        }
        
        if hasValidToken, let userId = storedUserId, let email = storedEmail {
            // Token exists and is valid - set authenticated immediately
            // This prevents showing sign-in screen to authenticated users
            self.currentUser = CognitoUser(userId: userId, email: email, username: nil)
            self.isAuthenticated = true
            self.isCheckingAuth = false
            print("✅ [AuthService] Restored session from cache (optimistic)")
        } else {
            // No valid tokens - show sign-in screen
            self.isAuthenticated = false
            self.isCheckingAuth = false
            print("ℹ️ [AuthService] No valid cached tokens")
        }
        
        let initDuration = Date().timeIntervalSince(initStart)
        MainActorMonitor.shared.logOperation("AuthService.init() completed", duration: initDuration)
        if initDuration > 0.1 {
            print("⚠️ [AuthService] Init took \(String(format: "%.3f", initDuration))s (SLOW)")
        }
        
        // Defer Combine subscription setup to avoid blocking init
        // CRITICAL: Use Task.detached instead of Task { @MainActor in } to avoid blocking MainActor
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            
            // Small delay to let UI render first
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Set up Combine subscription - receive on main thread but don't block MainActor
            await MainActor.run {
                self.cognitoService.$isAuthenticated
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        self?.updateAuthState()
                    }
                    .store(in: &self.cancellables)
            }
        }
        
        // Verify/refresh tokens in background (non-blocking)
        // CRITICAL: Set isCheckingAuth = true to keep splash screen visible during verification
        // This prevents showing sign-in screen while auth is being verified
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            // Set checking state immediately to keep splash screen visible
            await MainActor.run {
                // Only set isCheckingAuth if we have cached tokens (optimistic auth)
                // This keeps splash screen visible while we verify
                if self.isAuthenticated {
                    self.isCheckingAuth = true
                    print("🔄 [AuthService] Starting background auth verification (keeping splash visible)")
                }
            }
            
            // CRITICAL: Wait before checking to ensure UI is interactive
            // But don't wait too long - user wants to see home page quickly
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds - reduced from 30s
            
            // Run auth check off main thread (verifies token, refreshes if expired)
            // Use Task with timeout to prevent hanging
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await self.cognitoService.checkAuthState()
                    }
                    
                    group.addTask {
                        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 second timeout
                        throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Auth check timed out"])
                    }
                    
                    try await group.next()
                    group.cancelAll()
                }
                
                // Auth verified successfully
                await MainActor.run {
                    self.updateAuthState()
                    self.isCheckingAuth = false
                    print("✅ [AuthService] Background auth verification completed - user authenticated")
                }
            } catch {
                // Auth verification failed - only then show sign-in screen
                print("⚠️ [AuthService] Auth check failed: \(error.localizedDescription)")
                await MainActor.run {
                    // Only set authenticated to false if verification actually failed
                    // Don't clear if we still have valid cached tokens
                    self.isCheckingAuth = false
                    // Keep isAuthenticated as-is if we have cached tokens (optimistic)
                    // Only clear if verification explicitly failed
                    print("⚠️ [AuthService] Auth verification failed - user may need to sign in")
                }
            }
        }
    }
    
    // Fast synchronous token expiration check (for immediate auth state)
    // This avoids async/await overhead during init
    private func isTokenExpiredSync(_ token: String) -> Bool {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3, parts[1].count > 0 else { return true }
        
        guard let payloadData = Data(base64Encoded: parts[1], options: .ignoreUnknownCharacters),
              payloadData.count > 0 else {
            return true
        }
        
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return true
        }
        
        let expirationDate = Date(timeIntervalSince1970: exp)
        return expirationDate <= Date()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateAuthState() {
        // CRITICAL: Don't clear optimistic auth state during background verification
        // If we optimistically set isAuthenticated = true, keep it true until verification completes
        // Only update if we're not checking auth (to preserve optimistic state)
        if !isCheckingAuth {
            self.isAuthenticated = cognitoService.isAuthenticated
        } else {
            // During verification, only update if cognitoService confirms auth (don't clear optimistic state)
            if cognitoService.isAuthenticated {
                self.isAuthenticated = true
            }
            // If cognitoService.isAuthenticated is false, keep optimistic state (don't clear)
        }
        
        if let cognitoUser = cognitoService.currentUser {
            // Wrap CognitoUser in a way that maintains compatibility
            self.currentUser = cognitoUser
        } else {
            // Only clear currentUser if we're not checking auth (preserve during verification)
            if !isCheckingAuth {
                self.currentUser = nil
            }
        }
    }
    
    // Sign up with email and password
    @MainActor
    func signUp(email: String, password: String) async throws {
        try await cognitoService.signUp(email: email, password: password)
        self.updateAuthState()
    }
    
    // Sign in with email and password
    @MainActor
    func signIn(email: String, password: String) async throws {
        try await cognitoService.signIn(email: email, password: password)
        self.updateAuthState()
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
    
    // Confirm signup with verification code
    @MainActor
    func confirmSignUp(email: String, confirmationCode: String) async throws {
        try await cognitoService.confirmSignUp(email: email, confirmationCode: confirmationCode)
    }
}
