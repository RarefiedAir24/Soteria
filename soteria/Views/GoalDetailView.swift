//
//  GoalDetailView.swift
//  soteria
//
//  View to show goal details and progress when a goal leaf is tapped on the money tree
//

import SwiftUI

struct GoalDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var goalsService: GoalsService
    @EnvironmentObject var authService: AuthService
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    
    let goal: SavingsGoal
    
    @State private var showAddDeposit = false
    @State private var showEditGoal = false
    @State private var showShareGoal = false
    @State private var showPaywall = false
    @State private var currentGoal: SavingsGoal? = nil
    @State private var isLoading = true
    
    // Goal photo view helper
    private func goalPhotoView(goal: SavingsGoal) -> some View {
        Group {
            // Try UserDefaults cache first
            if let data = UserDefaults.standard.data(forKey: "goal_photo_\(goal.id)"),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(16)
                    .onAppear {
                        // Try to load from S3 in background if not in cache
                        if goal.photoPath != nil && !goal.photoPath!.hasPrefix("local://") {
                            Task {
                                do {
                                    if let s3Image = try await GoalPhotoService.shared.downloadGoalPhoto(goalId: goal.id) {
                                        // Cache it
                                        if let imageData = s3Image.jpegData(compressionQuality: 0.8) {
                                            UserDefaults.standard.set(imageData, forKey: "goal_photo_\(goal.id)")
                                        }
                                    }
                                } catch {
                                    // Photo not found or error - that's OK
                                }
                            }
                        }
                    }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.dreamMist)
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.softGraphite)
                    )
            }
        }
    }
    
    private func progressPercentage(for goal: SavingsGoal) -> Int {
        guard goal.targetAmount > 0 else { return 0 }
        return Int((goal.currentAmount / goal.targetAmount) * 100)
    }
    
    private func formattedCurrent(for goal: SavingsGoal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: goal.currentAmount)) ?? "$0.00"
    }
    
    private func formattedTarget(for goal: SavingsGoal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: goal.targetAmount)) ?? "$0.00"
    }
    
    private func formattedRemaining(for goal: SavingsGoal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: goal.remainingAmount)) ?? "$0.00"
    }
    
    // Computed property for the goal to display
    private var displayGoal: SavingsGoal {
        currentGoal ?? goal
    }
    
    // Check if goal can be shared (not completed or cancelled)
    private func canShareGoal(goal: SavingsGoal) -> Bool {
        // Goals can be shared if they are active or failed
        // Cannot share if completed (achieved) or cancelled
        return goal.status == .active || goal.status == .failed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mistGray
                    .ignoresSafeArea()
                
                Group {
                    if isLoading {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading goal...")
                                .font(.system(size: 16))
                                .foregroundColor(.softGraphite)
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                // Goal Photo
                                if displayGoal.photoPath != nil {
                                    goalPhotoView(goal: displayGoal)
                                }
                                
                                // Goal Info Card
                                VStack(alignment: .leading, spacing: 20) {
                                // Header
                                HStack {
                                    Image(systemName: displayGoal.category.icon)
                                        .font(.system(size: 28))
                                        .foregroundColor(.softGraphite)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(displayGoal.name)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.midnightSlate)
                                        
                                        Text(displayGoal.category.rawValue)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.softGraphite)
                                    }
                                    
                                    Spacer()
                                    
                                    // Status Badge
                                    HStack(spacing: 4) {
                                        Image(systemName: displayGoal.status.icon)
                                            .font(.system(size: 12))
                                        Text(displayGoal.status.displayName)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(statusColor(for: displayGoal.status))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(statusColor(for: displayGoal.status).opacity(0.1))
                                    )
                                }
                                
                                Divider()
                                
                                // Progress Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Progress")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.midnightSlate)
                                    
                                    // Progress Bar
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.dreamMist)
                                                .frame(height: 16)
                                            
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.softGraphite)
                                                .frame(width: geometry.size.width * min(displayGoal.progress, 1.0), height: 16)
                                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: displayGoal.progress)
                                        }
                                    }
                                    .frame(height: 16)
                                    
                                    // Amounts
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Current")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.softGraphite)
                                            Text(formattedCurrent(for: displayGoal))
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.softGraphite)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Target")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.softGraphite)
                                            Text(formattedTarget(for: displayGoal))
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.midnightSlate)
                                        }
                                    }
                                    
                                    // Percentage
                                    HStack {
                                        Text("\(progressPercentage(for: displayGoal))% Complete")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.softGraphite)
                                        
                                        Spacer()
                                        
                                        Text("\(formattedRemaining(for: displayGoal)) remaining")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.softGraphite)
                                    }
                                }
                                
                                Divider()
                                
                                // Forecasting Insights
                                if displayGoal.status == .active && displayGoal.remainingAmount > 0 {
                                    forecastingInsightsSection
                                }
                                
                                Divider()
                                
                                // Actions
                                VStack(spacing: 12) {
                                    Button(action: {
                                        showAddDeposit = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Deposit")
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.softGraphite)
                                        )
                                    }
                                    
                                    Button(action: {
                                        showEditGoal = true
                                    }) {
                                        HStack {
                                            Image(systemName: "pencil.circle.fill")
                                            Text("Edit Goal")
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.softGraphite)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.softGraphite.opacity(0.1))
                                        )
                                    }
                                }
                                
                                // Goal Description
                                if let description = displayGoal.description, !description.isEmpty {
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Description")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.midnightSlate)
                                        
                                        Text(description)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.softGraphite)
                                    }
                                }
                                
                                // Dates
                                if let startDate = displayGoal.startDate {
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Started")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.softGraphite)
                                        
                                        Text(startDate, style: .date)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.midnightSlate)
                                    }
                                }
                                
                                if let targetDate = displayGoal.targetDate {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Target Date")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.softGraphite)
                                        
                                        Text(targetDate, style: .date)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.midnightSlate)
                                        
                                        if let daysUntil = displayGoal.daysUntilTarget {
                                            if daysUntil > 0 {
                                                Text("\(daysUntil) days remaining")
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundColor(.softGraphite)
                                            } else if daysUntil == 0 {
                                                Text("Due today!")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.orange)
                                            } else {
                                                Text("\(abs(daysUntil)) days overdue")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                        }
                    }
                }
            }
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Only show share button if goal is shareable (not completed/cancelled) and user is premium
                    if canShareGoal(goal: displayGoal) {
                        Button(action: {
                            if subscriptionService.isPremium {
                                showShareGoal = true
                            } else {
                                showPaywall = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.softGraphite)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.softGraphite)
                }
            }
        }
        .onAppear {
            refreshGoalData()
        }
        .refreshable {
            // Pull-to-refresh
            await refreshGoalDataAsync()
        }
        .sheet(isPresented: $showShareGoal) {
            ShareGoalView(goal: displayGoal)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showAddDeposit) {
            NavigationStack {
                AddDepositView(goal: currentGoal ?? goal)
                    .environmentObject(goalsService)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showAddDeposit = false
                            }
                        }
                    }
            }
            .onDisappear {
                // Refresh goal data when deposit view is dismissed
                refreshGoalData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DepositMade"))) { _ in
            // Refresh when deposit is made
            refreshGoalData()
        }
        .sheet(isPresented: $showEditGoal) {
            NavigationStack {
                EditGoalView(goal: currentGoal ?? goal)
                    .environmentObject(goalsService)
                    .environmentObject(authService)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showEditGoal = false
                            }
                        }
                    }
            }
        }
    }
    
    private func statusColor(for status: SavingsGoal.GoalStatus) -> Color {
        switch status {
        case .active:
            return .softGraphite
        case .achieved:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
    
    // MARK: - Forecasting Insights
    
    private var forecastingInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(.softGraphite)
                
                Text("Forecasting Insights")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.midnightSlate)
            }
            
            // Calculate insights
            let insights = calculateForecastingInsights(for: displayGoal)
            
            if let insights = insights {
                VStack(alignment: .leading, spacing: 12) {
                    // Projected completion date
                    if let projectedDate = insights.projectedCompletionDate {
                        insightCard(
                            icon: "calendar",
                            title: "Projected Completion",
                            message: "Based on your current savings rate, you'll reach this goal on \(formatDate(projectedDate))",
                            color: .softGraphite
                        )
                    }
                    
                    // Extra deposit insights
                    if let extraDepositInsight = insights.extraDepositInsight {
                        insightCard(
                            icon: "plus.circle.fill",
                            title: extraDepositInsight.title,
                            message: extraDepositInsight.message,
                            color: .green
                        )
                    }
                    
                    // Small increase insight
                    if let smallIncreaseInsight = insights.smallIncreaseInsight {
                        insightCard(
                            icon: "arrow.up.circle.fill",
                            title: smallIncreaseInsight.title,
                            message: smallIncreaseInsight.message,
                            color: .orange
                        )
                    }
                    
                    // If no insights are available, show helpful message
                    if insights.projectedCompletionDate == nil && 
                       insights.extraDepositInsight == nil && 
                       insights.smallIncreaseInsight == nil {
                        Text("Make a few deposits to see personalized forecasting insights")
                            .font(.system(size: 14))
                            .foregroundColor(.softGraphite)
                            .italic()
                            .padding(.top, 8)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start making deposits to see forecasting insights")
                        .font(.system(size: 14))
                        .foregroundColor(.softGraphite)
                        .italic()
                    
                    if displayGoal.startDate == nil {
                        Text("Tip: Add a start date to your goal for more accurate forecasts")
                            .font(.system(size: 12))
                            .foregroundColor(.softGraphite.opacity(0.7))
                            .italic()
                    }
                }
            }
        }
        .onAppear {
            // Debug logging
            let insights = calculateForecastingInsights(for: displayGoal)
            print("📊 [GoalDetailView] Forecasting insights calculated:")
            print("   - Has insights: \(insights != nil)")
            if let insights = insights {
                print("   - Projected date: \(insights.projectedCompletionDate?.description ?? "nil")")
                print("   - Extra deposit insight: \(insights.extraDepositInsight != nil)")
                print("   - Small increase insight: \(insights.smallIncreaseInsight != nil)")
            } else {
                print("   - Reason: Goal status=\(displayGoal.status), remaining=\(displayGoal.remainingAmount), startDate=\(displayGoal.startDate?.description ?? "nil")")
            }
        }
    }
    
    private func insightCard(icon: String, title: String, message: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.midnightSlate)
                
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.softGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.05))
        )
    }
    
    private struct ForecastingInsights {
        let projectedCompletionDate: Date?
        let extraDepositInsight: (title: String, message: String)?
        let smallIncreaseInsight: (title: String, message: String)?
    }
    
    private func calculateForecastingInsights(for goal: SavingsGoal) -> ForecastingInsights? {
        guard goal.status == .active,
              goal.remainingAmount > 0,
              let startDate = goal.startDate else {
            return nil
        }
        
        let calendar = Calendar.current
        let now = Date()
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: now).day ?? 1
        
        // Get deposits for this goal from PlaidService
        let plaidService = PlaidService.shared
        let goalDeposits = plaidService.depositHistory.filter { $0.goalId == goal.id }
        
        // Calculate average deposit amount
        let averageDeposit: Double
        if !goalDeposits.isEmpty {
            let totalDeposited = goalDeposits.reduce(0.0) { $0 + $1.amount }
            averageDeposit = totalDeposited / Double(goalDeposits.count)
        } else {
            // Fallback: use current amount divided by days since start
            averageDeposit = goal.currentAmount / Double(max(daysSinceStart, 1))
        }
        
        // Calculate current savings rate (per day)
        let savingsRatePerDay = goal.currentAmount / Double(max(daysSinceStart, 1))
        
        // Projected completion date based on current rate
        let projectedCompletionDate: Date?
        if savingsRatePerDay > 0 {
            let daysToComplete = goal.remainingAmount / savingsRatePerDay
            projectedCompletionDate = calendar.date(byAdding: .day, value: Int(daysToComplete), to: now)
        } else {
            projectedCompletionDate = nil
        }
        
        // Calculate extra deposit insight (if user makes one extra deposit of average amount)
        let extraDepositInsight: (title: String, message: String)?
        if averageDeposit > 0 && savingsRatePerDay > 0 {
            let daysSaved = averageDeposit / savingsRatePerDay
            if daysSaved >= 1 {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = "USD"
                formatter.maximumFractionDigits = 0
                let depositString = formatter.string(from: NSNumber(value: averageDeposit)) ?? "$\(Int(averageDeposit))"
                
                extraDepositInsight = (
                    title: "Make an Extra Deposit",
                    message: "If you make one extra deposit of \(depositString), you'll reach your goal \(Int(daysSaved)) day\(Int(daysSaved) == 1 ? "" : "s") earlier."
                )
            } else {
                extraDepositInsight = nil
            }
        } else {
            extraDepositInsight = nil
        }
        
        // Calculate small increase insight (if user increases current deposit by $0.50)
        let smallIncreaseInsight: (title: String, message: String)?
        if averageDeposit > 0 && savingsRatePerDay > 0 {
            let increaseAmount = 0.50
            let daysSaved = increaseAmount / savingsRatePerDay
            
            // Only show if it saves at least 0.5 days
            if daysSaved >= 0.5 {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = "USD"
                formatter.maximumFractionDigits = 2
                let increaseString = formatter.string(from: NSNumber(value: increaseAmount)) ?? "$0.50"
                
                let daysText: String
                if daysSaved >= 1 {
                    daysText = "\(Int(daysSaved)) day\(Int(daysSaved) == 1 ? "" : "s")"
                } else {
                    daysText = "about \(Int(daysSaved * 24)) hour\(Int(daysSaved * 24) == 1 ? "" : "s")"
                }
                
                smallIncreaseInsight = (
                    title: "Small Increase, Big Impact",
                    message: "If you deposit \(increaseString) more than usual, you'll reach your goal \(daysText) sooner."
                )
            } else {
                smallIncreaseInsight = nil
            }
        } else {
            smallIncreaseInsight = nil
        }
        
        return ForecastingInsights(
            projectedCompletionDate: projectedCompletionDate,
            extraDepositInsight: extraDepositInsight,
            smallIncreaseInsight: smallIncreaseInsight
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Refresh Logic
    
    private func refreshGoalData() {
        Task { @MainActor in
            isLoading = true
            try? await Task.sleep(nanoseconds: 100_000_000)
            goalsService.refreshGoals()
            if let refreshedGoal = goalsService.getGoal(byId: goal.id) {
                currentGoal = refreshedGoal
                print("🎯 [GoalDetailView] Goal refreshed: \(refreshedGoal.name), Amount: \(refreshedGoal.currentAmount)/\(refreshedGoal.targetAmount)")
            } else {
                currentGoal = goal
                print("🎯 [GoalDetailView] Using fallback goal: \(goal.name)")
            }
            isLoading = false
        }
    }
    
    @MainActor
    private func refreshGoalDataAsync() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 100_000_000)
        goalsService.refreshGoals()
        if let refreshedGoal = goalsService.getGoal(byId: goal.id) {
            currentGoal = refreshedGoal
            print("🎯 [GoalDetailView] Goal refreshed (pull-to-refresh): \(refreshedGoal.name), Amount: \(refreshedGoal.currentAmount)/\(refreshedGoal.targetAmount)")
        } else {
            currentGoal = goal
            print("🎯 [GoalDetailView] Using fallback goal: \(goal.name)")
        }
        isLoading = false
    }
}
