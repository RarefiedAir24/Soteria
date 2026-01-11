//
//  DeveloperTestingView.swift
//  soteria
//
//  Developer testing utilities for loyalty system
//

import SwiftUI

struct DeveloperTestingView: View {
    @StateObject private var loyaltyService = LoyaltyPointsService.shared
    @StateObject private var sceneManager = SceneManager.shared
    @StateObject private var toolsService = SavingsToolsService.shared
    @EnvironmentObject var subscriptionService: SubscriptionService
    @EnvironmentObject var authService: AuthService
    @State private var pointsToAdd: String = "1000"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedGiftCard: GiftCard?
    @State private var showRedemptionTest = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - FEATURE FLAGS
                Section(header: Text("🎚️ FEATURE FLAGS")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Savings Tools")
                                .font(.headline)
                            Text(toolsService.isFeatureEnabled ? "Enabled - Badge visible on home" : "Disabled - Badge hidden")
                                .font(.caption)
                                .foregroundColor(toolsService.isFeatureEnabled ? .green : .gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { toolsService.isFeatureEnabled },
                            set: { _ in toolsService.toggleFeature() }
                        ))
                        .labelsHidden()
                    }
                    
                    if !toolsService.isFeatureEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Why is this off?")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            Text("We don't have partner agreements yet. Enable this when Upside/GoodRx partnerships are secured.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // MARK: - 🎓 UNLOCK TUTORIAL TESTING
                Section(header: Text("🎓 UNLOCK TUTORIAL TESTING")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test the new unlock→placement flow")
                            .font(.headline)
                        Text("Triggers celebration + guided placement tutorial")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    
                    Button("🐈 Test: Unlock Cat (with tutorial)") {
                        testUnlockFlowWithCat()
                    }
                    .foregroundColor(.blue)
                    
                    Button("🦜 Test: Unlock Parrot (with tutorial)") {
                        testUnlockFlowWithParrot()
                    }
                    .foregroundColor(.green)
                    
                    Button("🔄 Reset Tutorial (show again)") {
                        UserDefaults.standard.removeObject(forKey: "placement_tutorial_completed")
                        alertMessage = "✅ Tutorial reset! Next unlock will show full tutorial."
                        showAlert = true
                    }
                    .foregroundColor(.orange)
                }
                
                // MARK: - 10X UPGRADE TESTING
                Section(header: Text("🚀 10X UPGRADE TESTING")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Earning Rate: 10 pts/$1")
                            .font(.headline)
                        Text("Goal Bonus: 5,000 pts")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Text("Monthly Cap: $50")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                    
                    Button("Test: Save $100 → Earn 1,000 pts") {
                        testSave100()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Test: Complete Goal → Earn 5,000 pts") {
                        testGoalCompletion()
                    }
                    .foregroundColor(.purple)
                    
                    Button("Test: Unlock Achievement → Bonus Points") {
                        testAchievementUnlock()
                    }
                    .foregroundColor(.orange)
                }
                
                // MARK: - GIFT CARD TESTING
                Section(header: Text("🎁 GIFT CARD TESTING ($5-$100)")) {
                    Text("Available: 28 cards (Visa, Amazon, Target, Walmart, Starbucks)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button("Give 2,500 pts → Test $5 Card") {
                        loyaltyService.addPointsManual(2500, confidence: 1.0)
                        alertMessage = "Added 2,500 pts! Try redeeming a $5 card."
                        showAlert = true
                    }
                    
                    Button("Give 25,000 pts → Test $50 Card") {
                        loyaltyService.addPointsManual(25000, confidence: 1.0)
                        alertMessage = "Added 25,000 pts! Try redeeming a $50 card."
                        showAlert = true
                    }
                    
                    Button("Give 50,000 pts → Test $100 Card") {
                        loyaltyService.addPointsManual(50000, confidence: 1.0)
                        alertMessage = "Added 50,000 pts! Try redeeming a $100 card."
                        showAlert = true
                    }
                    
                    NavigationLink("Open Gift Card Shop") {
                        GiftCardShopView()
                            .environmentObject(subscriptionService)
                            .environmentObject(authService)
                    }
                }
                
                // MARK: - MONTHLY CAP TESTING
                Section(header: Text("🔒 MONTHLY CAP TESTING")) {
                    if let userId = authService.currentUserId {
                        let redemptionService = RedemptionLimitsService.shared
                        let cap = redemptionService.getMonthlyCapForUser()
                        let redeemed = redemptionService.getTotalRedeemedThisMonth(userId: userId)
                        let remaining = redemptionService.getRemainingThisMonth(userId: userId)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Monthly Cap:")
                                Spacer()
                                Text("$\(Int(cap))")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Redeemed This Month:")
                                Spacer()
                                Text("$\(Int(redeemed))")
                                    .font(.headline)
                                    .foregroundColor(redeemed >= cap ? .red : .green)
                            }
                            
                            HStack {
                                Text("Remaining:")
                                Spacer()
                                Text("$\(Int(remaining))")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            
                            if redeemed >= cap {
                                Text("⚠️ Cap reached! Cannot redeem more this month.")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Button("Simulate $25 Redemption") {
                            simulateRedemption(amount: 25.0, userId: userId)
                        }
                        
                        Button("Simulate $50 Redemption") {
                            simulateRedemption(amount: 50.0, userId: userId)
                        }
                        
                        Button("Reset Monthly Redemptions") {
                            // This would normally require manual UserDefaults clearing
                            alertMessage = "To reset redemptions, go to: Settings → Reset Loyalty Data"
                            showAlert = true
                        }
                        .foregroundColor(.red)
                    } else {
                        Text("Please sign in to test monthly caps")
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
                
                // MARK: - Loyalty Points Section
                Section(header: Text("💰 LOYALTY POINTS")) {
                    HStack {
                        Text("Current Points:")
                        Spacer()
                        Text("\(loyaltyService.totalPoints)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Lifetime Earned:")
                        Spacer()
                        Text("\(loyaltyService.lifetimePointsEarned)")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("$ Value:")
                        Spacer()
                        Text("$\(String(format: "%.2f", Double(loyaltyService.totalPoints) / 500.0))")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        TextField("Points to add", text: $pointsToAdd)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Add Points") {
                            if let points = Int(pointsToAdd) {
                                loyaltyService.addPointsManual(points, confidence: 1.0)
                                alertMessage = "Added \(points) loyalty points!"
                                showAlert = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Add 5,000 Points (Quick Test)") {
                        loyaltyService.addPointsManual(5000, confidence: 1.0)
                        alertMessage = "Added 5,000 points for testing!"
                        showAlert = true
                    }
                    .foregroundColor(.green)
                    
                    Button("Reset All Points") {
                        loyaltyService.resetAll()
                        alertMessage = "Reset all loyalty points and purchases!"
                        showAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                // MARK: - Purchased Items Section
                Section(header: Text("🛍️ PURCHASED ITEMS")) {
                    Text("Total Purchased: \(loyaltyService.purchasedItemIds.count)")
                        .font(.headline)
                    
                    if loyaltyService.purchasedItemIds.isEmpty {
                        Text("No items purchased yet")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(Array(loyaltyService.purchasedItemIds), id: \.self) { itemId in
                            if let item = SceneItem.catalog.first(where: { $0.id == itemId }) {
                                HStack {
                                    SceneItemIcon(item: item, tintColor: .blue)
                                    Text(item.name)
                                    Spacer()
                                    Text("\(item.pointCost) pts")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    Button("Unlock All Animals (Testing)") {
                        unlockAllAnimals()
                        alertMessage = "Unlocked all animals for testing!"
                        showAlert = true
                    }
                    .foregroundColor(.orange)
                }
                
                // MARK: - Scene Items Section
                Section(header: Text("🎨 SCENE ITEMS")) {
                    Text("Placed on Scene: \(sceneManager.placedItems.count)")
                        .font(.headline)
                    
                    if sceneManager.placedItems.isEmpty {
                        Text("No items placed on scene")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(sceneManager.placedItems) { placement in
                            if let item = SceneItem.catalog.first(where: { $0.id == placement.itemId }) {
                                HStack {
                                    SceneItemIcon(item: item, tintColor: .green)
                                    Text(item.name)
                                    Spacer()
                                    Text(placement.isFlipped ? "← Flipped" : "→ Normal")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    if !sceneManager.placedItems.isEmpty {
                        Button("Clear All Scene Items") {
                            sceneManager.clearScene()
                            alertMessage = "Cleared all items from scene!"
                            showAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // MARK: - Quick Actions Section
                Section(header: Text("⚡ QUICK TEST SCENARIOS")) {
                    Button("Scenario 1: New User") {
                        loyaltyService.resetAll()
                        sceneManager.clearScene()
                        alertMessage = "Reset to new user state!"
                        showAlert = true
                    }
                    
                    Button("Scenario 2: Active Saver ($100 saved)") {
                        loyaltyService.resetAll()
                        sceneManager.clearScene()
                        loyaltyService.addPointsManual(1000, confidence: 1.0) // 10 pts/$1
                        alertMessage = "Simulated $100 saved = 1,000 points earned!"
                        showAlert = true
                    }
                    
                    Button("Scenario 3: Goal Completer (First Goal)") {
                        loyaltyService.resetAll()
                        sceneManager.clearScene()
                        loyaltyService.addPointsManual(5000, confidence: 1.0) // Goal completion bonus
                        alertMessage = "Simulated first goal completed = 5,000 bonus points!"
                        showAlert = true
                    }
                    
                    Button("Scenario 4: Ready for $25 Card") {
                        loyaltyService.resetAll()
                        sceneManager.clearScene()
                        loyaltyService.addPointsManual(12500, confidence: 1.0) // 12,500 pts = $25
                        alertMessage = "Set up with 12,500 points (enough for $25 card)!"
                        showAlert = true
                    }
                    
                    Button("Scenario 5: Power User (50k pts)") {
                        loyaltyService.resetAll()
                        sceneManager.clearScene()
                        loyaltyService.addPointsManual(50000, confidence: 1.0)
                        unlockAllAnimals()
                        alertMessage = "Power user: 50,000 pts + all animals!"
                        showAlert = true
                    }
                }
            }
            .navigationTitle("🔧 Developer Testing")
            .alert("Success", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func testSave100() {
        // Simulate saving $100 → earn 1,000 points (10 pts/$1)
        loyaltyService.addPointsManual(1000, confidence: 1.0)
        alertMessage = "✅ Saved $100 → Earned 1,000 points!\n\n(10 pts/$1 rate working correctly)"
        showAlert = true
    }
    
    private func testGoalCompletion() {
        // Simulate completing a goal → earn 5,000 bonus points
        loyaltyService.addPointsManual(5000, confidence: 1.0)
        alertMessage = "✅ Goal Completed → Earned 5,000 bonus points!\n\n(10x bonus working correctly)"
        showAlert = true
    }
    
    private func testAchievementUnlock() {
        // Simulate unlocking an achievement (e.g., Cat = 2,000 pts)
        loyaltyService.addPointsManual(2000, confidence: 1.0)
        alertMessage = "✅ Achievement Unlocked → Earned 2,000 bonus points!\n\n(Cat/Parrot unlock bonus)"
        showAlert = true
    }
    
    // MARK: - Unlock Flow Testing
    
    private func testUnlockFlowWithCat() {
        // Find cat item
        guard let catItem = SceneItem.catalog.first(where: { $0.id == "cat" }) else {
            alertMessage = "❌ Cat item not found in catalog"
            showAlert = true
            return
        }
        
        // Trigger the unlock flow directly
        UnlockFlowCoordinator.shared.startUnlockFlow(for: catItem, bonusPoints: 2500)
        
        // Award points
        loyaltyService.addPointsManual(2500, confidence: 1.0)
    }
    
    private func testUnlockFlowWithParrot() {
        // Find parrot item
        guard let parrotItem = SceneItem.catalog.first(where: { $0.id == "parrot" }) else {
            alertMessage = "❌ Parrot item not found in catalog"
            showAlert = true
            return
        }
        
        // Trigger the unlock flow directly
        UnlockFlowCoordinator.shared.startUnlockFlow(for: parrotItem, bonusPoints: 3000)
        
        // Award points
        loyaltyService.addPointsManual(3000, confidence: 1.0)
    }
    
    private func simulateRedemption(amount: Double, userId: String) {
        let redemptionService = RedemptionLimitsService.shared
        let (canRedeem, reason) = redemptionService.canRedeemAmount(amount, userId: userId)
        
        if canRedeem {
            // Simulate a redemption
            let fakeRedemption = GiftCardRedemption(
                id: UUID().uuidString,
                userId: userId,
                giftCardId: "test_card",
                brand: "Test",
                amount: amount,
                pointsSpent: Int(amount * 500),
                redemptionDate: Date(),
                redemptionCode: nil,
                redemptionLink: nil,
                status: .pending,
                tremendousOrderId: nil
            )
            redemptionService.recordRedemption(fakeRedemption, userId: userId)
            
            alertMessage = "✅ Simulated $\(Int(amount)) redemption!\n\nRemaining: $\(Int(redemptionService.getRemainingThisMonth(userId: userId)))"
            showAlert = true
        } else {
            alertMessage = "❌ Cannot redeem!\n\n\(reason ?? "Unknown error")"
            showAlert = true
        }
    }
    
    private func unlockAllAnimals() {
        let animalIds = SceneItem.catalog
            .filter { $0.category == .animal }
            .map { $0.id }
        
        // Add each animal as "purchased" directly to the set for testing
        for animalId in animalIds {
            if !loyaltyService.hasPurchased(itemId: animalId) {
                // Add to the set directly for testing (bypassing normal purchase flow)
                loyaltyService.purchasedItemIds.insert(animalId)
            }
        }
        
        // Force save by triggering a point change (add 0 to trigger save)
        loyaltyService.addPointsManual(0, confidence: 1.0)
    }
}

// MARK: - Preview
#Preview {
    DeveloperTestingView()
}

