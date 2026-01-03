//
//  DecisionWindowEvent.swift
//  soteria
//
//  Event tracking for Decision Window engagement
//  Privacy-first: Only aggregates stored, not raw events
//

import Foundation

/// Tracks user engagement with Decision Windows
struct DecisionWindowEvent: Identifiable, Codable {
    let id: String
    let windowId: String
    let timestamp: Date
    let opened: Bool // Did user open the window?
    let completedAction: WindowAction?
    let suggestedAmount: Double?
    let chosenAmount: Double?
    
    enum WindowAction: String, Codable {
        case saveFirst = "SAVE_FIRST"
        case protect = "PROTECT"
        case remindOnly = "REMIND_ONLY"
        case notToday = "NOT_TODAY"
    }
    
    init(id: String = UUID().uuidString,
         windowId: String,
         timestamp: Date = Date(),
         opened: Bool,
         completedAction: WindowAction? = nil,
         suggestedAmount: Double? = nil,
         chosenAmount: Double? = nil) {
        self.id = id
        self.windowId = windowId
        self.timestamp = timestamp
        self.opened = opened
        self.completedAction = completedAction
        self.suggestedAmount = suggestedAmount
        self.chosenAmount = chosenAmount
    }
}

/// Tracks savings transfer results
struct SavingsTransferEvent: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let amount: Double
    let source: TransferSource
    let result: TransferResult
    
    enum TransferSource: String, Codable {
        case decisionWindow = "DECISION_WINDOW"
        case conditionalRule = "CONDITIONAL_RULE"
        case manual = "MANUAL"
    }
    
    enum TransferResult: String, Codable {
        case success = "SUCCESS"
        case failedInsufficientFunds = "FAILED_INSUFFICIENT_FUNDS"
        case failedOther = "FAILED_OTHER"
    }
    
    init(id: String = UUID().uuidString,
         timestamp: Date = Date(),
         amount: Double,
         source: TransferSource,
         result: TransferResult) {
        self.id = id
        self.timestamp = timestamp
        self.amount = amount
        self.source = source
        self.result = result
    }
}

