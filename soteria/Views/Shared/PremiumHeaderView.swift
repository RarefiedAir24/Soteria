//
//  PremiumHeaderView.swift
//  soteria
//
//  Unified premium header component for all pages
//

import SwiftUI

struct PremiumHeaderView: View {
    let title: String
    @ObservedObject var subscriptionService: SubscriptionService
    let userEmail: String
    
    var body: some View {
        VStack(spacing: 0) {
            headerContent
        }
        .frame(maxWidth: .infinity)
        .background(headerGradient.ignoresSafeArea(edges: .top))
        .zIndex(100)
    }
    
    private var headerContent: some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(headerTextColor)
                .tracking(0.5) // Add letter spacing for prestige
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
    
    // MARK: - Card Type Detection
    
    private func isBetaTester() -> Bool {
        if userEmail.lowercased() == "supergeek@me.com" {
            return false
        }
        #if DEBUG
        return true
        #else
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           receiptURL.lastPathComponent == "sandboxReceipt" {
            return true
        }
        return UserDefaults.standard.bool(forKey: "is_beta_tester")
        #endif
    }
    
    private func isRoseGoldFounder() -> Bool {
        return userEmail.lowercased() == "supergeek@me.com"
    }
    
    private func isBlackCardEligible() -> Bool {
        if isBetaTester() || isRoseGoldFounder() {
            return false
        }
        let isFirst100Annual = UserDefaults.standard.bool(forKey: "is_first_100_annual_user")
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        return isFirst100Annual && isAnnual
    }
    
    // MARK: - Header Styling
    
    private var headerGradient: LinearGradient {
        guard subscriptionService.isPremium else {
            // Free users get gray
            return LinearGradient(
                colors: [Color(red: 0.92, green: 0.97, blue: 0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
        
        if isRoseGold {
            return LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.65, blue: 0.55),
                    Color(red: 0.82, green: 0.58, blue: 0.48),
                    Color(red: 0.78, green: 0.52, blue: 0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isBeta {
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.4),
                    Color(red: 0.98, green: 0.90, blue: 0.35),
                    Color(red: 0.95, green: 0.85, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isBlack {
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.05),
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.06, green: 0.06, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isAnnual {
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.18),
                    Color(red: 0.18, green: 0.18, blue: 0.24),
                    Color(red: 0.15, green: 0.15, blue: 0.21)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Gold (monthly)
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.88, blue: 0.55),
                    Color(red: 0.92, green: 0.78, blue: 0.45),
                    Color(red: 0.88, green: 0.70, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var headerTextColor: Color {
        guard subscriptionService.isPremium else {
            return Color.midnightSlate
        }
        
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
        
        // Black cards need white text for readability
        if isBlack {
            return Color.white.opacity(0.95)
        }
        // Platinum (annual) - light text for contrast
        else if isAnnual {
            return Color(red: 0.95, green: 0.95, blue: 1.0)
        }
        // Rose Gold - dark text
        else if isRoseGold {
            return Color(red: 0.35, green: 0.25, blue: 0.2)
        }
        // Beta (yellow) - dark text
        else if isBeta {
            return Color(red: 0.3, green: 0.25, blue: 0.1)
        }
        // Gold (monthly) - dark text
        else {
            return Color(red: 0.3, green: 0.2, blue: 0.1)
        }
    }
}

