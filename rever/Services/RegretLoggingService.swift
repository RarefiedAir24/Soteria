//
//  RegretLoggingService.swift
//  rever
//
//  User-reported regret purchases with recovery guidance
//

import Foundation
import Combine

struct RegretEntry: Identifiable, Codable {
    let id: String
    var date: Date
    var amount: Double?
    var merchant: String?
    var category: String?
    var reason: String // Why was this a regret?
    var mood: MoodLevel
    var canReturn: Bool?
    var returnStatus: ReturnStatus?
    var recoveryActions: [RecoveryAction]
    
    enum ReturnStatus: String, Codable {
        case notAttempted = "not_attempted"
        case inProgress = "in_progress"
        case returned = "returned"
        case cannotReturn = "cannot_return"
        case expired = "expired"
        
        var displayName: String {
            switch self {
            case .notAttempted: return "Not Attempted"
            case .inProgress: return "In Progress"
            case .returned: return "Returned"
            case .cannotReturn: return "Cannot Return"
            case .expired: return "Expired"
            }
        }
    }
    
    enum RecoveryAction: String, Codable {
        case checkReturnPolicy = "check_return_policy"
        case cancelOrder = "cancel_order"
        case requestRefund = "request_refund"
        case sellItem = "sell_item"
        case giftItem = "gift_item"
        case learnFromIt = "learn_from_it"
        
        var displayName: String {
            switch self {
            case .checkReturnPolicy: return "Check Return Policy"
            case .cancelOrder: return "Cancel Order"
            case .requestRefund: return "Request Refund"
            case .sellItem: return "Sell Item"
            case .giftItem: return "Gift Item"
            case .learnFromIt: return "Learn From It"
            }
        }
        
        var guidance: String {
            switch self {
            case .checkReturnPolicy: return "Check the merchant's return policy. Most retailers allow returns within 14-30 days with receipt."
            case .cancelOrder: return "If the order hasn't shipped, you may be able to cancel it from your account or by contacting customer service."
            case .requestRefund: return "Contact customer service to request a refund. Be polite and explain your situation."
            case .sellItem: return "Consider selling the item on marketplace apps like Facebook Marketplace, OfferUp, or Poshmark."
            case .giftItem: return "If you can't return it, consider gifting it to someone who would appreciate it."
            case .learnFromIt: return "Reflect on what triggered this purchase. Use this insight to prevent future regrets."
            }
        }
    }
    
    init(id: String = UUID().uuidString, date: Date = Date(), amount: Double? = nil, merchant: String? = nil, category: String? = nil, reason: String, mood: MoodLevel, canReturn: Bool? = nil, returnStatus: ReturnStatus? = nil, recoveryActions: [RecoveryAction] = []) {
        self.id = id
        self.date = date
        self.amount = amount
        self.merchant = merchant
        self.category = category
        self.reason = reason
        self.mood = mood
        self.canReturn = canReturn
        self.returnStatus = returnStatus
        self.recoveryActions = recoveryActions
    }
}

struct ReturnGuidance {
    let merchant: String
    let returnWindow: String
    let requirements: [String]
    let steps: [String]
    let contactInfo: String?
    
    static func guidance(for merchant: String) -> ReturnGuidance? {
        let lowercased = merchant.lowercased()
        
        if lowercased.contains("amazon") {
            return ReturnGuidance(
                merchant: "Amazon",
                returnWindow: "30 days for most items",
                requirements: ["Original packaging", "Proof of purchase"],
                steps: [
                    "Go to Your Orders",
                    "Select the item",
                    "Click 'Return or Replace Items'",
                    "Choose return reason",
                    "Print return label",
                    "Drop off at UPS or schedule pickup"
                ],
                contactInfo: "Amazon Customer Service: 1-888-280-4331"
            )
        } else if lowercased.contains("doordash") || lowercased.contains("door dash") {
            return ReturnGuidance(
                merchant: "DoorDash",
                returnWindow: "Cancel within minutes of order",
                requirements: ["Order confirmation"],
                steps: [
                    "Open DoorDash app",
                    "Go to Orders",
                    "Select active order",
                    "Tap 'Cancel Order'",
                    "Contact support if cancellation window passed"
                ],
                contactInfo: "DoorDash Support: Available in app"
            )
        } else if lowercased.contains("target") {
            return ReturnGuidance(
                merchant: "Target",
                returnWindow: "90 days for most items",
                requirements: ["Receipt or card used for purchase"],
                steps: [
                    "Bring item and receipt to store",
                    "Go to Guest Services",
                    "Request return",
                    "Get refund to original payment method"
                ],
                contactInfo: "Target Guest Services: 1-800-440-0680"
            )
        } else if lowercased.contains("walmart") {
            return ReturnGuidance(
                merchant: "Walmart",
                returnWindow: "90 days for most items",
                requirements: ["Receipt or order confirmation"],
                steps: [
                    "Bring item and receipt to store",
                    "Go to Customer Service",
                    "Request return",
                    "Get refund to original payment method"
                ],
                contactInfo: "Walmart Customer Service: 1-800-925-6278"
            )
        }
        
        return nil
    }
}

class RegretLoggingService: ObservableObject {
    static let shared = RegretLoggingService()
    
    @Published var regretEntries: [RegretEntry] = []
    @Published var totalRegretAmount: Double = 0.0
    @Published var recentRegretCount: Int = 0
    
    private let regretsKey = "regret_entries"
    private let quietHoursService = QuietHoursService.shared
    
    private init() {
        loadRegrets()
        updateStats()
    }
    
    // Load regrets from UserDefaults
    private func loadRegrets() {
        if let data = UserDefaults.standard.data(forKey: regretsKey),
           let decoded = try? JSONDecoder().decode([RegretEntry].self, from: data) {
            regretEntries = decoded
        }
    }
    
    // Save regrets to UserDefaults
    private func saveRegrets() {
        if let encoded = try? JSONEncoder().encode(regretEntries) {
            UserDefaults.standard.set(encoded, forKey: regretsKey)
        }
    }
    
    // Update statistics
    private func updateStats() {
        totalRegretAmount = regretEntries.compactMap { $0.amount }.reduce(0, +)
        
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        recentRegretCount = regretEntries.filter { $0.date >= weekAgo }.count
    }
    
    // Add a regret entry
    func addRegret(_ entry: RegretEntry) {
        regretEntries.append(entry)
        saveRegrets()
        updateStats()
        
        // Auto-suggest recovery actions
        suggestRecoveryActions(for: entry)
        
        // Optionally activate quiet hours for next 24-48 hours
        if entry.mood.regretRisk > 0.7 {
            suggestQuietHoursActivation()
        }
    }
    
    // Update a regret entry
    func updateRegret(_ entry: RegretEntry) {
        if let index = regretEntries.firstIndex(where: { $0.id == entry.id }) {
            regretEntries[index] = entry
            saveRegrets()
            updateStats()
        }
    }
    
    // Delete a regret entry
    func deleteRegret(_ entry: RegretEntry) {
        regretEntries.removeAll { $0.id == entry.id }
        saveRegrets()
        updateStats()
    }
    
    // Suggest recovery actions based on merchant
    private func suggestRecoveryActions(for entry: RegretEntry) {
        guard let merchant = entry.merchant else { return }
        
        var actions: [RegretEntry.RecoveryAction] = []
        
        if let guidance = ReturnGuidance.guidance(for: merchant) {
            if guidance.merchant.lowercased().contains("amazon") {
                actions.append(.checkReturnPolicy)
                actions.append(.requestRefund)
            } else if guidance.merchant.lowercased().contains("doordash") {
                actions.append(.cancelOrder)
            } else {
                actions.append(.checkReturnPolicy)
                actions.append(.requestRefund)
            }
        } else {
            actions.append(.checkReturnPolicy)
        }
        
        actions.append(.learnFromIt)
        
        // Update entry with suggested actions
        var updatedEntry = entry
        updatedEntry.recoveryActions = actions
        updateRegret(updatedEntry)
    }
    
    // Suggest quiet hours activation after high-risk regret
    private func suggestQuietHoursActivation() {
        // This could trigger a notification or UI suggestion
        // For now, just log it
        print("💡 [RegretLoggingService] Suggesting Quiet Hours activation after high-risk regret")
    }
    
    // Get return guidance for a merchant
    func getReturnGuidance(for merchant: String) -> ReturnGuidance? {
        return ReturnGuidance.guidance(for: merchant)
    }
    
    // Get regrets by category
    func getRegretsByCategory() -> [String: [RegretEntry]] {
        Dictionary(grouping: regretEntries) { $0.category ?? "Other" }
    }
    
    // Get regrets by mood
    func getRegretsByMood() -> [MoodLevel: [RegretEntry]] {
        Dictionary(grouping: regretEntries) { $0.mood }
    }
}

