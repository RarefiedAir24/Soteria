//
//  GoalNotificationService.swift
//  soteria
//
//  Manages goal-specific notifications: progress updates, milestones, and achievements
//

import Foundation
import UserNotifications
import UIKit

class GoalNotificationService {
    static let shared = GoalNotificationService()
    
    private init() {
        // Register notification categories for goal notifications
        registerNotificationCategories()
    }
    
    // MARK: - Notification Categories
    
    private func registerNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // Goal progress category
        let progressCategory = UNNotificationCategory(
            identifier: "GOAL_PROGRESS",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Goal milestone category
        let milestoneCategory = UNNotificationCategory(
            identifier: "GOAL_MILESTONE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Goal achievement category
        let achievementCategory = UNNotificationCategory(
            identifier: "GOAL_ACHIEVEMENT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([progressCategory, milestoneCategory, achievementCategory])
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleNotifications(for goal: SavingsGoal) {
        guard goal.notificationsEnabled else {
            cancelNotifications(for: goal)
            return
        }
        
        // Cancel existing notifications for this goal
        cancelNotifications(for: goal)
        
        // Schedule progress notifications
        if goal.progressNotificationFrequency != .never {
            scheduleProgressNotifications(for: goal)
        }
        
        // Schedule milestone notifications (if not already reached)
        if goal.milestoneNotificationsEnabled {
            scheduleMilestoneNotifications(for: goal)
        }
        
        // Achievement notification is sent immediately when goal is achieved (handled in GoalsService)
    }
    
    private func scheduleProgressNotifications(for goal: SavingsGoal) {
        let calendar = Calendar.current
        
        // Get notification times (support multiple times, up to 5)
        var notificationTimes = goal.notificationTimes
        if notificationTimes.isEmpty {
            // Default to 9 AM if no times set
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            if let defaultTime = calendar.date(from: components) {
                notificationTimes = [defaultTime]
            }
        }
        
        // Schedule notifications for each time
        for notificationTime in notificationTimes {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
            let hour = timeComponents.hour ?? 9
            let minute = timeComponents.minute ?? 0
            
            switch goal.progressNotificationFrequency {
            case .daily:
                scheduleDailyProgressNotification(for: goal, hour: hour, minute: minute, timeIndex: notificationTimes.firstIndex(of: notificationTime) ?? 0)
            case .weekly:
                scheduleWeeklyProgressNotification(for: goal, hour: hour, minute: minute, timeIndex: notificationTimes.firstIndex(of: notificationTime) ?? 0)
            case .twiceWeekly:
                scheduleTwiceWeeklyProgressNotification(for: goal, hour: hour, minute: minute, timeIndex: notificationTimes.firstIndex(of: notificationTime) ?? 0)
            case .never:
                break
            }
        }
    }
    
    private func scheduleDailyProgressNotification(for goal: SavingsGoal, hour: Int, minute: Int, timeIndex: Int = 0) {
        let center = UNUserNotificationCenter.current()
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = "\(goal.name) Progress"
        content.body = getProgressNotificationBody(for: goal)
        content.sound = .default
        content.badge = NSNumber(value: 1) // Update badge
        content.categoryIdentifier = "GOAL_PROGRESS" // For better organization
        content.userInfo = [
            "type": "goal_progress",
            "goalId": goal.id
        ]
        
        // Note: Attachments are skipped for scheduled notifications because temporary files
        // may be cleaned up before the notification fires. Attachments are only used for
        // immediate notifications (achievement, milestone).
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "goal_progress_\(goal.id)_\(timeIndex)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ [GoalNotificationService] Failed to schedule daily progress notification: \(error)")
            } else {
                print("✅ [GoalNotificationService] Scheduled daily progress notification for goal: \(goal.name) at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    private func scheduleWeeklyProgressNotification(for goal: SavingsGoal, hour: Int, minute: Int, timeIndex: Int = 0) {
        let center = UNUserNotificationCenter.current()
        
        // Default to Monday (weekday 2)
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = "\(goal.name) Weekly Update"
        content.body = getProgressNotificationBody(for: goal)
        content.sound = .default
        content.badge = NSNumber(value: 1) // Update badge
        content.categoryIdentifier = "GOAL_PROGRESS" // For better organization
        content.userInfo = [
            "type": "goal_progress",
            "goalId": goal.id
        ]
        
        // Note: Attachments are skipped for scheduled notifications because temporary files
        // may be cleaned up before the notification fires. Attachments are only used for
        // immediate notifications (achievement, milestone).
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "goal_progress_\(goal.id)_weekly_\(timeIndex)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ [GoalNotificationService] Failed to schedule weekly progress notification: \(error)")
            } else {
                print("✅ [GoalNotificationService] Scheduled weekly progress notification for goal: \(goal.name) at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    private func scheduleTwiceWeeklyProgressNotification(for goal: SavingsGoal, hour: Int, minute: Int, timeIndex: Int = 0) {
        let center = UNUserNotificationCenter.current()
        
        // Monday and Thursday
        let weekdays = [2, 5] // Monday = 2, Thursday = 5
        
        for weekday in weekdays {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let content = UNMutableNotificationContent()
            content.title = "\(goal.name) Progress"
            content.body = getProgressNotificationBody(for: goal)
            content.sound = .default
            content.badge = NSNumber(value: 1) // Update badge
            content.categoryIdentifier = "GOAL_PROGRESS" // For better organization
            content.userInfo = [
                "type": "goal_progress",
                "goalId": goal.id
            ]
            
            // Note: Attachments are skipped for scheduled notifications because temporary files
            // may be cleaned up before the notification fires. Attachments are only used for
            // immediate notifications (achievement, milestone).
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "goal_progress_\(goal.id)_twice_\(timeIndex)_\(weekday)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("❌ [GoalNotificationService] Failed to schedule twice-weekly progress notification: \(error)")
                } else {
                    print("✅ [GoalNotificationService] Scheduled twice-weekly progress notification for goal: \(goal.name) (weekday \(weekday))")
                }
            }
        }
    }
    
    private func scheduleMilestoneNotifications(for goal: SavingsGoal) {
        // Milestone notifications are sent immediately when milestones are reached
        // We just need to track which milestones have been sent
        // This is handled in checkAndSendMilestoneNotifications()
        // No scheduling needed - they're sent on-demand when progress updates
    }
    
    // Reschedule all notifications for a goal (useful for ensuring persistence)
    func rescheduleNotifications(for goal: SavingsGoal) {
        scheduleNotifications(for: goal)
    }
    
    func checkAndSendMilestoneNotifications(for goal: SavingsGoal) {
        guard goal.milestoneNotificationsEnabled && goal.status == .active else { return }
        
        let progress = goal.progress
        let milestones: [Double] = [0.25, 0.50, 0.75]
        
        for milestone in milestones {
            // Check if we've crossed this milestone threshold
            let milestoneKey = "goal_milestone_\(milestone)_\(goal.id)"
            let hasReachedMilestone = UserDefaults.standard.bool(forKey: milestoneKey)
            
            if progress >= milestone && !hasReachedMilestone {
                sendMilestoneNotification(for: goal, milestone: milestone)
                UserDefaults.standard.set(true, forKey: milestoneKey)
            }
        }
    }
    
    private     func sendMilestoneNotification(for goal: SavingsGoal, milestone: Double) {
        let center = UNUserNotificationCenter.current()
        
        let percentage = Int(milestone * 100)
        let content = UNMutableNotificationContent()
        content.title = "🎉 \(percentage)% Milestone Reached!"
        content.body = "You're \(percentage)% of the way to \(goal.name)! Keep it up!"
        content.sound = .default
        content.badge = NSNumber(value: 1) // Update badge
        content.categoryIdentifier = "GOAL_MILESTONE" // For better organization
        content.userInfo = [
            "type": "goal_milestone",
            "goalId": goal.id,
            "milestone": milestone
        ]
        
        // Add goal photo attachment if available
        if let attachment = createGoalPhotoAttachment(for: goal) {
            content.attachments = [attachment]
        }
        
        // Send immediately
        let request = UNNotificationRequest(
            identifier: "goal_milestone_\(goal.id)_\(Int(milestone * 100))_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ [GoalNotificationService] Failed to send milestone notification: \(error)")
            } else {
                print("✅ [GoalNotificationService] Sent \(percentage)% milestone notification for goal: \(goal.name)")
            }
        }
    }
    
    func sendAchievementNotification(for goal: SavingsGoal) {
        guard goal.achievementNotificationEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Goal Achieved!"
        content.body = "Congratulations! You've reached your goal: \(goal.name) - $\(String(format: "%.2f", goal.currentAmount)) saved!"
        content.sound = .default
        content.badge = NSNumber(value: 1) // Update badge
        content.categoryIdentifier = "GOAL_ACHIEVEMENT" // For better organization
        content.userInfo = [
            "type": "goal_achievement",
            "goalId": goal.id
        ]
        
        // Add goal photo attachment if available
        if let attachment = createGoalPhotoAttachment(for: goal) {
            content.attachments = [attachment]
        }
        
        // Send immediately
        let request = UNNotificationRequest(
            identifier: "goal_achievement_\(goal.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ [GoalNotificationService] Failed to send achievement notification: \(error)")
            } else {
                print("✅ [GoalNotificationService] Sent achievement notification for goal: \(goal.name)")
            }
        }
    }
    
    func updateProgressNotification(for goal: SavingsGoal) {
        // Cancel and reschedule to update with latest progress
        cancelProgressNotifications(for: goal)
        if goal.notificationsEnabled && goal.progressNotificationFrequency != .never {
            scheduleProgressNotifications(for: goal)
        }
    }
    
    // MARK: - Notification Cancellation
    
    func cancelNotifications(for goal: SavingsGoal) {
        cancelProgressNotifications(for: goal)
        cancelMilestoneNotifications(for: goal)
    }
    
    private func cancelProgressNotifications(for goal: SavingsGoal) {
        let center = UNUserNotificationCenter.current()
        
        // Build list of all possible notification identifiers for this goal
        var identifiers: [String] = []
        
        // Daily notifications (up to 5 times)
        for timeIndex in 0..<5 {
            identifiers.append("goal_progress_\(goal.id)_\(timeIndex)")
        }
        
        // Weekly notifications (up to 5 times)
        for timeIndex in 0..<5 {
            identifiers.append("goal_progress_\(goal.id)_weekly_\(timeIndex)")
        }
        
        // Twice-weekly notifications (up to 5 times, for Monday and Thursday)
        for timeIndex in 0..<5 {
            identifiers.append("goal_progress_\(goal.id)_twice_\(timeIndex)_2") // Monday
            identifiers.append("goal_progress_\(goal.id)_twice_\(timeIndex)_5") // Thursday
        }
        
        // Legacy identifiers (for backward compatibility)
        identifiers.append(contentsOf: [
            "goal_progress_\(goal.id)",
            "goal_progress_\(goal.id)_2", // Monday
            "goal_progress_\(goal.id)_5"  // Thursday
        ])
        
        // Cancel all progress notifications for this goal
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    private func cancelMilestoneNotifications(for goal: SavingsGoal) {
        // Milestone notifications are sent immediately, so we just need to clear the tracking
        let milestones: [Double] = [0.25, 0.50, 0.75]
        for milestone in milestones {
            UserDefaults.standard.removeObject(forKey: "goal_milestone_\(milestone)_\(goal.id)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getProgressNotificationBody(for goal: SavingsGoal) -> String {
        let progress = goal.progress
        let current = goal.currentAmount
        let target = goal.targetAmount
        let remaining = target - current
        
        if progress >= 1.0 {
            return "🎉 You've reached your goal! $\(String(format: "%.2f", current)) saved!"
        } else {
            return "You're \(Int(progress * 100))% toward \(goal.name). $\(String(format: "%.2f", remaining)) to go!"
        }
    }
    
    // MARK: - Goal Photo Attachment
    
    /// Creates a notification attachment for goal photos.
    /// Note: Only use for immediate notifications (achievement, milestone).
    /// For scheduled notifications, attachments are skipped because temporary files
    /// may be cleaned up before the notification fires.
    private func createGoalPhotoAttachment(for goal: SavingsGoal) -> UNNotificationAttachment? {
        // Try to load goal photo from UserDefaults cache
        let cacheKey = "goal_photo_\(goal.id)"
        guard let imageData = UserDefaults.standard.data(forKey: cacheKey),
              let image = UIImage(data: imageData) else {
            // No photo available
            return nil
        }
        
        // Resize image if needed (notifications have size limits)
        let maxSize: CGFloat = 500 // Max dimension for notification images
        let resizedImage = max(image.size.width, image.size.height) > maxSize
            ? image.resized(toMaxDimension: maxSize)
            : image
        
        // Save to app's cache directory (more persistent than temp directory)
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let notificationAttachmentsDir = cacheDirectory.appendingPathComponent("notification_attachments")
        
        // Create directory if it doesn't exist
        do {
            try fileManager.createDirectory(at: notificationAttachmentsDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("⚠️ [GoalNotificationService] Failed to create notification attachments directory: \(error)")
            return nil
        }
        
        let fileName = "goal_photo_\(goal.id).jpg"
        let fileURL = notificationAttachmentsDir.appendingPathComponent(fileName)
        
        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.8) else {
            print("❌ [GoalNotificationService] Failed to convert image to JPEG")
            return nil
        }
        
        do {
            try jpegData.write(to: fileURL)
            
            // Verify file exists and is accessible
            guard fileManager.fileExists(atPath: fileURL.path) else {
                print("❌ [GoalNotificationService] File was not created at path: \(fileURL.path)")
                return nil
            }
            
            // Create attachment
            // Options: nil uses default settings (thumbnail visible)
            let attachment = try UNNotificationAttachment(
                identifier: "goal_photo_\(goal.id)",
                url: fileURL,
                options: nil
            )
            
            print("✅ [GoalNotificationService] Created goal photo attachment for goal: \(goal.name)")
            return attachment
        } catch {
            print("❌ [GoalNotificationService] Failed to create notification attachment: \(error)")
            // Clean up file if attachment creation failed
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
}

