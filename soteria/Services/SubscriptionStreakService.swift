//
//  SubscriptionStreakService.swift
//  soteria
//
//  Tracks consecutive months as a paid member
//  Annual subscriptions count as 12 months, monthly as 1 month
//

import Foundation
import Combine
import SwiftUI

class SubscriptionStreakService: ObservableObject {
    static let shared = SubscriptionStreakService()
    
    @Published var currentStreak: Int = 0 // Total months as paid member
    @Published var lastTransactionDate: Date? = nil // Last transaction date
    @Published var lastSubscriptionType: SubscriptionType? = nil // Last subscription type
    
    enum SubscriptionType: String, Codable {
        case monthly = "monthly"
        case annual = "annual"
        
        var monthsValue: Int {
            switch self {
            case .monthly: return 1
            case .annual: return 12
            }
        }
    }
    
    private let streakKey = "subscription_streak_months"
    private let lastTransactionDateKey = "last_subscription_transaction_date"
    private let lastSubscriptionTypeKey = "last_subscription_type"
    
    private init() {
        // Lazy loading - no work on init
        print("✅ [SubscriptionStreakService] Initialized (lazy)")
    }
    
    // Ensure data is loaded (call on-demand)
    func ensureDataLoaded() {
        loadStreakData()
    }
    
    // Load streak data from UserDefaults
    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        
        if let dateData = UserDefaults.standard.object(forKey: lastTransactionDateKey) as? Date {
            lastTransactionDate = dateData
        }
        
        if let typeString = UserDefaults.standard.string(forKey: lastSubscriptionTypeKey),
           let type = SubscriptionType(rawValue: typeString) {
            lastSubscriptionType = type
        }
    }
    
    // Save streak data to UserDefaults
    private func saveStreakData() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        if let date = lastTransactionDate {
            UserDefaults.standard.set(date, forKey: lastTransactionDateKey)
        }
        if let type = lastSubscriptionType {
            UserDefaults.standard.set(type.rawValue, forKey: lastSubscriptionTypeKey)
        }
        print("💾 [SubscriptionStreakService] Saved streak: \(currentStreak) months")
    }
    
    // Initialize streak for premium users who don't have a recorded transaction
    // This is a fallback for test accounts or manually set premium users
    func initializeForPremiumUser() {
        ensureDataLoaded()
        if currentStreak == 0 {
            // Set to 1 month as a default for premium users
            currentStreak = 1
            lastTransactionDate = Date()
            lastSubscriptionType = .monthly // Default to monthly
            saveStreakData()
            print("✅ [SubscriptionStreakService] Initialized premium user with 1 month streak")
        }
    }
    
    // Record a subscription transaction (call when a purchase or renewal happens)
    func recordSubscription(productID: String, transactionDate: Date) {
        let calendar = Calendar.current
        let transactionDay = calendar.startOfDay(for: transactionDate)
        
        // Determine subscription type from product ID
        let subscriptionType: SubscriptionType
        if productID.contains("yearly") || productID.contains("annual") {
            subscriptionType = .annual
        } else {
            subscriptionType = .monthly
        }
        
        let monthsToAdd = subscriptionType.monthsValue
        
        // Check if this is the exact same transaction (same date and type) - don't double count
        if let lastDate = lastTransactionDate,
           let lastType = lastSubscriptionType,
           calendar.isDate(transactionDay, inSameDayAs: lastDate),
           lastType == subscriptionType {
            print("⚠️ [SubscriptionStreakService] Same transaction already recorded - skipping")
            return
        }
        
        if let lastDate = lastTransactionDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            
            // Check if this is a renewal or upgrade
            if let lastType = lastSubscriptionType {
                // Check if upgrading from monthly to annual
                if lastType == .monthly && subscriptionType == .annual {
                    // Upgrade: add 12 months
                    currentStreak += monthsToAdd
                    print("✅ [SubscriptionStreakService] Upgrade from monthly to annual: +\(monthsToAdd) months")
                } else if lastType == subscriptionType {
                    // Same type - check if it's a renewal
                    // For annual: check if it's been ~12 months
                    // For monthly: check if it's been ~1 month
                    let daysSince = calendar.dateComponents([.day], from: lastDay, to: transactionDay).day ?? 0
                    
                    if subscriptionType == .annual {
                        // Annual renewal: should be around 365 days
                        if daysSince >= 300 { // Allow some flexibility
                            currentStreak += monthsToAdd
                            print("✅ [SubscriptionStreakService] Annual renewal: +\(monthsToAdd) months")
                        } else {
                            // Same transaction or very recent - don't double count
                            print("⚠️ [SubscriptionStreakService] Annual transaction too soon after last (likely same transaction)")
                            // Still update the date to prevent future duplicates
                            lastTransactionDate = transactionDay
                            lastSubscriptionType = subscriptionType
                            saveStreakData()
                            return
                        }
                    } else {
                        // Monthly renewal: should be around 30 days
                        if daysSince >= 25 { // Allow some flexibility
                            currentStreak += monthsToAdd
                            print("✅ [SubscriptionStreakService] Monthly renewal: +\(monthsToAdd) months")
                        } else {
                            // Same transaction or very recent - don't double count
                            print("⚠️ [SubscriptionStreakService] Monthly transaction too soon after last (likely same transaction)")
                            // Still update the date to prevent future duplicates
                            lastTransactionDate = transactionDay
                            lastSubscriptionType = subscriptionType
                            saveStreakData()
                            return
                        }
                    }
                } else if lastType == .annual && subscriptionType == .monthly {
                    // Downgrade: add 1 month
                    currentStreak += monthsToAdd
                    print("✅ [SubscriptionStreakService] Downgrade from annual to monthly: +\(monthsToAdd) months")
                }
            } else {
                // First transaction ever
                currentStreak = monthsToAdd
                print("✅ [SubscriptionStreakService] First subscription: \(subscriptionType.rawValue) = \(monthsToAdd) months")
            }
        } else {
            // First transaction ever
            currentStreak = monthsToAdd
            print("✅ [SubscriptionStreakService] First subscription: \(subscriptionType.rawValue) = \(monthsToAdd) months")
        }
        
        lastTransactionDate = transactionDay
        lastSubscriptionType = subscriptionType
        saveStreakData()
        
        print("📊 [SubscriptionStreakService] Total months: \(currentStreak), Type: \(subscriptionType.rawValue)")
    }
    
    // Update streak based on current subscription status
    // This is called periodically to check for renewals
    func updateStreak(isPremium: Bool, lastTransactionDate: Date?) {
        guard isPremium else {
            // If no longer premium, keep the streak count but don't increment
            return
        }
        
        // The streak is updated when transactions are recorded
        // This method is mainly for compatibility with existing code
        // If we have a transaction date but haven't recorded it, we need to check
        // But we can't determine the product ID here, so we'll rely on recordSubscription
        // being called with the proper product ID
        if lastTransactionDate != nil {
            // Transaction date exists - streak will be updated via recordSubscription
        }
    }
    
    // Legacy method for compatibility
    func recordPremiumStatus(isPremium: Bool) {
        // This method is kept for compatibility but doesn't track subscription type
        // New code should use recordSubscription(productID:transactionDate:) instead
        if isPremium {
            // Try to get the current subscription type from SubscriptionService
            // This is a fallback if recordSubscription wasn't called
            ensureDataLoaded()
        }
    }
    
    // Badge color based on month count (tier system)
    var badgeGradient: LinearGradient {
        let colors: [Color]
        
        switch currentStreak {
        case 0:
            colors = [Color.gray.opacity(0.6), Color.gray.opacity(0.4)]
        case 1...3:
            // Bronze tier: 1-3 months
            colors = [Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.7, green: 0.4, blue: 0.1)]
        case 4...11:
            // Silver tier: 4-11 months
            colors = [Color(red: 0.75, green: 0.75, blue: 0.75), Color(red: 0.6, green: 0.6, blue: 0.6)]
        case 12...23:
            // Gold tier: 12-23 months (1 year)
            colors = [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)]
        case 24...35:
            // Platinum tier: 24-35 months (2 years)
            colors = [Color(red: 0.9, green: 0.9, blue: 0.95), Color(red: 0.7, green: 0.7, blue: 0.85)]
        case 36...47:
            // Diamond tier: 36-47 months (3 years)
            colors = [Color(red: 0.4, green: 0.8, blue: 1.0), Color(red: 0.2, green: 0.6, blue: 0.9)]
        default:
            // Legendary tier: 48+ months (4+ years)
            colors = [Color(red: 1.0, green: 0.2, blue: 0.4), Color(red: 0.8, green: 0.1, blue: 0.3)]
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Get tier name for display
    var tierName: String {
        switch currentStreak {
        case 0: return "Member"
        case 1...3: return "Bronze"
        case 4...11: return "Silver"
        case 12...23: return "Gold"
        case 24...35: return "Platinum"
        case 36...47: return "Diamond"
        default: return "Legendary"
        }
    }
}
