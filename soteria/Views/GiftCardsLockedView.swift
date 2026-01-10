//
//  GiftCardsLockedView.swift
//  soteria
//
//  View shown to free users when they try to access gift cards
//

import SwiftUI

struct GiftCardsLockedView: View {
    @ObservedObject private var loyaltyService = LoyaltyPointsService.shared
    @ObservedObject private var missedPointsTracker = MissedPointsTracker.shared
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            Color.cloudWhite.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Gift Card Rewards")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        if missedPointsTracker.missedPoints > 0 {
                            VStack(spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.slash.fill")
                                        .foregroundColor(.orange.opacity(0.7))
                                    Text("\(missedPointsTracker.missedPoints) Missed Points")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.softGraphite)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(20)
                                
                                if let message = missedPointsTracker.getConversionMessage() {
                                    Text(message)
                                        .font(.system(size: 13))
                                        .foregroundColor(.softGraphite)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Locked gift cards preview (show first 2)
                    ForEach(Array(GiftCard.availableCards.prefix(2))) { card in
                        LockedGiftCardTile(
                            card: card,
                            missedPoints: missedPointsTracker.missedPoints
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Upgrade CTA
                    VStack(spacing: 20) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.88, blue: 0.55), Color(red: 0.92, green: 0.78, blue: 0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Upgrade to Premium")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Unlock gift card redemptions + savings tools")
                            .font(.system(size: 16))
                            .foregroundColor(.softGraphite)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Benefits
                        VStack(alignment: .leading, spacing: 16) {
                            PremiumBenefit(
                                icon: "gift.fill",
                                text: "Redeem points for Amazon, Target, Starbucks, Visa"
                            )
                            PremiumBenefit(
                                icon: "chart.line.uptrend.xyaxis",
                                text: "Activate savings tools (save $150-400/month)"
                            )
                            PremiumBenefit(
                                icon: "star.fill",
                                text: "Earn 50% more loyalty points on every save"
                            )
                            PremiumBenefit(
                                icon: "sparkles",
                                text: "Unlock exclusive money tree scene items"
                            )
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 12)
                        
                        // Pricing
                        VStack(spacing: 8) {
                            Text("Just $9.99/month")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.reverBlue)
                            
                            Text("Average member value: $160-425/month")
                                .font(.system(size: 13))
                                .foregroundColor(.softGraphite)
                        }
                        
                        // CTA Button
                        Button(action: { showPaywall = true }) {
                            Text("Upgrade to Premium")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.reverBlue, Color.reverBlue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.reverBlue.opacity(0.3), radius: 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Locked Gift Card Tile

struct LockedGiftCardTile: View {
    let card: GiftCard
    let missedPoints: Int
    
    private var missedProgress: Double {
        min(Double(missedPoints) / Double(card.pointsCost), 1.0)
    }
    
    private var couldAfford: Bool {
        missedPoints >= card.pointsCost
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Card header
            HStack(spacing: 16) {
                // Icon (grayed out)
                ZStack {
                    Circle()
                        .fill(Color.softGraphite.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: card.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(.softGraphite.opacity(0.5))
                }
                
                // Card info
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.softGraphite)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("\(card.pointsCost) points")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.softGraphite.opacity(0.7))
                }
                
                Spacer()
                
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.softGraphite.opacity(0.5))
            }
            
            // Missed points progress (if any)
            if missedPoints > 0 && !couldAfford {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Missed Progress")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange.opacity(0.7))
                        Spacer()
                        Text("\(Int(missedProgress * 100))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange.opacity(0.7))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.softGraphite.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.5), Color.orange.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * missedProgress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("You missed \(missedPoints) points as a free user")
                        .font(.system(size: 12))
                        .foregroundColor(.orange.opacity(0.7))
                }
            } else if couldAfford {
                // They missed enough points!
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("You've missed enough points to redeem this!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 8)
            }
            
            // Premium required message
            VStack(spacing: 8) {
                Text("🔒 Premium Feature")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.softGraphite)
                
                Text("Upgrade to Premium to redeem gift cards with your loyalty points")
                    .font(.system(size: 12))
                    .foregroundColor(.softGraphite.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.softGraphite.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Premium Benefit Row

struct PremiumBenefit: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.reverBlue)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.midnightSlate)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    GiftCardsLockedView()
        .environmentObject(SubscriptionService.shared)
}
