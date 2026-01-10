//
//  GiftCardShopView.swift
//  soteria
//
//  Premium-only gift card redemption view
//

import SwiftUI

struct GiftCardShopView: View {
    @ObservedObject private var loyaltyService = LoyaltyPointsService.shared
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    @State private var selectedCard: GiftCard?
    @State private var showRedemptionConfirmation = false
    @State private var showSuccessMessage = false
    @State private var isRedeeming = false
    @State private var errorMessage: String?
    @State private var redemptionResult: GiftCardRedemption?
    
    var body: some View {
        ZStack {
            Color.cloudWhite.ignoresSafeArea()
            
            if !subscriptionService.isPremium {
                // Should never happen, but show locked view as failsafe
                GiftCardsLockedView()
            } else {
                // Premium user - show gift card shop
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with points balance
                        VStack(spacing: 8) {
                            Text("Gift Card Rewards")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.midnightSlate)
                            
                            Text("Redeem your loyalty points")
                                .font(.system(size: 15))
                                .foregroundColor(.softGraphite)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                Text("\(loyaltyService.totalPoints) Points")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.reverBlue)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.softGraphite.opacity(0.1))
                            .cornerRadius(20)
                        }
                        .padding(.top, 20)
                        
                        // Gift cards grid
                        ForEach(GiftCard.availableCards) { card in
                            GiftCardTile(
                                card: card,
                                currentPoints: loyaltyService.totalPoints,
                                onRedeem: {
                                    selectedCard = card
                                    showRedemptionConfirmation = true
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                .overlay(
                    Group {
                        if isRedeeming {
                            ZStack {
                                Color.black.opacity(0.3)
                                    .ignoresSafeArea()
                                
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .reverBlue))
                                    
                                    Text("Processing redemption...")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(32)
                                .background(Color.midnightSlate.opacity(0.95))
                                .cornerRadius(16)
                            }
                        }
                    }
                )
            }
        }
        .confirmationDialog(
            "Redeem Gift Card?",
            isPresented: $showRedemptionConfirmation,
            presenting: selectedCard
        ) { card in
            Button("Redeem \(card.name) for \(card.pointsCost) points") {
                Task {
                    await redeemCard(card)
                }
            }
            Button("Cancel", role: .cancel) {
                selectedCard = nil
            }
        } message: { card in
            Text("This will deduct \(card.pointsCost) points from your balance and send the gift card to \(authService.currentUser?.email ?? "your email").")
        }
        .alert("Gift Card Sent! 🎉", isPresented: $showSuccessMessage) {
            Button("OK") {
                selectedCard = nil
                redemptionResult = nil
            }
        } message: {
            if let result = redemptionResult {
                Text("Your \(result.brand) gift card has been sent to \(authService.currentUser?.email ?? "your email"). Check your inbox!")
            } else {
                Text("Your gift card has been sent! Check your email.")
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
    }
    
    private func redeemCard(_ card: GiftCard) async {
        guard let userId = authService.currentUserUID,
              let email = authService.currentUser?.email else {
            errorMessage = "User not authenticated"
            return
        }
        
        isRedeeming = true
        
        do {
            // Call loyalty service to redeem
            let result = try await loyaltyService.redeemGiftCard(
                giftCard: card,
                userId: userId,
                email: email
            )
            
            redemptionResult = result
            showSuccessMessage = true
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            print("🎁 [GiftCardShop] Successfully redeemed \(card.name)")
            
        } catch let error as LoyaltyPointsService.GiftCardRedemptionError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to redeem gift card: \(error.localizedDescription)"
        }
        
        isRedeeming = false
    }
}

// MARK: - Gift Card Tile

struct GiftCardTile: View {
    let card: GiftCard
    let currentPoints: Int
    let onRedeem: () -> Void
    
    private var canAfford: Bool {
        currentPoints >= card.pointsCost
    }
    
    private var progress: Double {
        min(Double(currentPoints) / Double(card.pointsCost), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Card header
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: canAfford ? [Color.reverBlue.opacity(0.2), Color.reverBlue.opacity(0.1)] : [Color.softGraphite.opacity(0.2), Color.softGraphite.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: card.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(canAfford ? .reverBlue : .softGraphite)
                }
                
                // Card info
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("\(card.pointsCost) points")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.softGraphite)
                }
                
                Spacer()
            }
            
            // Progress bar (only show if not yet affordable)
            if !canAfford {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.softGraphite)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.reverBlue)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.softGraphite.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.reverBlue, Color.reverBlue.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("Need \(card.pointsCost - currentPoints) more points")
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite.opacity(0.8))
                }
            }
            
            // Redeem button
            Button(action: onRedeem) {
                HStack {
                    if canAfford {
                        Image(systemName: "gift.fill")
                        Text("Redeem Now")
                    } else {
                        Image(systemName: "lock.fill")
                        Text("Locked")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    canAfford ?
                        LinearGradient(colors: [Color.reverBlue, Color.reverBlue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Color.softGraphite.opacity(0.6), Color.softGraphite.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
            .disabled(!canAfford)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    GiftCardShopView()
        .environmentObject(AuthService())
        .environmentObject(SubscriptionService.shared)
}
