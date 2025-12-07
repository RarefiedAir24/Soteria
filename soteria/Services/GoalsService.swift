//
//  GoalsService.swift
//  rever
//
//  Created by Frank Schioppa on 12/7/25.
//

import Foundation
import Combine

struct SavingsGoal: Identifiable, Codable {
    let id: String
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var targetDate: Date?
    var category: GoalCategory
    
    enum GoalCategory: String, Codable, CaseIterable {
        case trip = "Trip"
        case purchase = "Purchase"
        case emergency = "Emergency Fund"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .trip: return "airplane"
            case .purchase: return "cart"
            case .emergency: return "shield"
            case .other: return "star"
            }
        }
    }
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var remainingAmount: Double {
        return max(targetAmount - currentAmount, 0)
    }
}

class GoalsService: ObservableObject {
    static let shared = GoalsService()
    
    @Published var goals: [SavingsGoal] = []
    @Published var activeGoal: SavingsGoal? = nil
    
    private let goalsKey = "saved_goals"
    
    private init() {
        loadGoals()
    }
    
    // Load goals from UserDefaults
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([SavingsGoal].self, from: data) {
            goals = decoded
            // Set first active goal as default, or most recent
            activeGoal = goals.first { $0.currentAmount < $0.targetAmount } ?? goals.first
        }
    }
    
    // Save goals to UserDefaults
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: goalsKey)
        }
    }
    
    // Create a new goal
    func createGoal(name: String, targetAmount: Double, targetDate: Date?, category: SavingsGoal.GoalCategory) {
        let goal = SavingsGoal(
            id: UUID().uuidString,
            name: name,
            targetAmount: targetAmount,
            currentAmount: 0,
            targetDate: targetDate,
            category: category
        )
        goals.append(goal)
        if activeGoal == nil {
            activeGoal = goal
        }
        saveGoals()
    }
    
    // Update goal
    func updateGoal(_ goal: SavingsGoal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            if activeGoal?.id == goal.id {
                activeGoal = goal
            }
            saveGoals()
        }
    }
    
    // Add money to a goal
    func addToGoal(goalId: String, amount: Double) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        var goal = goals[index]
        goal.currentAmount += amount
        goals[index] = goal
        
        if activeGoal?.id == goalId {
            activeGoal = goal
        }
        saveGoals()
    }
    
    // Set active goal
    func setActiveGoal(_ goal: SavingsGoal?) {
        activeGoal = goal
    }
    
    // Delete goal
    func deleteGoal(_ goal: SavingsGoal) {
        goals.removeAll { $0.id == goal.id }
        if activeGoal?.id == goal.id {
            activeGoal = goals.first { $0.currentAmount < $0.targetAmount } ?? goals.first
        }
        saveGoals()
    }
    
    // Get total saved across all goals
    var totalSavedAcrossGoals: Double {
        return goals.reduce(0) { $0 + $1.currentAmount }
    }
}

