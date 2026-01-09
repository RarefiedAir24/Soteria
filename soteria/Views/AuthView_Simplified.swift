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
    @State private var isSignUp = false // Toggle between sign-in and sign-up
    @State private var showConfirmationCode = false // Show email confirmation screen
    @State private var confirmationCode = "" // 6-digit confirmation code
    @State private var pendingConfirmationEmail = "" // Email that needs confirmation
    @State private var pendingConfirmationPassword = "" // Password for auto sign-in after confirmation
    
    var body: some View {
        ZStack {
            // Solid background - clean and elegant
            Color.cloudWhite
                .ignoresSafeArea()
            
            Group {
                if showConfirmationCode {
                    confirmationCodeView
                } else {
                    ScrollView {
                        VStack(spacing: ResponsiveSize.spacing(large: 40, medium: 32, small: 24)) {
                    // Logo/Title - Premium styling
                    VStack(spacing: 8) {
                        Text("SOTERIA")
                            .font(.system(size: ResponsiveSize.font(large: 42, medium: 38, small: 34), weight: .bold, design: .default))
                            .foregroundColor(.softGraphite) // Using darkest gradient color (mistGray was too light, using softGraphite for better contrast)
                            .tracking(4) // Letter spacing for prestige
                            .shadow(color: Color.softGraphite.opacity(0.2), radius: 8, x: 0, y: 2)
                        
                        Text("Secure Your Financial Future")
                            .font(.system(size: ResponsiveSize.font(large: 14, medium: 13, small: 12), weight: .light, design: .default))
                            .foregroundColor(.softGraphite)
                            .tracking(1.5)
                            .padding(.top, 4)
                    }
                    .padding(.top, ResponsiveSize.padding(large: 80, medium: 60, small: 40))
                    
                    // Sign In / Sign Up Toggle
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation {
                                isSignUp = false
                                errorMessage = nil
                            }
                        }) {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isSignUp ? .softGraphite : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isSignUp ? Color.clear : Color.softGraphite)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            withAnimation {
                                isSignUp = true
                                errorMessage = nil
                            }
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isSignUp ? .white : .softGraphite)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isSignUp ? Color.softGraphite : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                    .background(Color.dreamMist)
                    .cornerRadius(12)
                    .padding(.horizontal, ResponsiveSize.padding(large: 32, medium: 28, small: 24))
                    .padding(.top, ResponsiveSize.padding(large: 20, medium: 16, small: 12))
                    
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
                    .padding(.horizontal, ResponsiveSize.padding(large: 32, medium: 28, small: 24))
                
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
                    .padding(.horizontal, ResponsiveSize.padding(large: 32, medium: 28, small: 24))
                
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
                
                    // Biometric authentication button - Premium styling (only show for sign-in)
                    if !isSignUp && isBiometricAvailable && biometricService.hasSavedCredentials {
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
                    
                    // Sign In / Sign Up button - Premium gradient styling
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
                                Image(systemName: isSignUp ? "person.badge.plus.fill" : "arrow.right.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                Text(isSignUp ? "SIGN UP" : "SIGN IN")
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
                    .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && !isPasswordValid()))
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    
                    // Password requirements for sign-up
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password Requirements:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                                .padding(.bottom, 4)
                            
                            PasswordRequirementRow(met: password.count >= 8, text: "At least 8 characters")
                            PasswordRequirementRow(met: password.rangeOfCharacter(from: .uppercaseLetters) != nil, text: "One uppercase letter")
                            PasswordRequirementRow(met: password.rangeOfCharacter(from: .lowercaseLetters) != nil, text: "One lowercase letter")
                            PasswordRequirementRow(met: password.rangeOfCharacter(from: .decimalDigits) != nil, text: "One number")
                            PasswordRequirementRow(met: password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil, text: "One special character")
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.dreamMist.opacity(0.5))
                        )
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    }
                
                    Spacer(minLength: 40)
                        }
                        .padding(.vertical, 40)
                    }
                }
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
    
    // MARK: - Password Validation
    
    private func isPasswordValid() -> Bool {
        guard isSignUp else { return true }
        return validatePassword(password).isValid
    }
    
    private func validatePassword(_ password: String) -> (isValid: Bool, errorMessage: String?) {
        if password.count < 8 {
            return (false, "Password must be at least 8 characters")
        }
        
        if password.rangeOfCharacter(from: .uppercaseLetters) == nil {
            return (false, "Password must contain at least one uppercase letter")
        }
        
        if password.rangeOfCharacter(from: .lowercaseLetters) == nil {
            return (false, "Password must contain at least one lowercase letter")
        }
        
        if password.rangeOfCharacter(from: .decimalDigits) == nil {
            return (false, "Password must contain at least one number")
        }
        
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        if password.rangeOfCharacter(from: specialCharacters) == nil {
            return (false, "Password must contain at least one special character (!@#$%^&*()_+-=[]{}|;:,.<>?)")
        }
        
        return (true, nil)
    }
    
    private func performAuth() async {
        isLoading = true
        errorMessage = nil
        
        // Validate password for sign-up
        if isSignUp {
            let passwordValidation = validatePassword(password)
            if !passwordValidation.isValid {
                errorMessage = passwordValidation.errorMessage
                isLoading = false
                return
            }
        }
        
        // CRITICAL: Only create AuthService when user actually tries to sign in/sign up
        // This prevents blocking during view creation
        let authService = getAuthService()
        
        do {
            if isSignUp {
                let isFirst100 = try await authService.signUp(email: email, password: password)
                // After successful sign-up, automatically sign in
                try await authService.signIn(email: email, password: password)
                
                // Save credentials for biometric auth
                biometricService.saveCredentials(email: email, password: password)
                
                // Record sign-in timestamp
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_sign_in_timestamp")
                UserDefaults.standard.set(false, forKey: "welcome_back_shown_for_session")
                
                // Show congratulations if user is in first 100 TestFlight signups
                if isFirst100 {
                    // Post notification to show Meta Yellow Card congratulations
                    NotificationCenter.default.post(name: NSNotification.Name("ShowMetaYellowCardCelebration"), object: nil)
                }
            } else {
                try await authService.signIn(email: email, password: password)
                
                // Save credentials for biometric auth (only if user successfully signed in)
                biometricService.saveCredentials(email: email, password: password)
                
                // Record sign-in timestamp for welcome back message
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_sign_in_timestamp")
                UserDefaults.standard.set(false, forKey: "welcome_back_shown_for_session")
            }
            
            // Post notification when sign-in/sign-up succeeds so RootView can update
            NotificationCenter.default.post(name: NSNotification.Name("UserDidSignIn"), object: nil)
        } catch {
            // Check if email confirmation is required
            if let nsError = error as NSError?,
               nsError.userInfo["requiresConfirmation"] as? Bool == true {
                // Show confirmation code screen
                pendingConfirmationEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                pendingConfirmationPassword = password // Store password for auto sign-in after confirmation
                withAnimation {
                    showConfirmationCode = true
                    errorMessage = nil // Clear error message when showing confirmation screen
                }
                isLoading = false
                return
            } else {
                // Check for other specific error messages
                let errorDesc = error.localizedDescription.lowercased()
                if errorDesc.contains("confirm your email") || errorDesc.contains("usernotconfirmed") {
                    // User trying to sign in without confirming
                    pendingConfirmationEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    pendingConfirmationPassword = password // Store password for auto sign-in after confirmation
                    withAnimation {
                        showConfirmationCode = true
                        errorMessage = "Please confirm your email address first"
                    }
                    isLoading = false
                    return
                } else {
                    // Check for password requirement errors
                    let errorDesc = error.localizedDescription.lowercased()
                    if errorDesc.contains("password does not meet requirements") || errorDesc.contains("invalidpassword") {
                        errorMessage = "Password must meet all requirements: at least 8 characters, one uppercase letter, one lowercase letter, one number, and one special character"
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
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
    
    // MARK: - Email Confirmation View
    private var confirmationCodeView: some View {
        ScrollView {
            VStack(spacing: ResponsiveSize.spacing(large: 32, medium: 28, small: 24)) {
                Spacer()
                    .frame(height: ResponsiveSize.padding(large: 60, medium: 50, small: 40))
                
                // Icon
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: ResponsiveSize.font(large: 64, medium: 56, small: 48)))
                    .foregroundColor(.softGraphite)
                
                // Title
                Text("Confirm Your Email")
                    .font(.system(size: ResponsiveSize.font(large: 28, medium: 26, small: 24), weight: .bold))
                    .foregroundColor(.midnightSlate)
                    .padding(.top, ResponsiveSize.padding(large: 16, medium: 12, small: 8))
                
                // Description
                VStack(spacing: 8) {
                    Text("We sent a verification code to")
                        .font(.system(size: ResponsiveSize.font(large: 16, medium: 15, small: 14)))
                        .foregroundColor(.softGraphite)
                    
                    Text(pendingConfirmationEmail)
                        .font(.system(size: ResponsiveSize.font(large: 16, medium: 15, small: 14), weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                .padding(.horizontal, ResponsiveSize.padding(large: 32, medium: 28, small: 24))
                .padding(.bottom, ResponsiveSize.padding(large: 24, medium: 20, small: 16))
                
                // Confirmation Code Field
                VStack(alignment: .leading, spacing: 12) {
                    Text("VERIFICATION CODE")
                        .font(.system(size: ResponsiveSize.font(large: 11, medium: 10, small: 9), weight: .semibold, design: .default))
                        .foregroundColor(.softGraphite)
                        .tracking(1.5)
                        .textCase(.uppercase)
                    
                    TextField("Enter 6-digit code", text: $confirmationCode)
                        .font(.system(size: ResponsiveSize.font(large: 24, medium: 22, small: 20), weight: .bold, design: .monospaced))
                        .foregroundColor(.midnightSlate)
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cloudWhite)
                                .shadow(color: Color.softGraphite.opacity(0.1), radius: 8, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.softGraphite.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .onChange(of: confirmationCode) { oldValue, newValue in
                            confirmationCode = String(newValue.prefix(6)) // Limit to 6 digits
                        }
                }
                .padding(.horizontal, ResponsiveSize.padding(large: 32, medium: 28, small: 24))
                
                // Error message
                if let errorMessage = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: ResponsiveSize.font(large: 14, medium: 13, small: 12)))
                        Text(errorMessage)
                            .font(.system(size: ResponsiveSize.font(large: 13, medium: 12, small: 11), weight: .medium, design: .default))
                    }
                    .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.3))
                    .padding(.horizontal, ResponsiveSize.padding(large: 20, medium: 16, small: 12))
                    .padding(.vertical, ResponsiveSize.padding(large: 12, medium: 10, small: 8))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.1))
                    )
                    .padding(.horizontal, ResponsiveSize.padding(large: 32, medium: 28, small: 24))
                    .multilineTextAlignment(.center)
                }
                
                // Confirm Button
                Button(action: {
                    Task {
                        await confirmEmail()
                    }
                }) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                            Text("CONFIRM EMAIL")
                                .font(.system(size: ResponsiveSize.font(large: 16, medium: 15, small: 14), weight: .semibold, design: .default))
                                .tracking(1.5)
                                .textCase(.uppercase)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: ResponsiveSize.padding(large: 56, medium: 50, small: 44))
                    .foregroundColor(.white)
                    .background(
                        Group {
                            if isLoading || confirmationCode.count != 6 {
                                Color.softGraphite.opacity(0.8)
                            } else {
                                Color.softGraphite
                            }
                        }
                    )
                    .cornerRadius(14)
                    .shadow(color: (isLoading || confirmationCode.count != 6) ? Color.clear : Color.softGraphite.opacity(0.3), radius: 12, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .disabled(isLoading || confirmationCode.count != 6)
                .padding(.horizontal, ResponsiveSize.padding(large: 32, medium: 28, small: 24))
                .padding(.top, ResponsiveSize.padding(large: 8, medium: 6, small: 4))
                
                // Back to Sign In
                Button(action: {
                    withAnimation {
                        showConfirmationCode = false
                        confirmationCode = ""
                        errorMessage = nil
                    }
                }) {
                    Text("Back to Sign In")
                        .font(.system(size: ResponsiveSize.font(large: 14, medium: 13, small: 12), weight: .medium))
                        .foregroundColor(.softGraphite)
                }
                .padding(.top, ResponsiveSize.padding(large: 16, medium: 12, small: 8))
                
                Spacer(minLength: ResponsiveSize.padding(large: 40, medium: 32, small: 24))
            }
            .padding(.vertical, ResponsiveSize.padding(large: 40, medium: 32, small: 24))
        }
    }
    
    // MARK: - Email Confirmation
    private func confirmEmail() async {
        isLoading = true
        errorMessage = nil
        
        let authService = getAuthService()
        
        do {
            try await authService.confirmSignUp(email: pendingConfirmationEmail, confirmationCode: confirmationCode)
            
            // After successful confirmation, automatically sign in
            try await authService.signIn(email: pendingConfirmationEmail, password: pendingConfirmationPassword)
            
            // Save credentials for biometric auth
            biometricService.saveCredentials(email: pendingConfirmationEmail, password: pendingConfirmationPassword)
            
            // Record sign-in timestamp
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_sign_in_timestamp")
            UserDefaults.standard.set(false, forKey: "welcome_back_shown_for_session")
            
            // Check if user is in first 100 TestFlight signups and show celebration
            if UserDefaults.standard.bool(forKey: "is_first_100_testflight_user") {
                NotificationCenter.default.post(name: NSNotification.Name("ShowMetaYellowCardCelebration"), object: nil)
            }
            
            // Post notification when sign-in succeeds so RootView can update
            NotificationCenter.default.post(name: NSNotification.Name("UserDidSignIn"), object: nil)
        } catch {
            let errorDesc = error.localizedDescription.lowercased()
            if errorDesc.contains("invalid") || errorDesc.contains("mismatch") {
                errorMessage = "Invalid confirmation code. Please check your email and try again."
            } else if errorDesc.contains("expired") {
                errorMessage = "Confirmation code has expired. Please sign up again to receive a new code."
            } else {
                errorMessage = error.localizedDescription
            }
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

// MARK: - Password Requirement Row
struct PasswordRequirementRow: View {
    let met: Bool
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(met ? .green : .softGraphite.opacity(0.5))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(met ? .softGraphite : .softGraphite.opacity(0.7))
        }
    }
}
