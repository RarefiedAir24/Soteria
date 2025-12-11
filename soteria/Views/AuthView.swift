//
//  AuthView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false
    @State private var isPasswordVisible = false
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.98, blue: 0.95), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)
                    
                    // Logo/Title Section
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.themePrimaryLight, Color.themePrimaryDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.themePrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text("SOTERIA")
                            .font(.system(size: 42, weight: .bold, design: .default))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Your behavioral finance companion")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                            .padding(.top, 4)
                    }
                    .padding(.bottom, 50)
                    
                    // Form Section
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                
                                if isSignUp {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(Color.themePrimary)
                                            .font(.footnote)
                                        Text("Choose your email")
                                            .font(.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.themePrimary)
                                    }
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                            
                            TextField(isSignUp ? "Enter your desired email" : "Enter your email", text: $email)
                                .textFieldStyle(.plain)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .accentColor(.green)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    focusedField == .email 
                                                        ? (isEmailValid || email.isEmpty ? Color.themePrimary : Color.red)
                                                        : (isSignUp && email.isEmpty ? Color.themePrimary.opacity(0.3) : Color.clear),
                                                    lineWidth: 2
                                                )
                                        )
                                )
                            
                            // Email validation error (only show if email is not empty and invalid)
                            if !email.isEmpty && !isEmailValid {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Please enter a valid email address (e.g., user@example.com)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                                .padding(.top, 6)
                                .padding(.horizontal, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                
                                if isSignUp {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(Color.themePrimary)
                                            .font(.footnote)
                                        Text("Choose your password")
                                            .font(.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.themePrimary)
                                    }
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                            
                            ZStack(alignment: .trailing) {
                                Group {
                                    if isPasswordVisible {
                                        TextField(isSignUp ? "Enter your desired password" : "Enter your password", text: $password)
                                            .textFieldStyle(.plain)
                                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                            .accentColor(.green)
                                    } else {
                                        SecureField(isSignUp ? "Enter your desired password" : "Enter your password", text: $password)
                                            .textFieldStyle(.plain)
                                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                            .accentColor(.green)
                                    }
                                }
                                .focused($focusedField, equals: .password)
                                .padding()
                                .padding(.trailing, 40)
                                
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                        .padding(.trailing, 16)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .password ? Color.themePrimary : (isSignUp && password.isEmpty ? Color.themePrimary.opacity(0.3) : Color.clear), lineWidth: 2)
                                    )
                            )
                            
                            // Password Requirements (only in sign-up mode)
                            if isSignUp && !password.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    PasswordRequirement(met: password.count >= 6, text: "At least 6 characters")
                                    PasswordRequirement(met: password.rangeOfCharacter(from: .uppercaseLetters) != nil, text: "One uppercase letter")
                                    PasswordRequirement(met: password.rangeOfCharacter(from: .lowercaseLetters) != nil, text: "One lowercase letter")
                                    PasswordRequirement(met: password.rangeOfCharacter(from: .decimalDigits) != nil, text: "One number")
                                    PasswordRequirement(met: password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil, text: "One special character")
                                }
                                .padding(.top, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        
                        // Success Message
                        if let successMessage = successMessage {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(successMessage)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.subheadline)
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Sign In/Up Button
                        Button(action: {
                            Task {
                                await performAuth()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: email.isEmpty || password.isEmpty || isLoading
                                        ? [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]
                                        : [Color.themePrimaryLight, Color.themePrimaryDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: (email.isEmpty || password.isEmpty || isLoading) ? Color.clear : Color.themePrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty || !isEmailValid || (isSignUp && !isPasswordValid))
                        .padding(.top, 8)
                        
                        // Toggle Sign In/Sign Up
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                errorMessage = nil
                                successMessage = nil
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 8)
                        
                        // Forgot Password Link (only in sign-in mode)
                        if !isSignUp {
                            Button(action: {
                                showForgotPassword = true
                                forgotPasswordEmail = email // Pre-fill with entered email if available
                            }) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(
                email: $forgotPasswordEmail,
                onDismiss: { showForgotPassword = false },
                onSuccess: { message in
                    successMessage = message
                    errorMessage = nil
                    showForgotPassword = false
                },
                onError: { message in
                    errorMessage = message
                    successMessage = nil
                }
            )
        }
    }
    
    // Email validation
    private var isEmailValid: Bool {
        guard !email.isEmpty else { return true } // Allow empty for initial state
        
        // Trim email for validation
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return false }
        
        // Basic email format validation
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: trimmedEmail)
    }
    
    // Password validation
    private var isPasswordValid: Bool {
        guard password.count >= 6 else { return false }
        guard password.rangeOfCharacter(from: .uppercaseLetters) != nil else { return false }
        guard password.rangeOfCharacter(from: .lowercaseLetters) != nil else { return false }
        guard password.rangeOfCharacter(from: .decimalDigits) != nil else { return false }
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        guard password.rangeOfCharacter(from: specialCharacters) != nil else { return false }
        return true
    }
    
    private func performAuth() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        focusedField = nil
        
        // Trim whitespace from email and password
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate email
        if !isEmailValid {
            withAnimation {
                errorMessage = "Please enter a valid email address. Example: user@example.com"
            }
            isLoading = false
            return
        }
        
        // Validate password for sign-up
        if isSignUp && !isPasswordValid {
            withAnimation {
                errorMessage = "Password must meet all requirements"
            }
            isLoading = false
            return
        }
        
        // Check if email or password is empty after trimming
        if trimmedEmail.isEmpty || trimmedPassword.isEmpty {
            withAnimation {
                errorMessage = "Email and password cannot be empty"
            }
            isLoading = false
            return
        }
        
        do {
            if isSignUp {
                try await authService.signUp(email: trimmedEmail, password: trimmedPassword)
            } else {
                try await authService.signIn(email: trimmedEmail, password: trimmedPassword)
            }
        } catch {
            withAnimation {
                // Check for Firebase Auth errors
                if let authError = error as NSError?,
                   let errorCode = AuthErrorCode(_bridgedNSError: authError) {
                    errorMessage = getErrorMessage(for: errorCode)
                } else {
                    // Check if error message contains specific strings
                    let errorDesc = error.localizedDescription.lowercased()
                    if errorDesc.contains("malformed") || errorDesc.contains("expired") || errorDesc.contains("invalid") {
                        errorMessage = "Invalid email or password. Please check your credentials and try again."
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        
        isLoading = false
    }
    
    // Helper function to get user-friendly error messages
    private func getErrorMessage(for errorCode: AuthErrorCode) -> String {
        switch errorCode.code {
        case .emailAlreadyInUse:
            return "This email is already registered. Please sign in instead, or use 'Forgot Password?' if you don't remember your password."
        case .weakPassword:
            return "Password is too weak. Please use a stronger password."
        case .invalidEmail:
            return "The email address is invalid. Please check and try again."
        case .userNotFound:
            return "No account found with this email. Please sign up first."
        case .wrongPassword:
            return "Incorrect password. Please try again or use 'Forgot Password?' to reset."
        case .invalidCredential:
            return "Invalid email or password. Please check your credentials and try again."
        case .networkError:
            return "Network error. Please check your internet connection and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        case .userDisabled:
            return "This account has been disabled. Please contact support."
        case .operationNotAllowed:
            return "This sign-in method is not allowed. Please contact support."
        default:
            // Fallback to a more user-friendly message
            let description = errorCode.localizedDescription
            if description.contains("malformed") || description.contains("expired") {
                return "Invalid email or password. Please check your credentials and try again."
            }
            return description
        }
    }
}

// Password Requirement Row Component
struct PasswordRequirement: View {
    let met: Bool
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .gray)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .green : .secondary)
                .strikethrough(met)
        }
    }
}

// Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var email: String
    let onDismiss: () -> Void
    let onSuccess: (String) -> Void
    let onError: (String) -> Void
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "key.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                    .padding(.top, 40)
                
                // Title and Description
                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(.plain)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isEmailFocused)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isEmailFocused ? Color.themePrimary : Color.clear, lineWidth: 2)
                                )
                        )
                }
                .padding(.horizontal, 32)
                
                // Error Message
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 32)
                }
                
                // Send Button
                Button(action: {
                    Task {
                        await sendResetEmail()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Link")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: email.isEmpty || isLoading
                                ? [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]
                                : [Color.themePrimaryLight, Color.themePrimaryDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: (email.isEmpty || isLoading) ? Color.clear : Color.themePrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(isLoading || email.isEmpty)
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func sendResetEmail() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(email: email)
            onSuccess("Password reset email sent! Check your inbox.")
        } catch {
            errorMessage = error.localizedDescription
            onError(error.localizedDescription)
        }
        
        isLoading = false
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService())
}

