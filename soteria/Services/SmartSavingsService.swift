//
//  SmartSavingsService.swift
//  soteria
//
//  Calculates optimal savings amounts based on goal milestones, round-ups, and auto-adjust logic
//

import Foundation

struct SmartSuggestion {
    let amount: Double
    let reason: String
    let impact: GoalImpact
    let type: SuggestionType
    
    enum SuggestionType {
        case milestone      // Reaching a milestone (e.g., $500, 25%, 50%)
        case roundUp        // Round-up to next nice number
        case autoAdjust     // Behind schedule, need to catch up
        case standard       // Standard suggestion
    }
}

class SmartSavingsService {
    static let shared = SmartSavingsService()
    
    private let goalImpactService = GoalImpactService.shared
    
    private init() {}
    
    /// Get smart savings suggestions for a goal
    /// Returns array of suggestions sorted by priority (most impactful first)
    func getSmartSuggestions(for goal: SavingsGoal) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // 1. Find milestone suggestions
        if let milestoneSuggestion = findMilestoneSuggestion(for: goal) {
            suggestions.append(milestoneSuggestion)
        }
        
        // 2. Find round-up suggestions
        if let roundUpSuggestion = findRoundUpSuggestion(for: goal) {
            suggestions.append(roundUpSuggestion)
        }
        
        // 3. Find auto-adjust suggestion (if behind schedule)
        if let autoAdjustSuggestion = findAutoAdjustSuggestion(for: goal) {
            suggestions.append(autoAdjustSuggestion)
        }
        
        // 4. Add standard suggestions if we don't have enough
        if suggestions.count < 3 {
            let standardSuggestions = getStandardSuggestions(for: goal, excluding: suggestions.map { $0.amount })
            suggestions.append(contentsOf: standardSuggestions)
        }
        
        // Sort by impact (days closer) and return top 4
        return suggestions
            .sorted { $0.impact.daysCloser > $1.impact.daysCloser }
            .prefix(4)
            .map { $0 }
    }
    
    // MARK: - Milestone Suggestions
    
    private func findMilestoneSuggestion(for goal: SavingsGoal) -> SmartSuggestion? {
        let currentAmount = goal.currentAmount
        let targetAmount = goal.targetAmount
        let _ = goal.remainingAmount // Available if needed
        
        // Find next milestone
        let milestones: [Double] = [
            targetAmount * 0.25,  // 25%
            targetAmount * 0.50,  // 50%
            targetAmount * 0.75,  // 75%
            targetAmount * 0.90,  // 90%
            // Dollar amount milestones
            ceil(currentAmount / 100) * 100,  // Next $100
            ceil(currentAmount / 250) * 250,  // Next $250
            ceil(currentAmount / 500) * 500,  // Next $500
            ceil(currentAmount / 1000) * 1000 // Next $1000
        ]
        
        // Find the next milestone that's achievable (not already passed)
        for milestone in milestones.sorted() {
            if milestone > currentAmount && milestone <= targetAmount {
                let amountNeeded = milestone - currentAmount
                
                // Only suggest if amount is reasonable (between $1 and $500)
                if amountNeeded >= 1 && amountNeeded <= 500 {
                    if let impact = goalImpactService.calculateImpact(amount: amountNeeded, goal: goal) {
                        let reason: String
                        if milestone.truncatingRemainder(dividingBy: 1) == 0 {
                            // Dollar milestone
                            reason = "Reach $\(Int(milestone)) milestone"
                        } else {
                            // Percentage milestone
                            let percentage = Int((milestone / targetAmount) * 100)
                            reason = "Reach \(percentage)% of your goal"
                        }
                        
                        return SmartSuggestion(
                            amount: amountNeeded,
                            reason: reason,
                            impact: impact,
                            type: .milestone
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Round-Up Suggestions
    
    private func findRoundUpSuggestion(for goal: SavingsGoal) -> SmartSuggestion? {
        let currentAmount = goal.currentAmount
        
        // Find nice round numbers near current amount
        let roundNumbers: [Double] = [
            ceil(currentAmount / 10) * 10,      // Next $10
            ceil(currentAmount / 25) * 25,       // Next $25
            ceil(currentAmount / 50) * 50,       // Next $50
            ceil(currentAmount / 100) * 100      // Next $100
        ]
        
        for roundNumber in roundNumbers {
            if roundNumber > currentAmount {
                let amountNeeded = roundNumber - currentAmount
                
                // Only suggest if amount is reasonable (between $1 and $100)
                if amountNeeded >= 1 && amountNeeded <= 100 {
                    if let impact = goalImpactService.calculateImpact(amount: amountNeeded, goal: goal) {
                        return SmartSuggestion(
                            amount: amountNeeded,
                            reason: "Round up to $\(Int(roundNumber))",
                            impact: impact,
                            type: .roundUp
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Auto-Adjust Suggestions
    
    private func findAutoAdjustSuggestion(for goal: SavingsGoal) -> SmartSuggestion? {
        guard let daysUntil = goal.daysUntilTarget,
              daysUntil > 0,
              goal.remainingAmount > 0 else {
            return nil
        }
        
        // Calculate required daily savings rate
        let requiredDailyRate = goal.remainingAmount / Double(daysUntil)
        
        // Get recent savings velocity (last 7 days)
        let recentDeposits = getRecentDeposits(days: 7)
        let averageDailySavings = recentDeposits.isEmpty ? 0 : recentDeposits.reduce(0, +) / Double(recentDeposits.count)
        
        // If user is behind schedule (saving less than required daily rate)
        if averageDailySavings < requiredDailyRate * 0.8 { // 80% threshold
            // Suggest amount to catch up
            let daysBehind = daysUntil
            let catchUpAmount = (requiredDailyRate - averageDailySavings) * Double(min(daysBehind, 7)) // Catch up over next week
            
            // Cap at reasonable amount ($5 - $200)
            let suggestedAmount = max(5, min(catchUpAmount, 200))
            
            if let impact = goalImpactService.calculateImpact(amount: suggestedAmount, goal: goal) {
                return SmartSuggestion(
                    amount: suggestedAmount,
                    reason: "Catch up to stay on track",
                    impact: impact,
                    type: .autoAdjust
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Standard Suggestions
    
    private func getStandardSuggestions(for goal: SavingsGoal, excluding amounts: [Double]) -> [SmartSuggestion] {
        let standardAmounts: [Double] = [5, 10, 15, 25, 50, 100]
        var suggestions: [SmartSuggestion] = []
        
        for amount in standardAmounts {
            // Skip if already suggested
            if amounts.contains(amount) { continue }
            
            // Only suggest if it makes meaningful progress
            if let impact = goalImpactService.calculateImpact(amount: amount, goal: goal),
               impact.daysCloser >= 0.1 {
                suggestions.append(SmartSuggestion(
                    amount: amount,
                    reason: "Quick save",
                    impact: impact,
                    type: .standard
                ))
            }
        }
        
        return suggestions.prefix(2).map { $0 }
    }
    
    // MARK: - Helper Methods
    
    private func getRecentDeposits(days: Int) -> [Double] {
        // Get recent deposits from PlaidService
        let plaidService = PlaidService.shared
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Filter deposits from last N days
        let recentDeposits = plaidService.depositHistory.filter { deposit in
            deposit.timestamp >= cutoffDate
        }
        
        return recentDeposits.map { $0.amount }
    }
}

