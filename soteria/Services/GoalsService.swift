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
    var sharedGoalId: String? = nil // ID of shared goal if this is a multi-user goal
    
    // Goal notification settings
    var notificationsEnabled: Bool = true // Default to enabled
    var progressNotificationFrequency: ProgressNotificationFrequency = .daily // How often to send progress updates
    var milestoneNotificationsEnabled: Bool = true // Notify at 25%, 50%, 75%
    var achievementNotificationEnabled: Bool = true // Notify when goal is achieved
    var notificationTime: Date? = nil // Time of day for notifications (optional, defaults to 9 AM)
    
    enum ProgressNotificationFrequency: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case twiceWeekly = "twice_weekly" // Monday & Thursday
        case never = "never"
    }
    
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
    static let shared: GoalsService = {
        let startTime = Date()
        let service = GoalsService()
        // CRITICAL: Don't access StartupDiagnostics.shared during initialization
        // StartupDiagnostics.shared.logServiceAccess("GoalsService.shared", startTime: startTime)
        return service
    }()
    
    @Published var goals: [SavingsGoal] = []
    @Published var activeGoal: SavingsGoal? = nil
    @Published var archivedGoals: [SavingsGoal] = [] // Stored property for better control
    
    private let goalsKey = "saved_goals"
    private let archivedGoalsKey = "archived_goals"
    
    // Computed properties for filtering
    var activeGoals: [SavingsGoal] {
        goals.filter { $0.status == .active }
    }
    
    var achievedGoals: [SavingsGoal] {
        archivedGoals.filter { $0.status == .achieved }
    }
    
    var failedGoals: [SavingsGoal] {
        archivedGoals.filter { $0.status == .failed }
    }
    
    private init() {
        // Load goals immediately on init (UserDefaults reads are fast and non-blocking)
        // This ensures goals are available for the money tree and other views
        // The JSON decode is small and fast, won't block startup
        loadGoals()
        // Load and filter archived goals immediately
        refreshArchivedGoals()
    }
    
    // Ensure data is loaded (call on-demand)
    func ensureDataLoaded() {
        // Only load if not already loaded
        guard goals.isEmpty else {
            // Even if loaded, refresh archived goals to ensure they're up to date
            refreshArchivedGoals()
            return
        }
        loadGoals()
        refreshArchivedGoals()
    }
    
    // Refresh archived goals - loads from storage and filters out active goals
    private func refreshArchivedGoals() {
        let activeGoalIds = Set(goals.map { $0.id })
        let loaded = loadArchivedGoals()
        
        // Filter out active goals and goals that exist in active goals array
        let filtered = loaded.filter { goal in
            // Must not be active status
            guard goal.status != .active else { return false }
            // Must not exist in active goals array
            guard !activeGoalIds.contains(goal.id) else { return false }
            // Must be one of the historical statuses
            return goal.status == .achieved || goal.status == .failed || goal.status == .cancelled
        }
        
        // Update the stored property
        archivedGoals = filtered
        
        // Save cleaned version if anything was removed
        if filtered.count != loaded.count {
            saveArchivedGoals(filtered)
        }
    }
    
    // Load goals from UserDefaults
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([SavingsGoal].self, from: data) {
            // Migrate old goals that might not have new fields
            var loadedGoals = decoded.map { goal in
                var migratedGoal = goal
                // Ensure createdDate is set (handles migration from old goals)
                // The default value in the struct should handle this, but we'll ensure it's reasonable
                if migratedGoal.createdDate.timeIntervalSince1970 < 1000000000 { // Before year 2001
                    migratedGoal.createdDate = Date()
                }
                // If goal doesn't have status set properly, determine it
                // BUT: Don't mark newly created goals as failed even if target date is in past
                if migratedGoal.status == .active {
                    if migratedGoal.isAchieved {
                        migratedGoal.status = .achieved
                    } else if migratedGoal.isPastTargetDate {
                        // Only mark as failed if goal is older than 10 seconds
                        // This prevents newly created goals from being immediately archived
                        let secondsSinceCreation = abs(migratedGoal.createdDate.timeIntervalSinceNow)
                        if secondsSinceCreation > 10.0 {
                            migratedGoal.status = .failed
                        } else {
                            print("⚠️ [GoalsService] Skipping failed status for newly created goal with past target date: \(migratedGoal.id) (created \(String(format: "%.1f", secondsSinceCreation))s ago)")
                        }
                    }
                }
                return migratedGoal
            }
            
            // CRITICAL: Filter out any goals that are not active (should only be in archivedGoals)
            // This prevents goals from appearing in both active and historical sections
            goals = loadedGoals.filter { goal in
                // Only keep active goals in the main goals array
                if goal.status != .active {
                    print("⚠️ [GoalsService] Found non-active goal in active goals array: \(goal.id), status: \(goal.status). Moving to archived.")
                    // Move to archived if not already there
                    var currentArchived = loadArchivedGoals()
                    if !currentArchived.contains(where: { $0.id == goal.id }) {
                        currentArchived.append(goal)
                        saveArchivedGoals(currentArchived)
                    }
                    return false
                }
                return true
            }
            
            // Check for goal completion and update status
            checkAndUpdateGoalStatuses()
            // Set first active goal as default, or most recent
            activeGoal = activeGoals.first
            
            // Reschedule notifications for all active goals (ensures persistence across app sessions)
            rescheduleAllGoalNotifications()
            
            // Save cleaned goals array
            if goals.count != loadedGoals.count {
                saveGoals()
                print("✅ [GoalsService] Cleaned goals array: removed \(loadedGoals.count - goals.count) non-active goal(s)")
            }
        }
    }
    
    // Reschedule notifications for all active goals (called on app launch/login)
    // Made public so it can be called when user signs in or app becomes active
    private var lastRescheduleTime: Date?
    private let rescheduleCooldown: TimeInterval = 5.0 // Prevent rescheduling more than once every 5 seconds
    
    func rescheduleAllGoalNotifications() {
        // Prevent infinite loops by adding a cooldown
        if let lastTime = lastRescheduleTime, Date().timeIntervalSince(lastTime) < rescheduleCooldown {
            print("⚠️ [GoalsService] Skipping rescheduleAllGoalNotifications - too soon since last call")
            return
        }
        
        lastRescheduleTime = Date()
        
        // Schedule notifications for all active goals with notifications enabled
        let goalsToReschedule = activeGoals.filter { $0.notificationsEnabled }
        for goal in goalsToReschedule {
            GoalNotificationService.shared.scheduleNotifications(for: goal)
        }
        print("✅ [GoalsService] Rescheduled notifications for \(goalsToReschedule.count) active goal(s)")
    }
    
    // Load archived goals from UserDefaults
    private func loadArchivedGoals() -> [SavingsGoal] {
        if let data = UserDefaults.standard.data(forKey: archivedGoalsKey),
           let decoded = try? JSONDecoder().decode([SavingsGoal].self, from: data) {
            // Clean up: Remove any active goals from archived storage
            // Also remove any goals that exist in the active goals array
            let activeGoalIds = Set(goals.map { $0.id })
            let cleaned = decoded.filter { goal in
                // Must not be active status
                guard goal.status != .active else { return false }
                // Must not exist in active goals array
                guard !activeGoalIds.contains(goal.id) else { return false }
                // Must be one of the historical statuses
                return goal.status == .achieved || goal.status == .failed || goal.status == .cancelled
            }
            if cleaned.count != decoded.count {
                // Save cleaned version back to storage immediately
                saveArchivedGoals(cleaned)
            }
            return cleaned
        }
        return []
    }
    
    // Save archived goals to UserDefaults
    private func saveArchivedGoals(_ goalsToSave: [SavingsGoal]) {
        if let encoded = try? JSONEncoder().encode(goalsToSave) {
            UserDefaults.standard.set(encoded, forKey: archivedGoalsKey)
        }
        // Update the stored property to match what was saved
        archivedGoals = goalsToSave
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
            // BUT: Don't archive goals that were just created (within last 10 seconds)
            // This prevents newly created goals with past/same-day target dates from being immediately archived
            else if goal.status == .active && goal.isPastTargetDate && !goal.isAchieved {
                let secondsSinceCreation = abs(goal.createdDate.timeIntervalSinceNow)
                if secondsSinceCreation > 10.0 {
                    // Goal is older than 10 seconds, safe to archive if past target date
                    updatedGoal.status = .failed
                    updatedGoal.completedDate = Date()
                    updatedGoal.completedAmount = goal.currentAmount
                    goals[index] = updatedGoal
                    goalsToArchive.append(updatedGoal)
                    updated = true
                } else {
                    // Goal was just created, don't archive it even if target date is in past
                    print("⚠️ [GoalsService] Skipping archive for newly created goal with past target date: \(goal.id) (created \(String(format: "%.1f", secondsSinceCreation))s ago)")
                }
            }
        }
        
        // Move completed/failed goals to archived
        if !goalsToArchive.isEmpty {
            var currentArchived = loadArchivedGoals()
            // Remove any duplicates (goals that already exist in archived)
            let archiveIds = Set(currentArchived.map { $0.id })
            let newGoals = goalsToArchive.filter { !archiveIds.contains($0.id) }
            currentArchived.append(contentsOf: newGoals)
            saveArchivedGoals(currentArchived)
            // refreshArchivedGoals() is called by saveArchivedGoals()
            
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
        // Refresh archived goals after saving active goals to ensure separation
        refreshArchivedGoals()
    }
    
    // Create a new goal
    @discardableResult
    func createGoal(name: String, targetAmount: Double, startDate: Date?, targetDate: Date?, category: SavingsGoal.GoalCategory, photoPath: String? = nil, description: String? = nil) -> SavingsGoal {
        // CRITICAL: Check for duplicate goal (same name and target amount created within last 10 seconds)
        // Increased window from 5 to 10 seconds to catch more duplicates
        let now = Date()
        let recentDuplicate = goals.first { existingGoal in
            existingGoal.name == name &&
            abs(existingGoal.targetAmount - targetAmount) < 0.01 && // Same amount (within 1 cent)
            existingGoal.status == .active &&
            abs(existingGoal.createdDate.timeIntervalSince(now)) < 10.0 // Created within last 10 seconds
        }
        
        if let duplicate = recentDuplicate {
            print("⚠️ [GoalsService] Duplicate goal detected (created \(String(format: "%.1f", abs(duplicate.createdDate.timeIntervalSince(now))))s ago), returning existing goal: \(duplicate.id)")
            // Ensure duplicate is not in archived goals
            if archivedGoals.contains(where: { $0.id == duplicate.id }) {
                print("⚠️ [GoalsService] Duplicate goal found in archived goals, removing it")
                archivedGoals.removeAll { $0.id == duplicate.id }
                saveArchivedGoals(archivedGoals)
            }
            return duplicate
        }
        
        // Additional check: prevent creating goal if one with same name was just created
        // This is a more aggressive duplicate check
        let veryRecentDuplicate = goals.first { existingGoal in
            existingGoal.name == name &&
            existingGoal.status == .active &&
            abs(existingGoal.createdDate.timeIntervalSince(now)) < 2.0 // Created within last 2 seconds
        }
        
        if let veryRecent = veryRecentDuplicate {
            print("⚠️ [GoalsService] Very recent duplicate goal detected (created \(String(format: "%.1f", abs(veryRecent.createdDate.timeIntervalSince(now))))s ago), returning existing goal: \(veryRecent.id)")
            return veryRecent
        }
        
        // FINAL CHECK: Log all active goals before creating to debug duplicates
        print("🔵 [GoalsService] Active goals before creation: \(goals.map { "\($0.name) (id: \($0.id.prefix(8)))" }.joined(separator: ", "))")
        
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
            completedAmount: nil,
            notificationsEnabled: true, // Default to enabled
            progressNotificationFrequency: .daily, // Default to daily
            milestoneNotificationsEnabled: true, // Default to enabled
            achievementNotificationEnabled: true, // Default to enabled
            notificationTime: nil // Default to 9 AM (handled in service)
        )
        
        print("✅ [GoalsService] Creating new goal: \(goal.id), name: \(name), target: \(targetAmount), status: \(goal.status)")
        
        // CRITICAL: Ensure goal is not in archived goals before adding to active
        var currentArchived = loadArchivedGoals()
        let wasInArchived = currentArchived.contains(where: { $0.id == goal.id })
        if wasInArchived {
            print("⚠️ [GoalsService] New goal was found in archived goals, removing it: \(goal.id)")
            currentArchived.removeAll { $0.id == goal.id }
            saveArchivedGoals(currentArchived)
            archivedGoals = currentArchived
        }
        
        // Add to active goals
        goals.append(goal)
        if activeGoal == nil {
            activeGoal = goal
        }
        
        // Save goals WITHOUT calling checkAndUpdateGoalStatuses (new goals shouldn't be archived)
        // Direct save to avoid triggering status checks that might archive new goals
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: goalsKey)
        }
        
        // Refresh archived goals to ensure separation (but don't check statuses for new goal)
        refreshArchivedGoals()
        
        // Schedule notifications for the new goal
        GoalNotificationService.shared.scheduleNotifications(for: goal)
        
        // Final verification: ensure goal is only in active, not archived
        let finalArchived = loadArchivedGoals()
        if finalArchived.contains(where: { $0.id == goal.id }) {
            print("❌ [GoalsService] ERROR: Goal \(goal.id) is in archived after creation! Removing it.")
            var cleanedArchived = finalArchived
            cleanedArchived.removeAll { $0.id == goal.id }
            saveArchivedGoals(cleanedArchived)
            refreshArchivedGoals()
        }
        
        // Verify goal is in active goals
        let isInActive = goals.contains(where: { $0.id == goal.id })
        let isInArchived = archivedGoals.contains(where: { $0.id == goal.id })
        
        print("✅ [GoalsService] Goal creation complete: \(goal.id)")
        print("   - In active goals: \(isInActive), In archived: \(isInArchived)")
        print("   - Active goals count: \(goals.count), Archived goals count: \(archivedGoals.count)")
        print("   - Goal status: \(goal.status)")
        
        if !isInActive {
            print("❌ [GoalsService] ERROR: Goal \(goal.id) is NOT in active goals after creation!")
        }
        if isInArchived {
            print("❌ [GoalsService] ERROR: Goal \(goal.id) IS in archived goals after creation!")
        }
        
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
            let oldGoal = goals[index]
            goals[index] = goal
            if activeGoal?.id == goal.id {
                activeGoal = goal
            }
            saveGoals()
            
            // Reschedule notifications if settings changed
            if oldGoal.notificationsEnabled != goal.notificationsEnabled ||
               oldGoal.progressNotificationFrequency != goal.progressNotificationFrequency ||
               oldGoal.notificationTime != goal.notificationTime {
                GoalNotificationService.shared.scheduleNotifications(for: goal)
            }
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
            
            // Calculate days to complete
            let daysToComplete: Int?
            if let startDate = goal.startDate {
                daysToComplete = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day
            } else {
                daysToComplete = nil
            }
            
            // Track goal completion with AI service
            BehavioralAIService.shared.recordGoalCompleted(
                goalId: goal.id,
                targetAmount: goal.targetAmount,
                completedAmount: goal.currentAmount,
                daysToComplete: daysToComplete
            )
            
            // Post notification for celebration (in-app)
            NotificationCenter.default.post(
                name: NSNotification.Name("GoalCompleted"),
                object: goal
            )
            
            // Send system notification for achievement
            GoalNotificationService.shared.sendAchievementNotification(for: goal)
            
            // Remove from active goals first
            goals.remove(at: index)
            saveGoals()
            
            // Move to archived
            var archived = loadArchivedGoals()
            // Check if goal already exists in archived (prevent duplicates)
            if !archived.contains(where: { $0.id == goal.id }) {
                archived.append(goal)
                saveArchivedGoals(archived)
            }
            
            // Refresh to ensure proper filtering
            refreshArchivedGoals()
            
            // Update active goal if needed
            if activeGoal?.id == goalId {
                activeGoal = activeGoals.first
            }
        } else {
            goals[index] = goal
            if activeGoal?.id == goalId {
                activeGoal = goal
            }
            saveGoals()
        }
    }
    
    // Get all goals (active + archived) for historical view
    func getAllGoals() -> [SavingsGoal] {
        return goals + loadArchivedGoals()
    }
    
    // Get goal by ID (searches both active and archived goals)
    func getGoal(byId goalId: String) -> SavingsGoal? {
        // First check active goals
        if let goal = goals.first(where: { $0.id == goalId }) {
            return goal
        }
        // Then check archived goals
        let archived = loadArchivedGoals()
        return archived.first(where: { $0.id == goalId })
    }
    
    // Refresh goals from storage (useful when data might be stale)
    func refreshGoals() {
        loadGoals()
        refreshArchivedGoals()
        // Double-check: ensure archivedGoals doesn't contain any active goals
        // This is a safety measure in case any active goals slipped through
        let activeGoalIds = Set(goals.map { $0.id })
        let beforeCount = archivedGoals.count
        archivedGoals = archivedGoals.filter { goal in
            // Must not be active status
            guard goal.status != .active else { return false }
            // Must not exist in active goals array
            guard !activeGoalIds.contains(goal.id) else { return false }
            // Must be one of the historical statuses
            return goal.status == .achieved || goal.status == .failed || goal.status == .cancelled
        }
        // Save cleaned version if anything was removed
        if archivedGoals.count != beforeCount {
            saveArchivedGoals(archivedGoals)
        }
    }
    
    // Set active goal (only if goal is active)
    func setActiveGoal(_ goal: SavingsGoal?) {
        guard let goal = goal, goal.status == .active else { return }
        activeGoal = goal
    }
    
    // Cancel a goal (move to historical with cancelled status)
    func cancelGoal(_ goal: SavingsGoal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }),
              goal.status == .active else { return }
        
        var cancelledGoal = goal
        cancelledGoal.status = .cancelled
        cancelledGoal.completedDate = Date()
        
        // Remove from active goals
        goals.remove(at: index)
        
        // Add to archived goals
        var currentArchived = loadArchivedGoals()
        // Remove if already exists (shouldn't happen, but safety check)
        currentArchived.removeAll { $0.id == cancelledGoal.id }
        currentArchived.append(cancelledGoal)
        saveArchivedGoals(currentArchived)
        
        // Update activeGoal if it was the cancelled one
        if activeGoal?.id == goal.id {
            activeGoal = activeGoals.first
        }
        
        saveGoals()
        refreshArchivedGoals()
        
        // Cancel notifications for the cancelled goal
        GoalNotificationService.shared.cancelNotifications(for: cancelledGoal)
        
        print("✅ [GoalsService] Goal cancelled: \(goal.id), name: \(goal.name)")
    }
    
    // Delete goal (only active goals - archived goals are deleted separately)
    func deleteGoal(_ goal: SavingsGoal) {
        guard goal.status == .active else { return } // Only delete active goals
        
        // Remove from local cache FIRST (before async S3 deletion)
        // This ensures the photo doesn't reappear if the view refreshes
        UserDefaults.standard.removeObject(forKey: "goal_photo_\(goal.id)")
        // Mark photo as deleted to prevent GoalCard from trying to reload it
        UserDefaults.standard.set(true, forKey: "goal_photo_deleted_\(goal.id)")
        
        // Delete goal photo from S3 (async, but don't block deletion)
        if goal.photoPath != nil {
            Task {
                do {
                    try await GoalPhotoService.shared.deleteGoalPhoto(goalId: goal.id)
                    print("✅ [GoalsService] Goal photo deleted from S3: \(goal.id)")
                } catch {
                    // Log error but don't fail deletion - local cache is already cleared
                    print("⚠️ [GoalsService] Failed to delete goal photo from S3: \(error.localizedDescription)")
                }
            }
        }
        
        // Remove goal from active goals
        goals.removeAll { $0.id == goal.id }
        if activeGoal?.id == goal.id {
            activeGoal = activeGoals.first
        }
        saveGoals()
        
        // Refresh to ensure UI updates
        refreshArchivedGoals()
    }
    
    // Delete archived goal
    func deleteArchivedGoal(_ goal: SavingsGoal) {
        // Remove from local cache FIRST (before async S3 deletion)
        // This ensures the photo doesn't reappear if the view refreshes
        UserDefaults.standard.removeObject(forKey: "goal_photo_\(goal.id)")
        // Mark photo as deleted to prevent GoalCard from trying to reload it
        UserDefaults.standard.set(true, forKey: "goal_photo_deleted_\(goal.id)")
        
        // Delete goal photo from S3 (async, but don't block deletion)
        if goal.photoPath != nil {
            Task {
                do {
                    try await GoalPhotoService.shared.deleteGoalPhoto(goalId: goal.id)
                    print("✅ [GoalsService] Archived goal photo deleted from S3: \(goal.id)")
                } catch {
                    // Log error but don't fail deletion - local cache is already cleared
                    print("⚠️ [GoalsService] Failed to delete archived goal photo from S3: \(error.localizedDescription)")
                }
            }
        }
        
        // Remove from archived goals
        var archived = loadArchivedGoals()
        archived.removeAll { $0.id == goal.id }
        saveArchivedGoals(archived)
        // refreshArchivedGoals() is called by saveArchivedGoals()
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
    
    // Recalculate goal amounts from deposit history (fixes double-counting issues)
    func recalculateGoalAmounts(from plaidService: PlaidService) {
        print("🔄 [GoalsService] Recalculating goal amounts from deposit history...")
        
        for (index, goal) in goals.enumerated() {
            // Get all deposits for this goal
            let goalDeposits = plaidService.depositHistory.filter { $0.goalId == goal.id }
            
            // Sum up all deposits for this goal
            let calculatedAmount = goalDeposits.reduce(0.0) { $0 + $1.amount }
            
            // Only update if there's a discrepancy
            if abs(goal.currentAmount - calculatedAmount) > 0.01 {
                print("🔧 [GoalsService] Goal '\(goal.name)': Correcting amount from $\(goal.currentAmount) to $\(calculatedAmount) (based on \(goalDeposits.count) deposits)")
                var updatedGoal = goal
                updatedGoal.currentAmount = calculatedAmount
                goals[index] = updatedGoal
                
                // Update activeGoal if this is the active goal
                if activeGoal?.id == goal.id {
                    activeGoal = updatedGoal
                }
            }
        }
        
        saveGoals()
        
        // Update notifications for all goals to ensure they show current amounts
        // This fixes the issue where notifications show stale deposit amounts ($10 instead of $5)
        for goal in goals {
            GoalNotificationService.shared.updateProgressNotification(for: goal)
        }
        
        print("✅ [GoalsService] Goal amounts recalculated and notifications updated")
    }
}

