//
//  BiometricAuthService.swift
//  soteria
//
//  Face ID / Touch ID authentication service
//

import Foundation
import LocalAuthentication
import Combine

class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    // Published property for ObservableObject conformance
    // This allows the view to observe changes to the service
    @Published private(set) var authenticationState: AuthenticationState = .idle
    
    enum AuthenticationState {
        case idle
        case authenticating
        case success
        case failed(String)
    }
    
    /// Create a fresh LAContext (should not be reused)
    private func createContext() -> LAContext {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        return context
    }
    
    // Cached values to avoid repeated LAContext access
    @MainActor private var cachedIsAvailable: Bool?
    @MainActor private var cachedBiometricType: String?
    
    /// Check if biometric authentication is available (must be called from MainActor)
    @MainActor
    func checkAvailability() -> Bool {
        if let cached = cachedIsAvailable {
            return cached
        }
        
        let context = createContext()
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if let error = error {
            print("⚠️ [BiometricAuthService] Biometric check error: \(error.localizedDescription)")
        }
        cachedIsAvailable = available
        return available
    }
    
    /// Get the biometric type (Face ID or Touch ID) - must be called from MainActor
    @MainActor
    func getBiometricType() -> String {
        if let cached = cachedBiometricType {
            return cached
        }
        
        let context = createContext()
        let type: String
        switch context.biometryType {
        case .faceID:
            type = "Face ID"
        case .touchID:
            type = "Touch ID"
        case .none:
            type = "Biometric"
        @unknown default:
            type = "Biometric"
        }
        cachedBiometricType = type
        return type
    }
    
    /// Check if credentials are saved in keychain
    var hasSavedCredentials: Bool {
        return KeychainHelper.get(key: "saved_email") != nil && 
               KeychainHelper.get(key: "saved_password") != nil
    }
    
    /// Save credentials securely in keychain
    func saveCredentials(email: String, password: String) {
        KeychainHelper.set(key: "saved_email", value: email)
        KeychainHelper.set(key: "saved_password", value: password)
        // Also save a flag that user wants to use biometric auth
        UserDefaults.standard.set(true, forKey: "biometric_auth_enabled")
        print("✅ [BiometricAuthService] Credentials saved securely")
    }
    
    /// Get saved email from keychain
    func getSavedEmail() -> String? {
        return KeychainHelper.get(key: "saved_email")
    }
    
    /// Get saved password from keychain
    func getSavedPassword() -> String? {
        return KeychainHelper.get(key: "saved_password")
    }
    
    /// Clear saved credentials
    func clearCredentials() {
        KeychainHelper.delete(key: "saved_email")
        KeychainHelper.delete(key: "saved_password")
        UserDefaults.standard.set(false, forKey: "biometric_auth_enabled")
        print("✅ [BiometricAuthService] Credentials cleared")
    }
    
    /// Check if user has enabled biometric auth
    var isBiometricAuthEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "biometric_auth_enabled")
    }
    
    /// Authenticate using Face ID / Touch ID
    @MainActor
    func authenticate(reason: String = "Authenticate to sign in") async throws -> Bool {
        // Create a fresh context for each authentication attempt
        // LAContext should not be reused after a failed attempt
        let context = createContext()
        
        // Check availability with the new context (must be on main thread)
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                print("❌ [BiometricAuthService] Cannot evaluate policy: \(error.localizedDescription)")
            }
            self.authenticationState = .failed("Biometric authentication not available")
            throw BiometricAuthError.notAvailable
        }
        
        // Update state
        self.authenticationState = .authenticating
        
        // Use continuation for async evaluation
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            // Evaluate policy (must be called from main thread)
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                // Callback is on main thread
                if success {
                    self.authenticationState = .success
                    continuation.resume(returning: true)
                } else if let error = error {
                    let nsError = error as NSError
                    let errorCode = nsError.code
                    let errorMessage = error.localizedDescription
                    
                    self.authenticationState = .failed(errorMessage)
                    
                    if errorCode == LAError.userCancel.rawValue {
                        continuation.resume(throwing: BiometricAuthError.userCanceled)
                    } else if errorCode == LAError.userFallback.rawValue {
                        continuation.resume(throwing: BiometricAuthError.userFallback)
                    } else if errorCode == LAError.systemCancel.rawValue {
                        continuation.resume(throwing: BiometricAuthError.userCanceled)
                    } else {
                        continuation.resume(throwing: BiometricAuthError.authenticationFailed(errorMessage))
                    }
                } else {
                    self.authenticationState = .failed("Unknown error")
                    continuation.resume(throwing: BiometricAuthError.authenticationFailed("Unknown error"))
                }
            }
        }
    }
}

enum BiometricAuthError: LocalizedError {
    case notAvailable
    case userCanceled
    case userFallback
    case authenticationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .userCanceled:
            return "Authentication was canceled"
        case .userFallback:
            return "User chose to use password instead"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        }
    }
}

