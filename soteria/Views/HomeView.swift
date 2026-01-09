//
//  HomeView.swift
//  rever
//
//  Home view with behavioral insights
//

import SwiftUI
import StoreKit
import UserNotifications
// TEMPORARILY DISABLED: Firebase imports - testing if they're causing crash
// import FirebaseAuth
// import FirebaseStorage

// Helper function for safe screen bounds access
private func getScreenHeight() -> CGFloat {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        return window.bounds.height
    }
    return UIScreen.main.bounds.height
}

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    // SIMPLIFIED: Reduced @State properties from 20+ to 7 essential ones
    // Essential metrics (load immediately from fast services)
    @State private var totalSaved: Double = 0.0
    @State private var streak: Int = 0
    @State private var activeGoal: SavingsGoal? = nil
    @State private var allGoals: [SavingsGoal] = [] // Cache goals locally (lazy service access)
    @AppStorage("money_tree_name") private var treeName: String = "Your Money Tree"
    @State private var isEditingTreeName = false
    @State private var editingTreeName = ""
    
    // Services for tracking savings - LAZY: Only access when actually needed
    // CRITICAL: Don't access .shared during view creation - it blocks MainActor
    // Access these services only when user actually needs the data (in loadEssentialData, etc.)
    private var plaidService: PlaidService {
        PlaidService.shared // Access lazily when needed
    }
    private var goalsService: GoalsService {
        GoalsService.shared // Access lazily when needed
    }
    
    // Header data
    @State private var avatarImage: UIImage? = nil
    @State private var userName: String = "User"
    @State private var userEmail: String = "there"
    
    // Progressive loading flags (cards appear one by one)
    @State private var showRiskCard = false
    @State private var showMoodCard = false
    @State private var showInteractionsCard = false
    @State private var showInsightsCard = false
    
    // Dashboard API data (for passing to card views)
    @State private var dashboardData: AWSDataService.DashboardData? = nil
    
    // Loading state - start as false so content shows immediately
    @State private var isLoadingData = false
    
    // Sheet states
    @State private var showMetrics = false
    @State private var showPurchaseIntentHistory = false
    @State private var showProfile = false
    @State private var showGoalCompletionCelebration = false
    @State private var completedGoal: SavingsGoal? = nil
    @State private var showManualDeposit = false
    @State private var showGoalDetails = false
    @State private var selectedGoalForDetails: SavingsGoal? = nil
    @State private var showFirstDepositCelebration = false
    @State private var firstDepositAmount: Double = 0
    @State private var showDecisionWindowPrompt = false
    @State private var activeDecisionWindow: DecisionWindow? = nil
    @State private var showWelcomeBack = false
    @State private var showDepositOptions = false
    @State private var showPlaidTransfer = false
    @State private var plaidTransferInitialAmount: Double? = nil
    @State private var showUnitAccountPrompt = false
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
    @State private var showDecisionWindows = false
    @State private var showNotificationCenter = false
    @State private var showMetaYellowCardCelebration = false
    @State private var showHomeScreenTutorial = false
    @State private var showLoyaltyShop = false
    @State private var showSceneEditor = false
    @State private var notificationCount: Int = 0
    @State private var badgePulse: Bool = false
    @AppStorage("last_sign_in_timestamp") private var lastSignInTimestamp: Double = 0
    @AppStorage("welcome_back_shown_for_session") private var welcomeBackShownForSession: Bool = false
    
    // Task tracking for cancellation (prevent memory leaks)
    @State private var dataLoadingTask: Task<Void, Never>? = nil
    @State private var progressiveLoadingTask: Task<Void, Never>? = nil
    
    // Scroll tracking for header collapse
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var cardPosition: CGFloat = -1000 // Position of premium card (initialized to off-screen)
    private let headerCollapseThreshold: CGFloat = 50 // Hide header after scrolling 50 points
    private let pullDownThreshold: CGFloat = 30 // Hide header when pulling down 30 points
    
    init() {
        let initStart = Date()
        StartupDiagnostics.shared.log("🔍 [HomeView] init() started")
        StartupDiagnostics.shared.logViewInit("HomeView", startTime: initStart)
    }
    
    private var formattedTotalSaved: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalSaved)) ?? "$0.00"
    }
    
    private func formatGoalAmounts(current: Double, target: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        let currentString = formatter.string(from: NSNumber(value: current)) ?? "$\(Int(current))"
        let targetString = formatter.string(from: NSNumber(value: target)) ?? "$\(Int(target))"
        return "\(currentString) of \(targetString)"
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    // MARK: - Computed Properties (defined before body to help compiler)
    
    private var formattedTotalSaved: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalSaved)) ?? "$0"
    }
    
    @ViewBuilder
    private var essentialMetricsCard: some View {
        VStack(spacing: .spacingSection) {
            // Money Tree Card
            ReverCard {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if isEditingTreeName {
                                TextField("Enter tree name", text: $editingTreeName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                    .textFieldStyle(.plain)
                                    .autocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .padding(8)
                                    .background(Color.dreamMist.opacity(0.5))
                                    .cornerRadius(8)
                                    .onSubmit {
                                        let trimmed = editingTreeName.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !trimmed.isEmpty {
                                            treeName = trimmed
                                        } else {
                                            treeName = "Your Money Tree"
                                        }
                                        isEditingTreeName = false
                                    }
                                    .onAppear {
                                        editingTreeName = treeName
                                    }
                                
                                Button(action: {
                                    let trimmed = editingTreeName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmed.isEmpty {
                                        treeName = trimmed
                                    } else {
                                        treeName = "Your Money Tree"
                                    }
                                    isEditingTreeName = false
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.reverBlue)
                                }
                                
                                Button(action: {
                                    isEditingTreeName = false
                                    editingTreeName = treeName
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.softGraphite)
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Text(treeName.isEmpty ? "Your Money Tree" : treeName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                    
                                    Button(action: {
                                        isEditingTreeName = true
                                        editingTreeName = treeName
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.softGraphite)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        
                        if !isEditingTreeName {
                            Text("Tap pencil to rename")
                                .font(.system(size: 11))
                                .foregroundColor(.softGraphite.opacity(0.7))
                                .padding(.leading, 2)
                        } else {
                            Text("Press Enter or tap ✓ to save")
                                .font(.system(size: 11))
                                .foregroundColor(.softGraphite.opacity(0.7))
                                .padding(.leading, 2)
                        }
                    }
                    
                    // Money Tree Visualization with Value Overlay
                    ZStack(alignment: .bottom) {
                        MoneyTreeView(
                            totalSaved: totalSaved,
                            activeGoal: activeGoal,
                            allGoals: allGoals,
                            onGoalLeafTapped: { tappedGoal in
                                print("🏠 [HomeView] Goal leaf tapped: \(tappedGoal.name), ID: \(tappedGoal.id)")
                                print("🏠 [HomeView] Current allGoals count: \(allGoals.count)")
                                // Find the goal in allGoals by ID to ensure we have the latest version
                                if let foundGoal = allGoals.first(where: { $0.id == tappedGoal.id }) {
                                    print("🏠 [HomeView] Found goal in allGoals: \(foundGoal.name)")
                                    selectedGoalForDetails = foundGoal
                                    showGoalDetails = true
                                } else {
                                    print("⚠️ [HomeView] Goal not found in allGoals, using tapped goal directly")
                                    // Fallback: use the tapped goal directly
                                    selectedGoalForDetails = tappedGoal
                                    showGoalDetails = true
                                }
                            }
                        )
                        
                        // Tree Value Overlay - Shows current savings and deposit CTA
                        VStack(spacing: 12) {
                            // Current tree value
                            VStack(spacing: 4) {
                                Text("Tree Value")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text(formattedTotalSaved)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.6))
                                    .blur(radius: 10)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            
                            // Deposit CTA Button
                            Button(action: {
                                showDepositOptions = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Water Your Tree")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .padding()
            }
            .padding(.horizontal, .spacingCard)
            
            // Streak Card
            ReverCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.softGraphite.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Text(StreakService.shared.streakEmoji)
                                .font(.system(size: 24))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Savings Streak")
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                            Text("\(streak) days")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.softGraphite)
                        }
                        
                        Spacer()
                    }
                    
                    // Premium CTA Phrase
                    Text("Execute a Save and Grow your Money Tree")
                        .font(.system(size: 17, weight: .medium, design: .default))
                        .foregroundColor(.softGraphite)
                        .tracking(0.5)
                        .italic()
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding()
            }
            .padding(.horizontal, .spacingCard)
        }
    }
    
    @ViewBuilder
    private var savingsReminderCard: some View {
        ReverCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.softGraphite.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.softGraphite)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Decision Notifications")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        
                        Text("Set up time-based savings prompts")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.softGraphite)
                }
            }
            .padding()
        }
        .padding(.horizontal, .spacingCard)
        .onTapGesture {
            // Open Decision Notifications (formerly Savings Reminders)
            NotificationCenter.default.post(name: NSNotification.Name("OpenDecisionWindows"), object: nil)
        }
    }
    
    @ViewBuilder
    private var depositTrackerCard: some View {
        NavigationLink(destination: DepositTrackerView()) {
            ReverCard {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.softGraphite.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 24))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Deposit Tracker")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.midnightSlate)
                                
                                Text("View your savings history")
                                    .font(.system(size: 14))
                                    .foregroundColor(.softGraphite)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.softGraphite)
                        }
                        
                        if !plaidService.depositHistory.isEmpty {
                            Divider()
                            
                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Deposits")
                                        .font(.system(size: 12))
                                        .foregroundColor(.softGraphite)
                                    Text("\(plaidService.depositHistory.count)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.softGraphite)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("This Month")
                                        .font(.system(size: 12))
                                        .foregroundColor(.softGraphite)
                                    
                                    let monthlyDepositsTotal = plaidService.depositHistory
                                        .filter { Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .month) }
                                        .reduce(0) { $0 + $1.amount }
                                    
                                    Text(formatCurrency(monthlyDepositsTotal))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.softGraphite)
                                }
                            }
                            
                            // Recent deposits preview
                            if let recentDeposit = plaidService.depositHistory.sorted(by: { $0.timestamp > $1.timestamp }).first {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.softGraphite)
                                    
                                    Text("Last deposit: \(formatCurrency(recentDeposit.amount))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.softGraphite)
                                    
                                    Spacer()
                                    
                                    Text(recentDeposit.timestamp, style: .relative)
                                        .font(.system(size: 12))
                                        .foregroundColor(.softGraphite)
                                }
                                .padding(.top, 8)
                                
                                Divider()
                                    .padding(.top, 8)
                            }
                            
                            // Free User CTA - Upgrade prompt
                            if !SubscriptionService.shared.isPremium {
                                Divider()
                                
                                Button(action: {
                                    showPaywall = true
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.softGraphite)
                                                Text("Limited to 7 days")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.midnightSlate)
                                            }
                                            
                                            Text("Upgrade to view full history")
                                                .font(.system(size: 12))
                                                .foregroundColor(.softGraphite)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Text("Upgrade")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.reverBlue, Color.deepReverBlue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(8)
                                    }
                                    .padding(12)
                                    .background(Color.reverBlue.opacity(0.05))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, .spacingCard)
        }
    }
    
    
    // Helper function to determine if user is a beta tester/TestFlight user
    private func isBetaTester() -> Bool {
        // supergeek@me.com is NOT a beta tester - they get rose gold founder card
        if userEmail.lowercased() == "supergeek@me.com" {
            return false
        }
        
        // Check if user is in first 100 TestFlight signups (gets Meta Yellow Card)
        let isFirst100TestFlight = UserDefaults.standard.bool(forKey: "is_first_100_testflight_user")
        if isFirst100TestFlight {
            return true // First 100 TestFlight users get Meta Yellow Card
        }
        
        // Check if running in TestFlight (but NOT first 100 - they don't get Meta Yellow Card)
        #if DEBUG
        return false // Debug builds don't get Meta Yellow Card unless they're first 100
        #else
        // Check for TestFlight receipt
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           receiptURL.lastPathComponent == "sandboxReceipt" {
            // User is in TestFlight but NOT first 100, so they don't get Meta Yellow Card
            return false
        }
        
        // Check UserDefaults flag (can be set manually for testing)
        return UserDefaults.standard.bool(forKey: "is_beta_tester")
        #endif
    }
    
    // Helper function to determine if user should get ROSE GOLD founder card
    private func isRoseGoldFounder() -> Bool {
        // supergeek@me.com always gets rose gold founder card
        return userEmail.lowercased() == "supergeek@me.com"
    }
    
    // Helper function to determine if user should get BLACK card
    private func isBlackCardEligible() -> Bool {
        // Beta testers get yellow card, not black
        if isBetaTester() {
            return false
        }
        
        // supergeek@me.com gets rose gold, not black
        if isRoseGoldFounder() {
            return false
        }
        
        // Check if user is in first 100 paid ANNUAL users
        // This flag should be set when user first becomes premium with annual subscription (if they're in first 100)
        let isFirst100Annual = UserDefaults.standard.bool(forKey: "is_first_100_annual_user")
        
        // Also verify they have an annual subscription
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        
        return isFirst100Annual && isAnnual
    }
    
    // Helper function to get user sign-up year
    private func getUserSignUpYear() -> String {
        // Try to get sign-up date from UserDefaults (stored when user first signs up)
        if let signUpDate = UserDefaults.standard.object(forKey: "user_signup_date") as? Date {
            let year = Calendar.current.component(.year, from: signUpDate)
            return String(year)
        }
        
        // Fallback: Use first subscription date if available
        if let firstSubscriptionDate = SubscriptionStreakService.shared.lastTransactionDate {
            let year = Calendar.current.component(.year, from: firstSubscriptionDate)
            return String(year)
        }
        
        // Final fallback: Use current year
        let currentYear = Calendar.current.component(.year, from: Date())
        return String(currentYear)
    }
    
    private func premiumMemberCardLogoColor(isBlack: Bool, isAnnual: Bool, isBeta: Bool, isRoseGold: Bool) -> Color {
        if isRoseGold {
            return Color(red: 0.4, green: 0.25, blue: 0.2) // Dark rose gold/bronze for logo on rose gold card
        } else if isBeta {
            return Color(red: 0.25, green: 0.2, blue: 0.1) // Dark yellow/bronze for logo on yellow card
        } else if isBlack {
            return .white
        } else if isAnnual {
            return Color(red: 0.95, green: 0.95, blue: 1.0)
        } else {
            return Color(red: 0.3, green: 0.2, blue: 0.1)
        }
    }
    
    private func formatUID(_ uid: String) -> String {
        if uid == "N/A" {
            return "N/A"
        }
        let components = uid.components(separatedBy: "-")
        if components.count >= 5 {
            return components.prefix(4).joined(separator: "-")
        }
        return uid
    }
    
    private func getMemberSinceDate() -> Date {
        if let signUpDate = UserDefaults.standard.object(forKey: "user_signup_date") as? Date {
            return signUpDate
        }
        if let firstSubscriptionDate = SubscriptionStreakService.shared.lastTransactionDate {
            return firstSubscriptionDate
        }
        return Date()
    }
    
    // Helper functions for widget data
    private func determineCardTypeForWidget() -> String {
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
        
        if isBeta {
            return "beta"
        } else if isRoseGold {
            return "rosegold"
        } else if isBlack {
            return "black"
        } else if isAnnual {
            return "platinum"
        } else {
            return "gold"
        }
    }
    
    private func getSignUpYearForWidget() -> String {
        return getUserSignUpYear()
    }
    
    @State private var isCardFlipped = false
    
    @ViewBuilder
    private func premiumMemberCard(streakMonths: Int, tierName: String) -> some View {
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible() // Beta testers get yellow, founder gets rose gold
        let logoColor = premiumMemberCardLogoColor(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold)
        let isSupergeek = userEmail.lowercased() == "supergeek@me.com"
        let fullUID = authService.currentUserId ?? authService.getUserId() ?? "N/A"
        let _ = formatUID(fullUID) // Available if needed for display
        let cardType = isBeta ? "beta" : (isRoseGold ? "rosegold" : (isBlack ? "black" : (isAnnual ? "platinum" : "gold")))
        let memberSince = getMemberSinceDate()
        
        ZStack {
            // Card Front
            PremiumCardFront(
                isBlack: isBlack,
                isAnnual: isAnnual,
                isBeta: isBeta,
                isRoseGold: isRoseGold,
                logoColor: logoColor,
                isSupergeek: isSupergeek,
                streakMonths: streakMonths,
                userName: userName,
                showFounder: isSupergeek,
                userId: fullUID,
                cardType: cardType,
                memberSince: memberSince
            )
            .rotation3DEffect(.degrees(isCardFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .opacity(isCardFlipped ? 0 : 1)
            .zIndex(isCardFlipped ? 0 : 1)
            
            // Card Back
            PremiumCardBack(
                isBlack: isBlack,
                isAnnual: isAnnual,
                isBeta: isBeta,
                isRoseGold: isRoseGold,
                userId: fullUID,
                cardType: cardType,
                memberSince: memberSince,
                userName: userName
            )
            .rotation3DEffect(.degrees(isCardFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            .opacity(isCardFlipped ? 1 : 0)
            .zIndex(isCardFlipped ? 1 : 0)
        }
        .aspectRatio(1.712, contentMode: .fit) // Credit card aspect ratio (85.60mm x 50mm)
        .frame(maxWidth: .infinity) // Full width of device
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isCardFlipped.toggle()
            }
        }
    }
    
    @ViewBuilder
    private var storeCTACard: some View {
        // CRITICAL: Strict subscription enforcement - verify status before showing premium card
        // This ensures users who cancel/stop paying immediately lose premium card access
        if SubscriptionService.shared.isPremium {
            // Double-check subscription status is still valid
            let subscriptionStatus = SubscriptionService.shared.isPremium
            
            if subscriptionStatus {
                // Premium User - Awe-Inspiring Premium Card (Gold or Platinum)
                let _ = SubscriptionStreakService.shared.ensureDataLoaded()
                let rawStreakMonths = SubscriptionStreakService.shared.currentStreak
                let streakMonths = rawStreakMonths > 0 ? rawStreakMonths : 1
                let tierName = SubscriptionStreakService.shared.tierName
                
                VStack(spacing: 12) {
                    premiumMemberCard(streakMonths: streakMonths, tierName: tierName)
                    
                    // Manage Subscription Button for Premium Users
                    Button(action: {
                        showPaywall = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Manage Subscription")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.softGraphite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.softGraphite.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.softGraphite.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, .spacingCard)
                .padding(.top, 4)
                .onAppear {
                    // Verify subscription status when card appears
                    Task {
                        await SubscriptionService.shared.updateSubscriptionStatus()
                        if !SubscriptionService.shared.isPremium {
                            print("🔒 [HomeView] Premium card displayed but subscription expired - will hide on next refresh")
                        }
                    }
                }
            } else {
                // Subscription expired - show free user CTA
                freeUserStoreCTA
            }
        } else {
            freeUserStoreCTA
        }
    }
    
    @ViewBuilder
    private var freeUserStoreCTA: some View {
        // Free User - Store CTA
        ReverCard {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2), Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Unlock Soteria Plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.midnightSlate)
                            
                            Text("Full deposit history, unlimited goals & more")
                                .font(.system(size: 13))
                                .foregroundColor(.softGraphite)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        showPaywall = true
                    }) {
                        HStack(spacing: 8) {
                            Text("View Plans")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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
                }
                .padding()
            }
            .padding(.horizontal, .spacingCard)
        }
    
    // MARK: - Lifecycle Methods (defined before body to help compiler)
    
    func handleAppear() {
        StartupDiagnostics.shared.log("🔍 [HomeView] onAppear called")
        goalsService.ensureDataLoaded()
        SubscriptionStreakService.shared.ensureDataLoaded()
        
        // CRITICAL: Always verify subscription status when HomeView appears
        // This ensures expired subscriptions are immediately detected
        Task {
            await SubscriptionService.shared.updateSubscriptionStatus()
            let wasPremium = SubscriptionService.shared.isPremium
            
            // If subscription status changed, log it
            if !wasPremium {
                print("🔒 [HomeView] Subscription check: User is NOT premium - premium features disabled")
            } else {
                print("✅ [HomeView] Subscription check: User has active premium subscription")
            }
        }
        
        // If user is premium but streak is 0, try to initialize it
        if SubscriptionService.shared.isPremium && SubscriptionStreakService.shared.currentStreak == 0 {
            print("⚠️ [HomeView] Premium user with 0 streak - attempting to initialize")
            // First try to get transaction from StoreKit
            Task {
                await SubscriptionService.shared.updateSubscriptionStatus()
                // Double-check premium status after update
                guard SubscriptionService.shared.isPremium else {
                    print("🔒 [HomeView] Subscription expired during initialization - aborting streak init")
                    return
                }
                // If still 0 after update, initialize as premium user
                if SubscriptionStreakService.shared.currentStreak == 0 {
                    SubscriptionStreakService.shared.initializeForPremiumUser()
                }
            }
        }
        
        loadEssentialData()
        activeGoal = goalsService.activeGoal
        allGoals = goalsService.goals
        startProgressiveLoading()
        loadAvatar()
        let currentTimestamp = Date().timeIntervalSince1970
        let timeSinceLastSignIn = currentTimestamp - lastSignInTimestamp
        if !welcomeBackShownForSession && timeSinceLastSignIn < 30 && timeSinceLastSignIn > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showWelcomeBack = true
                welcomeBackShownForSession = true
            }
        }
        checkForUnitAccountPrompt()
        
        // Show home screen tutorial on first visit (if not permanently hidden)
        if !UserDefaults.standard.bool(forKey: "home_screen_tutorial_hidden") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showHomeScreenTutorial = true
            }
        }
    }
    
    var body: some View {
        baseContentView
        .onAppear {
            handleAppear()
            // Sync deposit screenshots to cloud in background
            Task {
                await DepositScreenshotAPIService.shared.syncAllScreenshots()
            }
            // Load member number if premium (defer to avoid state modification during view update)
            Task {
                // Defer execution to next run loop to avoid state modification during view update
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await MainActor.run {
                    if subscriptionService.isPremium {
                        Task {
                            await MemberNumberService.shared.fetchMemberNumber()
                        }
                    }
                }
            }
        }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AvatarUpdated"))) { _ in
                self.loadAvatar()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GoalCompleted"))) { notification in
                if let goal = notification.object as? SavingsGoal {
                    self.completedGoal = goal
                    self.showGoalCompletionCelebration = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FirstDepositMade"))) { notification in
                if let amount = notification.object as? Double {
                    self.firstDepositAmount = amount
                    self.showFirstDepositCelebration = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DepositMade"))) { _ in
                // Refresh data when deposit is made
                print("🏠 [HomeView] Deposit made notification received, refreshing data...")
                refreshHomeData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DecisionWindowActive"))) { notification in
                if let window = notification.object as? DecisionWindow {
                    // Ensure we're on main thread and add a small delay to ensure view is ready
                    DispatchQueue.main.async {
                        self.activeDecisionWindow = window
                        // Small delay to ensure view hierarchy is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.showDecisionWindowPrompt = true
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenPlaidTransferForDecisionWindow"))) { notification in
                if let userInfo = notification.object as? [String: Any],
                   let amount = userInfo["amount"] as? Double {
                    self.plaidTransferInitialAmount = amount
                    self.showPlaidTransfer = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidSignIn"))) { _ in
                let currentTimestamp = Date().timeIntervalSince1970
                let timeSinceLastSignIn = currentTimestamp - self.lastSignInTimestamp
                self.goalsService.rescheduleAllGoalNotifications()
                if !self.welcomeBackShownForSession || timeSinceLastSignIn > 300 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.showWelcomeBack = true
                        self.lastSignInTimestamp = currentTimestamp
                        self.welcomeBackShownForSession = true
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowMetaYellowCardCelebration"))) { _ in
                // Show Meta Yellow Card celebration for first 100 TestFlight users
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showMetaYellowCardCelebration = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenDecisionWindows"))) { _ in
                print("🔔 [HomeView] Received OpenDecisionWindows notification - opening Decision Notifications")
                showDecisionWindows = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NotificationCountUpdated"))) { notification in
                if let count = notification.object as? Int {
                    notificationCount = count
                    // Restart animation if count > 0
                    if count > 0 && !badgePulse {
                        withAnimation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                        ) {
                            badgePulse = true
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NotificationDelivered"))) { _ in
                // Update badge when notification is delivered
                checkNotificationCount()
            }
            .onAppear {
                checkNotificationCount()
            }
            .onChange(of: showNotificationCenter) { _, isShowing in
                if !isShowing {
                    // When notification center closes, refresh count (notifications may have been cleared)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        checkNotificationCount()
                    }
                }
            }
            .onDisappear {
                print("🟡 [HomeView] onDisappear - cancelling tasks")
                dataLoadingTask?.cancel()
                progressiveLoadingTask?.cancel()
                dataLoadingTask = nil
                progressiveLoadingTask = nil
            }
            .sheet(isPresented: $showMetrics) {
                MetricsDashboardView()
            }
            .sheet(isPresented: $showPurchaseIntentHistory) {
                PurchaseIntentHistoryView()
            }
            .fullScreenCover(isPresented: $showGoalCompletionCelebration) {
                if let goal = self.completedGoal {
                    GoalCompletionCelebrationView(goal: goal) {
                        self.showGoalCompletionCelebration = false
                        self.completedGoal = nil
                        self.activeGoal = self.goalsService.activeGoal
                        self.allGoals = self.goalsService.goals
                    }
                }
            }
            .fullScreenCover(isPresented: $showFirstDepositCelebration) {
                FirstDepositCelebrationView(depositAmount: self.firstDepositAmount) {
                    self.showFirstDepositCelebration = false
                    self.totalSaved = self.plaidService.totalSaved
                }
            }
            .sheet(isPresented: $showWelcomeBack) {
                WelcomeBackView(
                    onMakeDeposit: {
                        self.showWelcomeBack = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.showDepositOptions = true
                        }
                    },
                    onDismiss: {
                        self.showWelcomeBack = false
                    }
                )
                .environmentObject(self.authService)
                .environmentObject(self.goalsService)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: self.showWelcomeBack) { _, isShowing in
                if !isShowing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.allGoals = self.goalsService.goals
                    }
                }
            }
            .sheet(isPresented: $showDepositOptions) {
                DepositOptionsView(
                    onPlaidDeposit: {
                        self.showDepositOptions = false
                        self.showPlaidTransfer = true
                    },
                    onManualDeposit: {
                        self.showDepositOptions = false
                        self.showManualDeposit = true
                    }
                )
            }
            .sheet(isPresented: $showPlaidTransfer) {
                PlaidTransferView(initialAmount: self.plaidTransferInitialAmount)
                    .onDisappear {
                        self.totalSaved = self.plaidService.totalSaved
                        self.activeGoal = self.goalsService.activeGoal
                        self.allGoals = self.goalsService.goals
                        StreakService.shared.ensureDataLoaded()
                        self.streak = StreakService.shared.currentStreak
                        self.plaidTransferInitialAmount = nil
                    }
            }
            .fullScreenCover(isPresented: Binding(
                get: { showDecisionWindowPrompt && activeDecisionWindow != nil },
                set: { showDecisionWindowPrompt = $0 }
            )) {
                if let window = self.activeDecisionWindow {
                    DecisionWindowPromptView(window: window) {
                        self.showDecisionWindowPrompt = false
                        self.activeDecisionWindow = nil
                        self.totalSaved = self.plaidService.totalSaved
                        // Clear the UserDefaults flag when prompt is dismissed
                        UserDefaults.standard.set(false, forKey: "shouldShowDecisionWindowPrompt")
                        UserDefaults.standard.removeObject(forKey: "activeDecisionWindowId")
                    }
                } else {
                    // Fallback view if window is nil (shouldn't happen, but prevents white screen)
                    Color.cloudWhite
                        .ignoresSafeArea()
                        .onAppear {
                            print("⚠️ [HomeView] DecisionWindowPromptView attempted to show but activeDecisionWindow is nil")
                            self.showDecisionWindowPrompt = false
                        }
                }
            }
            .overlay {
                if self.showUnitAccountPrompt {
                    UnitAccountPromptView(onDismiss: {
                        self.showUnitAccountPrompt = false
                    })
                    .environmentObject(self.authService)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .sheet(isPresented: $showManualDeposit) {
                ManualDepositView()
                    .onDisappear {
                        self.totalSaved = self.plaidService.totalSaved
                        self.activeGoal = self.goalsService.activeGoal
                        self.allGoals = self.goalsService.goals
                        StreakService.shared.ensureDataLoaded()
                        self.streak = StreakService.shared.currentStreak
                    }
            }
            .sheet(isPresented: $showDecisionWindows) {
                DecisionWindowsView()
                    .environmentObject(subscriptionService)
            }
            .sheet(isPresented: $showNotificationCenter) {
                NotificationCenterView()
            }
            .overlay {
                if showMetaYellowCardCelebration {
                    MetaYellowCardCelebrationView(isPresented: $showMetaYellowCardCelebration)
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1000)
                }
                
                // Home Screen Tutorial
                TutorialPopup(
                    title: "Welcome to Your Money Tree",
                    content: AnyView(HomeScreenTutorialContent()),
                    userDefaultsKey: "home_screen_tutorial_hidden",
                    isPresented: $showHomeScreenTutorial
                )
                
                // Loyalty Shop & Scene Edit Floating Action Buttons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Scene Edit Button
                            Button(action: {
                                showSceneEditor = true
                            }) {
                                Image(systemName: "paintbrush.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.purple, Color.purple.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                            
                            // Loyalty Shop Button
                            LoyaltyShopButton(showShop: $showLoyaltyShop)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 90) // Above tab bar
                    }
                }
            }
            .sheet(isPresented: $showGoalDetails) {
                goalDetailSheetContent
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(SubscriptionService.shared)
            }
            .sheet(isPresented: $showLoyaltyShop) {
                LoyaltyShopView()
            }
            .sheet(isPresented: $showSceneEditor) {
                SceneEditorView()
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
            .onChange(of: showGoalDetails) { oldValue, newValue in
                if !newValue {
                    // Clear the selected goal when sheet is dismissed
                    print("🏠 [HomeView] Goal details sheet dismissed, clearing selectedGoalForDetails")
                    selectedGoalForDetails = nil
                }
            }
    }
    
    @ViewBuilder
    private var goalDetailSheetContent: some View {
        if let goal = selectedGoalForDetails {
            GoalDetailView(goal: goal)
                .environmentObject(goalsService)
                .environmentObject(authService)
                .onAppear {
                    print("🏠 [HomeView] Showing GoalDetailView for: \(goal.name), ID: \(goal.id)")
                }
        } else {
            NavigationStack {
                VStack {
                    Text("Goal not found")
                        .foregroundColor(.midnightSlate)
                        .padding()
                    Button("Done") {
                        showGoalDetails = false
                        selectedGoalForDetails = nil
                    }
                    .padding()
                }
            }
            .onAppear {
                print("⚠️ [HomeView] selectedGoalForDetails is nil when showing sheet")
            }
        }
    }
    
    @ViewBuilder
    private var baseContentView: some View {
        ZStack(alignment: .top) {
            // Background
            Color.mistGray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for fixed header - filled with banner color
                    usernameBannerBackgroundGradient
                        .frame(height: 60)
                    
                    // Username/Avatar Banner (scrolls with content)
                    usernameAvatarBanner
                    
                    // Content spacing
                    VStack(spacing: .spacingSection) {
                        // Essential Metrics (Load immediately - always shows, even with 0 values)
                        self.essentialMetricsCard
                        
                        // Savings Reminder Card (Core Feature - Show prominently)
                        self.savingsReminderCard
                        
                        // Deposit Tracker Card (Core Feature - Show prominently)
                        self.depositTrackerCard
                        
                        // Store CTA Card (Show for all users - different content for premium)
                        self.storeCTACard
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(
                                            key: CardPositionPreferenceKey.self,
                                            value: geometry.frame(in: .named("scroll")).minY
                                        )
                                }
                            )
                        
                        // Progressive Cards (Load one by one - truly lazy)
                        if showRiskCard {
                            RiskCardView(dashboardData: dashboardData)
                        }
                        
                        if showMoodCard {
                            MoodCardView(dashboardData: dashboardData)
                        }
                        
                        if showInteractionsCard {
                            InteractionsCardView(dashboardData: dashboardData)
                        }
                        
                        if showInsightsCard {
                            InsightsCardView()
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .refreshable {
                // Pull-to-refresh
                await refreshHomeDataAsync()
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                }
            )
            .coordinateSpace(name: "scroll")
            
            // Premium Header (fixed at top)
            PremiumHeaderView(
                title: "SOTERIA",
                subscriptionService: subscriptionService,
                userEmail: userEmail
            )
            
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                // When at top, minY should be around the padding value (110 or 90)
                // When scrolling UP (dragging bottom to top), content moves up, minY becomes negative
                // When pulling DOWN (refresh), content moves down, minY becomes larger than initial padding
                let initialOffset = subscriptionService.isPremium ? 110.0 : 90.0
                let adjustedOffset = value - initialOffset
                
                // Debug logging (can enable for testing)
                // print("🔍 [HomeView] Scroll - raw: \(String(format: "%.1f", value)), adjusted: \(String(format: "%.1f", adjustedOffset))")
                
                // Update scroll offset without animation to avoid conflicts
                scrollOffset = adjustedOffset
            }
            .onPreferenceChange(CardPositionPreferenceKey.self) { value in
                // Track premium card position
                cardPosition = value
            }
            
            // Header removed - no rose gold strip on home page
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .fullScreenCover(isPresented: $subscriptionService.showCelebration) {
            if let subscriptionType = subscriptionService.celebrationSubscriptionType {
                SubscriptionCelebrationView(
                    isPresented: $subscriptionService.showCelebration,
                    subscriptionType: subscriptionType
                )
            }
        }
    }
    
    // MARK: - Header Collapse Animation
    
    private var headerOpacity: Double {
        // Default: Always show header (opacity = 1.0)
        // Only hide when specific conditions are met
        
        // First, check if premium card is in view (only for premium users)
        // This should ONLY hide when card is clearly visible
        if subscriptionService.isPremium && cardPosition > -1000 && scrollOffset < -400 {
            let screenHeight = getScreenHeight()
            let cardHeight: CGFloat = 220
            let initialOffset = subscriptionService.isPremium ? 110.0 : 90.0
            
            // Adjust card position relative to initial offset (same as scrollOffset)
            let adjustedCardPosition = cardPosition - initialOffset
            let cardTop = adjustedCardPosition
            let cardBottom = adjustedCardPosition + cardHeight
            
            // Card is in view if it's clearly visible in the viewport
            // Only hide if card is in the middle-to-bottom portion of the screen
            if cardTop >= 0 && cardTop < (screenHeight - 100) && cardBottom > 100 {
                // Card is visible in viewport - hide header
                return 0.0
            }
        }
        
        // Handle scroll-based hiding
        // scrollOffset is adjusted relative to initial position
        // At top: scrollOffset ≈ 0
        // Scrolling UP: scrollOffset becomes negative
        // Pulling DOWN: scrollOffset becomes positive
        
        // Hide header when scrolling UP (dragging thumb from bottom to top)
        if scrollOffset < -3 {
            let scrollAmount = abs(scrollOffset)
            if scrollAmount > headerCollapseThreshold {
                return 0.0 // Completely hidden
            } else {
                // Fade out as scrolling up
                let adjustedAmount = scrollAmount - 3
                let fadeRange = headerCollapseThreshold - 3
                return max(0.0, 1.0 - (adjustedAmount / fadeRange))
            }
        } else if scrollOffset > pullDownThreshold {
            // Pulling down to refresh - hide header
            let pullAmount = scrollOffset - pullDownThreshold
            let maxPull = 50.0
            let fadeAmount = min(pullAmount / maxPull, 1.0)
            return max(0.0, 1.0 - fadeAmount)
        }
        
        // At top or minimal movement - always show
        return 1.0
    }
    
    private var headerOffset: CGFloat {
        // Default: Header stays in place (offset = 0)
        // Only move when scrolling or card is in view
        
        // Check if premium card is in view (only for premium users)
        if subscriptionService.isPremium && cardPosition > -1000 && scrollOffset < -400 {
            let screenHeight = getScreenHeight()
            let cardHeight: CGFloat = 220
            let initialOffset = subscriptionService.isPremium ? 110.0 : 90.0
            
            let adjustedCardPosition = cardPosition - initialOffset
            let cardTop = adjustedCardPosition
            let cardBottom = adjustedCardPosition + cardHeight
            
            // If card is visible, slide header up
            if cardTop >= 0 && cardTop < (screenHeight - 100) && cardBottom > 100 {
                return -120 // Hide completely off-screen
            }
        }
        
        // Hide header when scrolling UP (dragging thumb from bottom to top)
        if scrollOffset < -3 {
            // Scrolling up - slide header up
            let scrollAmount = abs(scrollOffset)
            if scrollAmount > headerCollapseThreshold {
                return -120 // Hide completely off-screen
            } else {
                // Slide up proportionally
                let adjustedAmount = scrollAmount - 3
                return -adjustedAmount * 0.6
            }
        } else if scrollOffset > pullDownThreshold {
            // Pulling down - slide header down
            let pullAmount = scrollOffset - pullDownThreshold
            return pullAmount * 0.5
        }
        
        // At top - no offset
        return 0
    }
    
    // MARK: - Username/Avatar Banner
    
    @ViewBuilder
    private var usernameAvatarBanner: some View {
        HStack(spacing: 12) {
            Button(action: { showProfile = true }) {
                Group {
                    if let avatarImage = avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Default avatar with user's initial
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.reverBlueDark, Color.reverBlueLight],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if !userName.isEmpty {
                    Text("HI, \(userName.uppercased())")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                } else {
                    Text("HI, USER")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                }
                Text("Welcome home!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.softGraphite)
            }
            
            Spacer()
            
            // Notification Envelope Icon
            Button(action: {
                showNotificationCenter = true
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.midnightSlate)
                    
                    // Badge indicator when there are notifications - flashing red light
                    if notificationCount > 0 {
                        ZStack {
                            // Outer pulsing glow - more pronounced
                            Circle()
                                .fill(Color.red)
                                .frame(width: 14, height: 14)
                                .shadow(color: Color.red.opacity(0.8), radius: 6, x: 0, y: 2)
                                .opacity(badgePulse ? 1.0 : 0.4)
                                .scaleEffect(badgePulse ? 1.0 : 0.9)
                            
                            // Middle ring - pulsing
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: 12, height: 12)
                                .opacity(badgePulse ? 0.9 : 0.5)
                                .scaleEffect(badgePulse ? 1.0 : 0.95)
                            
                            // Inner bright dot
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.red.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                        .offset(x: 8, y: -8)
                        .onAppear {
                            // Start pulsing animation
                            withAnimation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                            ) {
                                badgePulse = true
                            }
                        }
                    }
                }
                .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(usernameBannerBackgroundGradient)
    }
    
    // MARK: - Card Status Header
    
    @ViewBuilder
    private var cardStatusHeader: some View {
        let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
        let isAnnual = subscriptionType == .annual
        let isBeta = isBetaTester()
        let isRoseGold = isRoseGoldFounder()
        let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
        
        // Card type text available if needed for display
        let _: String = {
            if isBeta {
                return "BETA"
            } else if isRoseGold {
                return "ROSE GOLD"
            } else if isBlack {
                return "BLACK"
            } else if isAnnual {
                return "PLATINUM"
            } else {
                return "GOLD"
            }
        }()
        
        VStack(spacing: 2) {
            Text("SOTERIA")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(cardStatusTextColor(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6) // Match Goals and Settings header padding exactly
        .frame(height: 36) // Fixed total height to match Goals/Settings exactly (24pt text + 12pt padding = 36pt)
        .background(
            cardStatusHeaderGradient(isBlack: isBlack, isAnnual: isAnnual, isBeta: isBeta, isRoseGold: isRoseGold)
                .ignoresSafeArea(edges: .top) // Match Goals and Settings header background
        )
        .clipped() // Ensure background doesn't extend beyond frame
    }
    
    private func cardStatusHeaderGradient(isBlack: Bool, isAnnual: Bool, isBeta: Bool, isRoseGold: Bool) -> LinearGradient {
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
                    Color(red: 1.0, green: 0.92, blue: 0.65),
                    Color(red: 1.0, green: 0.88, blue: 0.55),
                    Color(red: 0.98, green: 0.84, blue: 0.45)
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
    
    private func cardStatusTextColor(isBlack: Bool, isAnnual: Bool, isBeta: Bool, isRoseGold: Bool) -> Color {
        if isRoseGold {
            return Color(red: 0.35, green: 0.25, blue: 0.2)
        } else if isBeta {
            return Color(red: 0.3, green: 0.25, blue: 0.1)
        } else if isBlack {
            return Color.white.opacity(0.95)
        } else if isAnnual {
            return Color(red: 0.95, green: 0.95, blue: 1.0)
        } else {
            return Color(red: 0.3, green: 0.2, blue: 0.1)
        }
    }
    
    private var cardHeaderBackgroundColor: Color {
        if subscriptionService.isPremium {
            // Use a subtle version of the card color for the main header background
            let subscriptionType = SubscriptionStreakService.shared.lastSubscriptionType ?? .monthly
            let isAnnual = subscriptionType == .annual
            let isBeta = isBetaTester()
            let isRoseGold = isRoseGoldFounder()
            let isBlack = (isBeta || isRoseGold) ? false : isBlackCardEligible()
            
            if isRoseGold {
                return Color(red: 0.95, green: 0.75, blue: 0.65).opacity(0.15)  // Matches card lightest color
            } else if isBeta {
                return Color(red: 1.0, green: 0.92, blue: 0.65).opacity(0.15)
            } else if isBlack {
                return Color(red: 0.05, green: 0.05, blue: 0.05).opacity(0.15)
            } else if isAnnual {
                return Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.15)
            } else {
                return Color(red: 0.98, green: 0.88, blue: 0.55).opacity(0.15)
            }
        }
        return Color.mistGray.opacity(0.95)
    }
    
    // MARK: - Username Banner Background
    
    private var usernameBannerBackgroundGradient: LinearGradient {
        guard subscriptionService.isPremium else {
            // Free users get softGraphite
            return LinearGradient(
                colors: [Color.softGraphite.opacity(0.15)],
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
                    Color(red: 0.95, green: 0.75, blue: 0.65).opacity(0.25),  // Light rose gold - matches card
                    Color(red: 0.90, green: 0.65, blue: 0.55).opacity(0.22), // Medium rose gold - matches card
                    Color(red: 0.85, green: 0.55, blue: 0.45).opacity(0.20)  // Deeper rose gold - matches card (darkest)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isBeta {
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.4).opacity(0.25),
                    Color(red: 0.98, green: 0.90, blue: 0.35).opacity(0.22),
                    Color(red: 0.95, green: 0.85, blue: 0.30).opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isBlack {
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.05).opacity(0.25),
                    Color(red: 0.08, green: 0.08, blue: 0.08).opacity(0.22),
                    Color(red: 0.06, green: 0.06, blue: 0.06).opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isAnnual {
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.25),
                    Color(red: 0.18, green: 0.18, blue: 0.24).opacity(0.22),
                    Color(red: 0.15, green: 0.15, blue: 0.21).opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Gold (monthly)
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.88, blue: 0.55).opacity(0.25),
                    Color(red: 0.92, green: 0.78, blue: 0.45).opacity(0.22),
                    Color(red: 0.88, green: 0.70, blue: 0.35).opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Data Loading
    
    private func refreshHomeData() {
        print("🔄 [HomeView] Refreshing home data...")
        // Refresh goals
        goalsService.refreshGoals()
        
        // Recalculate goal amounts from deposit history to fix any discrepancies
        goalsService.recalculateGoalAmounts(from: plaidService)
        
        self.activeGoal = goalsService.activeGoal
        self.allGoals = goalsService.goals
        
        // Refresh savings total
        self.totalSaved = plaidService.totalSaved
        
        // Refresh streak
        StreakService.shared.ensureDataLoaded()
        StreakService.shared.updateStreak()
        self.streak = StreakService.shared.currentStreak
        
        print("🔄 [HomeView] Refresh complete - Total: $\(totalSaved), Streak: \(streak)")
    }
    
    @MainActor
    private func refreshHomeDataAsync() async {
        print("🔄 [HomeView] Refreshing home data (pull-to-refresh)...")
        
        // Refresh goals
        goalsService.refreshGoals()
        
        // Recalculate goal amounts from deposit history to fix any discrepancies
        goalsService.recalculateGoalAmounts(from: plaidService)
        
        self.activeGoal = goalsService.activeGoal
        self.allGoals = goalsService.goals
        
        // Refresh savings total
        self.totalSaved = plaidService.totalSaved
        
        // Refresh streak
        StreakService.shared.ensureDataLoaded()
        StreakService.shared.updateStreak()
        self.streak = StreakService.shared.currentStreak
        
        print("🔄 [HomeView] Refresh complete (pull-to-refresh) - Total: $\(totalSaved), Streak: \(streak)")
    }
    
    private func checkNotificationCount() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                self.notificationCount = notifications.count
                print("📬 [HomeView] Notification count: \(self.notificationCount)")
            }
        }
    }
    
    private func loadEssentialData() {
        print("🟢 [HomeView] loadEssentialData() called")
        // Set loading to false immediately so content shows (even with 0 values)
        isLoadingData = false
        
        // STRATEGY: Use cached data immediately, then update from API
        // 1. Load cached dashboard data instantly (from previous session)
        // 2. Load fresh data from API in background
        // 3. Update UI when API responds
        
        // Step 1: Load from PlaidService first (confirmed deposits) - LAZY ACCESS
        // CRITICAL: Only access services here, not during view creation
        // Ensure goals are loaded so money tree can display goal leaves
        goalsService.ensureDataLoaded()
        self.totalSaved = plaidService.totalSaved
        self.activeGoal = goalsService.activeGoal
        self.allGoals = goalsService.goals // Cache goals locally
        
        // Load streak from StreakService (tracks savings deposits)
        StreakService.shared.ensureDataLoaded()
        StreakService.shared.updateStreak() // Update streak based on time elapsed
        self.streak = StreakService.shared.currentStreak
        
        // Step 2: Load cached data immediately (instant, no blocking)
        if let cached = AWSDataService.shared.getCachedDashboardData() {
            // Use Plaid totalSaved if available, otherwise use cached data
            if plaidService.totalSaved == 0 {
                self.totalSaved = cached.totalSaved
            }
            // Streak is now loaded from StreakService above, not from cached data
            self.dashboardData = cached // Store for card views
            
            // Helper to convert timestamp (handles both seconds and milliseconds)
            let convertTimestamp: (TimeInterval?) -> Date? = { timestamp in
                guard let ts = timestamp else { return nil }
                // If timestamp is > year 2100, it's in milliseconds, otherwise seconds
                let seconds = ts > 4102444800 ? ts / 1000 : ts
                return Date(timeIntervalSince1970: seconds)
            }
            
            // Map cached goal data directly to SavingsGoal (no service call needed)
            if let goalData = cached.activeGoal {
                self.activeGoal = SavingsGoal(
                    id: goalData.id,
                    name: goalData.name,
                    targetAmount: goalData.targetAmount,
                    currentAmount: goalData.currentAmount,
                    startDate: convertTimestamp(goalData.startDate),
                    targetDate: convertTimestamp(goalData.targetDate),
                    category: SavingsGoal.GoalCategory(rawValue: goalData.category ?? "Other") ?? .other,
                    protectionAmount: goalData.protectionAmount ?? 10.0,
                    photoPath: goalData.photoPath,
                    description: goalData.description,
                    status: SavingsGoal.GoalStatus(rawValue: goalData.status ?? "active") ?? .active,
                    createdDate: convertTimestamp(goalData.createdDate) ?? Date(),
                    completedDate: convertTimestamp(goalData.completedDate),
                    completedAmount: goalData.completedAmount
                )
            } else {
                self.activeGoal = nil
            }
            
            print("✅ [HomeView] Loaded cached dashboard data instantly")
        }
        
        // Load user info from AuthService (Cognito)
        if let cognitoUser = authService.currentUser {
            // Extract username from email (part before @)
            if let email = cognitoUser.email {
                userEmail = email
                userName = email.components(separatedBy: "@").first ?? "User"
            } else {
                userName = cognitoUser.username ?? "User"
                userEmail = cognitoUser.email ?? "there"
            }
        } else {
            // Fallback to defaults
            userEmail = "there"
            userName = "User"
        }
        
        // Save userName to UserDefaults for widget access
        UserDefaults.standard.set(userName, forKey: "user_name")
        
        // Load avatar from UserDefaults (same as ProfileView)
        loadAvatar()
        
        // Step 3: Try to load fresh data from API (non-blocking, updates when ready)
        // OPTIMIZED: Defer API call slightly to let UI render first
        dataLoadingTask = Task.detached(priority: .utility) {
            // Small delay to let UI render and become interactive first
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Check for cancellation before starting
            guard !Task.isCancelled else { return }
            
            do {
                let dashboardData = try await AWSDataService.shared.getDashboardData()
                
                // Check for cancellation before updating UI
                guard !Task.isCancelled else { return }
                
                // Cache the fresh data for next time (synchronous, no await needed)
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    AWSDataService.shared.cacheDashboardData(dashboardData)
                }
                
                // Check for cancellation again
                guard !Task.isCancelled else { return }
                
                // Update UI with fresh data (all on MainActor)
                await MainActor.run {
                    // Double-check cancellation before updating UI
                    guard !Task.isCancelled else { return }
                    
                    // Safely update state (view might be deallocated)
                    // Use Plaid totalSaved if available (confirmed deposits), otherwise use API data
                    if self.plaidService.totalSaved > 0 {
                        self.totalSaved = self.plaidService.totalSaved
                    } else {
                        self.totalSaved = dashboardData.totalSaved
                    }
                    // Streak is loaded from StreakService (tracks savings deposits), not from API
                    StreakService.shared.ensureDataLoaded()
                    StreakService.shared.updateStreak()
                    self.streak = StreakService.shared.currentStreak
                    self.dashboardData = dashboardData // Store for card views
                    
                    // Helper to convert timestamp (handles both seconds and milliseconds)
                    let convertTimestamp: (TimeInterval?) -> Date? = { timestamp in
                        guard let ts = timestamp else { return nil }
                        // If timestamp is > year 2100, it's in milliseconds, otherwise seconds
                        let seconds = ts > 4102444800 ? ts / 1000 : ts
                        return Date(timeIntervalSince1970: seconds)
                    }
                    
                    // Map API goal data directly to SavingsGoal (no service call needed)
                    if let goalData = dashboardData.activeGoal {
                        self.activeGoal = SavingsGoal(
                            id: goalData.id,
                            name: goalData.name,
                            targetAmount: goalData.targetAmount,
                            currentAmount: goalData.currentAmount,
                            startDate: convertTimestamp(goalData.startDate),
                            targetDate: convertTimestamp(goalData.targetDate),
                            category: SavingsGoal.GoalCategory(rawValue: goalData.category ?? "Other") ?? .other,
                            protectionAmount: goalData.protectionAmount ?? 10.0,
                            photoPath: goalData.photoPath,
                            description: goalData.description,
                            status: SavingsGoal.GoalStatus(rawValue: goalData.status ?? "active") ?? .active,
                            createdDate: convertTimestamp(goalData.createdDate) ?? Date(),
                            completedDate: convertTimestamp(goalData.completedDate),
                            completedAmount: goalData.completedAmount
                        )
                    } else {
                        self.activeGoal = nil
                    }
                    
                    print("✅ [HomeView] Dashboard data updated from API")
                }
            } catch {
                // Check for cancellation before fallback
                guard !Task.isCancelled else { return }
                
                // API failed - log but don't block UI
                // We already have cached data displayed, so no need to fallback immediately
                print("⚠️ [HomeView] Dashboard API failed: \(error.localizedDescription) - using cached data")
                
                // OPTIMIZED: Don't call ensureDataLoaded() here - it triggers JSON decode
                // Instead, just use whatever cached values we have
                // Services will load their data in background (30s delay) if needed
                // This prevents blocking the UI during app launch
            }
        }
        
        // TEMPORARILY DISABLED: userInfoTask no longer exists (Firebase disabled)
        // Store task reference for cancellation
        // _ = userInfoTask
    }
    
    private func startProgressiveLoading() {
        // Cancel previous task if exists
        progressiveLoadingTask?.cancel()
        
        // OPTIMIZED: Defer card loading significantly to ensure UI is fully interactive first
        // Cards will load data when they appear, so we want to delay their appearance
        progressiveLoadingTask = Task.detached(priority: .utility) {
            // CRITICAL: Wait longer before showing first card to ensure UI is interactive
            // This prevents cards from triggering data loads that could block
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds - let UI be fully interactive
            
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard !Task.isCancelled else { return }
                showRiskCard = true
            }
            
            // Show remaining cards with delays
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard !Task.isCancelled else { return }
                showMoodCard = true
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard !Task.isCancelled else { return }
                showInteractionsCard = true
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard !Task.isCancelled else { return }
                showInsightsCard = true
            }
        }
    }
    
    private func loadAvatar() {
        // Load from UserDefaults only (local cache)
        // App deletion serves as account deletion, so no need for cloud persistence
        if let data = UserDefaults.standard.data(forKey: "user_avatar"),
           let image = UIImage(data: data) {
            avatarImage = image
            print("✅ [HomeView] Avatar loaded from UserDefaults")
        } else {
            avatarImage = nil
        }
    }
    
    // MARK: - Unit Account Prompt
    
    private func checkForUnitAccountPrompt() {
        // Only show if:
        // 1. User is authenticated (has Soteria account)
        // 2. Haven't created a Unit account yet
        // 3. Haven't dismissed the prompt in this session
        // 4. Haven't shown the prompt today
        // 5. User is on the home tab (not navigating to settings)
        
        guard authService.isAuthenticated else { return }
        
        let hasUnitAccount = UserDefaults.standard.bool(forKey: "unit_account_created")
        let dismissUntilDate = UserDefaults.standard.object(forKey: "unit_account_prompt_dismiss_until") as? Date
        let hasShownPrompt = UserDefaults.standard.bool(forKey: "unit_account_creation_prompt_shown")
        
        // Check if still within 3-day dismissal period
        let shouldShow: Bool
        if let dismissUntil = dismissUntilDate {
            // Check if current date is after the dismiss-until date
            shouldShow = Date() > dismissUntil
        } else {
            // Never dismissed, show it
            shouldShow = true
        }
        
        // Only show for new signups who haven't seen it before, or if user dismissed and 3 days passed
        let isNewSignUp = UserDefaults.standard.bool(forKey: "is_new_signup")
        let shouldShowForNewUser = isNewSignUp && !hasShownPrompt
        
        if !hasUnitAccount && shouldShow && (shouldShowForNewUser || !isNewSignUp) {
            // Longer delay to ensure user has time to see the home screen first
            // Only show after user has been on home screen for a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showUnitAccountPrompt = true
            }
        }
    }
}

// MARK: - Independent Card Components

struct RiskCardView: View {
    let dashboardData: AWSDataService.DashboardData?
    @State private var risk: RegretRiskAssessment? = nil
    @State private var loadTask: Task<Void, Never>? = nil
    
    var body: some View {
        Group {
            if let risk = risk, risk.riskLevel >= 0.4 {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: risk.riskLevel >= 0.7 ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(risk.riskLevel >= 0.7 ? .red : .orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(risk.riskLevel >= 0.7 ? "High Risk" : "Moderate Risk")
                                .reverH3()
                            
                            if let recommendation = risk.recommendation {
                                Text(recommendation)
                                    .reverBody()
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if !risk.factors.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(risk.factors, id: \.self) { factor in
                                    Text(factor.displayName)
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill((risk.riskLevel >= 0.7 ? Color.red : Color.orange).opacity(0.1))
                                        )
                                        .foregroundColor(risk.riskLevel >= 0.7 ? .red : .orange)
                                }
                            }
                        }
                    }
                }
                .reverCard()
                .padding(.horizontal, .spacingCard)
            }
        }
        .onAppear {
            // OPTIMIZED: Defer data loading to avoid blocking UI
            // Load data in background after a delay
            Task.detached(priority: .utility) {
                // Wait to ensure UI is interactive
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    loadRisk()
                }
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }
    
    private func loadRisk() {
        loadTask?.cancel()
        loadTask = Task {
            guard !Task.isCancelled else { return }
            
            // OPTIMIZED: Use ONLY Dashboard API data - no service fallback
            // This eliminates all JSON decode operations from startup path
            if let riskString = dashboardData?.currentRisk {
                // Convert API risk string to RegretRiskAssessment
                let riskLevel: Double
                let recommendation: String?
                let riskFactors: [RegretRiskAssessment.RiskFactor]
                
                switch riskString.lowercased() {
                case "high":
                    riskLevel = 0.8
                    recommendation = "Consider enabling Protection Hours for gentle reminders"
                    riskFactors = [.stressMood] // Simplified - API doesn't provide detailed factors
                case "medium":
                    riskLevel = 0.5
                    recommendation = "Stay mindful of your impulse decisions"
                    riskFactors = []
                default:
                    riskLevel = 0.2
                    recommendation = nil
                    riskFactors = []
                }
                
                risk = RegretRiskAssessment(
                    id: UUID().uuidString,
                    timestamp: Date(),
                    riskLevel: riskLevel,
                    factors: riskFactors,
                    recommendation: recommendation
                )
            }
            // No fallback - if API data not available, risk stays nil (card won't show)
        }
    }
}

struct ProtectionHoursCardView: View {
    let onTap: () -> Void
    @StateObject private var protectionHoursService = ProtectionHoursService.shared
    @State private var currentSchedule: ProtectionHoursSchedule? = nil
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: protectionHoursService.isProtectionActive ? "moon.fill" : "moon")
                        .font(.system(size: 24))
                        .foregroundColor(protectionHoursService.isProtectionActive ? Color.reverBlue : .softGraphite)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(protectionHoursService.isProtectionActive ? "Protection Hours Active" : "Protection Hours Inactive")
                            .reverH3()
                        
                        if protectionHoursService.isProtectionActive {
                            Text("You'll receive reminders during this time")
                                .reverCaption()
                                .foregroundColor(.reverBlue)
                        } else if let schedule = currentSchedule {
                            Text(schedule.name)
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                        } else {
                            Text("Tap to view schedules and settings")
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.softGraphite)
                }
            }
            .reverCard()
            .padding(.horizontal, .spacingCard)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Ensure schedules are loaded immediately
            protectionHoursService.ensureSchedulesLoaded()
            // Start monitoring to ensure status is checked regularly
            protectionHoursService.startMonitoring()
            // Check status immediately - no delay
            Task {
                await protectionHoursService.checkProtectionHoursStatus()
            }
        }
        .onChange(of: protectionHoursService.isProtectionActive) { oldValue, newValue in
            // Update current schedule when status changes
            currentSchedule = protectionHoursService.currentActiveSchedule
        }
        .onChange(of: protectionHoursService.schedules.count) { oldCount, newCount in
            // Re-check status when schedules change
            Task {
                await protectionHoursService.checkProtectionHoursStatus()
            }
        }
    }
}

// MARK: - Protection Hours Detail View
struct ProtectionHoursDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var protectionHoursService = ProtectionHoursService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var schedules: [ProtectionHoursSchedule] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cloudWhite
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Current Status Section
                            currentStatusSection
                            
                            // Active Schedule Section (if active)
                            if protectionHoursService.isProtectionActive {
                                activeScheduleSection
                            }
                            
                            // All Schedules Section
                            allSchedulesSection
                            
                            // Instructions Section
                            instructionsSection
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Protection Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.reverBlue)
                }
            }
            .onAppear {
                loadSchedules()
            }
        }
    }
    
    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: protectionHoursService.isProtectionActive ? "moon.fill" : "moon")
                    .font(.system(size: 32))
                    .foregroundColor(protectionHoursService.isProtectionActive ? Color.reverBlue : .softGraphite)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(protectionHoursService.isProtectionActive ? "Protection Hours Active" : "Protection Hours Inactive")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    if protectionHoursService.isProtectionActive {
                        Text("You'll receive reminders during this time")
                            .font(.system(size: 14))
                            .foregroundColor(.reverBlue)
                    } else {
                        Text("No active schedule at this time")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var activeScheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Schedule")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            if let activeSchedule = protectionHoursService.currentActiveSchedule {
                scheduleCard(schedule: activeSchedule, isActive: true)
            } else {
                // Fallback: find active schedule manually
                if let active = schedules.first(where: { $0.isCurrentlyActive() && $0.isActive }) {
                    scheduleCard(schedule: active, isActive: true)
                }
            }
        }
    }
    
    private var allSchedulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Schedules")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                    // Small delay to ensure sheet is fully dismissed before switching tabs
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // First switch to Settings tab
                        NotificationCenter.default.post(name: NSNotification.Name("NavigateToSettingsTab"), object: nil)
                        // Then open Quiet Hours view (with a small delay to ensure tab switch completes)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            NotificationCenter.default.post(name: NSNotification.Name("OpenQuietHours"), object: nil)
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                        Text("Manage")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.reverBlue)
                }
            }
            
            if schedules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 40))
                        .foregroundColor(.softGraphite)
                    
                    Text("No schedules created")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.midnightSlate)
                    
                    Text("Create a schedule to set up Protection Hours reminders")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(schedules) { schedule in
                    scheduleCard(schedule: schedule, isActive: schedule.isCurrentlyActive() && schedule.isActive)
                }
            }
        }
    }
    
    private func scheduleCard(schedule: ProtectionHoursSchedule, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.midnightSlate)
                    
                    Text(formatScheduleTime(schedule))
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                    
                    Text(formatScheduleDays(schedule))
                        .font(.system(size: 12))
                        .foregroundColor(.softGraphite)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.reverBlue)
                                .frame(width: 8, height: 8)
                            Text("Active")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.reverBlue)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.softGraphite.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Text(schedule.isActive ? "Inactive" : "Disabled")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.softGraphite)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.reverBlue.opacity(0.05) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color.reverBlue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Modify")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.midnightSlate)
            
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(
                    icon: "1.circle.fill",
                    text: "Go to Settings → Protection Hours"
                )
                instructionRow(
                    icon: "2.circle.fill",
                    text: "View or edit existing schedules"
                )
                instructionRow(
                    icon: "3.circle.fill",
                    text: "Toggle schedules on/off or create new ones"
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mistGray.opacity(0.3))
            )
            
            Button(action: {
                dismiss()
                // Small delay to ensure sheet is fully dismissed before switching tabs
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // First switch to Settings tab
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToSettingsTab"), object: nil)
                    // Then open Quiet Hours view (with a small delay to ensure tab switch completes)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(name: NSNotification.Name("OpenQuietHours"), object: nil)
                    }
                }
            }) {
                HStack {
                    Spacer()
                    Text("Open Settings")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.reverBlue)
                )
            }
        }
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.reverBlue)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.midnightSlate)
            
            Spacer()
        }
    }
    
    private func formatScheduleTime(_ schedule: ProtectionHoursSchedule) -> String {
        let startHour = schedule.startTime.hour ?? 0
        let startMinute = schedule.startTime.minute ?? 0
        let endHour = schedule.endTime.hour ?? 0
        let endMinute = schedule.endTime.minute ?? 0
        
        let startTimeStr = formatTime(hour: startHour, minute: startMinute)
        let endTimeStr = formatTime(hour: endHour, minute: endMinute)
        
        return "\(startTimeStr) - \(endTimeStr)"
    }
    
    private func formatTime(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func formatScheduleDays(_ schedule: ProtectionHoursSchedule) -> String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = schedule.daysOfWeek.sorted()
        
        if sortedDays.count == 7 {
            return "Every day"
        } else if sortedDays == [1, 7] {
            return "Weekends"
        } else if sortedDays == [2, 3, 4, 5, 6] {
            return "Weekdays"
        } else {
            return sortedDays.map { dayNames[$0 - 1] }.joined(separator: ", ")
        }
    }
    
    private func loadSchedules() {
        // Load schedules from service
        protectionHoursService.ensureSchedulesLoaded()
        
        // Wait a moment for schedules to load, then update
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                schedules = protectionHoursService.schedules
                isLoading = false
            }
        }
    }
}

struct MoodCardView: View {
    let dashboardData: AWSDataService.DashboardData?
    @State private var currentMood: MoodLevel? = nil
    @State private var loadTask: Task<Void, Never>? = nil
    
    var body: some View {
        Group {
            if let mood = currentMood {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(mood.emoji)
                            .font(.system(size: 32))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Mood")
                                .font(.system(size: 14))
                                .foregroundColor(.softGraphite)
                            
                            Text(mood.displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                        }
                        
                        Spacer()
                    }
                }
                .reverCard()
                .padding(.horizontal, .spacingCard)
            }
        }
        .onAppear {
            // OPTIMIZED: Defer data loading to avoid blocking UI
            Task.detached(priority: .utility) {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    loadMood()
                }
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }
    
    private func loadMood() {
        loadTask?.cancel()
        loadTask = Task {
            guard !Task.isCancelled else { return }
            
            // OPTIMIZED: Use ONLY Dashboard API data - no service fallback
            // This eliminates all JSON decode operations from startup path
            if let moodString = dashboardData?.currentMood,
               let mood = MoodLevel(rawValue: moodString) {
                currentMood = mood
            }
            // No fallback - if API data not available, currentMood stays nil (card shows placeholder)
        }
    }
}

struct InteractionsCardView: View {
    let dashboardData: AWSDataService.DashboardData?
    @State private var recentIntents: [PurchaseIntent] = []
    @State private var totalCount = 0
    @State private var showHistory = false
    @State private var loadTask: Task<Void, Never>? = nil
    
    var body: some View {
        Group {
            if totalCount > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 24))
                            .foregroundColor(.reverBlue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recent Interactions")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.midnightSlate)
                            
                            Text(totalCount == 1 ? "\(totalCount) total interaction" : "\(totalCount) total interactions")
                                .font(.system(size: 13))
                                .foregroundColor(.softGraphite)
                        }
                        
                        Spacer()
                        
                        Button(action: { showHistory = true }) {
                            Text("View All")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.reverBlue)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(recentIntents.prefix(3)) { intent in
                            HStack {
                                Image(systemName: intent.purchaseType == .planned ? "calendar.circle.fill" : "bolt.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(intent.purchaseType == .planned ? Color.reverBlue : Color.orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(intent.purchaseType.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.midnightSlate)
                                    
                                    if let category = intent.category {
                                        Text(category.displayName)
                                            .font(.system(size: 12))
                                            .foregroundColor(.softGraphite)
                                    } else if let mood = intent.impulseMood {
                                        Text(mood.displayName)
                                            .font(.system(size: 12))
                                            .foregroundColor(.softGraphite)
                                    }
                                }
                                
                                Spacer()
                                
                                if let amount = intent.amount {
                                    Text(formatCurrency(amount))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                }
                                
                                Text(formatShortDate(intent.date))
                                    .font(.system(size: 11))
                                    .foregroundColor(.softGraphite)
                            }
                            .padding(.vertical, 8)
                            
                            if intent.id != recentIntents.prefix(3).last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .reverCard()
                .padding(.horizontal, .spacingCard)
                .sheet(isPresented: $showHistory) {
                    PurchaseIntentHistoryView()
                }
            }
        }
        .onAppear {
            // OPTIMIZED: Defer data loading to avoid blocking UI
            Task.detached(priority: .utility) {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    loadInteractions()
                }
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }
    
    private func loadInteractions() {
        loadTask?.cancel()
        loadTask = Task {
            guard !Task.isCancelled else { return }
            
            // OPTIMIZED: Use ONLY Dashboard API data - no service fallback
            // This eliminates all JSON decode operations from startup path
            if let dashboardData = dashboardData {
                totalCount = dashboardData.recentPurchaseIntentsCount
                // Note: API only provides count, not full list
                // We'll show count without recent intents list to avoid blocking
                recentIntents = [] // Don't load intents - it triggers JSON decode
            } else {
                // No API data - show empty state
                totalCount = 0
                recentIntents = []
            }
            // No fallback - if API data not available, show empty state
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateComponents([.day], from: date, to: Date()).day ?? 0 < 7 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

struct InsightsCardView: View {
    var body: some View {
        // Placeholder - will be implemented with behavioral insights
        EmptyView()
    }
}

// MARK: - Helper Extensions
// Note: ensureDataLoaded() methods are already defined in the service files

#Preview {
    HomeView()
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Card Position Preference Key

struct CardPositionPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
