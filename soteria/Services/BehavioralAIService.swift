//
//  BehavioralAIService.swift
//  soteria
//
//  Quiet Behavioral Intelligence
//  AI that improves savings outcomes while staying privacy-first and non-judgmental
//  Core principle: AI should think quietly, speak rarely, and only act with permission
//

import Foundation
import Combine

class BehavioralAIService: ObservableObject {
    static let shared = BehavioralAIService()
    
    // Published recommendations
    @Published var timingRecommendations: [TimingRecommendation] = []
    @Published var amountSuggestions: [String: AmountSuggestion] = [:] // windowId -> suggestion
    @Published var copyVariantRecommendations: [CopyVariantRecommendation] = []
    @Published var weeklyReflections: [WeeklyReflection] = []
    
    // Event tracking
    private var windowEvents: [DecisionWindowEvent] = []
    private var transferEvents: [SavingsTransferEvent] = []
    
    // Services for accessing savings and goal data
    private var plaidService: PlaidService { PlaidService.shared }
    private var goalsService: GoalsService { GoalsService.shared }
    
    // Storage keys
    private let eventsKey = "decision_window_events"
    private let transfersKey = "savings_transfer_events"
    private let recommendationsKey = "ai_recommendations"
    private let lastTimingSuggestionKey = "last_timing_suggestion_date"
    private let lastWeeklyReflectionKey = "last_weekly_reflection_date"
    
    // Guardrails
    private let maxTimingSuggestionsPerWeek = 1
    private let maxWeeklyReflectionsPerWeek = 1
    private let discreteAmounts: [Double] = [1, 2, 3, 5, 10]
    
    private init() {
        loadEvents()
        loadTransfers()
        loadRecommendations()
    }
    
    // MARK: - Event Tracking
    
    /// Record when a Decision Window is opened
    func recordWindowOpened(windowId: String) {
        let event = DecisionWindowEvent(
            windowId: windowId,
            opened: true,
            completedAction: nil
        )
        windowEvents.append(event)
        saveEvents()
        print("🤖 [BehavioralAIService] Recorded window opened: \(windowId)")
    }
    
    /// Record when a user completes an action in a Decision Window
    func recordWindowAction(windowId: String, 
                           action: DecisionWindowEvent.WindowAction,
                           suggestedAmount: Double? = nil,
                           chosenAmount: Double? = nil) {
        let event = DecisionWindowEvent(
            windowId: windowId,
            opened: true,
            completedAction: action,
            suggestedAmount: suggestedAmount,
            chosenAmount: chosenAmount
        )
        windowEvents.append(event)
        saveEvents()
        print("🤖 [BehavioralAIService] Recorded window action: \(windowId), action: \(action.rawValue)")
    }
    
    /// Record a savings transfer result
    func recordTransfer(amount: Double, 
                       source: SavingsTransferEvent.TransferSource,
                       result: SavingsTransferEvent.TransferResult) {
        let event = SavingsTransferEvent(
            amount: amount,
            source: source,
            result: result
        )
        transferEvents.append(event)
        saveTransfers()
        print("🤖 [BehavioralAIService] Recorded transfer: \(amount), source: \(source.rawValue), result: \(result.rawValue)")
    }
    
    /// Record when a goal is completed (called from GoalsService)
    func recordGoalCompleted(goalId: String, targetAmount: Double, completedAmount: Double, daysToComplete: Int?) {
        // This helps AI understand user's goal achievement patterns
        // We can use this to improve recommendations
        print("🤖 [BehavioralAIService] Goal completed: \(goalId), target: $\(targetAmount), actual: $\(completedAmount), days: \(daysToComplete ?? 0)")
        
        // Future: Could store goal completion events for pattern analysis
        // For now, this is logged for future enhancement
    }
    
    // MARK: - Recommendation Generation
    
    /// Generate timing recommendation for a window (Premium only)
    func generateTimingRecommendation(for windowId: String) -> TimingRecommendation? {
        // Gate behind premium subscription
        let isPremium = SubscriptionService.shared.isPremium
        guard isPremium else {
            print("🔒 [BehavioralAIService] Timing recommendation blocked - premium feature")
            return nil
        }
        
        // Guardrail: Max 1 suggestion per 7 days
        if let lastSuggestionDate = UserDefaults.standard.object(forKey: lastTimingSuggestionKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastSuggestionDate, to: Date()).day ?? 0
            if daysSince < 7 {
                print("🤖 [BehavioralAIService] Timing suggestion skipped - only \(daysSince) days since last")
                return nil
            }
        }
        
        let windowEvents = getEvents(for: windowId)
        guard windowEvents.count >= 5 else {
            // Need at least 5 events to make a recommendation
            return nil
        }
        
        // Analyze engagement patterns
        let engagementByTime = analyzeEngagementByTime(events: windowEvents)
        
        // Also analyze when deposits actually happen (from deposit history)
        let savingsByTime = analyzeSavingsByTime()
        
        // Combine engagement and actual savings timing
        var combinedScores: [Int: Double] = [:]
        for (timeMinutes, engagementScore) in engagementByTime {
            // Weight engagement score
            combinedScores[timeMinutes] = engagementScore * 0.7
        }
        for (timeMinutes, savingsScore) in savingsByTime {
            // Add savings score (weighted less, but still important)
            combinedScores[timeMinutes, default: 0] += savingsScore * 0.3
        }
        
        // Find time with highest combined score
        guard let bestTime = combinedScores.max(by: { $0.value < $1.value }) else {
            return nil
        }
        
        // Get current window time
        guard let window = DecisionWindowsService.shared.windows.first(where: { $0.id == windowId }),
              let currentHour = window.time.hour,
              let currentMinute = window.time.minute else {
            return nil
        }
        
        let currentTimeMinutes = currentHour * 60 + currentMinute
        let bestTimeMinutes = bestTime.key
        
        // Only suggest if difference is meaningful (at least 30 minutes)
        guard abs(bestTimeMinutes - currentTimeMinutes) >= 30 else {
            return nil
        }
        
        let recommendedHour = bestTimeMinutes / 60
        let recommendedMinute = bestTimeMinutes % 60
        let recommendedTimeString = String(format: "%02d:%02d", recommendedHour, recommendedMinute)
        
        let confidence = min(bestTime.value, 0.85) // Cap confidence at 0.85
        
        // Determine reason code based on what drove the recommendation
        let reasonCode: RecommendationReasonCode
        if savingsByTime[bestTimeMinutes] ?? 0 > engagementByTime[bestTimeMinutes] ?? 0 {
            reasonCode = .moreSuccessfulSaves // Savings timing is better indicator
        } else {
            reasonCode = .higherEngagement // Engagement timing is better indicator
        }
        
        let recommendation = TimingRecommendation(
            windowId: windowId,
            recommendedTime: recommendedTimeString,
            confidence: confidence,
            reasonCode: reasonCode,
            userFacingCopy: UserFacingCopy(
                title: "Small tweak?",
                body: "You tend to respond more around \(formatTime(hour: recommendedHour, minute: recommendedMinute)). Want to move your Decision Window?"
            )
        )
        
        // Save last suggestion date
        UserDefaults.standard.set(Date(), forKey: lastTimingSuggestionKey)
        
        return recommendation
    }
    
    /// Generate amount suggestion for a window (Premium only)
    func generateAmountSuggestion(for windowId: String) -> AmountSuggestion? {
        // Gate behind premium subscription
        let isPremium = SubscriptionService.shared.isPremium
        guard isPremium else {
            print("🔒 [BehavioralAIService] Amount suggestion blocked - premium feature")
            return nil
        }
        let transferEvents = getTransferEvents(for: windowId)
        
        // Analyze recent performance
        let recentTransfers = transferEvents.suffix(10)
        
        // Count failures
        let failureCount = recentTransfers.filter { $0.result != .success }.count
        let successCount = recentTransfers.filter { $0.result == .success }.count
        
        // Analyze savings frequency and patterns from deposit history
        let savingsPatterns = analyzeSavingsPatterns()
        
        // Analyze goal progress to inform suggestions
        let goalContext = analyzeGoalContext()
        
        // Determine suggested amounts based on performance + savings patterns + goal context
        var suggestedAmounts: [Double]
        var defaultAmount: Double
        var reasonCode: RecommendationReasonCode
        
        // Factor 1: Recent transfer success/failure
        if failureCount > successCount {
            // Recent failures - suggest lower amounts
            suggestedAmounts = [1, 2, 3]
            defaultAmount = 2
            reasonCode = .recentFailedTransfers
        } else if successCount >= 3 {
            // Good follow-through - suggest moderate amounts
            suggestedAmounts = [2, 3, 5]
            defaultAmount = 3
            reasonCode = .recentFollowThrough
        } else {
            // Low engagement - suggest very low amounts
            suggestedAmounts = [1, 2, 3]
            defaultAmount = 1
            reasonCode = .lowEngagement
        }
        
        // Factor 2: Savings frequency - if user deposits frequently, can suggest slightly higher
        if savingsPatterns.depositsPerWeek >= 3 {
            // Frequent saver - can handle slightly higher amounts
            if !suggestedAmounts.contains(5) {
                suggestedAmounts.append(5)
            }
            if defaultAmount < 3 {
                defaultAmount = 3
            }
        } else if savingsPatterns.depositsPerWeek < 1 {
            // Infrequent saver - keep amounts very low
            suggestedAmounts = [1, 2, 3]
            defaultAmount = 1
        }
        
        // Factor 3: Goal progress - if user is close to goal, suggest amounts that help reach it
        if let goal = goalContext.activeGoal {
            let remaining = goal.remainingAmount
            let daysRemaining = goal.daysUntilTarget ?? 30 // Default to 30 if no target date
            
            // If close to goal, suggest amounts that would help complete it
            if remaining > 0 && daysRemaining > 0 {
                let suggestedWeeklyAmount = remaining / Double(max(daysRemaining / 7, 1))
                // If suggested amount is reasonable, include it
                if suggestedWeeklyAmount >= 1 && suggestedWeeklyAmount <= 10 {
                    if !suggestedAmounts.contains(suggestedWeeklyAmount) {
                        suggestedAmounts.append(suggestedWeeklyAmount)
                        suggestedAmounts.sort()
                    }
                    // Use as default if it's in the reasonable range
                    if suggestedWeeklyAmount >= 2 && suggestedWeeklyAmount <= 5 {
                        defaultAmount = suggestedWeeklyAmount
                    }
                }
            }
        }
        
        // Factor 4: Average deposit amount - if user consistently deposits certain amounts, suggest those
        if savingsPatterns.averageDepositAmount > 0 {
            let avgAmount = savingsPatterns.averageDepositAmount
            // Round to nearest discrete amount
            let roundedAmount = discreteAmounts.min(by: { abs($0 - avgAmount) < abs($1 - avgAmount) }) ?? avgAmount
            if roundedAmount >= 1 && roundedAmount <= 10 && !suggestedAmounts.contains(roundedAmount) {
                suggestedAmounts.append(roundedAmount)
                suggestedAmounts.sort()
            }
        }
        
        // Get last successful amount if available
        if let lastSuccess = recentTransfers.last(where: { $0.result == .success }) {
            // Include last successful amount in suggestions if not already there
            if !suggestedAmounts.contains(lastSuccess.amount) && lastSuccess.amount <= 10 {
                suggestedAmounts.append(lastSuccess.amount)
                suggestedAmounts.sort()
            }
            // Use last successful as default if it's reasonable
            if lastSuccess.amount <= 5 {
                defaultAmount = lastSuccess.amount
            }
        }
        
        // Calculate confidence based on multiple factors
        var confidence = min(0.7, Double(successCount) / 10.0 + 0.3)
        if savingsPatterns.depositsPerWeek >= 2 {
            confidence = min(0.85, confidence + 0.1) // Boost confidence if frequent saver
        }
        if goalContext.hasActiveGoal {
            confidence = min(0.9, confidence + 0.05) // Boost confidence if has goal
        }
        
        return AmountSuggestion(
            windowId: windowId,
            suggestedAmounts: suggestedAmounts,
            defaultAmount: defaultAmount,
            confidence: confidence,
            reasonCode: reasonCode,
            userFacingCopy: UserFacingCopy(
                title: "Pick a small save",
                body: "Keep it easy today. You can always change this.",
                header: "Pick a small save",
                helper: "Keep it easy today. You can always change this."
            )
        )
    }
    
    /// Select best copy variant based on engagement (Premium only, falls back to default for free)
    func selectCopyVariant(for windowId: String) -> CopyVariantId {
        // Gate behind premium subscription
        let isPremium = SubscriptionService.shared.isPremium
        guard isPremium else {
            // Free users get default variant
            return .aMomentForToday
        }
        
        // For MVP, use A/B testing approach
        // Track which variants lead to higher completion rates
        let windowEvents = getEvents(for: windowId)
        
        // Simple heuristic: if engagement is low, try different variant
        let recentEngagement = windowEvents.suffix(5).filter { $0.completedAction != nil }.count
        if recentEngagement < 2 {
            // Low engagement - try a different variant
            return .takeAPause
        }
        
        // Default variant
        return .aMomentForToday
    }
    
    // MARK: - Helper Methods
    
    private func getEvents(for windowId: String) -> [DecisionWindowEvent] {
        return windowEvents.filter { $0.windowId == windowId }
    }
    
    private func getTransferEvents(for windowId: String) -> [SavingsTransferEvent] {
        // Filter transfers that came from this window
        return transferEvents.filter { $0.source == .decisionWindow }
    }
    
    private func analyzeEngagementByTime(events: [DecisionWindowEvent]) -> [Int: Double] {
        // Group events by hour of day
        var engagementByHour: [Int: (opens: Int, completions: Int)] = [:]
        
        for event in events {
            let hour = Calendar.current.component(.hour, from: event.timestamp)
            if engagementByHour[hour] == nil {
                engagementByHour[hour] = (0, 0)
            }
            if event.opened {
                engagementByHour[hour]?.opens += 1
            }
            if event.completedAction != nil {
                engagementByHour[hour]?.completions += 1
            }
        }
        
        // Calculate engagement score (completion rate weighted by opens)
        var scores: [Int: Double] = [:]
        for (hour, counts) in engagementByHour {
            let completionRate = counts.opens > 0 ? Double(counts.completions) / Double(counts.opens) : 0.0
            let engagementScore = completionRate * Double(counts.opens) // Weight by volume
            scores[hour * 60] = engagementScore // Store as minutes for easier comparison
        }
        
        return scores
    }
    
    private func formatTime(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    // MARK: - Savings Pattern Analysis
    
    /// Analyze savings frequency and patterns from deposit history
    private func analyzeSavingsPatterns() -> SavingsPatterns {
        let deposits = plaidService.depositHistory
        let calendar = Calendar.current
        let now = Date()
        
        // Filter to last 30 days
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let recentDeposits = deposits.filter { $0.timestamp >= thirtyDaysAgo }
        
        // Calculate deposits per week
        let daysSinceFirst = recentDeposits.isEmpty ? 30 : 
            calendar.dateComponents([.day], from: recentDeposits.last?.timestamp ?? now, to: now).day ?? 30
        let weeks = max(1, Double(daysSinceFirst) / 7.0)
        let depositsPerWeek = Double(recentDeposits.count) / weeks
        
        // Calculate average deposit amount
        let totalAmount = recentDeposits.reduce(0.0) { $0 + $1.amount }
        let averageDepositAmount = recentDeposits.isEmpty ? 0 : totalAmount / Double(recentDeposits.count)
        
        // Calculate consistency (deposits per week variance)
        var weeklyDeposits: [Int] = []
        for weekOffset in 0..<4 {
            let weekStart = calendar.date(byAdding: .day, value: -7 * (weekOffset + 1), to: now) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: -7 * weekOffset, to: now) ?? now
            let weekCount = recentDeposits.filter { $0.timestamp >= weekStart && $0.timestamp < weekEnd }.count
            weeklyDeposits.append(weekCount)
        }
        
        return SavingsPatterns(
            depositsPerWeek: depositsPerWeek,
            averageDepositAmount: averageDepositAmount,
            totalDeposits: recentDeposits.count,
            weeklyConsistency: weeklyDeposits
        )
    }
    
    /// Analyze goal context to inform recommendations
    private func analyzeGoalContext() -> GoalContext {
        let activeGoals = goalsService.activeGoals
        let activeGoal = activeGoals.first // Primary active goal
        
        // Calculate goal completion rate from archived goals
        let archivedGoals = goalsService.archivedGoals
        let completedGoals = archivedGoals.filter { $0.status == .achieved }
        let totalGoals = activeGoals.count + archivedGoals.count
        let completionRate = totalGoals > 0 ? Double(completedGoals.count) / Double(totalGoals) : 0.0
        
        // Check if user typically meets target amounts
        var meetsTargets = true
        if let goal = activeGoal {
            // If goal has been active for a while, check if progress is on track
            if let startDate = goal.startDate, let targetDate = goal.targetDate {
                let daysElapsed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
                let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 1
                let expectedProgress = Double(daysElapsed) / Double(totalDays)
                let actualProgress = goal.progress
                // If significantly behind (more than 20% behind), they're not meeting targets
                meetsTargets = actualProgress >= (expectedProgress * 0.8)
            }
        }
        
        return GoalContext(
            hasActiveGoal: activeGoal != nil,
            activeGoal: activeGoal,
            goalCompletionRate: completionRate,
            meetsTargetAmounts: meetsTargets
        )
    }
    
    // MARK: - Helper Structures
    
    private struct SavingsPatterns {
        let depositsPerWeek: Double
        let averageDepositAmount: Double
        let totalDeposits: Int
        let weeklyConsistency: [Int] // Deposits per week for last 4 weeks
    }
    
    private struct GoalContext {
        let hasActiveGoal: Bool
        let activeGoal: SavingsGoal?
        let goalCompletionRate: Double // 0.0 to 1.0
        let meetsTargetAmounts: Bool // Whether user typically meets their target amounts
    }
    
    /// Analyze when deposits actually happen (from deposit history)
    private func analyzeSavingsByTime() -> [Int: Double] {
        let deposits = plaidService.depositHistory
        var savingsByHour: [Int: Double] = [:]
        
        // Group deposits by hour of day and sum amounts
        for deposit in deposits {
            let hour = Calendar.current.component(.hour, from: deposit.timestamp)
            savingsByHour[hour * 60, default: 0] += deposit.amount
        }
        
        // Normalize by number of deposits in that hour (to avoid bias from single large deposits)
        var depositCountsByHour: [Int: Int] = [:]
        for deposit in deposits {
            let hour = Calendar.current.component(.hour, from: deposit.timestamp)
            depositCountsByHour[hour * 60, default: 0] += 1
        }
        
        // Calculate average amount per deposit for each hour
        var normalizedScores: [Int: Double] = [:]
        for (hourMinutes, totalAmount) in savingsByHour {
            let count = depositCountsByHour[hourMinutes] ?? 1
            normalizedScores[hourMinutes] = totalAmount / Double(count) // Average amount
        }
        
        return normalizedScores
    }
    
    // MARK: - Persistence
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([DecisionWindowEvent].self, from: data) {
            windowEvents = decoded
            print("🤖 [BehavioralAIService] Loaded \(windowEvents.count) window events")
        }
    }
    
    private func saveEvents() {
        // Keep only last 100 events for privacy
        if windowEvents.count > 100 {
            windowEvents = Array(windowEvents.suffix(100))
        }
        
        if let encoded = try? JSONEncoder().encode(windowEvents) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }
    
    private func loadTransfers() {
        if let data = UserDefaults.standard.data(forKey: transfersKey),
           let decoded = try? JSONDecoder().decode([SavingsTransferEvent].self, from: data) {
            transferEvents = decoded
            print("🤖 [BehavioralAIService] Loaded \(transferEvents.count) transfer events")
        }
    }
    
    private func saveTransfers() {
        // Keep only last 100 transfers for privacy
        if transferEvents.count > 100 {
            transferEvents = Array(transferEvents.suffix(100))
        }
        
        if let encoded = try? JSONEncoder().encode(transferEvents) {
            UserDefaults.standard.set(encoded, forKey: transfersKey)
        }
    }
    
    private func loadRecommendations() {
        // Load timing recommendations
        if let data = UserDefaults.standard.data(forKey: "timing_recommendations"),
           let decoded = try? JSONDecoder().decode([TimingRecommendation].self, from: data) {
            timingRecommendations = decoded
        }
        
        // Load amount suggestions
        if let data = UserDefaults.standard.data(forKey: "amount_suggestions"),
           let decoded = try? JSONDecoder().decode([String: AmountSuggestion].self, from: data) {
            amountSuggestions = decoded
        }
    }
    
    func saveRecommendations() {
        if let encoded = try? JSONEncoder().encode(timingRecommendations) {
            UserDefaults.standard.set(encoded, forKey: "timing_recommendations")
        }
        
        if let encoded = try? JSONEncoder().encode(amountSuggestions) {
            UserDefaults.standard.set(encoded, forKey: "amount_suggestions")
        }
    }
}

