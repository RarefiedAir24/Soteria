//
//  CognitoAuthService.swift
//  soteria
//
//  AWS Cognito authentication service to replace Firebase Auth
//

import Foundation
import Combine

// Simple Cognito user model
struct CognitoUser {
    let userId: String
    let email: String?
    let username: String?
}

class CognitoAuthService: ObservableObject {
    static let shared = CognitoAuthService()
    
    // Configuration - Update these after running create-cognito-user-pool.sh
    // The baseURL should match your API Gateway URL
    private let baseURL: String = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/auth"
    
    @Published var currentUser: CognitoUser?
    @Published var isAuthenticated: Bool = false
    @Published var accessToken: String?
    @Published var idToken: String?
    @Published var refreshToken: String?
    
    private init() {
        print("✅ [CognitoAuthService] Initialized")
        print("📝 [CognitoAuthService] Base URL: \(baseURL)")
        print("📝 [CognitoAuthService] Make sure API Gateway endpoints are configured:")
        print("   - POST /soteria/auth/signup")
        print("   - POST /soteria/auth/signin")
        print("   - POST /soteria/auth/refresh")
        print("   - POST /soteria/auth/reset-password")
    }
    
    // MARK: - Authentication Methods
    
    /// Sign up a new user
    func signUp(email: String, password: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            throw NSError(domain: "CognitoAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email and password cannot be empty"])
        }
        
        guard trimmedPassword.count >= 8 else {
            throw NSError(domain: "CognitoAuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 8 characters"])
        }
        
        let url = URL(string: "\(baseURL)/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        let requestBody: [String: Any] = [
            "email": trimmedEmail,
            "password": trimmedPassword
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "CognitoAuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "CognitoAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success else {
            throw NSError(domain: "CognitoAuthService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Sign up failed"])
        }
        
        // Check if email confirmation is required
        if let requiresConfirmation = json["requiresConfirmation"] as? Bool, requiresConfirmation {
            let message = json["message"] as? String ?? "Please check your email for confirmation code"
            print("✅ [CognitoAuthService] User created, email confirmation required")
            // Don't sign in yet - user needs to confirm email first
            throw NSError(domain: "CognitoAuthService", code: -5, userInfo: [
                NSLocalizedDescriptionKey: message,
                "requiresConfirmation": true
            ])
        }
        
        // If tokens are returned, store them (user was auto-confirmed)
        if let tokens = json["tokens"] as? [String: Any] {
            await MainActor.run {
                self.accessToken = tokens["accessToken"] as? String
                self.idToken = tokens["idToken"] as? String
                self.refreshToken = tokens["refreshToken"] as? String
                
                if let userId = tokens["userId"] as? String {
                    self.currentUser = CognitoUser(userId: userId, email: trimmedEmail, username: nil)
                    self.isAuthenticated = true
                    self.saveTokens()
                }
            }
            print("✅ [CognitoAuthService] User signed up and signed in successfully")
        } else {
            throw NSError(domain: "CognitoAuthService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Sign up completed but no tokens received"])
        }
    }
    
    /// Confirm user signup with verification code
    func confirmSignUp(email: String, confirmationCode: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedCode = confirmationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedCode.isEmpty else {
            throw NSError(domain: "CognitoAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email and confirmation code cannot be empty"])
        }
        
        let url = URL(string: "\(baseURL)/confirm")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        let requestBody: [String: Any] = [
            "email": trimmedEmail,
            "confirmationCode": trimmedCode
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "CognitoAuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "CognitoAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success else {
            throw NSError(domain: "CognitoAuthService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Confirmation failed"])
        }
        
        print("✅ [CognitoAuthService] Email confirmed successfully")
    }
    
    /// Sign in an existing user
    func signIn(email: String, password: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            throw NSError(domain: "CognitoAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email and password cannot be empty"])
        }
        
        let url = URL(string: "\(baseURL)/signin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        let requestBody: [String: Any] = [
            "email": trimmedEmail,
            "password": trimmedPassword
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "CognitoAuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            
            // Check for specific error types
            if errorMessage.contains("confirm your email") || errorMessage.contains("UserNotConfirmedException") {
                throw NSError(domain: "CognitoAuthService", code: -5, userInfo: [
                    NSLocalizedDescriptionKey: errorMessage,
                    "requiresConfirmation": true
                ])
            }
            
            throw NSError(domain: "CognitoAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let tokens = json["tokens"] as? [String: Any] else {
            throw NSError(domain: "CognitoAuthService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Sign in failed"])
        }
        
        await MainActor.run {
            self.accessToken = tokens["accessToken"] as? String
            self.idToken = tokens["idToken"] as? String
            self.refreshToken = tokens["refreshToken"] as? String
            
            if let userId = tokens["userId"] as? String, let email = tokens["email"] as? String {
                self.currentUser = CognitoUser(userId: userId, email: email, username: nil)
                self.isAuthenticated = true
                self.saveTokens()
            }
        }
        
        print("✅ [CognitoAuthService] User signed in successfully")
    }
    
    /// Sign out the current user
    func signOut() {
        Task { @MainActor in
            self.currentUser = nil
            self.isAuthenticated = false
            self.accessToken = nil
            self.idToken = nil
            self.refreshToken = nil
            self.clearTokens()
            print("✅ [CognitoAuthService] User signed out")
        }
    }
    
    /// Get ID token for API authentication
    func getIDToken() async throws -> String? {
        // Check if we have a valid token
        if let idToken = self.idToken, !isTokenExpired(idToken) {
            return idToken
        }
        
        // Try to refresh token
        if let refreshToken = self.refreshToken {
            try await refreshAccessToken(refreshToken: refreshToken)
            return self.idToken
        }
        
        return nil
    }
    
    /// Get user ID
    func getUserId() -> String? {
        return currentUser?.userId
    }
    
    /// Check authentication state on app launch
    /// Runs off main thread to avoid blocking UI
    func checkAuthState() async {
        // Read from UserDefaults off main thread (faster)
        let storedIdToken = UserDefaults.standard.string(forKey: "cognito_id_token")
        let storedUserId = UserDefaults.standard.string(forKey: "cognito_user_id")
        let storedEmail = UserDefaults.standard.string(forKey: "cognito_user_email")
        let storedRefreshToken = UserDefaults.standard.string(forKey: "cognito_refresh_token")
        
        // Try to restore session from stored tokens
        if let idToken = storedIdToken,
           let userId = storedUserId,
           let email = storedEmail {
            
            // Check if token is still valid (runs off main thread)
            if !isTokenExpired(idToken) {
                await MainActor.run {
                    self.idToken = idToken
                    self.currentUser = CognitoUser(userId: userId, email: email, username: nil)
                    self.isAuthenticated = true
                    print("✅ [CognitoAuthService] Restored session from stored tokens")
                }
                return
            } else {
                // Token expired, try to refresh (network call happens off main thread)
                if let refreshToken = storedRefreshToken {
                    do {
                        try await refreshAccessToken(refreshToken: refreshToken)
                        print("✅ [CognitoAuthService] Refreshed expired token")
                    } catch {
                        print("⚠️ [CognitoAuthService] Failed to refresh token: \(error.localizedDescription)")
                        await MainActor.run {
                            self.isAuthenticated = false
                            self.currentUser = nil
                        }
                    }
                } else {
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.currentUser = nil
                    }
                }
            }
        } else {
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        }
    }
    
    /// Refresh access token using refresh token
    private func refreshAccessToken(refreshToken: String) async throws {
        let url = URL(string: "\(baseURL)/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3.0 // Reduced from 10s to 3s for faster failure
        
        let requestBody: [String: Any] = [
            "refreshToken": refreshToken
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "CognitoAuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "CognitoAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let tokens = json["tokens"] as? [String: Any] else {
            throw NSError(domain: "CognitoAuthService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Token refresh failed"])
        }
        
        await MainActor.run {
            self.accessToken = tokens["accessToken"] as? String
            self.idToken = tokens["idToken"] as? String
            self.saveTokens()
        }
    }
    
    /// Send password reset email
    func resetPassword(email: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedEmail.isEmpty else {
            throw NSError(domain: "CognitoAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email cannot be empty"])
        }
        
        let url = URL(string: "\(baseURL)/reset-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        let requestBody: [String: Any] = [
            "email": trimmedEmail
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "CognitoAuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "CognitoAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        print("✅ [CognitoAuthService] Password reset email sent")
    }
    
    // MARK: - Token Management
    
    private func saveTokens() {
        if let userId = currentUser?.userId {
            UserDefaults.standard.set(userId, forKey: "cognito_user_id")
        }
        if let email = currentUser?.email {
            UserDefaults.standard.set(email, forKey: "cognito_user_email")
        }
        if let idToken = idToken {
            UserDefaults.standard.set(idToken, forKey: "cognito_id_token")
        }
        if let refreshToken = refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: "cognito_refresh_token")
        }
    }
    
    private func clearTokens() {
        UserDefaults.standard.removeObject(forKey: "cognito_user_id")
        UserDefaults.standard.removeObject(forKey: "cognito_user_email")
        UserDefaults.standard.removeObject(forKey: "cognito_id_token")
        UserDefaults.standard.removeObject(forKey: "cognito_refresh_token")
    }
    
    /// Simple JWT expiration check (checks exp claim)
    /// Check if JWT token is expired (optimized for performance)
    /// Runs synchronously but is fast - only decodes JWT payload
    private func isTokenExpired(_ token: String) -> Bool {
        // Fast path: check token format first
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3, parts[1].count > 0 else { return true }
        
        // Decode the payload (second part) - optimized base64 decoding
        // Use .ignoreUnknownCharacters for faster parsing
        guard let payloadData = Data(base64Encoded: parts[1], options: .ignoreUnknownCharacters),
              payloadData.count > 0 else {
            return true
        }
        
        // Fast JSON parsing - only extract 'exp' field
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return true
        }
        
        // Check if token is expired (with 5 minute buffer)
        let expirationDate = Date(timeIntervalSince1970: exp)
        let now = Date()
        return expirationDate < now.addingTimeInterval(300) // 5 minute buffer
    }
}

