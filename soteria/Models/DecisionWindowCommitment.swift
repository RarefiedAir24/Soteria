//
//  DecisionWindowCommitment.swift
//  soteria
//
//  User commitments made during Decision Windows
//

import Foundation

enum CommitmentType: String, Codable {
    case microSave = "micro_save" // Option A: Immediate save
    case spendGate = "spend_gate" // Option B: Conditional save
    case pauseIntention = "pause_intention" // Option C: Reflection reminder
}

struct DecisionWindowCommitment: Identifiable, Codable {
    let id: String
    let windowId: String // Which Decision Window this commitment is for
    let type: CommitmentType
    let createdAt: Date
    let expiresAt: Date // End of day or window period
    
    // Option A: Micro-Save
    var microSaveAmount: Double?
    var microSaveExecuted: Bool = false
    
    // Option B: Spend Gate
    var spendGate: SpendGate?
    var spendGateTriggered: Bool = false
    var spendGateExecuted: Bool = false
    
    // Option C: Pause Intention
    var pauseIntention: String?
    var pauseIntentionReminderSent: Bool = false
    
    init(id: String = UUID().uuidString,
         windowId: String,
         type: CommitmentType,
         createdAt: Date = Date(),
         expiresAt: Date,
         microSaveAmount: Double? = nil,
         spendGate: SpendGate? = nil,
         pauseIntention: String? = nil) {
        self.id = id
        self.windowId = windowId
        self.type = type
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.microSaveAmount = microSaveAmount
        self.spendGate = spendGate
        self.pauseIntention = pauseIntention
    }
    
    // Check if commitment is still active (not expired)
    var isActive: Bool {
        Date() < expiresAt
    }
    
    // Check if commitment needs to be executed
    var needsExecution: Bool {
        switch type {
        case .microSave:
            return !microSaveExecuted && microSaveAmount != nil
        case .spendGate:
            return spendGateTriggered && !spendGateExecuted && spendGate != nil
        case .pauseIntention:
            return !pauseIntentionReminderSent && pauseIntention != nil
        }
    }
}

