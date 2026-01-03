//
//  GoalImpactService.swift
//  soteria
//
//  Calculates goal impact for savings amounts and provides regret reminders
//

import Foundation

struct GoalImpact {
    let amount: Double
    let daysCloser: Double
    let currentProgress: Double
    let projectedProgress: Double
    let daysUntilGoal: Int?
    let remainingAmount: Double
    let projectedRemainingAmount: Double
    
    var formattedDaysCloser: String {
        if daysCloser < 0.1 {
            return "less than 0.1 day"
        } else if daysCloser < 1 {
            return String(format: "%.1f day", daysCloser)
        } else {
            let wholeDays = Int(daysCloser)
            return "\(wholeDays) day\(wholeDays == 1 ? "" : "s")"
        }
    }
}

class GoalImpactService {
    static let shared = GoalImpactService()
    
    private init() {}
    
    /// Calculate how many days closer to goal a savings amount will bring the user
    func calculateImpact(amount: Double, goal: SavingsGoal) -> GoalImpact? {
        guard let daysUntil = goal.daysUntilTarget,
              daysUntil > 0,
              goal.remainingAmount > 0 else {
            return nil
        }
        
        // Calculate daily savings rate needed
        let dailyRate = goal.remainingAmount / Double(daysUntil)
        guard dailyRate > 0 else { return nil }
        
        // Calculate how many days this amount saves
        let daysSaved = amount / dailyRate
        
        // Calculate projected progress
        let projectedCurrentAmount = goal.currentAmount + amount
        let projectedProgress = min(projectedCurrentAmount / goal.targetAmount, 1.0)
        let projectedRemainingAmount = max(goal.targetAmount - projectedCurrentAmount, 0)
        
        return GoalImpact(
            amount: amount,
            daysCloser: max(daysSaved, 0),
            currentProgress: goal.progress,
            projectedProgress: projectedProgress,
            daysUntilGoal: daysUntil,
            remainingAmount: goal.remainingAmount,
            projectedRemainingAmount: projectedRemainingAmount
        )
    }
    
    /// Get suggested save amounts with their impact
    func getSuggestedAmounts(for goal: SavingsGoal) -> [(amount: Double, impact: GoalImpact)] {
        let suggestedAmounts: [Double] = [5, 10, 15, 25, 50, 100]
        var results: [(amount: Double, impact: GoalImpact)] = []
        
        for amount in suggestedAmounts {
            if let impact = calculateImpact(amount: amount, goal: goal), impact.daysCloser > 0 {
                results.append((amount: amount, impact: impact))
            }
        }
        
        // Return top 3-4 most meaningful amounts (filter out very small impacts)
        return results.filter { $0.impact.daysCloser >= 0.1 }.prefix(4).map { $0 }
    }
    
    /// Get similar regrets that could have been saved toward this goal
    func getSimilarRegrets(amount: Double, goal: SavingsGoal, regrets: [RegretEntry], maxResults: Int = 2) -> [RegretEntry] {
        // Find regrets within 50% of the suggested amount
        let minAmount = amount * 0.5
        let maxAmount = amount * 1.5
        
        let similarRegrets = regrets
            .filter { regret in
                guard let regretAmount = regret.amount else { return false }
                return regretAmount >= minAmount && regretAmount <= maxAmount
            }
            .sorted { $0.date > $1.date } // Most recent first
            .prefix(maxResults)
        
        return Array(similarRegrets)
    }
}

