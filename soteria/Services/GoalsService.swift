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
    var startDate: Date? // When the goal started
    var targetDate: Date? // When the goal should be completed (end date)
    var category: GoalCategory
    var protectionAmount: Double = 10.0 // Amount added to goal each time user chooses protection
    var photoPath: String? = nil // Firebase Storage path for goal photo (lazy loaded)
    var description: String? = nil // Text description of the goal
    var status: GoalStatus = .active // Current status of the goal
    var createdDate: Date = Date() // When the goal was created (defaults to now for migration)
    var completedDate: Date? // When the goal was completed (if achieved)
    var completedAmount: Double? // Final amount when completed
    
    enum GoalStatus: String, Codable {
        case active = "active" // Goal is in progress
        case achieved = "achieved" // Goal was completed successfully
        case failed = "failed" // Goal was not achieved by target date
        case cancelled = "cancelled" // Goal was cancelled by user
        
        var displayName: String {
            switch self {
            case .active: return "Active"
            case .achieved: return "Achieved"
            case .failed: return "Not Achieved"
            case .cancelled: return "Cancelled"
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "clock.fill"
            case .achieved: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            case .cancelled: return "minus.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .active: return "reverBlue"
            case .achieved: return "green"
            case .failed: return "red"
            case .cancelled: return "gray"
            }
        }
    }
    
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
    
    // Calculate days until goal target date (on-demand, no startup impact)
    var daysUntilTarget: Int? {
        guard let targetDate = targetDate else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: now, to: targetDate).day
        return days
    }
    
    // Calculate days since goal started (on-demand, no startup impact)
    var daysSinceStart: Int? {
        guard let startDate = startDate else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: startDate, to: now).day
        return days
    }
    
    // Check if goal is achieved
    var isAchieved: Bool {
        return currentAmount >= targetAmount
    }
    
    // Check if goal has passed target date
    var isPastTargetDate: Bool {
        guard let targetDate = targetDate else { return false }
        return Date() > targetDate
    }
    
    // Calculate days delayed by a purchase amount (on-demand calculation)
    func daysDelayedByPurchase(_ purchaseAmount: Double) -> Double? {
        guard targetDate != nil,
              let daysUntil = daysUntilTarget,
              daysUntil > 0 else { return nil }
        
        // Calculate daily savings rate needed
        let remainingAmount = self.remainingAmount
        guard remainingAmount > 0 else { return nil }
        
        let dailyRate = remainingAmount / Double(daysUntil)
        guard dailyRate > 0 else { return nil }
        
        // Calculate how many days this purchase delays the goal
        let daysDelayed = purchaseAmount / dailyRate
        return daysDelayed
    }
}

class GoalsService: ObservableObject {
    static let shared = GoalsService()
    
    @Published var goals: [SavingsGoal] = []
    @Published var activeGoal: SavingsGoal? = nil
    
    private let goalsKey = "saved_goals"
    private let archivedGoalsKey = "archived_goals"
    
    // Computed properties for filtering
    var activeGoals: [SavingsGoal] {
        goals.filter { $0.status == .active }
    }
    
    var archivedGoals: [SavingsGoal] {
        loadArchivedGoals()
    }
    
    var achievedGoals: [SavingsGoal] {
        archivedGoals.filter { $0.status == .achieved }
    }
    
    var failedGoals: [SavingsGoal] {
        archivedGoals.filter { $0.status == .failed }
    }
    
    private init() {
        let initStart = Date()
        print("✅ [GoalsService] Init started at \(initStart) (truly lazy - no work on startup)")
        // STREAMLINED: Do absolutely nothing on startup
        // Data will be loaded on-demand when user accesses goals features
        // This eliminates blocking JSON decode during app launch
        let initEnd = Date()
        print("✅ [GoalsService] Initialized at \(initEnd) (total: \(initEnd.timeIntervalSince(initStart))s)")
        
        // Defer all work to background task with delay
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            // Wait 30 seconds to ensure app is fully loaded and responsive
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            await MainActor.run {
                self.loadGoals()
                print("✅ [GoalsService] Goals loaded")
            }
        }
    }
    
    // Ensure data is loaded (call on-demand)
    func ensureDataLoaded() {
        // Only load if not already loaded
        guard goals.isEmpty else { return }
        loadGoals()
    }
    
    // Load goals from UserDefaults
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([SavingsGoal].self, from: data) {
            // Migrate old goals that might not have new fields
            goals = decoded.map { goal in
                var migratedGoal = goal
                // Ensure createdDate is set (handles migration from old goals)
                // The default value in the struct should handle this, but we'll ensure it's reasonable
                if migratedGoal.createdDate.timeIntervalSince1970 < 1000000000 { // Before year 2001
                    migratedGoal.createdDate = Date()
                }
                // If goal doesn't have status set properly, determine it
                if migratedGoal.status == .active {
                    if migratedGoal.isAchieved {
                        migratedGoal.status = .achieved
                    } else if migratedGoal.isPastTargetDate {
                        migratedGoal.status = .failed
                    }
                }
                return migratedGoal
            }
            // Check for goal completion and update status
            checkAndUpdateGoalStatuses()
            // Set first active goal as default, or most recent
            activeGoal = activeGoals.first
        }
    }
    
    // Load archived goals from UserDefaults
    private func loadArchivedGoals() -> [SavingsGoal] {
        if let data = UserDefaults.standard.data(forKey: archivedGoalsKey),
           let decoded = try? JSONDecoder().decode([SavingsGoal].self, from: data) {
            return decoded
        }
        return []
    }
    
    // Save archived goals to UserDefaults
    private func saveArchivedGoals(_ archivedGoals: [SavingsGoal]) {
        if let encoded = try? JSONEncoder().encode(archivedGoals) {
            UserDefaults.standard.set(encoded, forKey: archivedGoalsKey)
        }
    }
    
    // Check and update goal statuses (auto-detect completion)
    private func checkAndUpdateGoalStatuses() {
        var updated = false
        var goalsToArchive: [SavingsGoal] = []
        
        for (index, goal) in goals.enumerated() {
            var updatedGoal = goal
            
            // Check if goal is achieved
            if goal.status == .active && goal.isAchieved {
                updatedGoal.status = .achieved
                updatedGoal.completedDate = Date()
                updatedGoal.completedAmount = goal.currentAmount
                goals[index] = updatedGoal
                goalsToArchive.append(updatedGoal)
                updated = true
            }
            // Check if goal passed target date without being achieved
            else if goal.status == .active && goal.isPastTargetDate && !goal.isAchieved {
                updatedGoal.status = .failed
                updatedGoal.completedDate = Date()
                updatedGoal.completedAmount = goal.currentAmount
                goals[index] = updatedGoal
                goalsToArchive.append(updatedGoal)
                updated = true
            }
        }
        
        // Move completed/failed goals to archived
        if !goalsToArchive.isEmpty {
            var currentArchived = loadArchivedGoals()
            currentArchived.append(contentsOf: goalsToArchive)
            saveArchivedGoals(currentArchived)
            
            // Remove from active goals
            goals.removeAll { goal in
                goalsToArchive.contains { $0.id == goal.id }
            }
        }
        
        if updated {
            saveGoals()
        }
    }
    
    // Save goals to UserDefaults
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: goalsKey)
        }
    }
    
    // Create a new goal
    @discardableResult
    func createGoal(name: String, targetAmount: Double, startDate: Date?, targetDate: Date?, category: SavingsGoal.GoalCategory, photoPath: String? = nil, description: String? = nil) -> SavingsGoal {
        let goal = SavingsGoal(
            id: UUID().uuidString,
            name: name,
            targetAmount: targetAmount,
            currentAmount: 0,
            startDate: startDate ?? Date(), // Default to today if not provided
            targetDate: targetDate,
            category: category,
            photoPath: photoPath,
            description: description,
            status: .active,
            createdDate: Date(),
            completedDate: nil,
            completedAmount: nil
        )
        goals.append(goal)
        if activeGoal == nil {
            activeGoal = goal
        }
        saveGoals()
        return goal
    }
    
    // Update goal photo path (after upload to Firebase Storage)
    func updateGoalPhoto(goalId: String, photoPath: String?) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        var goal = goals[index]
        goal.photoPath = photoPath
        goals[index] = goal
        
        if activeGoal?.id == goalId {
            activeGoal = goal
        }
        saveGoals()
    }
    
    // Update goal description
    func updateGoalDescription(goalId: String, description: String?) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        var goal = goals[index]
        goal.description = description
        goals[index] = goal
        
        if activeGoal?.id == goalId {
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
        
        // Check if goal is now achieved
        if goal.status == .active && goal.isAchieved {
            goal.status = .achieved
            goal.completedDate = Date()
            goal.completedAmount = goal.currentAmount
            
            // Move to archived
            var archived = loadArchivedGoals()
            archived.append(goal)
            saveArchivedGoals(archived)
            
            // Remove from active goals
            goals.remove(at: index)
            
            // Update active goal if needed
            if activeGoal?.id == goalId {
                activeGoal = activeGoals.first
            }
        } else {
            goals[index] = goal
            if activeGoal?.id == goalId {
                activeGoal = goal
            }
        }
        saveGoals()
    }
    
    // Mark goal as cancelled
    func cancelGoal(_ goal: SavingsGoal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        var cancelledGoal = goal
        cancelledGoal.status = .cancelled
        cancelledGoal.completedDate = Date()
        cancelledGoal.completedAmount = goal.currentAmount
        
        // Move to archived
        var archived = loadArchivedGoals()
        archived.append(cancelledGoal)
        saveArchivedGoals(archived)
        
        // Remove from active goals
        goals.remove(at: index)
        
        // Update active goal if needed
        if activeGoal?.id == goal.id {
            activeGoal = activeGoals.first
        }
        
        saveGoals()
    }
    
    // Get all goals (active + archived) for historical view
    func getAllGoals() -> [SavingsGoal] {
        return goals + loadArchivedGoals()
    }
    
    // Set active goal (only if goal is active)
    func setActiveGoal(_ goal: SavingsGoal?) {
        guard let goal = goal, goal.status == .active else { return }
        activeGoal = goal
    }
    
    // Delete goal (only active goals - archived goals are deleted separately)
    func deleteGoal(_ goal: SavingsGoal) {
        guard goal.status == .active else { return } // Only delete active goals
        goals.removeAll { $0.id == goal.id }
        if activeGoal?.id == goal.id {
            activeGoal = activeGoals.first
        }
        saveGoals()
    }
    
    // Delete archived goal
    func deleteArchivedGoal(_ goal: SavingsGoal) {
        var archived = loadArchivedGoals()
        archived.removeAll { $0.id == goal.id }
        saveArchivedGoals(archived)
    }
    
    // Get total saved across all goals
    var totalSavedAcrossGoals: Double {
        return goals.reduce(0) { $0 + $1.currentAmount }
    }
    
    // Add protection amount to active goal (automatic when user chooses protection)
    func addProtectionToActiveGoal() {
        guard let activeGoal = activeGoal else { return }
        addToGoal(goalId: activeGoal.id, amount: activeGoal.protectionAmount)
    }
    
    // Update protection amount for a goal
    func updateProtectionAmount(goalId: String, amount: Double) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        var goal = goals[index]
        goal.protectionAmount = max(0, amount) // Ensure non-negative
        goals[index] = goal
        
        if activeGoal?.id == goalId {
            self.activeGoal = goal
        }
        saveGoals()
    }
}

