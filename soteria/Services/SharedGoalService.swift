//
//  SharedGoalService.swift
//  soteria
//
//  Service for managing shared goals and invitations
//

import Foundation
import Combine

class SharedGoalService: ObservableObject {
    static let shared = SharedGoalService()
    
    @Published var sharedGoals: [String: [SharedGoalMember]] = [:] // goalId -> members
    @Published var pendingInvitations: [GoalInvitation] = []
    @Published var receivedInvitations: [GoalInvitation] = []
    
    private let cognitoService = CognitoAuthService.shared
    private let apiGatewayURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
    
    private init() {
        loadLocalData()
    }
    
    // MARK: - Data Persistence
    
    private func loadLocalData() {
        // Load shared goals from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "shared_goals"),
           let decoded = try? JSONDecoder().decode([String: [SharedGoalMember]].self, from: data) {
            sharedGoals = decoded
        }
        
        // Load invitations
        if let data = UserDefaults.standard.data(forKey: "goal_invitations"),
           let decoded = try? JSONDecoder().decode([GoalInvitation].self, from: data) {
            pendingInvitations = decoded.filter { $0.status == .pending }
        }
    }
    
    private func saveLocalData() {
        // Save shared goals
        if let data = try? JSONEncoder().encode(sharedGoals) {
            UserDefaults.standard.set(data, forKey: "shared_goals")
        }
        
        // Save invitations
        let allInvitations = pendingInvitations + receivedInvitations
        if let data = try? JSONEncoder().encode(allInvitations) {
            UserDefaults.standard.set(data, forKey: "goal_invitations")
        }
    }
    
    // MARK: - Create Shared Goal
    
    /// Convert a regular goal to a shared goal
    func createSharedGoal(from goalId: String) async throws -> String {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "SharedGoalService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Create shared goal on backend
        let url = URL(string: "\(apiGatewayURL)/soteria/shared-goal/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await cognitoService.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "user_id": userId,
            "goal_id": goalId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SharedGoalService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create shared goal"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let sharedGoalId = json["shared_goal_id"] as? String else {
            throw NSError(domain: "SharedGoalService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // Initialize members list with owner
        await MainActor.run {
            // Get user email from Cognito currentUser
            let userEmail = cognitoService.currentUser?.email
            let owner = SharedGoalMember(
                id: userId,
                email: userEmail,
                displayName: userEmail?.components(separatedBy: "@").first,
                contributionAmount: 0,
                role: .owner
            )
            sharedGoals[goalId] = [owner]
            saveLocalData()
        }
        
        return sharedGoalId
    }
    
    // MARK: - Invitations
    
    /// Send invitation via SMS
    func sendInvitation(goalId: String, phoneNumber: String, message: String? = nil) async throws -> GoalInvitation {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "SharedGoalService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Generate deep link
        let deepLink = "soteria://goal/\(goalId)/invite"
        
        // Create invitation on backend
        let url = URL(string: "\(apiGatewayURL)/soteria/shared-goal/invite")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await cognitoService.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let inviterName = cognitoService.currentUser?.email?.components(separatedBy: "@").first
        
        let requestBody: [String: Any] = [
            "goal_id": goalId,
            "inviter_user_id": userId,
            "inviter_name": inviterName ?? "Someone",
            "invitee_phone": phoneNumber,
            "deep_link": deepLink,
            "message": message ?? "Join me in saving for this goal!"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SharedGoalService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to send invitation"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let invitationData = json["invitation"] as? [String: Any] else {
            throw NSError(domain: "SharedGoalService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // Parse invitation
        let invitation = try parseInvitation(from: invitationData)
        
        await MainActor.run {
            pendingInvitations.append(invitation)
            saveLocalData()
        }
        
        return invitation
    }
    
    /// Accept an invitation
    func acceptInvitation(_ invitationId: String) async throws {
        guard let userId = cognitoService.getUserId() else {
            throw NSError(domain: "SharedGoalService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard receivedInvitations.contains(where: { $0.id == invitationId }) else {
            throw NSError(domain: "SharedGoalService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invitation not found"])
        }
        
        let url = URL(string: "\(apiGatewayURL)/soteria/shared-goal/accept")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await cognitoService.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "invitation_id": invitationId,
            "user_id": userId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SharedGoalService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to accept invitation"])
        }
        
        // Update local state
        await MainActor.run {
            if let index = receivedInvitations.firstIndex(where: { $0.id == invitationId }) {
                let updated = receivedInvitations[index]
                // Create updated invitation with accepted status
                receivedInvitations[index] = GoalInvitation(
                    id: updated.id,
                    goalId: updated.goalId,
                    inviterUserId: updated.inviterUserId,
                    inviterName: updated.inviterName,
                    inviteePhoneNumber: updated.inviteePhoneNumber,
                    inviteeEmail: updated.inviteeEmail,
                    status: .accepted,
                    createdAt: updated.createdAt,
                    expiresAt: updated.expiresAt,
                    deepLink: updated.deepLink
                )
            }
            saveLocalData()
        }
    }
    
    // MARK: - Members
    
    /// Get members for a goal
    func getMembers(for goalId: String) -> [SharedGoalMember] {
        return sharedGoals[goalId] ?? []
    }
    
    /// Add member to goal
    func addMember(_ member: SharedGoalMember, to goalId: String) {
        if sharedGoals[goalId] == nil {
            sharedGoals[goalId] = []
        }
        sharedGoals[goalId]?.append(member)
        saveLocalData()
    }
    
    /// Update member contribution
    func updateMemberContribution(goalId: String, memberId: String, amount: Double) {
        guard var members = sharedGoals[goalId] else { return }
        if let index = members.firstIndex(where: { $0.id == memberId }) {
            var member = members[index]
            member = SharedGoalMember(
                id: member.id,
                email: member.email,
                phoneNumber: member.phoneNumber,
                displayName: member.displayName,
                contributionAmount: member.contributionAmount + amount,
                isActive: member.isActive,
                joinedDate: member.joinedDate,
                role: member.role
            )
            members[index] = member
            sharedGoals[goalId] = members
            saveLocalData()
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseInvitation(from data: [String: Any]) throws -> GoalInvitation {
        guard let id = data["id"] as? String,
              let goalId = data["goal_id"] as? String,
              let inviterUserId = data["inviter_user_id"] as? String,
              let deepLink = data["deep_link"] as? String else {
            throw NSError(domain: "SharedGoalService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid invitation data"])
        }
        
        let statusString = data["status"] as? String ?? "pending"
        let status = GoalInvitation.InvitationStatus(rawValue: statusString) ?? .pending
        
        let createdAt = (data["created_at"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        let expiresAt = (data["expires_at"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) } ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return GoalInvitation(
            id: id,
            goalId: goalId,
            inviterUserId: inviterUserId,
            inviterName: data["inviter_name"] as? String,
            inviteePhoneNumber: data["invitee_phone"] as? String,
            inviteeEmail: data["invitee_email"] as? String,
            status: status,
            createdAt: createdAt,
            expiresAt: expiresAt,
            deepLink: deepLink
        )
    }
}

