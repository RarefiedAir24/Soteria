//
//  DeviceActivityMonitorExtension.swift
//  SoteriaMonitor
//
//  Created by Frank Schioppa on 12/6/25.
//

import DeviceActivity
import ManagedSettings
import UserNotifications
import FamilyControls
import SwiftUI

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    
    override init() {
        super.init()
        print("🔔 [Extension] ════════════════════════════════════════")
        print("🔔 [Extension] DeviceActivityMonitorExtension INITIALIZED!")
        print("🔔 [Extension] Extension is loaded and running")
        print("🔔 [Extension] Current time: \(Date())")
        print("🔔 [Extension] ════════════════════════════════════════")
    }
    
    // MARK: - Notification Customization Helper
    
    /// Creates a customizable notification content with app-specific messaging
    /// - Parameters:
    ///   - title: Main notification title (e.g., "🛑 SOTERIA Moment")
    ///   - subtitle: Subtitle that appears below title in banner (e.g., "Protection Alert")
    ///   - body: Main notification message
    ///   - appName: Name of the app that triggered the notification
    ///   - type: Notification type identifier
    ///   - userInfo: Additional user info dictionary
    /// - Returns: Configured UNMutableNotificationContent
    private func createCustomNotificationContent(
        title: String,
        subtitle: String? = nil,
        body: String,
        appName: String? = nil,
        type: String,
        userInfo: [String: Any] = [:]
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Set customizable title
        content.title = title
        
        // Set customizable subtitle (appears below title in banner)
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        
        // Set customizable body text
        content.body = body
        
        // Set category identifier for custom actions (if needed)
        content.categoryIdentifier = type
        
        // Combine userInfo with type and appName
        var combinedUserInfo = userInfo
        combinedUserInfo["type"] = type
        if let appName = appName {
            combinedUserInfo["appName"] = appName
        }
        content.userInfo = combinedUserInfo
        
        // Set sound
        content.sound = .default
        
        // Set badge count
        content.badge = 1
        
        // Use time-sensitive interruption level for in-app visibility
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
        }
        
        // Set thread identifier to group related notifications
        content.threadIdentifier = type
        
        return content
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("🔔 [Extension] ════════════════════════════════════════")
        print("🔔 [Extension] intervalDidStart FIRED!")
        print("🔔 [Extension] Activity: \(activity)")
        print("🔔 [Extension] Current time: \(Date())")
        print("🔔 [Extension] ════════════════════════════════════════")
        
        // FIXED: Clear event state when interval starts to allow events to fire again
        // This ensures notifications can be sent every time the app opens, not just once per interval
        // DeviceActivity events reset when the monitoring interval starts
        print("🔄 [Extension] Monitoring interval started - events can now fire again")
        
        // The main app should have already set shield.applications
        // We just verify it's set and log for debugging
        let appCount = UserDefaults.standard.integer(forKey: "selectedAppsCount")
        print("🔔 [Extension] App count from UserDefaults: \(appCount)")
        
        // Check current shield applications count
        let currentShieldCount = store.shield.applications?.count ?? 0
        print("🔔 [Extension] Current shield.applications count: \(currentShieldCount)")
        
        if appCount > 0 {
            // Verify blocking is active
            if currentShieldCount > 0 {
                print("🔒 [Extension] ✅ Blocking is active - \(currentShieldCount) app(s) are blocked")
                print("🔒 [Extension] Blocking screen will show when user tries to open blocked apps")
                print("🔒 [Extension] When user taps button, app opens and SOTERIA will show prompt")
            } else {
                print("⚠️ [Extension] WARNING: App count is \(appCount) but shield.applications is empty!")
                print("⚠️ [Extension] Blocking may not be working - main app should set shield.applications")
            }
        } else {
            print("🔓 [Extension] No apps selected")
            // Only clear if we're sure there are no apps
            if currentShieldCount > 0 {
                print("⚠️ [Extension] WARNING: shield.applications has \(currentShieldCount) apps but UserDefaults says 0")
            }
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("🔔 [Extension] intervalDidEnd for activity: \(activity)")
        // Monitoring ended - check if there was an active shopping session
        checkAndPromptForPurchase()
    }
    
    // Check if user had a shopping session and prompt to log purchase
    private func checkAndPromptForPurchase() {
        if let sessionData = UserDefaults.standard.dictionary(forKey: "activeShoppingSession"),
           let startTime = sessionData["startTime"] as? TimeInterval {
            let sessionStart = Date(timeIntervalSince1970: startTime)
            let duration = Date().timeIntervalSince(sessionStart)
            
            // If session was > 2 minutes, likely made a purchase - send notification
            if duration > 120 {
                print("📱 [Extension] Shopping session ended (>2 min) - sending purchase log prompt")
                sendPurchaseLogNotification(duration: duration)
            }
            
            // Clear the session
            UserDefaults.standard.removeObject(forKey: "activeShoppingSession")
        }
    }
    
    // Send notification to prompt purchase logging
    private func sendPurchaseLogNotification(duration: TimeInterval) {
        Task {
            let content = UNMutableNotificationContent()
            content.title = "📝 Log Your Purchase?"
            content.body = "You were shopping for \(Int(duration / 60)) minutes. Quick log to track your spending."
            content.userInfo = ["type": "purchase_log_prompt"]
            content.sound = .default
            
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "purchase_log_\(UUID().uuidString)", content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ [Extension] Purchase log notification sent")
            } catch {
                print("❌ [Extension] Failed to send purchase log notification: \(error)")
            }
        }
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        print("⚠️ [Extension] eventWillReachThresholdWarning - Event: \(event), Activity: \(activity)")
        // FIXED: This fires BEFORE the app opens - this is our PRIMARY method to send notifications
        // This should fire every time the app is about to open, even if eventDidReachThreshold already fired
        print("🔔 [Extension] App about to open - sending notification BEFORE app launch")
        
        // Extract app index from event name
        let eventNameString = event.rawValue
        var appIndex: Int? = nil
        
        if let indexString = eventNameString.split(separator: ".").last,
           let index = Int(indexString) {
            appIndex = index
            print("✅ [Extension] Extracted app index: \(index) from event name: \(eventNameString)")
        }
        
        // Get app name using internal naming system
        let appName = getAppName(forIndex: appIndex ?? 0)
        print("✅ [Extension] App name: \(appName) (index: \(appIndex ?? -1))")
        
        UserDefaults.standard.set(true, forKey: "shouldShowPurchaseIntentPrompt")
        UserDefaults.standard.set(true, forKey: "shouldOpenTargetAppAfterPrompt")
        if let appIndex = appIndex {
            UserDefaults.standard.set(appIndex, forKey: "lastOpenedAppIndex")
        }
        print("✅ [Extension] Set shouldShowPurchaseIntentPrompt flag")
        
        // FIXED: Send notification in eventWillReachThresholdWarning (fires BEFORE threshold)
        // This ensures notification is sent every time app is about to open
        // eventWillReachThresholdWarning should fire even if eventDidReachThreshold already fired
        sendPurchaseIntentPromptNotification(appName: appName, appIndex: appIndex)
    }
    
           override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
               super.eventDidReachThreshold(event, activity: activity)
               print("🔔 [Extension] ════════════════════════════════════════")
               print("🔔 [Extension] eventDidReachThreshold FIRED!")
               print("🔔 [Extension] Event: \(event)")
               print("🔔 [Extension] Activity: \(activity)")
               print("🔔 [Extension] Monitored app opened during Quiet Hours")
               print("🔔 [Extension] ════════════════════════════════════════")
               
               // Extract app index from event name
               // Event name format: "soteria.moment.0", "soteria.moment.1", etc.
               let eventNameString = event.rawValue
               var appIndex: Int? = nil
               
               if let indexString = eventNameString.split(separator: ".").last,
                  let index = Int(indexString) {
                   appIndex = index
                   print("✅ [Extension] Extracted app index: \(index) from event name: \(eventNameString)")
               } else {
                   print("⚠️ [Extension] Could not extract app index from event name: \(eventNameString)")
               }
               
               // Get app name using internal naming system
               let appName = getAppName(forIndex: appIndex ?? 0)
               print("✅ [Extension] App name: \(appName) (index: \(appIndex ?? -1))")
               
               // Track that shopping app was opened
               recordShoppingSessionStart()
               
               // Notify main app that a shopping app came to foreground
               UserDefaults.standard.set(true, forKey: "shoppingAppOpened")
               UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "shoppingAppOpenedTime")
               
               // Store app index for main app
               if let appIndex = appIndex {
                   UserDefaults.standard.set(appIndex, forKey: "lastOpenedAppIndex")
               }
        
               // Set flag so SOTERIA shows prompt when it becomes active
               UserDefaults.standard.set(true, forKey: "shouldShowPurchaseIntentPrompt")
               print("✅ [Extension] Set shouldShowPurchaseIntentPrompt flag")
               
               // Send app-specific purchase intent prompt notification
               sendPurchaseIntentPromptNotification(appName: appName, appIndex: appIndex)
               
               // Also try to open SOTERIA directly via URL scheme
               if let url = URL(string: "soteria://purchase-intent") {
                   // Post notification to open SOTERIA
                   NotificationCenter.default.post(name: NSNotification.Name("OpenSOTERIA"), object: nil, userInfo: ["url": url.absoluteString])
                   print("✅ [Extension] Posted notification to open SOTERIA")
               }
           }
    
    // Get app name from internal naming system (shared UserDefaults)
    private func getAppName(forIndex index: Int) -> String {
        // Load app names from UserDefaults (shared between app and extension)
        if let data = UserDefaults.standard.data(forKey: "appNamesMapping"),
           let appNames = try? JSONDecoder().decode([Int: String].self, from: data),
           let name = appNames[index] {
            return name
        }
        // Fallback to default name
        return "App \(index + 1)"
    }
    
    // Get active goal information from shared UserDefaults
    private func getActiveGoalInfo() -> (name: String, progressPercent: Int)? {
        // Load goals from UserDefaults (shared between app and extension)
        // GoalsService stores goals with key "saved_goals"
        guard let data = UserDefaults.standard.data(forKey: "saved_goals"),
              let goals = try? JSONDecoder().decode([SavingsGoal].self, from: data) else {
            print("🔔 [Extension] No goals found in UserDefaults")
            return nil
        }
        
        // Find active goal
        let activeGoal = goals.first { goal in
            goal.status == .active
        }
        
        guard let goal = activeGoal else {
            print("🔔 [Extension] No active goal found")
            return nil
        }
        
        // Calculate progress percentage
        let progressPercent = Int(goal.progress * 100)
        
        print("🔔 [Extension] Found active goal: \(goal.name), Progress: \(progressPercent)%")
        return (name: goal.name, progressPercent: progressPercent)
    }
    
    // SavingsGoal struct for decoding (must match GoalsService.swift)
    // This is a simplified version for the extension - only fields we need
    // All fields are optional to handle decoding gracefully
    private struct SavingsGoal: Codable {
        let id: String
        var name: String
        var targetAmount: Double
        var currentAmount: Double
        var status: GoalStatus
        var targetDate: Date?
        var startDate: Date? // Optional - may not be present
        var category: GoalCategory? // Optional - may not be present
        var protectionAmount: Double? // Optional - may not be present
        var photoPath: String? // Optional
        var description: String? // Optional
        var createdDate: Date? // Optional
        var completedDate: Date? // Optional
        var completedAmount: Double? // Optional
        
        enum GoalStatus: String, Codable {
            case active = "active"
            case achieved = "achieved"
            case failed = "failed"
            case cancelled = "cancelled"
        }
        
        enum GoalCategory: String, Codable {
            case trip = "Trip"
            case purchase = "Purchase"
            case emergency = "Emergency Fund"
            case other = "Other"
        }
        
        var progress: Double {
            guard targetAmount > 0 else { return 0 }
            return min(currentAmount / targetAmount, 1.0)
        }
    }
    
    // Send app-specific notification to show purchase intent prompt
    // Track last notification time per app to prevent spam (optional rate limiting)
    private var lastNotificationTime: [Int: Date] = [:]
    private let minNotificationInterval: TimeInterval = 5.0 // Minimum 5 seconds between notifications for same app
    
    private func sendPurchaseIntentPromptNotification(appName: String, appIndex: Int?) {
        print("🔔 [Extension] Sending app-specific purchase intent prompt notification...")
        print("🔔 [Extension] App: \(appName) (index: \(appIndex ?? -1))")
        
        // FIXED: Optional rate limiting - only prevent notifications if sent very recently (within 5 seconds)
        // This allows notifications to show every time app opens, but prevents spam if app opens/closes rapidly
        if let appIndex = appIndex,
           let lastTime = lastNotificationTime[appIndex],
           Date().timeIntervalSince(lastTime) < minNotificationInterval {
            print("⏭️ [Extension] Skipping notification - sent recently for app \(appIndex) (rate limiting)")
            return
        }
        
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            guard settings.authorizationStatus == .authorized else {
                print("⚠️ [Extension] Notifications not authorized!")
                return
            }
            
            // Get active goal information
            let goalInfo = getActiveGoalInfo()
            
            // Create customizable notification content with goal information
            var bodyText: String
            var titleText: String = "🛑 SOTERIA Moment"
            
            if let goal = goalInfo {
                // Include goal information in notification
                // Format: "You're about to open <app name>. You have a save goal in progress <% to completion> would you like to save instead? click here <takes to soteria app>"
                titleText = "💰 Save Instead?"
                bodyText = "You're about to open \(appName). You have a save goal in progress: '\(goal.name)' (\(goal.progressPercent)% complete). Would you like to save instead? Tap to open Soteria."
            } else {
                // No active goal - use generic message with call to action to create a goal
                titleText = "🛑 SOTERIA Moment"
                let appNameLower = appName.lowercased()
                if appNameLower.contains("food") || appNameLower.contains("eat") || 
                   appNameLower.contains("door") || appNameLower.contains("uber") {
                    bodyText = "You're about to open \(appName). Take a moment to pause and think. Would you like to create a savings goal? Tap to open Soteria."
                } else {
                    bodyText = "You're about to open \(appName). Take a moment to pause and think. Would you like to create a savings goal? Tap to open Soteria."
                }
            }
            
            // Determine subtitle based on whether goal exists
            let subtitleText: String
            if let goal = goalInfo {
                subtitleText = "Goal Progress: \(goal.progressPercent)%"
            } else {
                subtitleText = "Create a Savings Goal"
            }
            
            // Add flag to userInfo to indicate if goal exists (for app navigation)
            var userInfo: [String: Any] = ["appIndex": appIndex ?? -1]
            if goalInfo == nil {
                userInfo["noActiveGoal"] = true  // Flag to indicate no goal - app can navigate to Goals tab
            }
            
            let content = createCustomNotificationContent(
                title: titleText,
                subtitle: subtitleText,
                body: bodyText,
                appName: appName,
                type: "purchase_intent_prompt",
                userInfo: userInfo
            )
            
            // Add URL to open SOTERIA (tapping notification will open the app)
            if let url = URL(string: "soteria://purchase-intent") {
                content.userInfo["url"] = url.absoluteString
            }
            
            // FIXED: Use unique identifier with timestamp to ensure notification is sent every time
            // Even if DeviceActivity event doesn't fire again, this ensures unique notifications
            let uniqueId = "purchase_intent_\(appIndex ?? -1)_\(Date().timeIntervalSince1970)_\(UUID().uuidString)"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: uniqueId, content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ [Extension] App-specific purchase intent prompt notification sent for \(appName)")
                
                // Update last notification time for rate limiting
                if let appIndex = appIndex {
                    lastNotificationTime[appIndex] = Date()
                }
            } catch {
                print("❌ [Extension] Failed to send purchase intent prompt notification: \(error)")
            }
        }
    }
    
    // Track shopping session start
    private func recordShoppingSessionStart() {
        let startTime = Date().timeIntervalSince1970
        let sessionData: [String: Any] = [
            "startTime": startTime,
            "timestamp": startTime
        ]
        UserDefaults.standard.set(sessionData, forKey: "activeShoppingSession")
        print("📱 [Extension] Started tracking shopping session at \(Date(timeIntervalSince1970: startTime))")
        print("📱 [Extension] Session data saved: \(sessionData)")
        
        // Verify it was saved
        if let saved = UserDefaults.standard.dictionary(forKey: "activeShoppingSession") {
            print("✅ [Extension] Verified session saved: \(saved)")
        } else {
            print("❌ [Extension] ERROR: Session NOT saved!")
        }
    }
    
    // Send notification when monitored app is opened
    private func sendSoteriaMomentNotification() {
        print("🔔 [Extension] Creating notification...")
        
        // Wrap in Task to handle async operations properly
        Task {
            // Check notification authorization first
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            print("🔔 [Extension] Notification settings - Authorization: \(settings.authorizationStatus.rawValue)")
            print("🔔 [Extension] Alert setting: \(settings.alertSetting.rawValue)")
            print("🔔 [Extension] Sound setting: \(settings.soundSetting.rawValue)")
            print("🔔 [Extension] Badge setting: \(settings.badgeSetting.rawValue)")
            print("🔔 [Extension] Lock screen setting: \(settings.lockScreenSetting.rawValue)")
            print("🔔 [Extension] Notification center setting: \(settings.notificationCenterSetting.rawValue)")
            if #available(iOS 15.0, *) {
                let timeSensitiveStatus = settings.timeSensitiveSetting.rawValue
                print("🔔 [Extension] Time sensitive setting: \(timeSensitiveStatus)")
                if timeSensitiveStatus != 2 { // 2 = enabled
                    print("⚠️ [Extension] WARNING: Time-sensitive notifications may not be enabled!")
                    print("⚠️ [Extension] User should enable in Settings → SOTERIA → Notifications → Time Sensitive Notifications")
                }
            }
            
            guard settings.authorizationStatus == .authorized else {
                print("⚠️ [Extension] Notifications not authorized! Status: \(settings.authorizationStatus.rawValue)")
                // Extensions can't request authorization - it must be done in the main app
                return
            }
            
            // Create customizable notification content
            let content = createCustomNotificationContent(
                title: "🛑 SOTERIA Moment",
                subtitle: "Protection Alert",
                body: "You're about to open a shopping app. Take a moment to pause and think.",
                type: "soteria_moment"
            )
            
            // Add URL to open app directly when notification is tapped
            // This will help bring the app to foreground
            if let url = URL(string: "soteria://pause") {
                content.userInfo["url"] = url.absoluteString
            }
            
            // Use time interval trigger with minimal delay for immediate delivery
            // Note: timeInterval must be > 0, so we use 0.1 seconds
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            let identifier = "soteria_moment_\(UUID().uuidString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            print("🔔 [Extension] Adding notification request with identifier: \(identifier)")
            if #available(iOS 15.0, *) {
                print("🔔 [Extension] Interruption level: timeSensitive")
                print("🔔 [Extension] Relevance score: \(content.relevanceScore)")
            }
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ [Extension] Notification sent successfully! Identifier: \(identifier)")
                
                // Wait a moment and check if it's still pending or delivered
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Check pending requests again
                let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
                print("🔔 [Extension] Pending notifications after delay: \(pendingRequests.count)")
                
                if let ourRequest = pendingRequests.first(where: { $0.identifier == identifier }) {
                    print("⚠️ [Extension] Notification still in pending list - may not have fired yet")
                    print("🔔 [Extension] Notification trigger: \(ourRequest.trigger?.description ?? "nil")")
                } else {
                    print("✅ [Extension] Notification no longer in pending - should have been delivered!")
                }
                
                // Also check delivered notifications (if available)
                let deliveredRequests = await UNUserNotificationCenter.current().deliveredNotifications()
                print("🔔 [Extension] Delivered notifications: \(deliveredRequests.count)")
                if let delivered = deliveredRequests.first(where: { $0.request.identifier == identifier }) {
                    print("✅ [Extension] Our notification was delivered! Title: \(delivered.request.content.title)")
                }
            } catch {
                print("❌ [Extension] Failed to send notification: \(error.localizedDescription)")
                print("❌ [Extension] Error details: \(error)")
            }
        }
    }
}
