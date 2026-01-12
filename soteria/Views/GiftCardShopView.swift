//
//  GiftCardShopView.swift
//  soteria
//
//  Premium-only gift card redemption view - REDESIGNED FOR AMAZING UX
//

import SwiftUI

struct GiftCardShopView: View {
    @ObservedObject private var loyaltyService = LoyaltyPointsService.shared
    @ObservedObject private var recommendationService = GiftCardRecommendationService.shared
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    @State private var selectedCard: GiftCard?
    @State private var showRedemptionConfirmation = false
    @State private var showSuccessMessage = false
    @State private var isRedeeming = false
    @State private var errorMessage: String?
    @State private var redemptionResult: GiftCardRedemption?
    @State private var expandedBrand: String? = nil
    
    // Group cards by brand
    private var cardsByBrand: [String: [GiftCard]] {
        Dictionary(grouping: GiftCard.availableCards, by: { $0.brand })
    }
    
    // Cards user can afford right now - AI RECOMMENDED
    private var affordableCards: [GiftCard] {
        let affordable = GiftCard.availableCards.filter { $0.pointsCost <= loyaltyService.totalPoints }
        
        // Use AI recommendations if user has history, otherwise sort by amount
        if !recommendationService.redemptionHistory.isEmpty {
            return recommendationService.getRecommendations(
                currentPoints: loyaltyService.totalPoints,
                availableCards: affordable
            )
        } else {
            return affordable.sorted { $0.amount < $1.amount }
        }
    }
    
    // Next card to unlock
    private var nextCard: GiftCard? {
        GiftCard.availableCards
            .filter { $0.pointsCost > loyaltyService.totalPoints }
            .sorted { $0.pointsCost < $1.pointsCost }
            .first
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.88, green: 0.93, blue: 0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if !subscriptionService.isPremium {
                GiftCardsLockedView()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // AI Personalized Insight
                        if let insight = recommendationService.getPersonalizedInsight() {
                            personalizedInsightCard(insight)
                        }
                        
                        // Monthly Cap Progress
                        monthlyCapCard
                        
                        // Quick Picks - Cards you can afford NOW (AI RECOMMENDED)
                        if !affordableCards.isEmpty {
                            quickPicksSection
                        }
                        
                        // Next Unlock Goal
                        if let next = nextCard {
                            nextUnlockCard(next)
                        }
                        
                        // Brand Sections (Collapsible)
                        brandSectionsView
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            
            // Loading Overlay
            if isRedeeming {
                loadingOverlay
            }
        }
        .alert("Confirm Redemption", isPresented: $showRedemptionConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Redeem") {
                if let card = selectedCard {
                    Task {
                        await redeemCard(card)
                    }
                }
            }
        } message: {
            if let card = selectedCard {
                Text("Redeem \(card.name) for \(card.pointsCost) points?")
            }
        }
        .fullScreenCover(isPresented: $showSuccessMessage) {
            if let redemption = redemptionResult {
                RedemptionSuccessView(redemption: redemption) {
                    showSuccessMessage = false
                    redemptionResult = nil
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Title
            Text("🎁 Gift Card Rewards")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.midnightSlate)
            
            Text("Redeem loyalty points for real rewards")
                .font(.system(size: 15))
                .foregroundColor(.softGraphite)
            
            // Points Balance Card
            HStack(spacing: 16) {
                // Points
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Points")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                        
                        Text("\(loyaltyService.totalPoints)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Value
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Cash Value")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("$\(String(format: "%.2f", Double(loyaltyService.totalPoints) / 500.0))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.reverBlue, Color.deepReverBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.reverBlue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Personalized Insight Card
    
    private func personalizedInsightCard(_ insight: String) -> some View {
        HStack(spacing: 12) {
            // Sparkle icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            Text(insight)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.midnightSlate)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.purple.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Monthly Cap Card
    
    private var monthlyCapCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Cap")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    Text("Resets monthly")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                }
                
                Spacer()
                
                if let userId = authService.currentUserId {
                    let remaining = RedemptionLimitsService.shared.getRemainingThisMonth(userId: userId)
                    let cap = RedemptionLimitsService.shared.getMonthlyCapForUser()
                    let redeemed = cap - remaining
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(Int(remaining)) left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(remaining > 0 ? .green : .red)
                        
                        Text("of $\(Int(cap))")
                            .font(.system(size: 12))
                            .foregroundColor(.softGraphite)
                    }
                }
            }
            
            // Progress Bar
            if let userId = authService.currentUserId {
                let remaining = RedemptionLimitsService.shared.getRemainingThisMonth(userId: userId)
                let cap = RedemptionLimitsService.shared.getMonthlyCapForUser()
                let progress = cap > 0 ? (cap - remaining) / cap : 0
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.softGraphite.opacity(0.2))
                            .frame(height: 12)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: progress < 0.8 ? [Color.green, Color.green.opacity(0.7)] : [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 12)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Quick Picks Section
    
    private var quickPicksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Picks")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.midnightSlate)
                    
                    if !recommendationService.redemptionHistory.isEmpty {
                        Text("✨ Personalized for you")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                    } else {
                        Text("Redeem now!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(affordableCards.prefix(6)) { card in
                        QuickPickCard(card: card) {
                            selectedCard = card
                            showRedemptionConfirmation = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Next Unlock Card
    
    private func nextUnlockCard(_ card: GiftCard) -> some View {
        let pointsNeeded = card.pointsCost - loyaltyService.totalPoints
        let progress = Double(loyaltyService.totalPoints) / Double(card.pointsCost)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
                
                Text("Next Unlock")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Card Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: brandColors(for: card.brand),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: card.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    Text("\(pointsNeeded) more points needed")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.softGraphite.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.purple.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Brand Sections
    
    private var brandSectionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.reverBlue)
                
                Text("All Gift Cards")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
            }
            
            // Brand Sections
            ForEach(["Visa", "Amazon", "Target", "Walmart", "Starbucks"], id: \.self) { brand in
                if let cards = cardsByBrand[brand] {
                    BrandSection(
                        brand: brand,
                        cards: cards.sorted { $0.amount < $1.amount },
                        currentPoints: loyaltyService.totalPoints,
                        isExpanded: expandedBrand == brand,
                        onTap: {
                            withAnimation {
                                expandedBrand = expandedBrand == brand ? nil : brand
                            }
                        },
                        onRedeem: { card in
                            selectedCard = card
                            showRedemptionConfirmation = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Processing redemption...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.midnightSlate)
            .cornerRadius(20)
        }
    }
    
    // MARK: - Helper Functions
    
    private func brandColors(for brand: String) -> [Color] {
        switch brand {
        case "Visa": return [Color.blue, Color.blue.opacity(0.7)]
        case "Amazon": return [Color.orange, Color.orange.opacity(0.7)]
        case "Target": return [Color.red, Color.red.opacity(0.7)]
        case "Walmart": return [Color.blue, Color.blue.opacity(0.7)]
        case "Starbucks": return [Color.green, Color.green.opacity(0.7)]
        default: return [Color.gray, Color.gray.opacity(0.7)]
        }
    }
    
    private func redeemCard(_ card: GiftCard) async {
        guard let userId = authService.currentUserId,
              let email = authService.currentUser?.email else {
            errorMessage = "User not authenticated"
            return
        }
        
        isRedeeming = true
        
        do {
            let redemption = try await loyaltyService.redeemGiftCard(giftCard: card, userId: userId, email: email)
            
            // Store redemption result with link
            redemptionResult = redemption
            
            // Record redemption for AI learning
            recommendationService.recordRedemption(card)
            
            showSuccessMessage = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            errorMessage = "Failed to redeem gift card: \(error.localizedDescription)"
        }
        
        isRedeeming = false
    }
}

// MARK: - Quick Pick Card Component

struct QuickPickCard: View {
    let card: GiftCard
    let onRedeem: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: brandGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: card.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Amount
            Text("$\(Int(card.amount))")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.midnightSlate)
            
            Text(card.brand)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.softGraphite)
            
            // Redeem Button
            Button(action: onRedeem) {
                Text("Redeem")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: brandGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
            }
        }
        .frame(width: 140)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var brandGradient: [Color] {
        switch card.brand {
        case "Visa": return [Color.blue, Color.blue.opacity(0.8)]
        case "Amazon": return [Color.orange, Color.orange.opacity(0.8)]
        case "Target": return [Color.red, Color.red.opacity(0.8)]
        case "Walmart": return [Color.blue, Color.blue.opacity(0.8)]
        case "Starbucks": return [Color.green, Color.green.opacity(0.8)]
        default: return [Color.gray, Color.gray.opacity(0.8)]
        }
    }
}

// MARK: - Brand Section Component

struct BrandSection: View {
    let brand: String
    let cards: [GiftCard]
    let currentPoints: Int
    let isExpanded: Bool
    let onTap: () -> Void
    let onRedeem: (GiftCard) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: onTap) {
                HStack {
                    // Brand Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: brandGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: brandIcon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(brand)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("\(cards.count) denominations")
                            .font(.system(size: 13))
                            .foregroundColor(.softGraphite)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.softGraphite)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            // Expanded Cards
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(cards) { card in
                            DenominationCard(
                                card: card,
                                currentPoints: currentPoints,
                                brandGradient: brandGradient,
                                onRedeem: { onRedeem(card) }
                            )
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
    
    private var brandIcon: String {
        switch brand {
        case "Visa": return "creditcard.fill"
        case "Amazon": return "cart.fill"
        case "Target": return "target"
        case "Walmart": return "bag.fill"
        case "Starbucks": return "cup.and.saucer.fill"
        default: return "giftcard.fill"
        }
    }
    
    private var brandGradient: [Color] {
        switch brand {
        case "Visa": return [Color.blue, Color.blue.opacity(0.7)]
        case "Amazon": return [Color.orange, Color.orange.opacity(0.7)]
        case "Target": return [Color.red, Color.red.opacity(0.7)]
        case "Walmart": return [Color.blue, Color.blue.opacity(0.7)]
        case "Starbucks": return [Color.green, Color.green.opacity(0.7)]
        default: return [Color.gray, Color.gray.opacity(0.7)]
        }
    }
}

// MARK: - Denomination Card Component

struct DenominationCard: View {
    let card: GiftCard
    let currentPoints: Int
    let brandGradient: [Color]
    let onRedeem: () -> Void
    
    private var canAfford: Bool {
        currentPoints >= card.pointsCost
    }
    
    private var progress: Double {
        min(1.0, Double(currentPoints) / Double(card.pointsCost))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Amount Badge
            Text("$\(Int(card.amount))")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(canAfford ? .midnightSlate : .softGraphite)
            
            // Points Cost
            Text("\(card.pointsCost) pts")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.softGraphite)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.softGraphite.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: brandGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            
            // Status
            if canAfford {
                Button(action: onRedeem) {
                    Text("Redeem")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: brandGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
            } else {
                Text("🔒 \(card.pointsCost - currentPoints) more")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.softGraphite)
                    .padding(.vertical, 10)
            }
        }
        .frame(width: 120)
        .padding(12)
        .background(canAfford ? Color.white : Color.softGraphite.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(canAfford ? Color.clear : Color.softGraphite.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        GiftCardShopView()
            .environmentObject(AuthService())
            .environmentObject(SubscriptionService.shared)
    }
}
