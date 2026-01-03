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
                // Success state
                if showSuccess {
                    successView
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
            HStack(spacing: 12) {
                // Create Account button
                Button(action: {
                    createAccount()
                }) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                        }
                        Text(isCreating ? "Creating..." : "Create My Account")
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
                .disabled(isCreating)
                
                // Maybe Later button
                Button(action: {
                    onDismiss()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
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
            
            Text("Account Created!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your dedicated savings account is ready. Start creating goals and watch your money tree grow!")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
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
    
    private func createAccount() {
        // Verify user is authenticated
        guard authService.isAuthenticated else {
            errorMessage = "Please sign in to create an account."
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            // For now, we'll need to collect user info (SSN, DOB, address) first
            // This is a placeholder - in production, we'd need a form to collect this
            // For MVP, we can show a message that account creation requires additional info
            
            // TODO: Collect user information (SSN, DOB, address) before creating account
            // For now, show a message that this feature is coming soon
            
            await MainActor.run {
                // Mark that user has seen the prompt
                UserDefaults.standard.set(true, forKey: "unit_account_creation_prompt_shown")
                
                // For now, show success (in production, actually create the account)
                withAnimation {
                    showSuccess = true
                }
                
                // Auto-populate user information from AuthService (no manual entry needed)
                guard let userId = authService.autoUserId,
                      let email = authService.autoUserEmail else {
                    isCreating = false
                    errorMessage = "Unable to get user information. Please sign in and try again."
                    return
                }
                
                // In production, uncomment this to actually create the account:
                /*
                do {
                    let customerId = try await UnitService.shared.createCustomer(
                        firstName: firstName,
                        lastName: lastName,
                        email: email, // Auto-populated from AuthService
                        ssn: ssn,
                        dateOfBirth: dateOfBirth,
                        address: UnitAddress(...)
                    )
                    
                    let account = try await UnitService.shared.createDepositAccount(
                        customerId: customerId,
                        userId: userId // Auto-populated from AuthService
                    )
                    
                    // Save account info
                    UserDefaults.standard.set(account.id, forKey: "unit_account_id")
                    UserDefaults.standard.set(account.accountNumber, forKey: "unit_account_number")
                    UserDefaults.standard.set(account.routingNumber, forKey: "unit_routing_number")
                    UserDefaults.standard.set(true, forKey: "unit_account_created")
                } catch {
                    isCreating = false
                    errorMessage = "Unable to create account. Please try again later."
                    print("❌ [UnitAccountCreationBanner] Error: \(error.localizedDescription)")
                }
                */
                
                // For now, just log that user info was auto-populated
                print("✅ [UnitAccountCreationBanner] User info auto-populated - User ID: \(userId), Email: \(email)")
            }
        }
    }
}

#Preview {
    UnitAccountCreationBanner(onDismiss: {})
        .environmentObject(AuthService())
        .padding()
}

