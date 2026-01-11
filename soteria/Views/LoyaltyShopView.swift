//
//  LoyaltyShopView.swift
//  soteria
//
//  Shop for redeeming loyalty points on money tree decorations
//

import SwiftUI

struct LoyaltyShopView: View {
    @StateObject private var loyaltyService = LoyaltyPointsService.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    @State private var selectedTab: ShopTab = .sceneItems
    @State private var selectedCategory: SceneItem.ItemCategory = .animal
    @State private var showingPurchaseConfirmation = false
    @State private var itemToPurchase: SceneItem?
    @State private var purchaseSuccess = false
    
    // Mock data for unlock requirements (would come from actual services)
    @State private var goalsCompleted = 0
    @State private var totalSaved: Double = 0
    
    enum ShopTab {
        case sceneItems
        case giftCards
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.9, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    tabSelector
                    
                    // Content based on selected tab
                    if selectedTab == .sceneItems {
                        VStack(spacing: 0) {
                            // Points Balance Header
                            pointsBalanceHeader
                            
                            // Category Picker
                            categoryPicker
                            
                            // Items Grid
                            ScrollView {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ], spacing: 16) {
                                    ForEach(filteredItems) { item in
                                        ItemCard(
                                            item: item,
                                            isUnlocked: isUnlocked(item),
                                            isPurchased: loyaltyService.hasPurchased(itemId: item.id),
                                            canAfford: loyaltyService.totalPoints >= item.pointCost,
                                            onPurchase: {
                                                itemToPurchase = item
                                                showingPurchaseConfirmation = true
                                            }
                                        )
                                    }
                                }
                                .padding()
                            }
                        }
                    } else {
                        // Gift Cards Tab
                        if subscriptionService.isPremium {
                            GiftCardShopView()
                        } else {
                            GiftCardsLockedView()
                        }
                    }
                }
            }
            .navigationTitle("Loyalty Shop")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Item?", isPresented: $showingPurchaseConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Purchase") {
                    purchaseItem()
                }
            } message: {
                if let item = itemToPurchase {
                    Text("Purchase \(item.name) for \(item.pointCost) points?")
                }
            }
            .alert(purchaseSuccess ? "Success!" : "Purchase Failed", isPresented: .constant(itemToPurchase != nil && !showingPurchaseConfirmation)) {
                Button("OK") {
                    itemToPurchase = nil
                }
            } message: {
                if purchaseSuccess {
                    Text("\(itemToPurchase?.name ?? "Item") has been added to your money tree!")
                } else {
                    Text("Unable to complete purchase. Check your points balance.")
                }
            }
        }
        .onAppear {
            loadUserProgress()
        }
    }
    
    // MARK: - Components
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            // Scene Items Tab
            Button(action: { selectedTab = .sceneItems }) {
                VStack(spacing: 8) {
                    Text("Scene Items")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedTab == .sceneItems ? .reverBlue : .softGraphite)
                    
                    if selectedTab == .sceneItems {
                        Rectangle()
                            .fill(Color.reverBlue)
                            .frame(height: 3)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 3)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Gift Cards Tab
            Button(action: { selectedTab = .giftCards }) {
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Gift Cards")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedTab == .giftCards ? .reverBlue : .softGraphite)
                        
                        if !subscriptionService.isPremium {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.softGraphite.opacity(0.5))
                        }
                    }
                    
                    if selectedTab == .giftCards {
                        Rectangle()
                            .fill(Color.reverBlue)
                            .frame(height: 3)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 3)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 16)
        .background(Color.white.opacity(0.9))
    }
    
    private var pointsBalanceHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(loyaltyService.totalPoints)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Available Points")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(loyaltyService.lifetimePointsEarned)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Lifetime Earned")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryButton(
                    title: "Animals",
                    icon: "hare.fill",
                    category: .animal,
                    isSelected: selectedCategory == .animal
                ) {
                    selectedCategory = .animal
                }
                
                CategoryButton(
                    title: "Decorations",
                    icon: "sparkles",
                    category: .decoration,
                    isSelected: selectedCategory == .decoration
                ) {
                    selectedCategory = .decoration
                }
                
                CategoryButton(
                    title: "Plants",
                    icon: "leaf.fill",
                    category: .plant,
                    isSelected: selectedCategory == .plant
                ) {
                    selectedCategory = .plant
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Helpers
    
    private var filteredItems: [SceneItem] {
        SceneItem.catalog.filter { $0.category == selectedCategory }
    }
    
    private func isUnlocked(_ item: SceneItem) -> Bool {
        return item.unlockRequirement?.isMet(
            goalsCompleted: goalsCompleted,
            totalSaved: totalSaved,
            savingsStreak: 0, // TODO: Track savings streak
            activatedTools: [], // TODO: Track activated tools
            giftCardsRedeemed: 0 // TODO: Track gift cards redeemed
        ) ?? true
    }
    
    private func purchaseItem() {
        guard let item = itemToPurchase else { return }
        purchaseSuccess = loyaltyService.purchaseItem(cost: item.pointCost, itemId: item.id, itemName: item.name)
    }
    
    private func loadUserProgress() {
        // TODO: Load from GoalsService
        goalsCompleted = UserDefaults.standard.integer(forKey: "goals_completed_count")
        totalSaved = UserDefaults.standard.double(forKey: "total_saved_amount")
    }
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let title: String
    let icon: String
    let category: SceneItem.ItemCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.white)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }
}

struct ItemCard: View {
    let item: SceneItem
    let isUnlocked: Bool
    let isPurchased: Bool
    let canAfford: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Item Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isPurchased ? [.green.opacity(0.3), .green.opacity(0.1)] :
                                     isUnlocked ? [.blue.opacity(0.3), .blue.opacity(0.1)] :
                                     [.gray.opacity(0.3), .gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Display icon based on type
                SceneItemIcon(
                    item: item,
                    tintColor: isPurchased ? .green : isUnlocked ? .blue : .gray
                )
                
                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                        .background(Circle().fill(Color.white).padding(4))
                        .offset(x: 25, y: -25)
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .background(Circle().fill(Color.white).padding(4))
                        .offset(x: 25, y: -25)
                }
            }
            
            // Item Info
            VStack(spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(item.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
            
            // Purchase Button
            if isPurchased {
                Text("Owned")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
            } else if !isUnlocked {
                unlockRequirementText
            } else {
                Button(action: onPurchase) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("\(item.pointCost)")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(canAfford ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(canAfford ? Color.blue : Color.gray.opacity(0.3))
                    )
                }
                .disabled(!canAfford)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var unlockRequirementText: some View {
        Group {
            if let requirement = item.unlockRequirement {
                VStack(spacing: 2) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text(requirementDescription(requirement))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }
    
    private func requirementDescription(_ req: SceneItem.UnlockRequirement) -> String {
        switch req.type {
        case .totalSaved:
            return "Save $\(req.value)"
        case .goalsCompleted:
            return "Complete \(req.value) goal\(req.value == 1 ? "" : "s")"
        case .firstGoal:
            return "Complete your first goal"
        case .goalCategory:
            return "Complete a \(req.categoryFilter ?? "specific") goal"
        case .savingsStreak:
            return "\(req.value) day saving streak"
        case .toolActivated:
            return "Activate \(req.categoryFilter ?? "savings tool")"
        case .giftCardRedeemed:
            return "Redeem your first gift card"
        case .none:
            return ""
        }
    }
}

// MARK: - Preview
struct LoyaltyShopView_Previews: PreviewProvider {
    static var previews: some View {
        LoyaltyShopView()
    }
}

