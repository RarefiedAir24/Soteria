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
    @Published var isLoyaltyEnabled: Bool = false
    
    // MARK: - Constants
    private let pointsKey = "loyalty_points_total"
    private let lifetimePointsKey = "loyalty_points_lifetime"
    private let purchasedItemsKey = "loyalty_purchased_items"
    private let transactionsKey = "loyalty_transactions"
    private let maxTransactionHistory = 500 // Keep last 500 transactions
    
    // MARK: - Point Earning Rates
    // ⚠️ TUNING PARAMETERS: Adjust these to control point economy
    private let pointsPerDollarSaved = 10.0       // Base rate: $1 saved = 10 points (10x more generous!)
    private let bonusPointsPerGoalCompleted = 5000 // Bonus for completing a goal (10x increase)
    private let streakBonusMultiplier = 1.5       // 50% bonus for consistent saving
    
    // MARK: - Initialization
    private init() {
        loadPoints()
        loadPurchasedItems()
        loadTransactions()
        checkLoyaltyAccess()
    }
    
    // MARK: - Premium Access Control
    
    /// Check if loyalty features are available (Premium only)
    func checkLoyaltyAccess() {
        let wasPreviouslyEnabled = isLoyaltyEnabled
        isLoyaltyEnabled = SubscriptionService.shared.isPremium
        
        if isLoyaltyEnabled && !wasPreviouslyEnabled {
            print("✅ [Loyalty] Enabled - User upgraded to Premium")
            // Clear missed points when upgrading
            MissedPointsTracker.shared.clearMissedPoints()
        } else if !isLoyaltyEnabled && wasPreviouslyEnabled {
            print("⚠️ [Loyalty] Disabled - Premium subscription expired")
        } else if !isLoyaltyEnabled {
            print("🔒 [Loyalty] Disabled - Premium required")
        }
    }
    
    /// Computed property for easier access to current points (respects premium status)
    var points: Int {
        return isLoyaltyEnabled ? totalPoints : 0
    }
    
    // MARK: - Smart Rollover Policy
    
    /// Points status for display and logic
    enum PointsStatus: String {
        case active   // Premium user, can earn & redeem
        case frozen   // Canceled premium, points preserved but locked
        case none     // Free user, never had points
        
        var displayText: String {
            switch self {
            case .active:
                return "Active"
            case .frozen:
                return "Frozen - Upgrade to unlock"
            case .none:
                return "No points"
            }
        }
        
        var icon: String {
            switch self {
            case .active:
                return "checkmark.circle.fill"
            case .frozen:
                return "lock.fill"
            case .none:
                return "minus.circle"
            }
        }
    }
    
    /// Get current points status
    func getPointsStatus() -> (total: Int, status: PointsStatus) {
        let total = totalPoints
        
        if isLoyaltyEnabled {
            // Premium user - points are active
            return (total, .active)
        } else if total > 0 {
            // Non-premium user with accumulated points - frozen
            return (total, .frozen)
        } else {
            // No points at all
            return (0, .none)
        }
    }
    
    /// Check if user can earn new points
    func canEarnPoints() -> Bool {
        return isLoyaltyEnabled
    }
    
    /// Check if user can redeem points
    func canRedeemPoints() -> Bool {
        return isLoyaltyEnabled && totalPoints > 0
    }
    
    /// Get frozen points message for UI
    func getFrozenPointsMessage() -> String? {
        let status = getPointsStatus()
        
        if status.status == .frozen {
            let giftCardValue = Double(status.total) / 500.0 // 2,500 pts = $5
            return "You have \(status.total) points (\(String(format: "$%.2f", giftCardValue)) in gift cards) waiting! Upgrade to Premium to unlock them."
        }
        
        return nil
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
        
        // Check if user is premium
        guard isLoyaltyEnabled else {
            // Track missed points for free users
            MissedPointsTracker.shared.trackMissedPoints(pointsEarned, action: "Saved $\(String(format: "%.2f", amount))")
            print("🔒 [Loyalty] Cannot award \(pointsEarned) points - Premium required")
            return
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
        guard isLoyaltyEnabled else {
            MissedPointsTracker.shared.trackMissedPoints(bonusPointsPerGoalCompleted, action: "Completed goal: \(goalName)")
            print("🔒 [Loyalty] Cannot award goal bonus - Premium required")
            return
        }
        
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
        guard isLoyaltyEnabled else {
            MissedPointsTracker.shared.trackMissedPoints(points, action: "Verified manual deposit")
            print("🔒 [Loyalty] Cannot award \(points) points from screenshot - Premium required")
            return
        }
        
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
        guard isLoyaltyEnabled else {
            print("🔒 [Loyalty] Cannot purchase item - Premium required")
            return false
        }
        
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
    
    // MARK: - Gift Card Redemptions
    
    /// Redeem loyalty points for a gift card (Premium only)
    /// - Parameters:
    ///   - giftCard: The gift card to redeem
    ///   - userId: Current user ID
    ///   - email: User's email for gift card delivery
    /// - Returns: Redemption result with success/failure and details
    func redeemGiftCard(giftCard: GiftCard, userId: String, email: String) async throws -> GiftCardRedemption {
        // Check premium status
        guard isLoyaltyEnabled else {
            throw GiftCardRedemptionError.premiumRequired
        }
        
        // Check points balance
        guard totalPoints >= giftCard.pointsCost else {
            throw GiftCardRedemptionError.insufficientPoints(needed: giftCard.pointsCost, available: totalPoints)
        }
        
        // Call backend Lambda to process redemption via Tremendous
        let redemption = try await callRedemptionAPI(
            giftCard: giftCard,
            userId: userId,
            email: email
        )
        
        // Deduct points locally
        let metadata = LoyaltyTransaction.TransactionMetadata(
            depositAmount: nil,
            itemId: giftCard.id,
            itemName: giftCard.name,
            streakBonus: false,
            goalCompleted: false,
            verificationConfidence: nil,
            source: "gift_card_redemption"
        )
        
        addPoints(
            -giftCard.pointsCost,
            type: .spent,
            description: "Redeemed \(giftCard.name)",
            metadata: metadata
        )
        
        print("🎁 [Loyalty] Redeemed \(giftCard.name) for \(giftCard.pointsCost) points")
        
        return redemption
    }
    
    private func callRedemptionAPI(giftCard: GiftCard, userId: String, email: String) async throws -> GiftCardRedemption {
        // ✅ LIVE API Gateway endpoint for gift card redemption
        let endpoint = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/redeem-gift-card"
        
        guard let url = URL(string: endpoint) else {
            throw GiftCardRedemptionError.invalidEndpoint
        }
        
        let payload: [String: Any] = [
            "userId": userId,
            "giftCardId": giftCard.id,
            "pointsToSpend": giftCard.pointsCost,
            "email": email,
            "brand": giftCard.brand,
            "amount": giftCard.amount
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        // Add auth token if available
        if let authService = try? AuthService() {
            // Get current user's ID token
            // Note: You'll need to expose getCurrentUserIdToken in AuthService
            // request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GiftCardRedemptionError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GiftCardRedemptionError.serverError(code: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GiftCardRedemptionError.invalidResponse
        }
        
        // Parse redemption response
        let redemptionId = json["redemptionId"] as? String ?? UUID().uuidString
        let redemptionLink = json["rewardLink"] as? String
        let tremendousOrderId = json["tremendousOrderId"] as? String
        
        let redemption = GiftCardRedemption(
            id: redemptionId,
            userId: userId,
            giftCardId: giftCard.id,
            brand: giftCard.brand,
            amount: giftCard.amount,
            pointsSpent: giftCard.pointsCost,
            redemptionDate: Date(),
            redemptionCode: nil,
            redemptionLink: redemptionLink,
            status: .delivered,
            tremendousOrderId: tremendousOrderId
        )
        
        return redemption
    }
    
    enum GiftCardRedemptionError: Error, LocalizedError {
        case premiumRequired
        case insufficientPoints(needed: Int, available: Int)
        case invalidEndpoint
        case invalidResponse
        case serverError(code: Int)
        
        var errorDescription: String? {
            switch self {
            case .premiumRequired:
                return "Premium subscription required to redeem gift cards"
            case .insufficientPoints(let needed, let available):
                return "Insufficient points. Need \(needed), have \(available)"
            case .invalidEndpoint:
                return "Invalid API endpoint"
            case .invalidResponse:
                return "Invalid response from server"
            case .serverError(let code):
                return "Server error (code: \(code))"
            }
        }
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

