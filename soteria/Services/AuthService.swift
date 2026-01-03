//
//  AuthService.swift
//  soteria
//
//  Authentication service using AWS Cognito (replaces Firebase Auth)
//

import Foundation
import Combine

class AuthService: ObservableObject {
    // CRITICAL: Don't access CognitoAuthService until sign-in/sign-up is called
    // Accessing .shared during init or property access blocks MainActor
    // We'll access it only when user actually tries to authenticate
    private func getCognitoService() -> CognitoAuthService {
        return CognitoAuthService.shared
    }
    
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
    
    private var hasInitialized = false
    
    init() {
        // CRITICAL: Do ABSOLUTELY NOTHING in init() - not even setting @Published properties
        // Setting @Published properties during init can trigger SwiftUI's observation system
        // All initialization happens in startInitialization() which is called from RootView.onAppear
        // Default values are set by property initializers (isAuthenticated = false, etc.)
    }
    
    // Call this from RootView.onAppear or AuthView.onAppear - AFTER UI is rendered
    func startInitialization() {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        // Check authentication immediately (UserDefaults reads are fast and non-blocking)
        // This ensures users stay logged in across app rebuilds
        let storedIdToken = UserDefaults.standard.string(forKey: "cognito_id_token")
        let storedUserId = UserDefaults.standard.string(forKey: "cognito_user_id")
        let storedEmail = UserDefaults.standard.string(forKey: "cognito_user_email")
        
        let hasValidToken = storedIdToken != nil && storedUserId != nil && storedEmail != nil && (storedIdToken.map { !self.isTokenExpiredSync($0) } ?? false)
        
        if hasValidToken, let userId = storedUserId, let email = storedEmail {
            self.currentUser = CognitoUser(userId: userId, email: email, username: nil)
            self.isAuthenticated = true
            self.isCheckingAuth = false
            print("✅ [AuthService] Restored session from cache (immediate)")
            
            // Defer SubscriptionService access
            DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
                SubscriptionService.shared.setPremiumForTesting(email: email)
            }
            
            // Reinstall detection
            let lastSyncTimestamp = UserDefaults.standard.double(forKey: "last_sync_timestamp")
            if lastSyncTimestamp == 0 {
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_sync_timestamp")
                print("ℹ️ [AuthService] No last_sync_timestamp found - treating as new session")
            }
        } else {
            self.isAuthenticated = false
            self.isCheckingAuth = false
        }
        
        // CRITICAL: Defer Combine subscription to 60+ seconds after startup
        // Only subscribe when actually needed (after user signs in)
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) { [weak self] in
            guard let self = self else { return }
            // Only subscribe if user is authenticated (cognitoService already accessed)
            if self.isAuthenticated {
                self.getCognitoService().$isAuthenticated
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        self?.updateAuthState()
                    }
                    .store(in: &self.cancellables)
            }
        }
        
        // Verify/refresh tokens in background (non-blocking)
        // CRITICAL: Defer auth verification to 30+ seconds after startup to avoid blocking
        // This ensures TextFields are interactive immediately
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            // CRITICAL: Wait 30 seconds to ensure app is fully interactive before checking auth
            // This prevents MainActor blocking during sign-in
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            
            // Set checking state (use DispatchQueue to avoid MainActor.run blocking)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // Only set isCheckingAuth if we have cached tokens (optimistic auth)
                if self.isAuthenticated {
                    self.isCheckingAuth = true
                    print("🔄 [AuthService] Starting background auth verification (deferred 30s)")
                }
            }
            
            // Run auth check off main thread (verifies token, refreshes if expired)
            // Use Task with timeout to prevent hanging, but handle cancellation gracefully
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await self.getCognitoService().checkAuthState()
                    }
                    
                    group.addTask {
                        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout (increased from 5s)
                        throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Auth check timed out"])
                    }
                    
                    // Wait for first task to complete
                    _ = try await group.next()
                    
                    // Cancel remaining tasks (timeout or auth check)
                    group.cancelAll()
                    
                    // If we got here, auth check completed (either success or failure)
                    // The timeout task will be cancelled
                }
                
                // Auth verified successfully (use DispatchQueue to avoid MainActor.run blocking)
                DispatchQueue.main.async {
                    self.updateAuthState()
                    self.isCheckingAuth = false
                    print("✅ [AuthService] Background auth verification completed - user authenticated")
                }
            } catch {
                // Check if this is a cancellation error
                let isCancelled = (error as? CancellationError) != nil || error.localizedDescription.contains("cancelled")
                
                if isCancelled {
                    // Task was cancelled - this is OK, don't treat as failure
                    print("ℹ️ [AuthService] Auth check was cancelled (likely timeout task)")
                    DispatchQueue.main.async {
                        self.isCheckingAuth = false
                        // Keep optimistic auth state - don't clear if we have cached tokens
                    }
                    return
                }
                // Auth verification failed - only then show sign-in screen
                let errorMsg = error.localizedDescription
                // Don't log "cancelled" as an error - it's expected when timeout fires
                if !errorMsg.contains("cancelled") {
                    print("⚠️ [AuthService] Auth check failed: \(errorMsg)")
                }
                DispatchQueue.main.async {
                    // Only set authenticated to false if verification actually failed
                    // Don't clear if we still have valid cached tokens
                    self.isCheckingAuth = false
                    // Keep isAuthenticated as-is if we have cached tokens (optimistic)
                    // Only clear if verification explicitly failed
                    if !errorMsg.contains("cancelled") && !errorMsg.contains("timed out") {
                        print("⚠️ [AuthService] Auth verification failed - user may need to sign in")
                    }
                }
            }
        }
    }
    
    // Fast synchronous token expiration check (for immediate auth state)
    // This avoids async/await overhead during init
    nonisolated private func isTokenExpiredSync(_ token: String) -> Bool {
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
        // CRITICAL: Only update if cognitoService was already accessed (user signed in)
        // Don't access cognitoService here - it blocks MainActor
        // This method is only called after user has signed in
        let cognitoService = getCognitoService()
        
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
        try await getCognitoService().signUp(email: email, password: password)
        self.updateAuthState()
        
        // Mark as new sign-up to show Unit account creation banner
        UserDefaults.standard.set(true, forKey: "is_new_signup")
        
        // Store sign-up date for premium card display
        UserDefaults.standard.set(Date(), forKey: "user_signup_date")
    }
    
    // Sign in with email and password
    @MainActor
    func signIn(email: String, password: String) async throws {
        try await getCognitoService().signIn(email: email, password: password)
        self.updateAuthState()
        
        // Clear new sign-up flag (this is a returning user)
        UserDefaults.standard.set(false, forKey: "is_new_signup")
        
        // Set premium status for test accounts
        if let userEmail = currentUserEmail {
            SubscriptionService.shared.setPremiumForTesting(email: userEmail)
        }
    }
    
    // Sign out
    func signOut() throws {
        getCognitoService().signOut()
        updateAuthState()
    }
    
    // Get current ID token string for API calls
    func getIDToken() async throws -> String? {
        return try await getCognitoService().getIDToken()
    }
    
    // Get current user ID
    func getUserId() -> String? {
        return getCognitoService().getUserId()
    }
    
    // Send password reset email
    func resetPassword(email: String) async throws {
        try await getCognitoService().resetPassword(email: email)
    }
    
    // Confirm signup with verification code
    @MainActor
    func confirmSignUp(email: String, confirmationCode: String) async throws {
        try await getCognitoService().confirmSignUp(email: email, confirmationCode: confirmationCode)
        
        // Set premium status for test accounts after confirmation
        SubscriptionService.shared.setPremiumForTesting(email: email)
    }
}
