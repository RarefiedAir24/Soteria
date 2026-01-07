//
//  SettingsView.swift
//  rever
//
//  Settings with behavioral features
//

import SwiftUI
import StoreKit
// TEMPORARILY DISABLED: Firebase imports - testing if they're causing crash
// import FirebaseAuth
import UIKit
// #if canImport(FirebaseStorage)
// import FirebaseStorage
// #endif

// MARK: - Lazy Profile View Wrapper

struct LazyProfileView: View {
    var body: some View {
        // ProfileView is pushed onto the existing NavigationView stack from MainTabView
        // It already has .navigationTitle("Profile") set, so it should work correctly
        ProfileView()
            .navigationBarBackButtonHidden(false)
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var subscriptionService: SubscriptionService
    // @EnvironmentObject var plaidService: PlaidService  // Temporarily disabled - Plaid removed
    @State private var showDecisionWindows = false
    @State private var showMoodCheckIn = false
    @State private var showRegretLog = false
    // App naming is now fully automatic via backend - no user editing needed
    // Removed: showAppNaming, showAppManagement (no longer needed)
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
    @State private var avatarImage: UIImage? = nil
    @State private var showProfileView = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showEditOnboarding = false
    @State private var isDeletingAccount = false
    @State private var showPartnerLoyalty = false
    @State private var showRedemptionHistory = false
    @State private var showAdminPartnerManagement = false
    
    // MARK: - Card Color Helpers
    
    private var userEmail: String {
        authService.currentUser?.email ?? ""
    }
    
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
    
    private var accountCardGradient: LinearGradient {
        guard subscriptionService.isPremium else {
            return LinearGradient(
                colors: [Color.cloudWhite, Color.mistGray.opacity(0.5)],
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
                    Color(red: 0.95, green: 0.75, blue: 0.65).opacity(0.4),  // Light rose gold - matches card
                    Color(red: 0.90, green: 0.65, blue: 0.55).opacity(0.35), // Medium rose gold - matches card
                    Color(red: 0.85, green: 0.55, blue: 0.45).opacity(0.3)  // Deeper rose gold - matches card (darkest)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isBeta {
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.4).opacity(0.5),  // Bright yellow - matches card
                    Color(red: 0.98, green: 0.90, blue: 0.35).opacity(0.45), // Medium yellow - matches card
                    Color(red: 0.95, green: 0.85, blue: 0.30).opacity(0.4)  // Deeper yellow - matches card (darkest)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isBlack {
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.05).opacity(0.6),
                    Color(red: 0.08, green: 0.08, blue: 0.08).opacity(0.55),
                    Color(red: 0.06, green: 0.06, blue: 0.06).opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isAnnual {
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.5),
                    Color(red: 0.18, green: 0.18, blue: 0.24).opacity(0.45),
                    Color(red: 0.15, green: 0.15, blue: 0.21).opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.88, blue: 0.55).opacity(0.5),
                    Color(red: 0.92, green: 0.78, blue: 0.45).opacity(0.45),
                    Color(red: 0.88, green: 0.70, blue: 0.35).opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var accountCardBorderColor: Color {
        guard subscriptionService.isPremium else {
            return Color.mistGray.opacity(0.3)
        }
        
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
        
        if isRoseGold {
            return Color(red: 0.85, green: 0.55, blue: 0.45)  // Matches card darkest color
        } else if isBeta {
            return Color(red: 0.9, green: 0.8, blue: 0.5)
        } else if isBlack {
            return Color.white.opacity(0.3)
        } else if isAnnual {
            return Color(red: 0.4, green: 0.4, blue: 0.5)
        } else {
            return Color(red: 0.85, green: 0.7, blue: 0.4)
        }
    }
    
    private var accountCardUsernameColor: Color {
        guard subscriptionService.isPremium else {
            return Color.midnightSlate
        }
        
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
        
        // Black card gets white username, others get dark
        if isBlack {
            return Color.white.opacity(0.95)
        } else if isAnnual {
            return Color(red: 0.95, green: 0.95, blue: 1.0)
        } else {
            return Color(red: 0.2, green: 0.15, blue: 0.1)
        }
    }
    
    private var accountCardLabelColor: Color {
        guard subscriptionService.isPremium else {
            return Color.softGraphite
        }
        
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
        
        if isBlack {
            return Color.white.opacity(0.8)
        } else if isAnnual {
            return Color(red: 0.85, green: 0.85, blue: 0.95)
        } else {
            return Color(red: 0.3, green: 0.25, blue: 0.2)
        }
    }
    
    private var accountCardAccentColor: Color {
        guard subscriptionService.isPremium else {
            return Color.reverBlue
        }
        
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
        
        if isBlack {
            return Color.white.opacity(0.9)
        } else if isAnnual {
            return Color(red: 0.9, green: 0.9, blue: 1.0)
        } else {
            return Color(red: 0.4, green: 0.3, blue: 0.2)
        }
    }
    
    // MARK: - Header Background Color
    
    private var headerBackgroundGradient: LinearGradient {
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
                    Color(red: 0.95, green: 0.75, blue: 0.65),  // Light rose gold - matches card
                    Color(red: 0.90, green: 0.65, blue: 0.55), // Medium rose gold - matches card
                    Color(red: 0.85, green: 0.55, blue: 0.45)  // Deeper rose gold - matches card (darkest)
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
    
    // Extract ScrollView content to help compiler type-check
    private var scrollContent: some View {
        ScrollView {
                Color.clear
                    .frame(height: 60)
                
                VStack(spacing: .spacingCard) {
                    // Account & Subscription Card
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            print("🔵 [SettingsView] Account button tapped - setting showProfileView = true")
                            showProfileView = true
                            print("🔵 [SettingsView] showProfileView is now: \(showProfileView)")
                        }) {
                            HStack(spacing: 12) {
                                // Avatar - wrapped in Group to prevent re-evaluation from affecting navigation
                                Group {
                                    if let avatarImage = avatarImage {
                                        Image(uiImage: avatarImage)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        // Default avatar
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.deepReverBlue, Color.reverBlue],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                            
                                            if let user = authService.currentUser, let email = user.email {
                                                Text(String((email.components(separatedBy: "@").first ?? "U").prefix(1)).uppercased())
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Account")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(accountCardLabelColor)
                                    
                                    if let user = authService.currentUser {
                                        Text(user.email ?? "Unknown User")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(accountCardUsernameColor)
                                        
                                        // Show User ID for easy copying (tap to copy)
                                        if let userId = authService.getUserId() {
                                            HStack(spacing: 4) {
                                                Text("ID: \(userId.prefix(8))...")
                                                    .font(.system(size: 11, weight: .regular))
                                                    .foregroundColor(accountCardLabelColor.opacity(0.7))
                                                Image(systemName: "doc.on.doc")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(accountCardLabelColor.opacity(0.5))
                                            }
                                            .onTapGesture {
                                                UIPasteboard.general.string = userId
                                                print("✅ [SettingsView] User ID copied to clipboard: \(userId)")
                                            }
                                        }
                                        
                                        Text("Manage account, banking & preferences")
                                            .font(.system(size: 13))
                                            .foregroundColor(accountCardLabelColor)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(accountCardLabelColor)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .background(accountCardLabelColor.opacity(0.3))
                        
                        // Subscription Status
                        HStack {
                            Image(systemName: subscriptionService.isPremium ? "crown.fill" : "crown")
                                .font(.system(size: 20))
                                .foregroundColor(subscriptionService.isPremium ? accountCardAccentColor : .softGraphite)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subscriptionService.isPremium ? "Premium" : "Free")
                                    .reverBody()
                                    .fontWeight(.semibold)
                                    .foregroundColor(accountCardUsernameColor)
                                
                                if !subscriptionService.isPremium {
                                    Text("Upgrade for advanced features")
                                        .font(.system(size: 12))
                                        .foregroundColor(accountCardLabelColor)
                                }
                            }
                            
                            Spacer()
                            
                            if !subscriptionService.isPremium {
                                Button(action: {
                                    showPaywall = true
                                }) {
                                    Text("Upgrade")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.reverBlue)
                                        )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        ZStack {
                            Color.cloudWhite
                            accountCardGradient
                        }
                    )
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(accountCardBorderColor, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, .spacingCard)
                    
                    // Store/Subscription Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Store")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.midnightSlate)
                        
                        SettingsRow(
                            icon: "crown.fill",
                            title: subscriptionService.isPremium ? "Manage Subscription" : "Upgrade to Premium",
                            subtitle: subscriptionService.isPremium ? "Manage or cancel your subscription" : "Unlock all features",
                            color: subscriptionService.isPremium ? Color(red: 1.0, green: 0.84, blue: 0.0) : Color.softGraphite
                        ) {
                            print("🔔 [SettingsView] Manage Subscription button tapped")
                            print("🔔 [SettingsView] subscriptionService.isPremium: \(subscriptionService.isPremium)")
                            print("🔔 [SettingsView] subscriptionService.subscriptionTier: \(subscriptionService.subscriptionTier)")
                            
                            if subscriptionService.isPremium {
                                print("🔔 [SettingsView] Premium user - setting showManageSubscriptions = true")
                                showManageSubscriptions = true
                                print("🔔 [SettingsView] showManageSubscriptions is now: \(showManageSubscriptions)")
                            } else {
                                print("🔔 [SettingsView] Free user - opening paywall")
                                showPaywall = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .reverCard()
                    .padding(.horizontal, .spacingCard)
                    
                    // Update Profile / Edit Onboarding
                    if OnboardingSurveyService.shared.hasCompletedSurvey {
                        VStack(alignment: .leading, spacing: 16) {
                            SettingsRow(
                                icon: "person.circle.fill",
                                title: "Update Profile",
                                subtitle: "Edit your savings preferences",
                                color: Color.softGraphite
                            ) {
                                showEditOnboarding = true
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .reverCard()
                        .padding(.horizontal, .spacingCard)
                        .sheet(isPresented: $showEditOnboarding) {
                            NavigationView {
                                OnboardingSurveyView(isEditMode: true)
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbar {
                                        ToolbarItem(placement: .cancellationAction) {
                                            Button("Cancel") {
                                                showEditOnboarding = false
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    
                    // Behavioral Features Section (Premium)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Behavioral Features")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.midnightSlate)
                            
                            if !subscriptionService.isPremium {
                                Text("Premium")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.softGraphite)
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Decision Notifications (Savings Behavior)
                        // NOTE: User-facing name is "Decision Notifications" but internal code uses "Decision Windows"
                        SettingsRow(
                            icon: "bell.fill",
                            title: "Decision Notifications",
                            subtitle: "Time-based savings prompts",
                            color: Color.softGraphite
                        ) {
                            if subscriptionService.isPremium {
                                showDecisionWindows = true
                            } else {
                                showPaywall = true
                            }
                        }
                        
                        // Mood Check-In
                        SettingsRow(
                            icon: "heart.fill",
                            title: "Mood Check-In",
                            subtitle: "Track your mood",
                            color: Color.softGraphite
                        ) {
                            showMoodCheckIn = true
                        }
                        
                        Divider()
                        
                        // Regret Log
                        SettingsRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Regret Log",
                            subtitle: "View regret purchases",
                            color: .orange
                        ) {
                            showRegretLog = true
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .reverCard()
                    .padding(.horizontal, .spacingCard)
                    
                    // Partner Loyalty Section (Premium)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Partner Loyalty")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.midnightSlate)
                            
                            if !subscriptionService.isPremium {
                                Text("Premium")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.98, green: 0.88, blue: 0.55), Color(red: 0.92, green: 0.78, blue: 0.45)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(8)
                                    .shadow(color: Color(red: 0.92, green: 0.78, blue: 0.45).opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        
                        // Partner Benefits
                        Button(action: {
                            showPartnerLoyalty = true
                        }) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.reverBlue.opacity(0.15), Color.reverBlue.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "ticket.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.reverBlue, Color.deepReverBlue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Partner Benefits")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.midnightSlate)
                                    
                                    Text("Exclusive loyalty & offers")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.softGraphite)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.reverBlue.opacity(0.6))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.reverBlue.opacity(0.2), Color.reverBlue.opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!subscriptionService.isPremium)
                        .opacity(subscriptionService.isPremium ? 1.0 : 0.6)
                        
                        // Admin Partner Management (only for supergeek@me.com)
                        if userEmail.lowercased() == "supergeek@me.com" {
                            Divider()
                                .padding(.vertical, 8)
                            
                            SettingsRow(
                                icon: "gearshape.2.fill",
                                title: "Admin: Manage Partners",
                                subtitle: "Edit partner logos and information",
                                color: Color.orange
                            ) {
                                print("🔵 [SettingsView] Admin Partner Management button tapped")
                                print("🔵 [SettingsView] Current email: \(userEmail)")
                                print("🔵 [SettingsView] showAdminPartnerManagement before: \(showAdminPartnerManagement)")
                                showAdminPartnerManagement = true
                                print("🔵 [SettingsView] showAdminPartnerManagement after: \(showAdminPartnerManagement)")
                            }
                        }
                        
                        // Redemption History
                        Button(action: {
                            showRedemptionHistory = true
                        }) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0.98, green: 0.88, blue: 0.55).opacity(0.2), Color(red: 0.92, green: 0.78, blue: 0.45).opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(red: 0.98, green: 0.88, blue: 0.55), Color(red: 0.92, green: 0.78, blue: 0.45)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Redemption History")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.midnightSlate)
                                    
                                    Text("Track your savings & analytics")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.softGraphite)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.92, green: 0.78, blue: 0.45).opacity(0.6))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color(red: 0.98, green: 0.88, blue: 0.55).opacity(0.2), Color(red: 0.92, green: 0.78, blue: 0.45).opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!subscriptionService.isPremium)
                        .opacity(subscriptionService.isPremium ? 1.0 : 0.6)
                        
                        if !subscriptionService.isPremium {
                            Button(action: {
                                showPaywall = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Upgrade to Premium")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.reverBlue, Color.deepReverBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.reverBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .reverCard()
                    .padding(.horizontal, .spacingCard)
                    
                    // Sign Out Button
                    Button(action: {
                        try? authService.signOut()
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Delete Account Button
                    Button(action: {
                        showDeleteAccountConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            if isDeletingAccount {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                Text("Deleting...")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                                    .padding(.leading, 8)
                            } else {
                                Text("Delete Account")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    .disabled(isDeletingAccount)
                    .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
                        Button("Delete", role: .destructive) {
                            Task {
                                await deleteAccount()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will permanently delete all your data including:\n\n• All goals and progress\n• Purchase intents and regrets\n• Mood tracking data\n• Quiet hours schedules\n• App usage history\n\nThis action cannot be undone. Are you sure you want to delete your account?")
                    }
                    
                    Spacer(minLength: 40)
                }
        }
    }
    
    var body: some View {
        let _ = {
            let timestamp = Date()
            print("🟢 [SettingsView] body evaluated at \(timestamp)")
        }()
        
        return ZStack(alignment: .top) {
            // REVER background
            Color.mistGray
                .ignoresSafeArea(.all, edges: .top)
            Color.cloudWhite
                .ignoresSafeArea()
            
            scrollContent
            
            // Premium Header
            PremiumHeaderView(
                title: "Settings",
                subscriptionService: subscriptionService,
                userEmail: userEmail
            )
        }
        // App naming is fully automatic via backend - no user editing sheets needed
        // NOTE: OpenQuietHours notification handler removed - Quiet Hours feature removed
        // NOTE: OpenSavingsReminders notification handler removed - Savings Reminders feature removed
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenDecisionWindows"))) { _ in
            print("🔔 [SettingsView] Received OpenDecisionWindows notification - opening Decision Notifications")
            showDecisionWindows = true
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .onChange(of: showManageSubscriptions) { oldValue, newValue in
            print("🔔 [SettingsView] showManageSubscriptions changed from \(oldValue) to \(newValue)")
        }
        .fullScreenCover(isPresented: $showDecisionWindows) {
            NavigationView {
                DecisionWindowsView()
                    .environmentObject(subscriptionService)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showDecisionWindows = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showMoodCheckIn) {
            NavigationView {
                MoodCheckInView()
                    .environmentObject(MoodTrackingService.shared)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showMoodCheckIn = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showRegretLog) {
            NavigationView {
                RegretLogView()
                    .environmentObject(RegretLoggingService.shared)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showRegretLog = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showProfileView) {
            NavigationView {
                LazyProfileView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                print("🔵 [SettingsView] Done button tapped - setting showProfileView = false")
                                showProfileView = false
                            }
                        }
                    }
            }
            .onAppear {
                print("🔵 [SettingsView] Profile sheet appeared")
            }
        }
        .sheet(isPresented: $showPartnerLoyalty) {
            PartnerLoyaltyView()
        }
        .sheet(isPresented: $showRedemptionHistory) {
            RedemptionHistoryView()
        }
        .sheet(isPresented: $showAdminPartnerManagement) {
            AdminPartnerManagementView()
                .environmentObject(authService)
                .onAppear {
                    print("🔵 [SettingsView] AdminPartnerManagementView sheet appeared")
                }
        }
        .onChange(of: showAdminPartnerManagement) { oldValue, newValue in
            print("🔵 [SettingsView] showAdminPartnerManagement changed from \(oldValue) to \(newValue)")
        }
        .onChange(of: showProfileView) { oldValue, newValue in
            print("🔵 [SettingsView] showProfileView changed from \(oldValue) to \(newValue)")
        }
        .onAppear {
            let timestamp = Date()
            print("🟢 [SettingsView] onAppear at \(timestamp)")
        }
        .task {
            // Load avatar first (fast, from UserDefaults)
            loadAvatar()
            
            // NOTE: Protection Hours loading removed - feature has been removed
        }
    }
    
    private func loadAvatar() {
        // Load from UserDefaults only (local cache)
        // App deletion serves as account deletion, so no need for cloud persistence
        if let data = UserDefaults.standard.data(forKey: "user_avatar"),
           let image = UIImage(data: data) {
            avatarImage = image
            print("✅ [SettingsView] Avatar loaded from UserDefaults")
        } else {
            avatarImage = nil
        }
    }
    
    // MARK: - Account Deletion
    
    private func deleteAccount() async {
        guard let userId = authService.currentUserId else {
            print("❌ [SettingsView] Cannot delete account - no user ID")
            return
        }
        
        isDeletingAccount = true
        
        do {
            // Delete all user data from AWS (DynamoDB and Cognito)
            try await AWSDataService.shared.deleteUserData(userId: userId)
            
            // Clear all local data (UserDefaults)
            // Note: This will be cleared when we sign out, but let's be explicit
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            // Sign out (this clears auth state)
            try authService.signOut()
            
            print("✅ [SettingsView] Account deleted successfully")
            
            // The app will automatically navigate to sign-in screen via RootView
            // since authService.isAuthenticated will be false
            
        } catch {
            print("❌ [SettingsView] Failed to delete account: \(error.localizedDescription)")
            
            // Show error alert
            await MainActor.run {
                // Error will be shown via the alert system
                // For now, just log it - user can try again
                isDeletingAccount = false
            }
        }
    }
}

// Helper function to add timeout to async operations
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.midnightSlate)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.softGraphite)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.softGraphite)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mistGray)
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(SubscriptionService.shared)
}
