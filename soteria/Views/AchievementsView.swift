//
//  AchievementsView.swift
//  soteria
//
//  Optional section to view and unlock achievements
//

import SwiftUI

struct AchievementsView: View {
    @ObservedObject private var achievementsService = AchievementsService.shared
    @ObservedObject private var goalsService = GoalsService.shared
    @ObservedObject private var loyaltyService = LoyaltyPointsService.shared
    @State private var showUnlockOffer: AchievementsService.PendingUnlock? = nil
    
    var body: some View {
        ZStack {
            Color.cloudWhite.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header stats
                    progressStatsSection
                    
                    // Available to unlock
                    if !achievementsService.pendingUnlocks.isEmpty {
                        availableSection
                    }
                    
                    // Locked achievements (coming soon)
                    lockedSection
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationTitle("Achievements")
        .sheet(item: $showUnlockOffer) { pending in
            AchievementUnlockOfferView(
                pendingUnlock: pending,
                isPresented: Binding(
                    get: { showUnlockOffer != nil },
                    set: { if !$0 { showUnlockOffer = nil } }
                )
            )
        }
    }
    
    private var progressStatsSection: some View {
        VStack(spacing: 16) {
            Text("Your Progress")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ProgressStat(
                    icon: "checkmark.circle.fill",
                    value: "\(completedGoalsCount)",
                    label: "Goals"
                )
                
                ProgressStat(
                    icon: "dollarsign.circle.fill",
                    value: "$\(Int(totalSaved))",
                    label: "Saved"
                )
                
                ProgressStat(
                    icon: "gift.fill",
                    value: "\(achievementsService.unlockedItems.count)",
                    label: "Unlocked"
                )
            }
        }
        .padding(.bottom, 8)
    }
    
    private var availableSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🎁 Available to Unlock")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
                
                Text("\(achievementsService.pendingUnlockCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            
            ForEach(achievementsService.pendingUnlocks) { pending in
                if let item = pending.item {
                    AvailableUnlockCard(
                        item: item,
                        bonusPoints: pending.bonusPoints,
                        onUnlock: {
                            showUnlockOffer = pending
                        }
                    )
                }
            }
        }
    }
    
    private var lockedSection: some View {
        VStack(spacing: 16) {
            Text("🔒 Locked Achievements")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.midnightSlate)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Show next achievements to unlock
            ForEach(upcomingAchievements, id: \.id) { item in
                if let requirement = item.unlockRequirement {
                    LockedAchievementCard(
                        item: item,
                        requirement: requirement,
                        currentProgress: getCurrentProgress(for: requirement)
                    )
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var completedGoalsCount: Int {
        goalsService.goals.filter { $0.status == .achieved }.count
    }
    
    private var totalSaved: Double {
        goalsService.goals.reduce(0) { $0 + $1.currentAmount }
    }
    
    private var upcomingAchievements: [SceneItem] {
        SceneItem.catalog
            .filter { item in
                item.unlockRequirement != nil &&
                !achievementsService.unlockedItems.contains(item.id) &&
                !achievementsService.pendingUnlocks.contains(where: { $0.itemId == item.id })
            }
            .sorted { item1, item2 in
                guard let req1 = item1.unlockRequirement,
                      let req2 = item2.unlockRequirement else {
                    return false
                }
                return req1.value < req2.value
            }
            .prefix(5)
            .map { $0 }
    }
    
    private func getCurrentProgress(for requirement: SceneItem.UnlockRequirement) -> (current: Int, total: Int) {
        switch requirement.type {
        case .firstGoal, .goalsCompleted:
            return (completedGoalsCount, requirement.value)
        case .totalSaved:
            return (Int(totalSaved), requirement.value)
        case .savingsStreak:
            return (0, requirement.value) // TODO: Track streak
        case .toolActivated:
            return (0, 1) // TODO: Track tools
        case .giftCardRedeemed:
            return (0, 1) // TODO: Track redemptions
        case .goalCategory:
            return (Int(totalSaved), requirement.value)
        case .none:
            return (1, 1)
        }
    }
}

// MARK: - Supporting Views

struct ProgressStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.reverBlue)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.midnightSlate)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.softGraphite)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AvailableUnlockCard: View {
    let item: SceneItem
    let bonusPoints: Int
    let onUnlock: () -> Void
    
    var body: some View {
        Button(action: onUnlock) {
            HStack(spacing: 16) {
                // Icon
                SceneItemIcon(item: item, tintColor: .reverBlue)
                    .frame(width: 60, height: 60)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.reverBlue.opacity(0.1))
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    Text(item.description)
                        .font(.system(size: 13))
                        .foregroundColor(.softGraphite)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("+\(bonusPoints) bonus points")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.softGraphite)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LockedAchievementCard: View {
    let item: SceneItem
    let requirement: SceneItem.UnlockRequirement
    let currentProgress: (current: Int, total: Int)
    
    var progressPercentage: Double {
        guard currentProgress.total > 0 else { return 0 }
        return Double(currentProgress.current) / Double(currentProgress.total)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon (grayed out)
            SceneItemIcon(item: item, tintColor: .softGraphite)
                .frame(width: 50, height: 50)
                .opacity(0.3)
                .padding()
                .background(
                    Circle()
                        .fill(Color.softGraphite.opacity(0.1))
                )
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Text(requirement.description)
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite)
                
                // Progress bar
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.softGraphite.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.reverBlue)
                                .frame(width: geometry.size.width * progressPercentage, height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("\(currentProgress.current) / \(currentProgress.total)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.softGraphite)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }
}
