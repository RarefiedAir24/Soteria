//
//  HomeView.swift
//  rever
//
//  Home view with behavioral insights
//

import SwiftUI
// TEMPORARILY DISABLED: Firebase imports - testing if they're causing crash
// import FirebaseAuth
// import FirebaseStorage

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    
    // SIMPLIFIED: Reduced @State properties from 20+ to 7 essential ones
    // Essential metrics (load immediately from fast services)
    @State private var totalSaved: Double = 0.0
    @State private var streak: Int = 0
    @State private var activeGoal: SavingsGoal? = nil
    
    // Header data
    @State private var avatarImage: UIImage? = nil
    @State private var userName: String = "User"
    @State private var userEmail: String = "there"
    
    // Progressive loading flags (cards appear one by one)
    @State private var showRiskCard = false
    @State private var showQuietModeCard = false
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
    
    // Task tracking for cancellation (prevent memory leaks)
    @State private var dataLoadingTask: Task<Void, Never>? = nil
    @State private var progressiveLoadingTask: Task<Void, Never>? = nil
    
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
    
    
    var body: some View {
        let bodyStart = Date()
        print("🔍 [HomeView] body evaluation started at \(bodyStart)")
        
        // ULTRA-SIMPLIFIED: Show only essential content immediately
        let view = ZStack(alignment: .top) {
            // REVER background - Mist Gray for calm, dreamlike feel
            Color.mistGray
                .ignoresSafeArea(.all, edges: .top)
            Color.cloudWhite
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: .spacingSection) {
                    // Essential Metrics (Load immediately - always shows, even with 0 values)
                    essentialMetricsCard
                    
                    // Progressive Cards (Load one by one - truly lazy)
                    if showRiskCard {
                        RiskCardView(dashboardData: dashboardData)
                    }
                    
                    if showQuietModeCard {
                        QuietModeCardView(dashboardData: dashboardData)
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
                .padding(.top, 60) // Add top padding for header
            }
            
            // Fixed Header - simplified to prevent blocking
            VStack {
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
                        Text("HI, \(userName.uppercased())")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.midnightSlate)
                        Text("Welcome back")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color.mistGray.opacity(0.95))
                
                Spacer()
            }
        }
        
        let bodyEnd = Date()
        let bodyDuration = bodyEnd.timeIntervalSince(bodyStart)
        if bodyDuration > 0.1 {
            print("⚠️ [HomeView] body evaluation took \(String(format: "%.3f", bodyDuration))s")
        } else {
            print("✅ [HomeView] body evaluation completed in \(String(format: "%.3f", bodyDuration))s")
        }
        
        return view
        .onAppear {
            let timestamp = Date()
            print("🟢 [HomeView] onAppear at \(timestamp)")
            
            // OPTIMIZED: Load cached data synchronously (fast, no blocking)
            // Then load fresh data in background (non-blocking)
            loadEssentialData()
            
            // Start progressive card loading (deferred, non-blocking)
            startProgressiveLoading()
            
            // Reload avatar in case it was updated in ProfileView (fast, local)
            loadAvatar()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AvatarUpdated"))) { _ in
            // Reload avatar when it's updated in ProfileView
            loadAvatar()
        }
        .onDisappear {
            // Cancel all tasks to prevent memory leaks
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
    }
    
    // MARK: - Essential Metrics Card (Loads Immediately)
    private var essentialMetricsCard: some View {
        ReverCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Total Saved
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Saved")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.softGraphite)
                        Text(formattedTotalSaved)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.reverBlue)
                    }
                    
                    Spacer()
                    
                    // Streak Badge
                    if streak > 0 {
                        VStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 32))
                            Text("\(streak)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.reverBlue)
                            Text("day streak")
                                .font(.system(size: 10))
                                .foregroundColor(.softGraphite)
                        }
                    }
                }
                
                // Active Goal Progress (if exists)
                if let goal = activeGoal {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(goal.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.softGraphite)
                            
                            Spacer()
                            
                            Text("\(Int(goal.progress * 100))%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.reverBlue)
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.mistGray)
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.reverBlue)
                                    .frame(width: geometry.size.width * goal.progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        Text(formatGoalAmounts(current: goal.currentAmount, target: goal.targetAmount))
                            .font(.system(size: 10))
                            .foregroundColor(.softGraphite)
                    }
                    .padding(.top, 12)
                }
            }
        }
        .padding(.horizontal, .spacingCard)
        .padding(.top, 60)
    }
    
    // MARK: - Progressive Card Views (Load After Delays)
    // Cards are created inline in body to ensure true lazy loading
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            // Avatar - load from UserDefaults (same as ProfileView)
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
            
            // User name
            VStack(alignment: .leading, spacing: 2) {
                Text("HI, \(userName.uppercased())")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                Text("Welcome back")
                    .font(.system(size: 14))
                    .foregroundColor(.softGraphite)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.mistGray.opacity(0.95))
    }
    
    // MARK: - Data Loading
    
    private func loadEssentialData() {
        print("🟢 [HomeView] loadEssentialData() called")
        // Set loading to false immediately so content shows (even with 0 values)
        isLoadingData = false
        
        // STRATEGY: Use cached data immediately, then update from API
        // 1. Load cached dashboard data instantly (from previous session)
        // 2. Load fresh data from API in background
        // 3. Update UI when API responds
        
        // Step 1: Load cached data immediately (instant, no blocking)
        if let cached = AWSDataService.shared.getCachedDashboardData() {
            self.totalSaved = cached.totalSaved
            self.streak = cached.currentStreak
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
                    self.totalSaved = dashboardData.totalSaved
                    self.streak = dashboardData.currentStreak
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
                showQuietModeCard = true
            }
            
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
        // Load avatar from UserDefaults (fast, local cache)
        // This matches ProfileView's avatar loading logic
        if let data = UserDefaults.standard.data(forKey: "user_avatar"),
           let image = UIImage(data: data) {
            avatarImage = image
            print("✅ [HomeView] Avatar loaded from UserDefaults")
        } else {
            avatarImage = nil
            print("ℹ️ [HomeView] No avatar found in UserDefaults")
        }
    }
    
    // MARK: - Progressive Card Views (Independent Components)
    
    // These cards load their own data independently to prevent blocking
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
                    recommendation = "Consider enabling Quiet Hours to protect your finances"
                    riskFactors = [.stressMood] // Simplified - API doesn't provide detailed factors
                case "medium":
                    riskLevel = 0.5
                    recommendation = "Stay mindful of your spending decisions"
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

struct QuietModeCardView: View {
    let dashboardData: AWSDataService.DashboardData?
    @State private var isQuietModeActive = false
    @State private var currentSchedule: QuietHoursSchedule? = nil
    @State private var loadTask: Task<Void, Never>? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isQuietModeActive ? "moon.fill" : "moon")
                    .font(.system(size: 24))
                    .foregroundColor(isQuietModeActive ? Color.reverBlue : .softGraphite)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isQuietModeActive ? "Financial Quiet Mode Active" : "Financial Quiet Mode Inactive")
                        .reverH3()
                    
                    if isQuietModeActive {
                        Text("Your sanctuary is protecting you")
                            .reverCaption()
                            .foregroundColor(.reverBlue)
                    } else if let schedule = currentSchedule {
                        Text(schedule.name)
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                    } else {
                        Text("Protection available when you need it")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                    }
                }
                
                Spacer()
            }
        }
        .reverCard()
        .padding(.horizontal, .spacingCard)
        .onAppear {
            // OPTIMIZED: Defer data loading to avoid blocking UI
            Task.detached(priority: .utility) {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    loadQuietMode()
                }
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }
    
    private func loadQuietMode() {
        loadTask?.cancel()
        loadTask = Task {
            guard !Task.isCancelled else { return }
            
            // OPTIMIZED: Use ONLY Dashboard API data - no service fallback
            // This eliminates all JSON decode operations from startup path
            if let dashboardData = dashboardData {
                isQuietModeActive = dashboardData.isQuietModeActive
                // Note: API doesn't provide schedule details, only status
                // We'll show status without schedule name to avoid blocking
                currentSchedule = nil // Don't load schedule - it triggers JSON decode
            }
            // No fallback - if API data not available, use defaults (isQuietModeActive = false)
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
