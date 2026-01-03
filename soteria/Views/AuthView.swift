//
//  AuthView.swift
//  rever
//
//  Created by Frank Schioppa on 12/6/25.
//

import SwiftUI
// TEMPORARILY DISABLED: Firebase import - testing if it's causing crash
// import FirebaseAuth

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
    @State private var showConfirmationCode = false
    @State private var confirmationCode = ""
    @State private var pendingConfirmationEmail = ""
    @State private var cachedEmailValidation: (email: String, isValid: Bool)? = nil
    @State private var cachedPasswordValidation: (password: String, requirements: [Bool])? = nil
    @FocusState private var focusedField: Field?
    @State private var bodyEvaluationStartTime: Date? = nil
    
    enum Field {
        case email, password, confirmationCode
    }
    
    var body: some View {
        // CRITICAL: Use synchronous print to detect if body evaluation is happening
        // This will work even if MainActor is blocked
        let bodyStart = Date()
        let shouldLog = !UserDefaults.standard.bool(forKey: "AuthViewBodyLogged")
        
        // CRITICAL: Use print() instead of StartupDiagnostics - it's synchronous and won't be blocked
        print("🔍 [AuthView] body evaluation started at \(Date().timeIntervalSince1970)")
        
        // Defer detailed logging to avoid blocking
        DispatchQueue.main.async {
            StartupDiagnostics.shared.log("🔍 [AuthView] body evaluation started")
            if shouldLog {
                UserDefaults.standard.set(true, forKey: "AuthViewBodyLogged")
                self.bodyEvaluationStartTime = bodyStart
            }
        }
        
        let view = ZStack {
            // Background - Match splash screen color (dreamMist)
            Color.dreamMist
                .ignoresSafeArea()
            
            Group {
                if showConfirmationCode {
                    confirmationCodeView
                } else {
                    ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)
                    
                    // Logo/Title Section
                    // CRITICAL: Temporarily remove logo to test if it's causing the 16s delay
                    // Logo will be added back after we identify the root cause
                    VStack(spacing: 12) {
                        Text("SOTERIA")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Your behavioral finance companion")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.softGraphite)
                            .padding(.top, 8)
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
                                            .foregroundColor(Color.reverBlue)
                                            .font(.footnote)
                                        Text("Choose your email")
                                            .font(.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.reverBlue)
                                    }
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                            
                            // CRITICAL: Cache stroke color computation to avoid expensive Color operations during body evaluation
                            let strokeColor: Color = {
                                if focusedField == .email {
                                    return (isEmailValid || email.isEmpty) ? Color.reverBlue : Color.red
                                } else {
                                    return (isSignUp && email.isEmpty) ? Color.reverBlue.opacity(0.3) : Color.clear
                                }
                            }()
                            
                            TextField(isSignUp ? "Enter your desired email" : "Enter your email", text: $email)
                                .textFieldStyle(.plain)
                                .foregroundColor(Color.midnightSlate)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .textContentType(.emailAddress) // Enables iOS autofill from keychain
                                .focused($focusedField, equals: .email)
                                .accentColor(.green)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.mistGray)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(strokeColor, lineWidth: 2)
                                        )
                                )
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .password
                                }
                            
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
                                            .foregroundColor(Color.reverBlue)
                                            .font(.footnote)
                                        Text("Choose your password")
                                            .font(.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.reverBlue)
                                    }
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                            
                            ZStack(alignment: .trailing) {
                                if isPasswordVisible {
                                    TextField(isSignUp ? "Enter your desired password" : "Enter your password", text: $password)
                                        .textFieldStyle(.plain)
                                        .foregroundColor(Color.midnightSlate)
                                        .accentColor(.green)
                                        .textContentType(isSignUp ? .newPassword : .password) // Enables iOS password autofill
                                        .focused($focusedField, equals: .password)
                                        .padding()
                                        .padding(.trailing, 40)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            if !email.isEmpty && !password.isEmpty {
                                                Task {
                                                    await performAuth()
                                                }
                                            }
                                        }
                                } else {
                                    SecureField(isSignUp ? "Enter your desired password" : "Enter your password", text: $password)
                                        .textFieldStyle(.plain)
                                        .foregroundColor(Color.midnightSlate)
                                        .accentColor(.green)
                                        .textContentType(isSignUp ? .newPassword : .password) // Enables iOS password autofill
                                        .focused($focusedField, equals: .password)
                                        .padding()
                                        .padding(.trailing, 40)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            if !email.isEmpty && !password.isEmpty {
                                                Task {
                                                    await performAuth()
                                                }
                                            }
                                        }
                                }
                                
                                Button(action: {
                                    // Preserve focus when toggling password visibility
                                    let wasFocused = focusedField == .password
                                    isPasswordVisible.toggle()
                                    if wasFocused {
                                        // Small delay to ensure field is recreated before refocusing
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                            focusedField = .password
                                        }
                                    }
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                        .padding(.trailing, 16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.mistGray)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .password ? Color.reverBlue : (isSignUp && password.isEmpty ? Color.reverBlue.opacity(0.3) : Color.clear), lineWidth: 2)
                                    )
                            )
                            
                            // Password Requirements (only in sign-up mode)
                            // CRITICAL: Use cached validation results to avoid expensive rangeOfCharacter calls during body evaluation
                            if isSignUp && !password.isEmpty {
                                let requirements = getPasswordRequirements()
                                VStack(alignment: .leading, spacing: 6) {
                                    PasswordRequirement(met: requirements[0], text: "At least 6 characters")
                                    PasswordRequirement(met: requirements[1], text: "One uppercase letter")
                                    PasswordRequirement(met: requirements[2], text: "One lowercase letter")
                                    PasswordRequirement(met: requirements[3], text: "One number")
                                    PasswordRequirement(met: requirements[4], text: "One special character")
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
                        
                        // Sign In/Up Button - REVER Primary Button
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
                                }
                            }
                        }
                        .reverPrimaryButton()
                        .disabled(isLoading || email.isEmpty || password.isEmpty || !isEmailValid || (isSignUp && !isPasswordValid))
                        .opacity((email.isEmpty || password.isEmpty || isLoading) ? 0.5 : 1.0)
                        .padding(.top, .spacingSmall)
                        
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
                                    .reverBody()
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
                .padding(.bottom, 40)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        
        // Log body evaluation duration - defer to async to avoid blocking
        DispatchQueue.main.async {
            let bodyDuration = Date().timeIntervalSince(bodyStart)
            if bodyDuration > 0.1 {
                StartupDiagnostics.shared.log("⚠️ [AuthView] body evaluation took \(String(format: "%.3f", bodyDuration))s")
            }
        }
        
        return view
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                // Only dismiss if not tapping on a text field
                if focusedField != nil {
                    focusedField = nil
                }
            }
            // CRITICAL: Completely remove .sheet modifier during first render to test if it's causing the 84s delay
            // Sheets will be added back after we identify the root cause
            // .sheet(isPresented: $showForgotPassword) {
            //     // Create sheet content lazily - only when sheet is actually shown
            //     ForgotPasswordView(
            //         email: $forgotPasswordEmail,
            //         onDismiss: { showForgotPassword = false },
            //         onSuccess: { message in
            //             successMessage = message
            //             errorMessage = nil
            //             showForgotPassword = false
            //         },
            //         onError: { message in
            //             errorMessage = message
            //             successMessage = nil
            //         }
            //     )
            //     .onAppear {
            //         StartupDiagnostics.shared.log("🔍 [AuthView] ForgotPasswordView sheet appeared")
            //     }
            // }
            .onAppear {
                let onAppearStart = Date()
                StartupDiagnostics.shared.log("🔍 [AuthView] onAppear called")
                
                if let bodyStart = bodyEvaluationStartTime {
                    let totalTime = Date().timeIntervalSince(bodyStart)
                    StartupDiagnostics.shared.log("⏱️ [AuthView] Time from body evaluation to onAppear: \(String(format: "%.3f", totalTime))s")
                } else {
                    let totalTime = Date().timeIntervalSince(bodyStart)
                    StartupDiagnostics.shared.log("⏱️ [AuthView] Time from body evaluation to onAppear: \(String(format: "%.3f", totalTime))s")
                }
                
                // Post notification so RootViewSheetModifier knows AuthView has appeared
                NotificationCenter.default.post(name: NSNotification.Name("AuthViewAppeared"), object: nil)
                
                let onAppearDuration = Date().timeIntervalSince(onAppearStart)
                if onAppearDuration > 0.01 {
                    StartupDiagnostics.shared.log("⚠️ [AuthView] onAppear handler took \(String(format: "%.3f", onAppearDuration))s")
                }
            }
    }
    
    // Email validation - optimized to prevent excessive re-computation
    // CRITICAL: Cache validation result to avoid recomputing on every keystroke
    private var isEmailValid: Bool {
        // CRITICAL: Don't do any async work here - it can block rendering
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return true } // Allow empty for initial state
        
        // Use cached result if email hasn't changed
        if let cached = cachedEmailValidation, cached.email == trimmedEmail {
            return cached.isValid
        }
        
        // Basic email format validation - simplified for performance
        let isValid = trimmedEmail.contains("@") && 
               trimmedEmail.contains(".") && 
               trimmedEmail.count > 5 &&
               trimmedEmail.first != "@" &&
               trimmedEmail.last != "@" &&
               trimmedEmail.first != "." &&
               trimmedEmail.last != "."
        
        // CRITICAL: Update cache synchronously to avoid async dispatch during view evaluation
        // This prevents blocking MainActor with async work
        cachedEmailValidation = (trimmedEmail, isValid)
        
        return isValid
    }
    
    // Password validation
    // CRITICAL: Cache CharacterSet to avoid recreating on every validation
    private static let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
    
    // CRITICAL: Cache password requirements to avoid expensive rangeOfCharacter calls during body evaluation
    private func getPasswordRequirements() -> [Bool] {
        // Use cached result if password hasn't changed
        if let cached = cachedPasswordValidation, cached.password == password {
            return cached.requirements
        }
        
        // Compute requirements (expensive operations)
        let requirements: [Bool] = [
            password.count >= 6,
            password.rangeOfCharacter(from: .uppercaseLetters) != nil,
            password.rangeOfCharacter(from: .lowercaseLetters) != nil,
            password.rangeOfCharacter(from: .decimalDigits) != nil,
            password.rangeOfCharacter(from: Self.specialCharacters) != nil
        ]
        
        // Cache the result
        cachedPasswordValidation = (password, requirements)
        return requirements
    }
    
    private var isPasswordValid: Bool {
        let requirements = getPasswordRequirements()
        return requirements.allSatisfy { $0 }
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
                // Record sign-in timestamp for welcome back message
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_sign_in_timestamp")
                UserDefaults.standard.set(false, forKey: "welcome_back_shown_for_session")
            }
        } catch {
            withAnimation {
                // TEMPORARILY DISABLED: Firebase AuthErrorCode - using simple error handling
                // Check for Firebase Auth errors
                // if let authError = error as NSError?,
                //    let errorCode = AuthErrorCode(_bridgedNSError: authError) {
                //     errorMessage = getErrorMessage(for: errorCode)
                // } else {
                //     // Check if error message contains specific strings
                //     let errorDesc = error.localizedDescription.lowercased()
                //     if errorDesc.contains("malformed") || errorDesc.contains("expired") || errorDesc.contains("invalid") {
                //         errorMessage = "Invalid email or password. Please check your credentials and try again."
                //     } else {
                //         errorMessage = error.localizedDescription
                //     }
                // }
                
                // Simple error handling
                let errorDesc = error.localizedDescription.lowercased()
                
                // Check if email confirmation is required
                if let nsError = error as NSError?,
                   nsError.userInfo["requiresConfirmation"] as? Bool == true {
                    // Show confirmation code screen
                    pendingConfirmationEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    withAnimation {
                        showConfirmationCode = true
                    }
                    return
                } else if errorDesc.contains("confirm your email") || errorDesc.contains("usernotconfirmed") {
                    // User trying to sign in without confirming
                    pendingConfirmationEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    withAnimation {
                        showConfirmationCode = true
                        errorMessage = "Please confirm your email address first"
                    }
                    return
                } else if errorDesc.contains("malformed") || errorDesc.contains("expired") || errorDesc.contains("invalid") {
                    errorMessage = "Invalid email or password. Please check your credentials and try again."
                } else if errorDesc.contains("already exists") || errorDesc.contains("already registered") {
                    errorMessage = "An account with this email already exists. Please sign in instead."
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Confirmation Code View
    private var confirmationCodeView: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)
                
                // Logo/Title Section
                VStack(spacing: 12) {
                    Image("soteria_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.reverBlue.opacity(0.25), radius: 10, x: 0, y: 5)
                    
                    Text("Confirm Your Email")
                        .reverH1()
                    
                    Text("Enter the verification code sent to")
                        .reverBody()
                        .padding(.top, .spacingSmall)
                    
                    Text(pendingConfirmationEmail)
                        .font(.headline)
                        .foregroundColor(.reverBlue)
                        .padding(.top, 4)
                }
                .padding(.bottom, 50)
                
                // Confirmation Code Field
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        Text("Verification Code")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    
                    TextField("Enter 6-digit code", text: $confirmationCode)
                        .textFieldStyle(.plain)
                        .foregroundColor(Color.midnightSlate)
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .confirmationCode)
                        .accentColor(.green)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mistGray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .confirmationCode ? Color.reverBlue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        )
                        .onChange(of: confirmationCode) { oldValue, newValue in
                            // Limit to 6 digits
                            confirmationCode = String(newValue.prefix(6))
                        }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
                
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
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
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
                    .padding(.horizontal, 36)
                    .padding(.bottom, 20)
                }
                
                // Confirm Button
                Button(action: {
                    Task {
                        await confirmEmail()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Confirm Email")
                        }
                    }
                }
                .reverPrimaryButton()
                .disabled(isLoading || confirmationCode.count != 6)
                .opacity((confirmationCode.count != 6 || isLoading) ? 0.5 : 1.0)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
                
                // Back to Sign In
                Button(action: {
                    withAnimation {
                        showConfirmationCode = false
                        confirmationCode = ""
                        errorMessage = nil
                        successMessage = nil
                    }
                }) {
                    Text("Back to Sign In")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .onAppear {
            // Log when view actually appears (after SwiftUI finishes rendering)
            let appearStart = Date()
            StartupDiagnostics.shared.log("🔍 [AuthView] onAppear called")
            
            // Measure time since body evaluation started
            if let bodyStart = bodyEvaluationStartTime {
                let bodyDuration = appearStart.timeIntervalSince(bodyStart)
                if bodyDuration > 0.1 {
                    StartupDiagnostics.shared.log("⚠️ [AuthView] Time from body start to onAppear: \(String(format: "%.3f", bodyDuration))s")
                }
            }
            
            // Post notification so RootViewSheetModifier knows AuthView has appeared
            NotificationCenter.default.post(name: NSNotification.Name("AuthViewAppeared"), object: nil)
            
            let appearDuration = Date().timeIntervalSince(appearStart)
            if appearDuration > 0.01 {
                StartupDiagnostics.shared.log("⚠️ [AuthView] onAppear handler took \(String(format: "%.3f", appearDuration))s")
            }
        }
    }
    
    private func confirmEmail() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        focusedField = nil
        
        do {
            try await authService.confirmSignUp(email: pendingConfirmationEmail, confirmationCode: confirmationCode)
            withAnimation {
                successMessage = "Email confirmed! You can now sign in."
                // Auto-switch to sign in after 2 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation {
                        showConfirmationCode = false
                        confirmationCode = ""
                        isSignUp = false
                        successMessage = nil
                    }
                }
            }
        } catch {
            withAnimation {
                let errorDesc = error.localizedDescription.lowercased()
                if errorDesc.contains("invalid") || errorDesc.contains("mismatch") {
                    errorMessage = "Invalid confirmation code. Please check your email and try again."
                } else if errorDesc.contains("expired") {
                    errorMessage = "Confirmation code has expired. Please sign up again to receive a new code."
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
        
        isLoading = false
    }
    
    // TEMPORARILY DISABLED: Firebase AuthErrorCode helper function
    // Helper function to get user-friendly error messages
    /*
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
    */
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
                                        .stroke(isEmailFocused ? Color.reverBlue : Color.clear, lineWidth: 2)
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
                                : [Color.reverBlueLight, Color.reverBlueDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: (email.isEmpty || isLoading) ? Color.clear : Color.reverBlue.opacity(0.3), radius: 10, x: 0, y: 5)
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

