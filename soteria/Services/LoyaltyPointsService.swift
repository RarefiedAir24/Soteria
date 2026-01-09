//
//  LoyaltyPointsService.swift
//  soteria
//
//  Manages loyalty points earned through savings
//  Points can be redeemed for money tree scene decorations
//

import Foundation
import Combine

@MainActor
class LoyaltyPointsService: ObservableObject {
    static let shared = LoyaltyPointsService()
    
    // MARK: - Published Properties
    @Published var totalPoints: Int = 0
    @Published var lifetimePointsEarned: Int = 0
    @Published var purchasedItemIds: Set<String> = []
    @Published var transactionHistory: [LoyaltyTransaction] = []
    
    // MARK: - Constants
    private let pointsKey = "loyalty_points_total"
    private let lifetimePointsKey = "loyalty_points_lifetime"
    private let purchasedItemsKey = "loyalty_purchased_items"
    private let transactionsKey = "loyalty_transactions"
    private let maxTransactionHistory = 500 // Keep last 500 transactions
    
    // MARK: - Point Earning Rates
    // ⚠️ TUNING PARAMETERS: Adjust these to control point economy
    private let pointsPerDollarSaved = 1.0        // Base rate: $1 saved = 1 point
    private let bonusPointsPerGoalCompleted = 500 // Bonus for completing a goal
    private let streakBonusMultiplier = 1.5       // 50% bonus for consistent saving
    
    // MARK: - Initialization
    private init() {
        loadPoints()
        loadPurchasedItems()
        loadTransactions()
    }
    
    // MARK: - Point Management
    
    /// Award points for saving money
    /// - Parameters:
    ///   - amount: Dollar amount saved
    ///   - hasStreak: Whether user has an active saving streak
    ///   - source: Source of the deposit (e.g., "plaid", "manual", "virtual")
    func awardPointsForSaving(amount: Double, hasStreak: Bool = false, source: String = "unknown") {
        let basePoints = Int(amount * pointsPerDollarSaved)
        var pointsEarned = basePoints
        
        // Apply streak bonus if applicable
        if hasStreak {
            pointsEarned = Int(Double(pointsEarned) * streakBonusMultiplier)
        }
        
        let description = hasStreak 
            ? "Saved $\(String(format: "%.2f", amount)) with streak bonus"
            : "Saved $\(String(format: "%.2f", amount))"
        
        let metadata = LoyaltyTransaction.TransactionMetadata(
            depositAmount: amount,
            itemId: nil,
            itemName: nil,
            streakBonus: hasStreak,
            goalCompleted: false,
            verificationConfidence: nil,
            source: source
        )
        
        addPoints(pointsEarned, type: .earned, description: description, metadata: metadata)
        
        print("💰 Loyalty: Earned \(pointsEarned) points for saving $\(amount)")
    }
    
    /// Award bonus points for completing a goal
    func awardPointsForGoalCompletion(goalName: String = "Savings Goal") {
        let metadata = LoyaltyTransaction.TransactionMetadata(
            depositAmount: nil,
            itemId: nil,
            itemName: nil,
            streakBonus: false,
            goalCompleted: true,
            verificationConfidence: nil,
            source: "goal_completion"
        )
        
        addPoints(
            bonusPointsPerGoalCompleted,
            type: .bonus,
            description: "Completed \(goalName)!",
            metadata: metadata
        )
        
        print("🎯 Loyalty: Earned \(bonusPointsPerGoalCompleted) points for completing a goal!")
    }
    
    /// Add points to user's balance with transaction logging
    private func addPoints(
        _ points: Int,
        type: LoyaltyTransaction.TransactionType = .earned,
        description: String,
        metadata: LoyaltyTransaction.TransactionMetadata? = nil
    ) {
        totalPoints += points
        if points > 0 {
            lifetimePointsEarned += points
        }
        
        // Log transaction
        let transaction = LoyaltyTransaction(
            type: type,
            points: points,
            balanceAfter: totalPoints,
            description: description,
            metadata: metadata
        )
        transactionHistory.insert(transaction, at: 0) // Add to front (newest first)
        
        // Trim history if too long
        if transactionHistory.count > maxTransactionHistory {
            transactionHistory = Array(transactionHistory.prefix(maxTransactionHistory))
        }
        
        savePoints()
        saveTransactions()
        
        // Sync to AWS in background
        Task {
            await syncToAWS()
        }
    }
    
    /// Award points from verified screenshot deposits
    /// Called by ScreenshotVerificationService after successful verification
    func addPointsManual(_ points: Int, confidence: Double = 0.0) {
        let metadata = LoyaltyTransaction.TransactionMetadata(
            depositAmount: nil,
            itemId: nil,
            itemName: nil,
            streakBonus: false,
            goalCompleted: false,
            verificationConfidence: confidence,
            source: "manual_screenshot"
        )
        
        addPoints(
            points,
            type: .earned,
            description: "Verified manual deposit (\(Int(confidence * 100))% confidence)",
            metadata: metadata
        )
        
        print("✅ [LoyaltyPoints] Awarded \(points) points from verified screenshot")
    }
    
    /// Spend points on an item
    /// - Parameters:
    ///   - cost: Point cost of the item
    ///   - itemId: Unique identifier for the item
    ///   - itemName: Display name of the item
    /// - Returns: True if purchase was successful
    func purchaseItem(cost: Int, itemId: String, itemName: String = "Scene Item") -> Bool {
        guard totalPoints >= cost else {
            print("❌ Loyalty: Insufficient points. Need \(cost), have \(totalPoints)")
            return false
        }
        
        guard !purchasedItemIds.contains(itemId) else {
            print("⚠️ Loyalty: Item \(itemId) already purchased")
            return false
        }
        
        purchasedItemIds.insert(itemId)
        
        // Log transaction (negative points for spending)
        let metadata = LoyaltyTransaction.TransactionMetadata(
            depositAmount: nil,
            itemId: itemId,
            itemName: itemName,
            streakBonus: false,
            goalCompleted: false,
            verificationConfidence: nil,
            source: "loyalty_shop"
        )
        
        addPoints(
            -cost,
            type: .spent,
            description: "Purchased \(itemName)",
            metadata: metadata
        )
        
        savePurchasedItems()
        
        print("✅ Loyalty: Purchased item \(itemId) for \(cost) points")
        return true
    }
    
    /// Check if user has purchased an item
    func hasPurchased(itemId: String) -> Bool {
        return purchasedItemIds.contains(itemId)
    }
    
    // MARK: - Persistence
    
    private func loadPoints() {
        totalPoints = UserDefaults.standard.integer(forKey: pointsKey)
        lifetimePointsEarned = UserDefaults.standard.integer(forKey: lifetimePointsKey)
    }
    
    private func savePoints() {
        UserDefaults.standard.set(totalPoints, forKey: pointsKey)
        UserDefaults.standard.set(lifetimePointsEarned, forKey: lifetimePointsKey)
        
        // Sync to AWS in background
        Task {
            await syncToAWS()
        }
    }
    
    private func loadPurchasedItems() {
        if let data = UserDefaults.standard.data(forKey: purchasedItemsKey),
           let items = try? JSONDecoder().decode(Set<String>.self, from: data) {
            purchasedItemIds = items
        }
    }
    
    private func savePurchasedItems() {
        if let data = try? JSONEncoder().encode(purchasedItemIds) {
            UserDefaults.standard.set(data, forKey: purchasedItemsKey)
        }
        
        // Sync to AWS in background
        Task {
            await syncToAWS()
        }
    }
    
    private func loadTransactions() {
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let transactions = try? JSONDecoder().decode([LoyaltyTransaction].self, from: data) {
            transactionHistory = transactions
        }
    }
    
    private func saveTransactions() {
        if let data = try? JSONEncoder().encode(transactionHistory) {
            UserDefaults.standard.set(data, forKey: transactionsKey)
        }
    }
    
    // MARK: - AWS Cloud Sync
    
    /// Sync loyalty data to AWS
    func syncToAWS() async {
        let data = LoyaltyData(
            totalPoints: totalPoints,
            lifetimePointsEarned: lifetimePointsEarned,
            purchasedItemIds: Array(purchasedItemIds)
        )
        
        do {
            try await AWSDataService.shared.syncData(data, dataType: .loyaltyPoints)
            print("✅ Loyalty: Synced to AWS - Points: \(totalPoints), Lifetime: \(lifetimePointsEarned), Items: \(purchasedItemIds.count)")
        } catch {
            // Silently fail AWS sync - local UserDefaults is source of truth
            // This allows offline usage and development/testing without AWS access
            #if DEBUG
            print("⚠️ Loyalty: AWS sync unavailable (data saved locally)")
            #endif
        }
    }
    
    /// Load loyalty data from AWS (if local data is empty)
    func loadFromAWS() async {
        // Only load from AWS if we have no local data
        guard totalPoints == 0 && lifetimePointsEarned == 0 && purchasedItemIds.isEmpty else {
            print("ℹ️ Loyalty: Local data exists, skipping AWS load")
            return
        }
        
        do {
            let dataArray: [LoyaltyData] = try await AWSDataService.shared.getData(dataType: .loyaltyPoints)
            
            guard let data = dataArray.first else {
                print("ℹ️ Loyalty: No data in AWS")
                return
            }
            
            // Update local data
            await MainActor.run {
                self.totalPoints = data.totalPoints
                self.lifetimePointsEarned = data.lifetimePointsEarned
                self.purchasedItemIds = Set(data.purchasedItemIds)
                
                // Save to UserDefaults
                savePoints()
                savePurchasedItems()
                
                print("✅ Loyalty: Loaded from AWS - Points: \(totalPoints), Lifetime: \(lifetimePointsEarned), Items: \(purchasedItemIds.count)")
            }
        } catch {
            print("ℹ️ Loyalty: No data in AWS or failed to load: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Debug / Admin
    
    /// Reset all points and purchases (for testing)
    func resetAll() {
        totalPoints = 0
        lifetimePointsEarned = 0
        purchasedItemIds.removeAll()
        savePoints()
        savePurchasedItems()
        Task {
            await syncToAWS()
        }
        print("🔄 Loyalty: Reset all points and purchases")
    }
}

// MARK: - Loyalty Data Model for AWS Sync
struct LoyaltyData: Codable {
    let totalPoints: Int
    let lifetimePointsEarned: Int
    let purchasedItemIds: [String]
}

