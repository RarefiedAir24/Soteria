//
//  PremiumAnalyticsService.swift
//  soteria
//
//  Premium-only analytics: Goal predictions, savings velocity, and advanced insights
//

import Foundation
import Combine

struct GoalPrediction {
    let goalId: String
    let goalName: String
    let predictedCompletionDate: Date?
    let confidence: Double // 0.0 to 1.0
    let daysUntilPredicted: Int?
    let onTrack: Bool
    let reason: String
}

struct SavingsVelocity {
    let averageDailySavings: Double
    let averageWeeklySavings: Double
    let trend: VelocityTrend // increasing, decreasing, stable
    let projectedCompletionDate: Date?
    let daysAheadOrBehind: Int? // Positive = ahead, Negative = behind
}

enum VelocityTrend {
    case increasing
    case decreasing
    case stable
}

class PremiumAnalyticsService: ObservableObject {
    static let shared = PremiumAnalyticsService()
    
    @Published var goalPredictions: [GoalPrediction] = []
    @Published var savingsVelocity: SavingsVelocity?
    
    private let goalsService = GoalsService.shared
    private let plaidService = PlaidService.shared
    
    private init() {
        loadAnalytics()
    }
    
    // MARK: - Goal Predictions (Premium Only)
    
    /// Calculate predicted completion date for active goals based on current savings velocity
    func calculateGoalPredictions() -> [GoalPrediction] {
        guard SubscriptionService.shared.isPremium else {
            return []
        }
        
        let activeGoals = goalsService.activeGoals
        var predictions: [GoalPrediction] = []
        
        for goal in activeGoals {
            let prediction = predictGoalCompletion(goal: goal)
            predictions.append(prediction)
        }
        
        goalPredictions = predictions
        return predictions
    }
    
    private func predictGoalCompletion(goal: SavingsGoal) -> GoalPrediction {
        let remainingAmount = goal.remainingAmount
        guard remainingAmount > 0 else {
            // Goal already completed
            return GoalPrediction(
                goalId: goal.id,
                goalName: goal.name,
                predictedCompletionDate: Date(),
                confidence: 1.0,
                daysUntilPredicted: 0,
                onTrack: true,
                reason: "Goal completed"
            )
        }
        
        // Calculate savings velocity from deposit history
        let velocity = calculateSavingsVelocity(for: goal)
        
        // Predict completion date based on velocity
        let predictedDate: Date?
        let daysUntilPredicted: Int?
        let onTrack: Bool
        let reason: String
        let confidence: Double
        
        if velocity.averageDailySavings > 0 {
            let daysNeeded = Int(ceil(remainingAmount / velocity.averageDailySavings))
            predictedDate = Calendar.current.date(byAdding: .day, value: daysNeeded, to: Date())
            daysUntilPredicted = daysNeeded
            
            // Check if on track with target date
            if let targetDate = goal.targetDate {
                let daysUntilTarget = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                onTrack = daysNeeded <= daysUntilTarget
                
                if onTrack {
                    reason = "On track to complete \(daysUntilTarget - daysNeeded) days early"
                } else {
                    reason = "Projected to complete \(daysNeeded - daysUntilTarget) days after target"
                }
            } else {
                onTrack = true
                reason = "No target date set"
            }
            
            // Confidence based on data quality
            let daysOfData = min(30, velocity.averageDailySavings > 0 ? 30 : 7)
            confidence = min(0.9, Double(daysOfData) / 30.0)
        } else {
            predictedDate = nil
            daysUntilPredicted = nil
            onTrack = false
            reason = "No savings activity yet"
            confidence = 0.0
        }
        
        return GoalPrediction(
            goalId: goal.id,
            goalName: goal.name,
            predictedCompletionDate: predictedDate,
            confidence: confidence,
            daysUntilPredicted: daysUntilPredicted,
            onTrack: onTrack,
            reason: reason
        )
    }
    
    // MARK: - Savings Velocity (Premium Only)
    
    /// Calculate savings velocity metrics for active goals
    func calculateSavingsVelocity(for goal: SavingsGoal? = nil) -> SavingsVelocity {
        guard SubscriptionService.shared.isPremium else {
            return SavingsVelocity(
                averageDailySavings: 0,
                averageWeeklySavings: 0,
                trend: .stable,
                projectedCompletionDate: nil,
                daysAheadOrBehind: nil
            )
        }
        
        let targetGoal = goal ?? goalsService.activeGoal
        
        guard let targetGoal = targetGoal else {
            return SavingsVelocity(
                averageDailySavings: 0,
                averageWeeklySavings: 0,
                trend: .stable,
                projectedCompletionDate: nil,
                daysAheadOrBehind: nil
            )
        }
        
        // Get deposit history for this goal (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentDeposits = plaidService.depositHistory.filter { deposit in
            deposit.timestamp >= thirtyDaysAgo && deposit.goalId == targetGoal.id
        }
        
        // Calculate average daily savings
        let totalSavings = recentDeposits.reduce(0.0) { $0 + $1.amount }
        let daysOfData = max(1, Calendar.current.dateComponents([.day], from: thirtyDaysAgo, to: Date()).day ?? 1)
        let averageDaily = totalSavings / Double(daysOfData)
        let averageWeekly = averageDaily * 7.0
        
        // Calculate trend (compare first half vs second half of period)
        let midpoint = recentDeposits.count / 2
        let firstHalf = Array(recentDeposits.prefix(midpoint))
        let secondHalf = Array(recentDeposits.suffix(recentDeposits.count - midpoint))
        
        let firstHalfTotal = firstHalf.reduce(0.0) { $0 + $1.amount }
        let secondHalfTotal = secondHalf.reduce(0.0) { $0 + $1.amount }
        
        let firstHalfDays = max(1, midpoint)
        let secondHalfDays = max(1, recentDeposits.count - midpoint)
        
        let firstHalfDaily = firstHalfTotal / Double(firstHalfDays)
        let secondHalfDaily = secondHalfTotal / Double(secondHalfDays)
        
        let trend: VelocityTrend
        if secondHalfDaily > firstHalfDaily * 1.1 {
            trend = .increasing
        } else if secondHalfDaily < firstHalfDaily * 0.9 {
            trend = .decreasing
        } else {
            trend = .stable
        }
        
        // Project completion date
        let remaining = targetGoal.remainingAmount
        let projectedDate: Date?
        if averageDaily > 0 {
            let daysNeeded = Int(ceil(remaining / averageDaily))
            projectedDate = Calendar.current.date(byAdding: .day, value: daysNeeded, to: Date())
        } else {
            projectedDate = nil
        }
        
        // Calculate days ahead/behind target
        let daysAheadOrBehind: Int?
        if let targetDate = targetGoal.targetDate, let projectedDate = projectedDate {
            let daysDiff = Calendar.current.dateComponents([.day], from: projectedDate, to: targetDate).day ?? 0
            daysAheadOrBehind = -daysDiff // Negative = ahead, Positive = behind
        } else {
            daysAheadOrBehind = nil
        }
        
        let velocity = SavingsVelocity(
            averageDailySavings: averageDaily,
            averageWeeklySavings: averageWeekly,
            trend: trend,
            projectedCompletionDate: projectedDate,
            daysAheadOrBehind: daysAheadOrBehind
        )
        
        savingsVelocity = velocity
        return velocity
    }
    
    // MARK: - Pattern Recognition
    
    /// Identify savings patterns and insights (Premium Only)
    func getSavingsInsights() -> [String] {
        guard SubscriptionService.shared.isPremium else {
            return []
        }
        
        var insights: [String] = []
        
        // Check savings velocity
        let velocity = calculateSavingsVelocity()
        if velocity.trend == .increasing {
            insights.append("Your savings rate is increasing! Keep up the momentum.")
        } else if velocity.trend == .decreasing {
            insights.append("Your savings rate has slowed. Consider setting a reminder.")
        }
        
        // Check goal predictions
        let predictions = calculateGoalPredictions()
        for prediction in predictions {
            if prediction.onTrack {
                insights.append("\(prediction.goalName) is on track!")
            } else if let daysBehind = prediction.daysUntilPredicted, daysBehind > 0 {
                insights.append("\(prediction.goalName) may need more frequent saves to meet target.")
            }
        }
        
        return insights
    }
    
    // MARK: - Data Loading
    
    private func loadAnalytics() {
        // Refresh analytics when service is accessed
        if SubscriptionService.shared.isPremium {
            _ = calculateGoalPredictions()
            _ = calculateSavingsVelocity()
        }
    }
    
    func refreshAnalytics() {
        loadAnalytics()
    }
}

