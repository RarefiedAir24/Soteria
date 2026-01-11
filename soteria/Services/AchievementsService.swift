//
//  AchievementsService.swift
//  soteria
//
//  Manages optional achievement unlocks for money tree decorations
//  Goal-driven: Decorations unlock when goals are completed (optional bonus)
//

import Foundation
import Combine

@MainActor
class AchievementsService: ObservableObject {
    static let shared = AchievementsService()
    
    // MARK: - Published Properties
    @Published var unlockedItems: Set<String> = []
    @Published var availableToUnlock: [SceneItem] = []
    @Published var pendingUnlocks: [PendingUnlock] = [] // User completed requirement but hasn't unlocked yet
    
    // MARK: - Constants
    private let unlockedItemsKey = "achievements_unlocked_items"
    private let pendingUnlocksKey = "achievements_pending_unlocks"
    
    struct PendingUnlock: Codable, Identifiable {
        let id: String
        let itemId: String
        let itemName: String
        let bonusPoints: Int
        let unlockedDate: Date
        let triggerType: String // "goal_completed", "milestone", etc.
        
        var item: SceneItem? {
            SceneItem.catalog.first { $0.id == itemId }
        }
    }
    
    // MARK: - Initialization
    private init() {
        loadUnlockedItems()
        loadPendingUnlocks()
    }
    
    // MARK: - Check for New Unlocks
    
    /// Check if any items became unlockable (called after goal completion, milestones, etc.)
    func checkForNewUnlocks(
        goalsCompleted: Int,
        totalSaved: Double,
        savingsStreak: Int = 0,
        activatedTools: Set<String> = [],
        giftCardsRedeemed: Int = 0,
        completedGoalCategory: String? = nil,
        triggerType: String = "goal_completed"
    ) {
        print("🏆 [Achievements] Checking for new unlocks...")
        print("   Goals: \(goalsCompleted), Saved: $\(totalSaved), Streak: \(savingsStreak)")
        
        // Get all items with unlock requirements
        let achievementItems = SceneItem.catalog.filter { $0.unlockRequirement != nil }
        
        for item in achievementItems {
            // Skip if already unlocked
            guard !unlockedItems.contains(item.id) else { continue }
            
            // Skip if already pending
            guard !pendingUnlocks.contains(where: { $0.itemId == item.id }) else { continue }
            
            // Check if requirement is met
            guard let requirement = item.unlockRequirement else { continue }
            
            let isMet = requirement.isMet(
                goalsCompleted: goalsCompleted,
                totalSaved: totalSaved,
                savingsStreak: savingsStreak,
                activatedTools: activatedTools,
                giftCardsRedeemed: giftCardsRedeemed,
                completedGoalCategory: completedGoalCategory
            )
            
            if isMet {
                // Add to pending unlocks
                let pending = PendingUnlock(
                    id: UUID().uuidString,
                    itemId: item.id,
                    itemName: item.name,
                    bonusPoints: requirement.bonusPoints,
                    unlockedDate: Date(),
                    triggerType: triggerType
                )
                
                pendingUnlocks.append(pending)
                savePendingUnlocks()
                
                print("✅ [Achievements] New unlock available: \(item.name) (+\(requirement.bonusPoints) pts)")
                
                // Post notification for UI
                NotificationCenter.default.post(
                    name: NSNotification.Name("NewAchievementAvailable"),
                    object: pending
                )
            }
        }
        
        updateAvailableToUnlock()
    }
    
    // MARK: - Unlock Item
    
    /// User chooses to unlock an achievement item
    func unlockItem(_ itemId: String) -> Bool {
        guard let pending = pendingUnlocks.first(where: { $0.itemId == itemId }),
              let item = pending.item,
              let requirement = item.unlockRequirement else {
            print("❌ [Achievements] Cannot unlock \(itemId) - not available")
            return false
        }
        
        // Add to unlocked set
        unlockedItems.insert(itemId)
        saveUnlockedItems()
        
        // Remove from pending
        pendingUnlocks.removeAll { $0.itemId == itemId }
        savePendingUnlocks()
        
        // Award bonus points (only if premium)
        if LoyaltyPointsService.shared.isLoyaltyEnabled {
            LoyaltyPointsService.shared.awardPointsForSaving(
                amount: Double(requirement.bonusPoints),
                hasStreak: false,
                source: "achievement_unlock_\(itemId)"
            )
            
            print("🌟 [Achievements] Unlocked \(item.name), awarded \(requirement.bonusPoints) bonus points")
        } else {
            print("⚠️ [Achievements] Unlocked \(item.name), but loyalty disabled (not premium)")
        }
        
        // Start unlock flow (celebration → placement tutorial)
        UnlockFlowCoordinator.shared.startUnlockFlow(for: item, bonusPoints: requirement.bonusPoints)
        
        updateAvailableToUnlock()
        
        return true
    }
    
    /// User declines to unlock (just dismiss the offer)
    func declineUnlock(_ itemId: String) {
        // Remove from pending but don't unlock
        pendingUnlocks.removeAll { $0.itemId == itemId }
        savePendingUnlocks()
        
        print("🚫 [Achievements] User declined to unlock \(itemId)")
        
        updateAvailableToUnlock()
    }
    
    // MARK: - Query Methods
    
    /// Check if an item is unlocked
    func isUnlocked(_ itemId: String) -> Bool {
        return unlockedItems.contains(itemId)
    }
    
    /// Get count of pending unlocks (for badge)
    var pendingUnlockCount: Int {
        return pendingUnlocks.count
    }
    
    /// Get total bonus points available from pending unlocks
    var totalPendingBonusPoints: Int {
        return pendingUnlocks.reduce(0) { $0 + $1.bonusPoints }
    }
    
    // MARK: - Private Helpers
    
    private func updateAvailableToUnlock() {
        availableToUnlock = pendingUnlocks.compactMap { $0.item }
    }
    
    // MARK: - Persistence
    
    private func loadUnlockedItems() {
        if let data = UserDefaults.standard.data(forKey: unlockedItemsKey),
           let items = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedItems = items
        }
    }
    
    private func saveUnlockedItems() {
        if let data = try? JSONEncoder().encode(unlockedItems) {
            UserDefaults.standard.set(data, forKey: unlockedItemsKey)
        }
    }
    
    private func loadPendingUnlocks() {
        if let data = UserDefaults.standard.data(forKey: pendingUnlocksKey),
           let unlocks = try? JSONDecoder().decode([PendingUnlock].self, from: data) {
            pendingUnlocks = unlocks
            updateAvailableToUnlock()
        }
    }
    
    private func savePendingUnlocks() {
        if let data = try? JSONEncoder().encode(pendingUnlocks) {
            UserDefaults.standard.set(data, forKey: pendingUnlocksKey)
        }
    }
}
