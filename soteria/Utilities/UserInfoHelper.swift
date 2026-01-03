//
//  UserInfoHelper.swift
//  soteria
//
//  Helper utilities for auto-populating user information from AuthService
//  Eliminates need for manual user ID entry
//

import Foundation
import SwiftUI

/// Helper extension to easily access user information from AuthService
extension AuthService {
    /// Get user ID for API calls or account creation
    /// Returns nil if user is not authenticated
    var autoUserId: String? {
        return getUserId()
    }
    
    /// Get user email for forms or account creation
    /// Returns nil if user is not authenticated
    var autoUserEmail: String? {
        return currentUserEmail
    }
    
    /// Check if user info is available for auto-population
    var hasUserInfo: Bool {
        return isAuthenticated && getUserId() != nil && currentUserEmail != nil
    }
}

/// View modifier to auto-populate user information in forms
struct AutoPopulateUserInfo: ViewModifier {
    @EnvironmentObject var authService: AuthService
    @Binding var userId: String
    @Binding var email: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Auto-populate from AuthService
                if let autoUserId = authService.autoUserId {
                    userId = autoUserId
                }
                if let autoEmail = authService.autoUserEmail {
                    email = autoEmail
                }
            }
    }
}

extension View {
    /// Auto-populate user ID and email from AuthService
    func autoPopulateUserInfo(userId: Binding<String>, email: Binding<String>) -> some View {
        modifier(AutoPopulateUserInfo(userId: userId, email: email))
    }
}

/// Example usage in a form:
/// ```swift
/// struct MyForm: View {
///     @EnvironmentObject var authService: AuthService
///     @State private var userId: String = ""
///     @State private var email: String = ""
///     
///     var body: some View {
///         Form {
///             TextField("User ID", text: $userId)
///                 .disabled(true) // Auto-populated, read-only
///             TextField("Email", text: $email)
///                 .disabled(true) // Auto-populated, read-only
///         }
///         .autoPopulateUserInfo(userId: $userId, email: $email)
///     }
/// }
/// ```

