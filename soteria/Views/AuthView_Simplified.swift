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
    @ObservedObject private var biometricService = BiometricAuthService.shared
    @State private var isAuthenticatingWithBiometric = false
    @State private var isBiometricAvailable = false
    @State private var biometricType = "Face ID"
    
    var body: some View {
        ZStack {
            // Solid background - clean and elegant
            Color.cloudWhite
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    // Logo/Title - Premium styling
                    VStack(spacing: 8) {
                        Text("SOTERIA")
                            .font(.system(size: 42, weight: .bold, design: .default))
                            .foregroundColor(.softGraphite) // Using darkest gradient color (mistGray was too light, using softGraphite for better contrast)
                            .tracking(4) // Letter spacing for prestige
                            .shadow(color: Color.softGraphite.opacity(0.2), radius: 8, x: 0, y: 2)
                        
                        Text("Secure Your Financial Future")
                            .font(.system(size: 14, weight: .light, design: .default))
                            .foregroundColor(.softGraphite)
                            .tracking(1.5)
                            .padding(.top, 4)
                    }
                    .padding(.top, 80)
                    
                    // Email field - Luxury styling
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EMAIL")
                            .font(.system(size: 11, weight: .semibold, design: .default))
                            .foregroundColor(.softGraphite)
                            .tracking(1.5)
                            .textCase(.uppercase)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.reverBlue.opacity(0.6))
                                .frame(width: 24)
                            
                            TextField("", text: $email, prompt: Text("Enter your email").foregroundColor(.softGraphite.opacity(0.5)))
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .foregroundColor(.midnightSlate)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cloudWhite)
                                .shadow(color: Color.reverBlue.opacity(0.1), radius: 8, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.reverBlue.opacity(0.3), Color.reverBlue.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .padding(.horizontal, 32)
                
                    // Password field - Luxury styling
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PASSWORD")
                                .font(.system(size: 11, weight: .semibold, design: .default))
                                .foregroundColor(.softGraphite)
                                .tracking(1.5)
                                .textCase(.uppercase)
                            Spacer()
                            Button(action: {
                                showPasswordReset = true
                            }) {
                                Text("Forgot?")
                                    .font(.system(size: 12, weight: .medium, design: .default))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.reverBlueDark, Color.reverBlueLight],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .tracking(0.5)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.reverBlue.opacity(0.6))
                                .frame(width: 24)
                            
                            Group {
                                if isPasswordVisible {
                                    TextField("", text: $password, prompt: Text("Enter your password").foregroundColor(.softGraphite.opacity(0.5)))
                                        .textContentType(.password)
                                        .submitLabel(.go)
                                } else {
                                    SecureField("", text: $password, prompt: Text("Enter your password").foregroundColor(.softGraphite.opacity(0.5)))
                                        .textContentType(.password)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            if !email.isEmpty && !password.isEmpty {
                                                Task {
                                                    await performAuth()
                                                }
                                            }
                                        }
                                }
                            }
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(.midnightSlate)
                            
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.reverBlue.opacity(0.6))
                                    .frame(width: 24)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cloudWhite)
                                .shadow(color: Color.reverBlue.opacity(0.1), radius: 8, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.reverBlue.opacity(0.3), Color.reverBlue.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .padding(.horizontal, 32)
                
                    // Error message - Refined styling
                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium, design: .default))
                        }
                        .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.3))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.1))
                        )
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                    }
                
                    // Biometric authentication button - Premium styling
                    if isBiometricAvailable && biometricService.hasSavedCredentials {
                        Button(action: {
                            Task {
                                await performBiometricAuth()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: biometricType == "Face ID" ? "faceid" : "touchid")
                                    .font(.system(size: 22, weight: .medium))
                                Text("Sign in with \(biometricType)")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .tracking(0.5)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundColor(.white)
                            .background(
                                Group {
                                    if isAuthenticatingWithBiometric {
                                        Color.softGraphite.opacity(0.8)
                                    } else {
                                        Color.softGraphite // Using darkest gradient color for better contrast
                                    }
                                }
                            )
                            .cornerRadius(14)
                            .shadow(color: isAuthenticatingWithBiometric ? Color.clear : Color.softGraphite.opacity(0.3), radius: 12, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .disabled(isLoading || isAuthenticatingWithBiometric)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                        
                        // Elegant divider
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, Color.softGraphite.opacity(0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                            Text("OR")
                                .font(.system(size: 11, weight: .medium, design: .default))
                                .foregroundColor(.softGraphite)
                                .tracking(2)
                                .textCase(.uppercase)
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.softGraphite.opacity(0.2), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                    }
                    
                    // Sign In button - Premium gradient styling
                    Button(action: {
                        Task {
                            await performAuth()
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                Text("SIGN IN")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .tracking(1.5)
                                    .textCase(.uppercase)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundColor(.white)
                        .background(
                            Group {
                                if isLoading {
                                    Color.softGraphite.opacity(0.8)
                                } else {
                                    Color.softGraphite // Using darkest gradient color for better contrast
                                }
                            }
                        )
                        .cornerRadius(14)
                        .shadow(color: isLoading ? Color.clear : Color.softGraphite.opacity(0.3), radius: 12, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 40)
            }
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView(
                email: $resetEmail,
                isResetting: $isResettingPassword,
                successMessage: $resetSuccessMessage,
                errorMessage: $resetErrorMessage,
                getAuthService: getAuthService
            )
        }
        .onAppear {
            // Load saved email if available
            if let savedEmail = biometricService.getSavedEmail() {
                email = savedEmail
            }
            
            // Check biometric availability on main actor
            Task { @MainActor in
                isBiometricAvailable = biometricService.checkAvailability()
                biometricType = biometricService.getBiometricType()
            }
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
            
            // Save credentials for biometric auth (only if user successfully signed in)
            biometricService.saveCredentials(email: email, password: password)
            
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
    
    private func performBiometricAuth() async {
        await MainActor.run {
            isAuthenticatingWithBiometric = true
            errorMessage = nil
        }
        
        do {
            // First, authenticate with Face ID / Touch ID
            // authenticate() is @MainActor, Swift will ensure it runs on MainActor
            let authenticated = try await biometricService.authenticate(reason: "Sign in to Soteria")
            
            guard authenticated else {
                await MainActor.run {
                    errorMessage = "Biometric authentication failed"
                    isAuthenticatingWithBiometric = false
                }
                return
            }
            
            // Get saved credentials
            guard let savedEmail = biometricService.getSavedEmail(),
                  let savedPassword = biometricService.getSavedPassword() else {
                await MainActor.run {
                    errorMessage = "No saved credentials found"
                    isAuthenticatingWithBiometric = false
                }
                return
            }
            
            // Update UI with saved email
            await MainActor.run {
                email = savedEmail
            }
            
            // Sign in with saved credentials
            let authService = getAuthService()
            try await authService.signIn(email: savedEmail, password: savedPassword)
            
            // Record sign-in timestamp for welcome back message
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_sign_in_timestamp")
            UserDefaults.standard.set(false, forKey: "welcome_back_shown_for_session")
            // Post notification when sign-in succeeds so RootView can update
            NotificationCenter.default.post(name: NSNotification.Name("UserDidSignIn"), object: nil)
            
        } catch let error as BiometricAuthError {
            // Don't show error for user cancellation
            if case .userCanceled = error {
                // User canceled, just return silently
                await MainActor.run {
                    isAuthenticatingWithBiometric = false
                }
            } else {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAuthenticatingWithBiometric = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAuthenticatingWithBiometric = false
            }
        }
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
