//
//  LoyaltyTransaction.swift
//  soteria
//
//  Model for loyalty points transaction history
//

import Foundation

struct LoyaltyTransaction: Codable, Identifiable {
    let id: String
    let type: TransactionType
    let points: Int // Positive for earned, negative for spent
    let balanceAfter: Int
    let timestamp: Date
    let description: String
    let metadata: TransactionMetadata?
    
    enum TransactionType: String, Codable {
        case earned = "earned"
        case spent = "spent"
        case bonus = "bonus"
        case adjustment = "adjustment" // Admin adjustments
    }
    
    struct TransactionMetadata: Codable {
        let depositAmount: Double?      // For saving-related points
        let itemId: String?              // For purchase-related points
        let itemName: String?            // Item purchased
        let streakBonus: Bool?           // If streak bonus applied
        let goalCompleted: Bool?         // If from goal completion
        let verificationConfidence: Double? // For screenshot verification
        let source: String?              // "plaid", "manual", "virtual", etc.
    }
    
    init(
        type: TransactionType,
        points: Int,
        balanceAfter: Int,
        description: String,
        metadata: TransactionMetadata? = nil,
        id: String? = nil,
        timestamp: Date? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.type = type
        self.points = points
        self.balanceAfter = balanceAfter
        self.timestamp = timestamp ?? Date()
        self.description = description
        self.metadata = metadata
    }
    
    // MARK: - Helper Properties
    
    var formattedPoints: String {
        let prefix = points > 0 ? "+" : ""
        return "\(prefix)\(points)"
    }
    
    var icon: String {
        switch type {
        case .earned:
            return "arrow.up.circle.fill"
        case .spent:
            return "arrow.down.circle.fill"
        case .bonus:
            return "star.circle.fill"
        case .adjustment:
            return "wrench.and.screwdriver.fill"
        }
    }
    
    var color: String {
        switch type {
        case .earned, .bonus:
            return "green"
        case .spent:
            return "red"
        case .adjustment:
            return "orange"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: timestamp)
    }
    
    var relativeDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(timestamp) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: timestamp))"
        } else if calendar.isDateInYesterday(timestamp) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Yesterday at \(formatter.string(from: timestamp))"
        } else if let days = calendar.dateComponents([.day], from: timestamp, to: now).day, days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE 'at' h:mm a"
            return formatter.string(from: timestamp)
        } else {
            return formattedDate
        }
    }
}

