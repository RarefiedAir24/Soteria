//
//  SharedGoal.swift
//  soteria
//
//  Model for multi-user shared goals with invitation system
//

import Foundation

struct SharedGoalMember: Identifiable, Codable {
    let id: String // User ID
    let email: String?
    let phoneNumber: String?
    let displayName: String?
    var contributionAmount: Double // How much this member has contributed
    var isActive: Bool // Whether member is actively participating
    let joinedDate: Date
    var role: MemberRole
    
    enum MemberRole: String, Codable {
        case owner = "owner" // Goal creator
        case member = "member" // Regular participant
    }
    
    init(id: String, email: String? = nil, phoneNumber: String? = nil, displayName: String? = nil, contributionAmount: Double = 0, isActive: Bool = true, joinedDate: Date = Date(), role: MemberRole = .member) {
        self.id = id
        self.email = email
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.contributionAmount = contributionAmount
        self.isActive = isActive
        self.joinedDate = joinedDate
        self.role = role
    }
}

struct GoalInvitation: Identifiable, Codable {
    let id: String
    let goalId: String
    let inviterUserId: String
    let inviterName: String?
    let inviteePhoneNumber: String?
    let inviteeEmail: String?
    let status: InvitationStatus
    let createdAt: Date
    let expiresAt: Date
    let deepLink: String // URL to accept invitation
    
    enum InvitationStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        case expired = "expired"
    }
    
    init(id: String = UUID().uuidString,
         goalId: String,
         inviterUserId: String,
         inviterName: String? = nil,
         inviteePhoneNumber: String? = nil,
         inviteeEmail: String? = nil,
         status: InvitationStatus = .pending,
         createdAt: Date = Date(),
         expiresAt: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
         deepLink: String) {
        self.id = id
        self.goalId = goalId
        self.inviterUserId = inviterUserId
        self.inviterName = inviterName
        self.inviteePhoneNumber = inviteePhoneNumber
        self.inviteeEmail = inviteeEmail
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.deepLink = deepLink
    }
}

// Extension to SavingsGoal to support shared goals
extension SavingsGoal {
    var isShared: Bool {
        return sharedGoalId != nil
    }
    
    var memberCount: Int {
        // Get member count from SharedGoalService
        if sharedGoalId != nil {
            return SharedGoalService.shared.getMembers(for: id).count
        }
        return 1 // Default to 1 for single-user goals
    }
}

