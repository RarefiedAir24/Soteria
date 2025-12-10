//
//  HomeView.swift
//  rever
//
//  Home view with behavioral insights
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var savingsService: SavingsService
    @EnvironmentObject var quietHoursService: QuietHoursService
    @EnvironmentObject var regretRiskEngine: RegretRiskEngine
    @EnvironmentObject var moodService: MoodTrackingService
    @EnvironmentObject var regretService: RegretLoggingService
    @EnvironmentObject var deviceActivityService: DeviceActivityService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @EnvironmentObject var goalsService: GoalsService
    @EnvironmentObject var streakService: StreakService
    
    @State private var showMetrics = false
    @State private var unblockMetrics: (totalUnblocks: Int, plannedUnblocks: Int, impulseUnblocks: Int, mostCommonCategory: String?, mostCommonMood: String?, mostRequestedAppIndex: Int?, mostRequestedAppName: String?) = (0, 0, 0, nil, nil, nil, nil)
    @State private var isLoadingMetrics = true
    @State private var behavioralPatterns: DeviceActivityService.BehavioralPatterns? = nil
    
    private var userEmail: String {
        authService.currentUser?.email?.components(separatedBy: "@").first ?? "there"
    }
    
    private var formattedTotalSaved: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: savingsService.totalSaved)) ?? "$0.00"
    }
    
    private var formattedLastSaved: String {
        guard let lastSaved = savingsService.lastSavedAmount else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: lastSaved)) ?? "$0.00"
    }
    
    private func formatGoalAmounts(current: Double, target: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        let currentString = formatter.string(from: NSNumber(value: current)) ?? "$\(Int(current))"
        let targetString = formatter.string(from: NSNumber(value: target)) ?? "$\(Int(target))"
        return "\(currentString) of \(targetString)"
    }
    
    private var riskLevelColor: Color {
        guard let risk = regretRiskEngine.currentRisk else { return .gray }
        if risk.riskLevel >= 0.7 {
            return .red
        } else if risk.riskLevel >= 0.4 {
            return .orange
        } else {
            return Color(red: 0.1, green: 0.6, blue: 0.3)
        }
    }
    
    private var riskLevelText: String {
        guard let risk = regretRiskEngine.currentRisk else { return "Unknown" }
        if risk.riskLevel >= 0.7 {
            return "High Risk"
        } else if risk.riskLevel >= 0.4 {
            return "Moderate Risk"
        } else {
            return "Low Risk"
        }
    }
    
    var body: some View {
        let _ = {
            let timestamp = Date()
            print("🟢 [HomeView] body evaluated at \(timestamp)")
        }()
        
        return ZStack(alignment: .top) {
            // Consistent background that extends to safe area
            Color(red: 0.95, green: 0.95, blue: 0.95)
                .ignoresSafeArea(.all, edges: .top)
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Regret Risk Alert Card
                    if let risk = regretRiskEngine.currentRisk, risk.riskLevel >= 0.4 {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: risk.riskLevel >= 0.7 ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(riskLevelColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(riskLevelText)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    
                                    if let recommendation = risk.recommendation {
                                        Text(recommendation)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
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
                                                        .fill(riskLevelColor.opacity(0.1))
                                                )
                                                .foregroundColor(riskLevelColor)
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
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                    }
                    
                    // Quiet Mode Status Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: quietHoursService.isQuietModeActive ? "moon.fill" : "moon")
                                .font(.system(size: 24))
                                .foregroundColor(quietHoursService.isQuietModeActive ? Color(red: 0.1, green: 0.6, blue: 0.3) : .gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quietHoursService.isQuietModeActive ? "Financial Quiet Mode Active" : "Financial Quiet Mode Inactive")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                if quietHoursService.isQuietModeActive {
                                    Text("Your sanctuary is protecting you")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                } else if let schedule = quietHoursService.currentActiveSchedule {
                                    Text(schedule.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                } else {
                                    Text("Protection available when you need it")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
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
                    .padding(.horizontal, 20)
                    .padding(.top, quietHoursService.isQuietModeActive || (regretRiskEngine.currentRisk?.riskLevel ?? 0) >= 0.4 ? 0 : 60)
                    
                    // Protection Moments Card - Hero Card (Behavioral Focus)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Protection Moments")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                
                                Text("\(savingsService.soteriaMomentsCount)")
                                    .font(.system(size: 52, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                
                                Text("times you chose protection")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            }
                            
                            Spacer()
                            
                            // Streak Badge
                            if streakService.currentStreak > 0 {
                                VStack(spacing: 4) {
                                    Text(streakService.streakEmoji)
                                        .font(.system(size: 32))
                                    Text("\(streakService.currentStreak)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                    Text("day streak")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // Active Goal Progress (if exists)
                        if let activeGoal = goalsService.activeGoal {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(activeGoal.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(activeGoal.progress * 100))%")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                }
                                
                                // Progress Bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(red: 0.1, green: 0.6, blue: 0.3))
                                            .frame(width: geometry.size.width * activeGoal.progress, height: 6)
                                    }
                                }
                                .frame(height: 6)
                                
                                Text(formatGoalAmounts(current: activeGoal.currentAmount, target: activeGoal.targetAmount))
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 8)
                        }
                        
                        Text("Building awareness, one moment at a time")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .italic()
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.95, green: 0.98, blue: 0.95),
                                        Color(red: 0.92, green: 0.97, blue: 0.92)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
                    // Behavioral Stats Row
                    // Use cached metrics (loaded asynchronously)
                    if !isLoadingMetrics && unblockMetrics.totalUnblocks > 0 {
                        HStack(spacing: 16) {
                            // Unblock Frequency Card
                            VStack(alignment: .leading, spacing: 6) {
                                Text("This Week")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                
                                Text("\(unblockMetrics.totalUnblocks)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                Text("unblock requests")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            
                            // Impulse vs Planned Card
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Impulse Rate")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                
                                if unblockMetrics.totalUnblocks > 0 {
                                    let impulseRate = Double(unblockMetrics.impulseUnblocks) / Double(unblockMetrics.totalUnblocks) * 100
                                    Text("\(String(format: "%.0f", impulseRate))%")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.orange)
                                } else {
                                    Text("0%")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.orange)
                                }
                                
                                Text("impulse vs planned")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Mood Insights Card
                    if let currentMood = moodService.currentMood {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(currentMood.emoji)
                                    .font(.system(size: 32))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Mood")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    
                                    Text(currentMood.displayName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
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
                        .padding(.horizontal, 20)
                    }
                    
                    // Behavioral Insights Card
                    if let behavioralPatterns = behavioralPatterns, unblockMetrics.totalUnblocks > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                
                                Text("Your Insights")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                Spacer()
                            }
                            
                            // Quick stats
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Unblocks")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("\(unblockMetrics.totalUnblocks)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Planned")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("\(unblockMetrics.plannedUnblocks)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                }
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Impulse")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("\(unblockMetrics.impulseUnblocks)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Divider()
                            
                            // Key insights
                            VStack(alignment: .leading, spacing: 8) {
                                if let timeOfDay = behavioralPatterns.mostCommonTimeOfDay {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 14))
                                        Text("Most active: \(timeOfDay)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 14))
                                    Text("\(String(format: "%.0f", behavioralPatterns.usageRate))% of unblocks led to app usage")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                
                                if behavioralPatterns.avgUnblocksPerDay > 0 {
                                    HStack {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .foregroundColor(.green)
                                            .font(.system(size: 14))
                                        Text("\(String(format: "%.1f", behavioralPatterns.avgUnblocksPerDay)) unblocks per day on average")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            // Link to full metrics
                            Button(action: {
                                showMetrics = true
                            }) {
                                HStack {
                                    Text("View Full Metrics")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.3))
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Regret Summary Card
                    if regretService.recentRegretCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("This Week's Regrets")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    
                                    Text("\(regretService.recentRegretCount)")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
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
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Fixed Header
            VStack(spacing: 2) {
                Text("Hi, \(userEmail)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                Text("Welcome back")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Color(red: 0.92, green: 0.97, blue: 0.94)
                    .ignoresSafeArea(edges: .top)
            )
            .zIndex(100)
        }
        .sheet(isPresented: $showMetrics) {
            MetricsDashboardView()
                .environmentObject(deviceActivityService)
                .environmentObject(subscriptionService)
        }
        .onAppear {
            let timestamp = Date()
            print("🟢 [HomeView] onAppear at \(timestamp)")
        }
        .task {
            let taskStartTime = Date()
            print("🟢 [HomeView] .task started at \(taskStartTime)")
            // Skip all metrics loading to prevent blocking
            // Just set isLoadingMetrics to false immediately
            isLoadingMetrics = false
            print("🟡 [HomeView] Set isLoadingMetrics = false immediately")
            let taskEndTime = Date()
            print("🟢 [HomeView] .task completed at \(taskEndTime) (total: \(taskEndTime.timeIntervalSince(taskStartTime))s)")
            
            // DISABLED: All metrics loading to prevent blocking
            /*
            Task.detached(priority: .background) {
                let sleepStart = Date()
                print("🟡 [HomeView] Starting 3s sleep at \(sleepStart)")
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds - wait for DeviceActivityService to load
                let sleepEnd = Date()
                print("🟡 [HomeView] Sleep completed at \(sleepEnd) (took \(sleepEnd.timeIntervalSince(sleepStart))s)")
                
                // Skip metrics loading entirely if it's blocking - just show empty state
                // The metrics can be loaded later when user interacts with the app
                print("🟡 [HomeView] Skipping metrics loading to prevent blocking - will load on demand")
                
                // Update UI state directly without MainActor.run to avoid potential deadlock
                // Since we're already in a background task, we need to update on main actor
                // But use a simpler approach - just set the flag directly
                let updateStart = Date()
                print("🟡 [HomeView] Updating UI state at \(updateStart)")
                
                // Use Task with MainActor annotation instead of MainActor.run
                await MainActor.run {
                    unblockMetrics = (0, 0, 0, nil, nil, nil, nil)
                    behavioralPatterns = nil
                    isLoadingMetrics = false
                    // Skip streakService.updateStreak() for now - it can be called later
                    // streakService.updateStreak()
                }
                
                let updateEnd = Date()
                print("🟡 [HomeView] UI state updated at \(updateEnd) (took \(updateEnd.timeIntervalSince(updateStart))s)")
                
                let taskEndTime = Date()
                print("🟢 [HomeView] .task completed at \(taskEndTime) (total: \(taskEndTime.timeIntervalSince(taskStartTime))s)")
            }
            */
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService())
        .environmentObject(SavingsService())
        .environmentObject(QuietHoursService.shared)
        .environmentObject(RegretRiskEngine.shared)
        .environmentObject(MoodTrackingService.shared)
        .environmentObject(RegretLoggingService.shared)
}
