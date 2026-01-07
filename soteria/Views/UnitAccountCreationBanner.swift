//
//  UnitAccountCreationBanner.swift
//  Soteria
//
//  Celebratory banner prompting users to create their dedicated savings account
//

import SwiftUI

struct UnitAccountCreationBanner: View {
    @EnvironmentObject var authService: AuthService
    @State private var isCreating = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var bannerScale: CGFloat = 0.9
    @State private var sparkleRotation: Double = 0
    
    // User information for account creation
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var ssn: String = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var phone: String = ""
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var showUserInfoForm = false
    @State private var isCheckingExistingAccount = false
    @State private var existingAccount: UnitAccount? = nil
    @State private var showManualLinkAccount = false
    @State private var manualAccountId = ""
    
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.6, blue: 0.9),
                            Color(red: 0.3, green: 0.5, blue: 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 16) {
                // Success state or existing account
                if showSuccess || existingAccount != nil {
                    successView
                } else if let error = errorMessage, !error.isEmpty {
                    // Show error with retry option
                    errorView(message: error)
                } else {
                    // Main content
                    mainContent
                }
            }
            .padding(24)
        }
        .scaleEffect(bannerScale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                bannerScale = 1.0
            }
            // Verify token first
            Task {
                do {
                    let isValid = try await UnitService.shared.verifyToken()
                    if !isValid {
                        await MainActor.run {
                            errorMessage = "API token is invalid. Please check your Unit API token configuration."
                        }
                    }
                } catch {
                    print("⚠️ [UnitAccountCreationBanner] Token verification error: \(error)")
                }
            }
            // Check for existing account
            Task {
                await checkForExistingAccount()
            }
        }
        .sheet(isPresented: $showUserInfoForm) {
            NavigationView {
                UnitAccountInfoForm(
                    firstName: $firstName,
                    lastName: $lastName,
                    ssn: $ssn,
                    dateOfBirth: $dateOfBirth,
                    phone: $phone,
                    street: $street,
                    city: $city,
                    state: $state,
                    postalCode: $postalCode,
                    onComplete: {
                        showUserInfoForm = false
                        createAccount()
                    }
                )
            }
        }
        .sheet(isPresented: $showManualLinkAccount) {
            NavigationView {
                UnitAccountLinkForm(
                    accountId: $manualAccountId,
                    onComplete: {
                        showManualLinkAccount = false
                        linkAccountById(accountId: manualAccountId)
                    }
                )
            }
        }
    }
    
    private func linkAccountById(accountId: String) {
        guard !accountId.isEmpty else { return }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                if let account = try await UnitService.shared.getAccount(accountId: accountId) {
                    // Save account info
                    UserDefaults.standard.set(account.id, forKey: "unit_account_id")
                    UserDefaults.standard.set(account.accountNumber, forKey: "unit_account_number")
                    UserDefaults.standard.set(account.routingNumber, forKey: "unit_routing_number")
                    UserDefaults.standard.set(true, forKey: "unit_account_created")
                    
                    print("✅ [UnitAccountCreationBanner] Account linked: \(account.id)")
                    
                    await MainActor.run {
                        existingAccount = account
                        withAnimation {
                            showSuccess = true
                        }
                        isCreating = false
                    }
                } else {
                    // Account not found - check if they entered a Customer ID instead
                    // Try to find accounts for this ID as a customer
                    if let accounts = try? await UnitService.shared.findAccountsByCustomer(customerId: accountId),
                       !accounts.isEmpty {
                        await MainActor.run {
                            isCreating = false
                            errorMessage = """
                            You entered a Customer ID (\(accountId)), not an Account ID.
                            
                            This customer has \(accounts.count) account(s). To link an account:
                            1. Go to https://app.s.unit.sh/accounts
                            2. Find the account for customer \(accountId)
                            3. Copy the Account ID from the account page
                            4. Enter the Account ID (not Customer ID) in the form
                            
                            Or, if you want to create a new account for this customer, use the "Create My Account" option instead.
                            """
                        }
                    } else {
                        await MainActor.run {
                            isCreating = false
                            errorMessage = """
                            Account not found. Please check the Account ID.
                            
                            Note: You need an Account ID, not a Customer ID.
                            - Customer ID: Identifies the customer (e.g., 4036778)
                            - Account ID: Identifies the account (different format)
                            
                            To find your Account ID:
                            1. Go to https://app.s.unit.sh/accounts
                            2. Click on your account
                            3. Copy the Account ID from the URL or account details
                            
                            If you don't have an account yet, use "Create My Account" to create one first.
                            """
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Unable to link account: \(error.localizedDescription)"
                    print("❌ [UnitAccountCreationBanner] Error linking account: \(error)")
                }
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 16) {
            // Icon with sparkle animation
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "banknote.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                // Sparkle effect
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .offset(x: 50)
                        .rotationEffect(.degrees(Double(index) * 60 + sparkleRotation))
                }
            }
            .frame(height: 100)
            
            // Title
            Text("Your Dedicated Savings Account")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("Congratulations! You're taking the first step toward your financial goals. Create your protected savings account to start growing your money tree.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
                    // Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        benefitRow(icon: "checkmark.circle.fill", text: "FDIC-insured protection")
                        benefitRow(icon: "checkmark.circle.fill", text: "Separate from your checking account")
                        benefitRow(icon: "checkmark.circle.fill", text: "Track all your goals in one place")
                        benefitRow(icon: "checkmark.circle.fill", text: "Easy transfers via Plaid or account credentials")
                    }
                    .padding(.vertical, 8)
            
            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                // Create Account button
                Button(action: {
                    if UnitService.shared.isConfigured {
                        // Check if we have user info, if not show form
                        if firstName.isEmpty || lastName.isEmpty || ssn.isEmpty || phone.isEmpty || street.isEmpty {
                            showUserInfoForm = true
                        } else {
                            createAccount()
                        }
                    } else {
                        errorMessage = "Unit API is not configured. Please contact support."
                    }
                }) {
                    HStack {
                        if isCreating || isCheckingExistingAccount {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                        }
                        Text(isCheckingExistingAccount ? "Checking..." : (isCreating ? "Creating..." : "Create My Account"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.25))
                    )
                }
                .disabled(isCreating || isCheckingExistingAccount)
                
                // Link Existing Account button (if account exists in Unit but not linked)
                Button(action: {
                    showManualLinkAccount = true
                }) {
                    Text("Link Existing Account")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .underline()
                }
                .disabled(isCreating || isCheckingExistingAccount)
                
                // Maybe Later button
                Button(action: {
                    onDismiss()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .disabled(isCreating)
            }
        }
        .onAppear {
            // Animate sparkles
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            Text(existingAccount != nil ? "Account Connected!" : "Account Created!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            if let account = existingAccount {
                VStack(spacing: 8) {
                    Text("Your dedicated savings account is already set up.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                    
                    if !account.accountNumber.isEmpty {
                        Text("Account ending in \(String(account.accountNumber.suffix(4)))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 4)
                    }
                }
            } else {
                Text("Your dedicated savings account is ready. Start creating goals and watch your money tree grow!")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: {
                onDismiss()
            }) {
                Text("Get Started")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.25))
                    )
            }
        }
    }
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.9))
            
            Text("Account Setup")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {
                    errorMessage = nil
                }) {
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.25))
                        )
                }
                
                Button(action: {
                    onDismiss()
                }) {
                    Text("Continue Without Account")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
            
            Spacer()
        }
    }
    
    private func checkForExistingAccount() async {
        guard UnitService.shared.isConfigured else {
            return
        }
        
        guard let email = authService.autoUserEmail,
              let userId = authService.autoUserId else {
            return
        }
        
        isCheckingExistingAccount = true
        
        // First check UserDefaults
        if UserDefaults.standard.bool(forKey: "unit_account_created"),
           let accountId = UserDefaults.standard.string(forKey: "unit_account_id") {
            // Verify the account still exists
            if let account = try? await UnitService.shared.getAccount(accountId: accountId) {
                await MainActor.run {
                    existingAccount = account
                    isCheckingExistingAccount = false
                }
                return
            }
        }
        
        // Try to find existing account via API
        if let account = await UnitService.shared.findExistingAccount(email: email, userId: userId) {
            await MainActor.run {
                existingAccount = account
                isCheckingExistingAccount = false
            }
        } else {
            await MainActor.run {
                isCheckingExistingAccount = false
            }
        }
    }
    
    private func createAccount() {
        // Verify user is authenticated
        guard authService.isAuthenticated else {
            errorMessage = "Please sign in to create an account."
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            // Mark that user has seen the prompt
            UserDefaults.standard.set(true, forKey: "unit_account_creation_prompt_shown")
            
            // Auto-populate user information from AuthService
            guard let userId = authService.autoUserId,
                  let email = authService.autoUserEmail else {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Unable to get user information. Please sign in and try again."
                }
                return
            }
            
            // Verify Unit API is configured
            guard UnitService.shared.isConfigured else {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Unit API is not configured. Please contact support."
                }
                return
            }
            
            // Create customer and account
            do {
                let address = UnitAddress(
                    street: street,
                    city: city,
                    state: state,
                    postalCode: postalCode,
                    country: "US"
                )
                
                let customerId = try await UnitService.shared.createCustomer(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    ssn: ssn,
                    dateOfBirth: dateOfBirth,
                    phone: phone,
                    address: address
                )
                
                let account = try await UnitService.shared.createDepositAccount(
                    customerId: customerId,
                    userId: userId
                )
                
                // Save account info
                UserDefaults.standard.set(account.id, forKey: "unit_account_id")
                UserDefaults.standard.set(account.accountNumber, forKey: "unit_account_number")
                UserDefaults.standard.set(account.routingNumber, forKey: "unit_routing_number")
                UserDefaults.standard.set(true, forKey: "unit_account_created")
                
                print("✅ [UnitAccountCreationBanner] Account created successfully - ID: \(account.id)")
                
                await MainActor.run {
                    withAnimation {
                        showSuccess = true
                    }
                    isCreating = false
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    // User-friendly error message for demo
                    let userMessage: String
                    if let unitError = error as? UnitError {
                        switch unitError {
                        case .apiError(let message):
                            if message.contains("denied") || message.contains("Denied") {
                                userMessage = "Your application is being reviewed. This is normal for new accounts. You can continue using the app while we process your application."
                            } else if message.contains("401") || message.contains("unauthorized") {
                                userMessage = "Unable to verify your account. Please try again later or contact support."
                            } else {
                                userMessage = "We're setting up your account. Please try again in a few moments."
                            }
                        default:
                            userMessage = "We're setting up your account. Please try again in a few moments."
                        }
                    } else {
                        userMessage = "We're setting up your account. Please try again in a few moments."
                    }
                    errorMessage = userMessage
                    print("❌ [UnitAccountCreationBanner] Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Link Account Form

struct UnitAccountLinkForm: View {
    @Binding var accountId: String
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Link Existing Account")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If you already have a Unit account created in the dashboard, enter the Account ID to link it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Important: You need an Account ID, not a Customer ID")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                    
                    Text("To find your Account ID:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Text("1. Go to https://app.s.unit.sh/accounts\n2. Click on your account (not the customer page)\n3. Copy the Account ID from the URL (e.g., /accounts/12345678) or account details\n\nNote: If you only see a Customer page, you need to create an account first for that customer.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                TextField("Account ID", text: $accountId)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.default)
            }
            
            Section {
                Button("Link Account") {
                    onComplete()
                }
                .disabled(accountId.isEmpty)
            }
        }
        .navigationTitle("Link Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - User Info Form

struct UnitAccountInfoForm: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var ssn: String
    @Binding var dateOfBirth: Date
    @Binding var phone: String
    @Binding var street: String
    @Binding var city: String
    @Binding var state: String
    @Binding var postalCode: String
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("SSN", text: $ssn)
                    .keyboardType(.numberPad)
                TextField("Phone Number", text: $phone)
                    .keyboardType(.phonePad)
                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
            }
            
            Section(header: Text("Address")) {
                TextField("Street Address", text: $street)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("ZIP Code", text: $postalCode)
                    .keyboardType(.numberPad)
            }
            
            Section {
                Button("Continue") {
                    onComplete()
                }
                .disabled(firstName.isEmpty || lastName.isEmpty || ssn.isEmpty || phone.isEmpty || street.isEmpty || city.isEmpty || state.isEmpty || postalCode.isEmpty)
            }
        }
        .navigationTitle("Account Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    UnitAccountCreationBanner(onDismiss: {})
        .environmentObject(AuthService())
        .padding()
}

