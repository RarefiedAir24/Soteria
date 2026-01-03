//
//  ShareGoalView.swift
//  soteria
//
//  View for sharing goals via SMS and managing shared goal members
//

import SwiftUI
import MessageUI

struct ShareGoalView: View {
    let goal: SavingsGoal
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var sharedGoalService = SharedGoalService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @EnvironmentObject var authService: AuthService
    
    @State private var phoneNumber: String = ""
    @State private var customMessage: String = ""
    @State private var showMessageComposer = false
    @State private var isCreatingSharedGoal = false
    @State private var errorMessage: String? = nil
    @State private var showMembers = false
    
    // This view should only be shown to premium users (gated in GoalDetailView)
    // But add a check here as well for safety
    private var isPremium: Bool {
        subscriptionService.isPremium
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mistGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Goal Info Card
                        goalInfoCard
                        
                        // Share Section
                        if !goal.isShared {
                            shareSection
                        } else {
                            sharedGoalSection
                        }
                        
                        // Members Section (if shared)
                        if goal.isShared, let members = sharedGoalService.sharedGoals[goal.id], !members.isEmpty {
                            membersSection(members: members)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Share Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.midnightSlate)
                }
            }
            .sheet(isPresented: $showMessageComposer) {
                if MFMessageComposeViewController.canSendText() {
                    MessageComposeView(
                        recipients: [phoneNumber],
                        body: generateMessageBody()
                    )
                }
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
    
    // MARK: - Goal Info Card
    
    private var goalInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    Text("Target: \(formatCurrency(goal.targetAmount))")
                        .font(.system(size: 16))
                        .foregroundColor(.softGraphite)
                    
                    Text("Progress: \(Int(goal.progress * 100))%")
                        .font(.system(size: 14))
                        .foregroundColor(.reverBlue)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Share Section
    
    private var shareSection: some View {
        VStack(spacing: 16) {
            Text("Invite Others to Join")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Share this goal via SMS so others can contribute and track progress together.")
                .font(.system(size: 14))
                .foregroundColor(.softGraphite)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Phone Number")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.softGraphite)
                
                TextField("(555) 123-4567", text: $phoneNumber)
                    .font(.system(size: 16))
                    .foregroundColor(.midnightSlate)
                    .keyboardType(.phonePad)
                    .padding(14)
                    .background(Color.dreamMist)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Custom Message (Optional)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.softGraphite)
                
                TextField("Add a personal message...", text: $customMessage, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(.midnightSlate)
                    .lineLimit(3...5)
                    .padding(14)
                    .background(Color.dreamMist)
                    .cornerRadius(12)
            }
            
            Button(action: {
                shareGoal()
            }) {
                HStack {
                    if isCreatingSharedGoal {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "message.fill")
                        Text("Send Invitation")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isValidPhoneNumber ? Color.reverBlue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isValidPhoneNumber || isCreatingSharedGoal)
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Shared Goal Section
    
    private var sharedGoalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.reverBlue)
                Text("Shared Goal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                Spacer()
            }
            
            Text("This goal is shared with others. You can invite more people or manage members.")
                .font(.system(size: 14))
                .foregroundColor(.softGraphite)
            
            Button(action: {
                showMembers = true
            }) {
                HStack {
                    Image(systemName: "person.2.circle.fill")
                    Text("View Members")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.reverBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.reverBlue.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Members Section
    
    private func membersSection(members: [SharedGoalMember]) -> some View {
        VStack(spacing: 16) {
            Text("Members")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(members) { member in
                memberRow(member: member)
            }
        }
        .padding(20)
        .background(Color.cloudWhite)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 4)
    }
    
    private func memberRow(member: SharedGoalMember) -> some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color.reverBlue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String((member.displayName ?? member.email ?? "U").prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.reverBlue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName ?? member.email ?? "Member")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.midnightSlate)
                
                if member.role == .owner {
                    Text("Owner")
                        .font(.system(size: 12))
                        .foregroundColor(.reverBlue)
                } else {
                    Text("Contributed: \(formatCurrency(member.contributionAmount))")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.dreamMist)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private var isValidPhoneNumber: Bool {
        // Basic phone number validation
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleaned.count >= 10
    }
    
    // Check if goal can be shared (not completed or cancelled)
    private func canShareGoal() -> Bool {
        // Goals can be shared if they are active or failed
        // Cannot share if completed (achieved) or cancelled
        return goal.status == .active || goal.status == .failed
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func generateMessageBody() -> String {
        let baseMessage = "Hey! I'm saving for \(goal.name) ($\(String(format: "%.2f", goal.targetAmount))). Want to join me? "
        let deepLink = "soteria://goal/\(goal.id)/invite/\(sharedGoalService.pendingInvitations.last?.id ?? "")"
        let customMsg = customMessage.isEmpty ? "" : "\n\n\(customMessage)\n\n"
        let instructions = "\n\nTo join, you'll need to:\n1. Create your own Soteria account\n2. Connect your bank account\n3. Start contributing!\n\n"
        return "\(baseMessage)\(customMsg)\(instructions)Join here: \(deepLink)"
    }
    
    private func shareGoal() {
        guard isValidPhoneNumber else { return }
        
        // Check if goal can be shared (not completed or cancelled)
        guard canShareGoal() else {
            errorMessage = "This goal cannot be shared. Only active or in-progress goals can be shared."
            return
        }
        
        isCreatingSharedGoal = true
        errorMessage = nil
        
        Task {
            do {
                // First, create shared goal if not already shared
                if !goal.isShared {
                    _ = try await sharedGoalService.createSharedGoal(from: goal.id)
                }
                
                // Send invitation
                _ = try await sharedGoalService.sendInvitation(
                    goalId: goal.id,
                    phoneNumber: phoneNumber,
                    message: customMessage.isEmpty ? nil : customMessage
                )
                
                // Show SMS composer
                await MainActor.run {
                    isCreatingSharedGoal = false
                    showMessageComposer = true
                }
            } catch {
                await MainActor.run {
                    isCreatingSharedGoal = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Message Composer

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    ShareGoalView(goal: SavingsGoal(
        id: "test",
        name: "Trip to Hawaii",
        targetAmount: 2000,
        currentAmount: 500,
        category: .trip
    ))
}

