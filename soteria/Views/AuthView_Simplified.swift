//
//  AuthView_Simplified.swift
//  soteria
//
//  Styled sign-in view with password reset functionality
//

import SwiftUI

struct AuthView_Simplified: View {
    // CRITICAL: Don't create AuthService until user actually tries to sign in
    // This prevents any blocking during view creation
    let getAuthService: () -> AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPasswordReset = false
    @State private var resetEmail = ""
    @State private var isResettingPassword = false
    @State private var resetSuccessMessage: String?
    @State private var resetErrorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo/Title
                Text("SOTERIA")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.midnightSlate)
                    .padding(.top, 60)
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 32)
                
                // Password field with visibility toggle
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.softGraphite)
                        Spacer()
                        Button(action: {
                            showPasswordReset = true
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.reverBlue)
                        }
                    }
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Enter your password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password) // Enables iOS password autofill
                                .submitLabel(.go) // Shows "Go" on keyboard
                        } else {
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password) // Enables iOS password autofill
                                .submitLabel(.go) // Shows "Go" on keyboard
                                .onSubmit {
                                    // Auto-submit when password is entered
                                    if !email.isEmpty && !password.isEmpty {
                                        Task {
                                            await performAuth()
                                        }
                                    }
                                }
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.softGraphite)
                                .frame(width: 24, height: 24)
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding(.horizontal, 32)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }
                
                // Sign In button - styled
                Button(action: {
                    Task {
                        await performAuth()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isLoading ? Color.softGraphite : Color.reverBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal, 32)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView(
                email: $resetEmail,
                isResetting: $isResettingPassword,
                successMessage: $resetSuccessMessage,
                errorMessage: $resetErrorMessage,
                getAuthService: getAuthService
            )
        }
    }
    
    private func performAuth() async {
        isLoading = true
        errorMessage = nil
        
        // CRITICAL: Only create AuthService when user actually tries to sign in
        // This prevents blocking during view creation
        let authService = getAuthService()
        
        do {
            try await authService.signIn(email: email, password: password)
            // Record sign-in timestamp for welcome back message
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_sign_in_timestamp")
            UserDefaults.standard.set(false, forKey: "welcome_back_shown_for_session")
            // Post notification when sign-in succeeds so RootView can update
            NotificationCenter.default.post(name: NSNotification.Name("UserDidSignIn"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Password Reset View
struct PasswordResetView: View {
    @Binding var email: String
    @Binding var isResetting: Bool
    @Binding var successMessage: String?
    @Binding var errorMessage: String?
    let getAuthService: () -> AuthService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "lock.rotation")
                    .font(.system(size: 48))
                    .foregroundColor(.reverBlue)
                    .padding(.top, 40)
                
                // Title
                Text("Reset Password")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.midnightSlate)
                
                // Description
                Text("Enter your email address and we'll send you instructions to reset your password.")
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.softGraphite)
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 32)
                
                // Success message
                if let successMessage = successMessage {
                    Text(successMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }
                
                // Reset button
                Button(action: {
                    Task {
                        await resetPassword()
                    }
                }) {
                    HStack {
                        if isResetting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Send Reset Link")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isResetting || email.isEmpty ? Color.softGraphite : Color.reverBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isResetting || email.isEmpty)
                .padding(.horizontal, 32)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.vertical, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.reverBlue)
                }
            }
        }
    }
    
    private func resetPassword() async {
        isResetting = true
        successMessage = nil
        errorMessage = nil
        
        let authService = getAuthService()
        
        do {
            try await authService.resetPassword(email: email)
            successMessage = "Password reset instructions have been sent to \(email). Please check your email."
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isResetting = false
    }
}
