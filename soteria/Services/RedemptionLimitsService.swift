//
//  RedemptionLimitsService.swift
//  soteria
//
//  Manages monthly gift card redemption limits for fraud protection
//

import Foundation

class RedemptionLimitsService {
    static let shared = RedemptionLimitsService()
    
    // MARK: - Monthly Cap Limits (Fraud Protection Only - Gift Cards Are FREE!)
    
    /// Monthly redemption caps per user tier
    struct Limits {
        static let freeUser: Double = 0.00          // Free users: no gift cards
        static let basicPremium: Double = 50.00     // Basic Premium: $50/month cap
        static let connectedPremium: Double = 100.00 // Connected Premium (Phase 2): $100/month cap
    }
    
    private let redemptionsKey = "gift_card_redemptions_history"
    
    private init() {}
    
    // MARK: - Get User's Monthly Cap
    
    /// Get the current user's monthly redemption cap based on their tier
    func getMonthlyCapForUser() -> Double {
        // Check subscription status
        guard SubscriptionService.shared.isPremium else {
            return Limits.freeUser
        }
        
        // Check if Plaid is connected (Phase 2 feature)
        // TODO: Uncomment when Plaid is fully integrated
        // if PlaidService.shared.isAccountLinked {
        //     return Limits.connectedPremium
        // }
        
        // Basic premium
        return Limits.basicPremium
    }
    
    // MARK: - Track Redemptions
    
    /// Get all redemptions for the current month
    func getRedemptionsThisMonth(userId: String) -> [GiftCardRedemption] {
        guard let data = UserDefaults.standard.data(forKey: "\(redemptionsKey)_\(userId)"),
              let allRedemptions = try? JSONDecoder().decode([GiftCardRedemption].self, from: data) else {
            return []
        }
        
        let now = Date()
        let calendar = Calendar.current
        let thisMonth = calendar.component(.month, from: now)
        let thisYear = calendar.component(.year, from: now)
        
        return allRedemptions.filter { redemption in
            let month = calendar.component(.month, from: redemption.redemptionDate)
            let year = calendar.component(.year, from: redemption.redemptionDate)
            return month == thisMonth && year == thisYear
        }
    }
    
    /// Get total amount redeemed this month
    func getTotalRedeemedThisMonth(userId: String) -> Double {
        return getRedemptionsThisMonth(userId: userId)
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Get remaining redemption amount for this month
    func getRemainingThisMonth(userId: String) -> Double {
        let cap = getMonthlyCapForUser()
        let redeemed = getTotalRedeemedThisMonth(userId: userId)
        let remaining = cap - redeemed
        return max(0, remaining) // Never negative
    }
    
    /// Check if user can redeem a specific amount
    func canRedeemAmount(_ amount: Double, userId: String) -> (canRedeem: Bool, reason: String?) {
        // Check if user is premium
        guard SubscriptionService.shared.isPremium else {
            return (false, "Premium subscription required to redeem gift cards")
        }
        
        let remaining = getRemainingThisMonth(userId: userId)
        
        if amount > remaining {
            if remaining > 0 {
                return (false, "Only $\(Int(remaining)) remaining this month. Monthly cap: $\(Int(getMonthlyCapForUser()))")
            } else {
                return (false, "Monthly cap of $\(Int(getMonthlyCapForUser())) reached. Resets next month.")
            }
        }
        
        return (true, nil)
    }
    
    /// Record a redemption
    func recordRedemption(_ redemption: GiftCardRedemption, userId: String) {
        var allRedemptions = loadAllRedemptions(userId: userId)
        allRedemptions.append(redemption)
        
        // Keep only last 12 months of redemptions
        let twelveMonthsAgo = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        allRedemptions = allRedemptions.filter { $0.redemptionDate >= twelveMonthsAgo }
        
        saveRedemptions(allRedemptions, userId: userId)
        
        print("✅ [RedemptionLimits] Recorded $\(redemption.amount) redemption for user \(userId)")
    }
    
    // MARK: - Persistence
    
    private func loadAllRedemptions(userId: String) -> [GiftCardRedemption] {
        guard let data = UserDefaults.standard.data(forKey: "\(redemptionsKey)_\(userId)"),
              let redemptions = try? JSONDecoder().decode([GiftCardRedemption].self, from: data) else {
            return []
        }
        return redemptions
    }
    
    private func saveRedemptions(_ redemptions: [GiftCardRedemption], userId: String) {
        if let data = try? JSONEncoder().encode(redemptions) {
            UserDefaults.standard.set(data, forKey: "\(redemptionsKey)_\(userId)")
        }
    }
    
    // MARK: - Admin & Analytics
    
    /// Get months user hit cap (for fraud detection)
    func getMonthsAtCap(userId: String) -> Int {
        var monthsAtCap = 0
        let calendar = Calendar.current
        let cap = getMonthlyCapForUser()
        
        // Check last 12 months
        for monthOffset in 0..<12 {
            guard let targetMonth = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) else { continue }
            
            let month = calendar.component(.month, from: targetMonth)
            let year = calendar.component(.year, from: targetMonth)
            
            let allRedemptions = loadAllRedemptions(userId: userId)
            let monthRedemptions = allRedemptions.filter { redemption in
                let redemptionMonth = calendar.component(.month, from: redemption.redemptionDate)
                let redemptionYear = calendar.component(.year, from: redemption.redemptionDate)
                return redemptionMonth == month && redemptionYear == year
            }
            
            let totalRedeemed = monthRedemptions.reduce(0) { $0 + $1.amount }
            
            if totalRedeemed >= cap {
                monthsAtCap += 1
            } else {
                break // Stop counting if a month wasn't at cap
            }
        }
        
        return monthsAtCap
    }
}
