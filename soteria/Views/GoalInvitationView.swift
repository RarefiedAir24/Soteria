//
//  GoalInvitationView.swift
//  soteria
//
//  View shown when user opens app from goal invitation deep link
//  Requires user to sign up/sign in and connect their own bank account
//

import SwiftUI

struct GoalInvitationView: View {
    let invitationId: String
    let goalId: String
    let inviterName: String?
    
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var sharedGoalService = SharedGoalService.shared
    @ObservedObject private var goalsService = GoalsService.shared
    
    @State private var isLoading = true
    @State private var invitation: GoalInvitation? = nil
    @State private var goal: SavingsGoal? = nil
    @State private var showPlaidConnection = false
    @State private var errorMessage: String? = nil
    @State private var isAccepting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading invitation...")
                            .font(.system(size: 16))
                            .foregroundColor(.softGraphite)
                    }
                } else if let invitation = invitation, let goal = goal {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Invitation Header
                            invitationHeader(invitation: invitation, goal: goal)
                            
                            // Authentication Check
                            if !authService.isAuthenticated {
                                signUpRequiredSection
                            } else {
                                // Check if user has Plaid connected
                                if !hasPlaidConnected {
                                    plaidConnectionRequiredSection
                                } else {
                                    acceptInvitationSection(invitation: invitation)
                                }
                            }
                        }
                        .padding(20)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Invitation Not Found")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        Text("This invitation may have expired or been cancelled.")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                }
            }
            .navigationTitle("Goal Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.midnightSlate)
                }
            }
            .onAppear {
                loadInvitation()
            }
            .sheet(isPresented: $showPlaidConnection) {
                // Show Plaid connection view
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Invitation Header
    
    private func invitationHeader(invitation: GoalInvitation, goal: SavingsGoal) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundColor(.softGraphite)
            
            Text("You've been invited!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.midnightSlate)
            
            if let inviterName = invitation.inviterName {
                Text("\(inviterName) invited you to join their savings goal")
                    .font(.system(size: 16))
                    .foregroundColor(.softGraphite)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Goal Info
            VStack(alignment: .leading, spacing: 12) {
                Text(goal.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Text("Target: \(formatCurrency(goal.targetAmount))")
                    .font(.system(size: 16))
                    .foregroundColor(.softGraphite)
                
                if let targetDate = goal.targetDate {
                    Text("By: \(targetDate, style: .date)")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.cloudWhite)
            .cornerRadius(16)
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Sign Up Required Section
    
    private var signUpRequiredSection: some View {
        VStack(spacing: 16) {
            Text("Create Your Account")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("To join this shared goal, you'll need to create your own Soteria account. Each member uses their own account and bank connection to contribute to the goal.")
                .font(.system(size: 14))
                .foregroundColor(.softGraphite)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("You'll need to create your own Soteria account to join this shared goal. Each member uses their own account and bank connection.")
                .font(.system(size: 13))
                .foregroundColor(.softGraphite)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            
            Text("Please sign in or create an account to continue.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Plaid Connection Required Section
    
    private var plaidConnectionRequiredSection: some View {
        VStack(spacing: 16) {
            Text("Connect Your Bank Account")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("To contribute to this shared goal, you'll need to connect your own bank account. Each member uses their own bank account to make deposits.")
                .font(.system(size: 14))
                .foregroundColor(.softGraphite)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                showPlaidConnection = true
            }) {
                HStack {
                    Image(systemName: "banknote.fill")
                    Text("Connect Bank Account")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.softGraphite)
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Accept Invitation Section
    
    private func acceptInvitationSection(invitation: GoalInvitation) -> some View {
        VStack(spacing: 16) {
            Text("Ready to Join?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("You're all set! Here's how it works:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.softGraphite)
                        Text("You'll use your own bank account to make deposits")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.softGraphite)
                        Text("Your contributions are tracked separately from other members")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.softGraphite)
                        Text("You can see everyone's progress toward the shared goal")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                acceptInvitation()
            }) {
                HStack {
                    if isAccepting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Accept Invitation")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isAccepting ? Color.gray : Color.softGraphite)
                .cornerRadius(12)
            }
            .disabled(isAccepting)
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    private var hasPlaidConnected: Bool {
        // Check if user has Plaid connected (has at least one connected account)
        return !PlaidService.shared.connectedAccounts.isEmpty
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func loadInvitation() {
        Task {
            // Load invitation from backend
            // For now, create a mock invitation
            await MainActor.run {
                // In production, fetch from backend
                isLoading = false
            }
        }
    }
    
    private func acceptInvitation() {
        guard let invitation = invitation else { return }
        
        isAccepting = true
        errorMessage = nil
        
        Task {
            do {
                try await sharedGoalService.acceptInvitation(invitation.id)
                
                // Add user as member to the goal
                if let userId = authService.currentUserId {
                    let member = SharedGoalMember(
                        id: userId,
                        email: authService.currentUserEmail,
                        displayName: authService.currentUserEmail?.components(separatedBy: "@").first,
                        contributionAmount: 0,
                        role: .member
                    )
                    sharedGoalService.addMember(member, to: goalId)
                }
                
                await MainActor.run {
                    isAccepting = false
                    // Navigate to goal detail view
                }
            } catch {
                await MainActor.run {
                    isAccepting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    GoalInvitationView(
        invitationId: "test",
        goalId: "goal123",
        inviterName: "John"
    )
    .environmentObject(AuthService())
}

