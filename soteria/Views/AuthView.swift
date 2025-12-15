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
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, confirmationCode
    }
    
    init() {
        let initStart = Date()
        MainActorMonitor.shared.logOperation("AuthView.init() called")
        print("🔍 [AuthView] init() called")
        let initDuration = Date().timeIntervalSince(initStart)
        MainActorMonitor.shared.logOperation("AuthView.init() completed", duration: initDuration)
        if initDuration > 0.01 {
            print("⚠️ [AuthView] Init took \(String(format: "%.3f", initDuration))s (SLOW)")
        }
    }
    
    var body: some View {
        let _ = {
            MainActorMonitor.shared.logOperation("AuthView.body evaluation START")
            print("🟢 [AuthView] body evaluation started")
        }()
        
        return ZStack {
            // Background - Match splash screen color (dreamMist)
            Color.dreamMist
                .ignoresSafeArea()
                // Removed .allowsHitTesting(false) - it was preventing first tap from working
            
            Group {
                if showConfirmationCode {
                    confirmationCodeView
                } else {
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
                            .drawingGroup()  // Optimize rendering performance
                        
                        Text("SOTERIA")
                            .reverH1()
                        
                        Text("Your behavioral finance companion")
                            .reverBody()
                            .padding(.top, .spacingSmall)
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
                            
                            TextField(isSignUp ? "Enter your desired email" : "Enter your email", text: $email)
                                .textFieldStyle(.plain)
                                .foregroundColor(Color.midnightSlate)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .accentColor(.green)
                                .padding()
                                .contentShape(Rectangle()) // Ensure entire area is tappable
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.mistGray)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    focusedField == .email 
                                                        ? (isEmailValid || email.isEmpty ? Color.reverBlue : Color.red)
                                                        : (isSignUp && email.isEmpty ? Color.reverBlue.opacity(0.3) : Color.clear),
                                                    lineWidth: 2
                                                )
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
                                Group {
                                    if isPasswordVisible {
                                        TextField(isSignUp ? "Enter your desired password" : "Enter your password", text: $password)
                                            .textFieldStyle(.plain)
                                            .foregroundColor(Color.midnightSlate)
                                            .accentColor(.green)
                                    } else {
                                        SecureField(isSignUp ? "Enter your desired password" : "Enter your password", text: $password)
                                            .textFieldStyle(.plain)
                                            .foregroundColor(Color.midnightSlate)
                                            .accentColor(.green)
                                    }
                                }
                                .focused($focusedField, equals: .password)
                                .padding()
                                .padding(.trailing, 40)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    focusedField = .password
                                }
                                
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
                                    .fill(Color.mistGray)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .password ? Color.reverBlue : (isSignUp && password.isEmpty ? Color.reverBlue.opacity(0.3) : Color.clear), lineWidth: 2)
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
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Dismiss keyboard when tapping outside text fields
                    // Use simultaneousGesture to avoid interfering with TextField taps
                    focusedField = nil
                }
        )
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
            let appearTime = Date()
            MainActorMonitor.shared.logOperation("AuthView.onAppear called")
            print("✅ [AuthView] View appeared at \(String(format: "%.3f", appearTime.timeIntervalSince1970.truncatingRemainder(dividingBy: 1000)))s")
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

