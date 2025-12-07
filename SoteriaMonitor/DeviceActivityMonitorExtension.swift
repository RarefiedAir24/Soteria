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
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("🔔 [Extension] ════════════════════════════════════════")
        print("🔔 [Extension] intervalDidStart FIRED!")
        print("🔔 [Extension] Activity: \(activity)")
        print("🔔 [Extension] Current time: \(Date())")
        print("🔔 [Extension] ════════════════════════════════════════")
        
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
        // This fires BEFORE the app opens - this is our chance to intercept!
        print("🔔 [Extension] Blocking screen appeared - intercepting BEFORE app launch")
        
        // Store which app was attempted (we'll use this to open it later)
        // Note: We can't get the exact app from the event, but we can store a flag
        // The main app will try to open the first selected app
        UserDefaults.standard.set(true, forKey: "shouldShowPurchaseIntentPrompt")
        UserDefaults.standard.set(true, forKey: "shouldOpenTargetAppAfterPrompt")
        print("✅ [Extension] Set shouldShowPurchaseIntentPrompt flag")
        print("✅ [Extension] Set shouldOpenTargetAppAfterPrompt flag")
        
        // Send notification that will open SOTERIA immediately
        // This notification should appear and when tapped, opens SOTERIA with the prompt
        sendPurchaseIntentPromptNotification()
        
        // Also try to open SOTERIA directly via URL scheme (if possible from extension)
        // Note: Extensions can't directly open apps, but we can try via notification
        Task {
            // Send a critical notification that opens SOTERIA
            let content = UNMutableNotificationContent()
            content.title = "🛑 SOTERIA Moment"
            content.body = "Is this a planned purchase or impulse?"
            content.userInfo = [
                "type": "purchase_intent_prompt",
                "url": "soteria://purchase-intent"
            ]
            content.sound = .default
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .critical // Critical notifications can interrupt
                content.relevanceScore = 1.0
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: "soteria_intercept_\(UUID().uuidString)", content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ [Extension] Critical notification sent to open SOTERIA")
            } catch {
                print("❌ [Extension] Failed to send critical notification: \(error)")
            }
        }
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("🔔 [Extension] ════════════════════════════════════════")
        print("🔔 [Extension] eventDidReachThreshold FIRED!")
        print("🔔 [Extension] Event: \(event)")
        print("🔔 [Extension] Activity: \(activity)")
        print("🔔 [Extension] User tapped through blocking screen - app opened")
        print("🔔 [Extension] ════════════════════════════════════════")
        
        // Track that shopping app was opened
        recordShoppingSessionStart()
        
        // Set flag so SOTERIA shows prompt when it becomes active
        UserDefaults.standard.set(true, forKey: "shouldShowPurchaseIntentPrompt")
        print("✅ [Extension] Set shouldShowPurchaseIntentPrompt flag")
        
        // Send purchase intent prompt notification
        sendPurchaseIntentPromptNotification()
        
        // Also try to open SOTERIA directly via URL scheme
        if let url = URL(string: "soteria://purchase-intent") {
            // Post notification to open SOTERIA
            NotificationCenter.default.post(name: NSNotification.Name("OpenSOTERIA"), object: nil, userInfo: ["url": url.absoluteString])
            print("✅ [Extension] Posted notification to open SOTERIA")
        }
    }
    
    // Send notification to show purchase intent prompt
    private func sendPurchaseIntentPromptNotification() {
        print("🔔 [Extension] Sending purchase intent prompt notification...")
        
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            guard settings.authorizationStatus == .authorized else {
                print("⚠️ [Extension] Notifications not authorized!")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Purchase Intent"
            content.body = "Is this a planned purchase or impulse?"
            content.userInfo = ["type": "purchase_intent_prompt"]
            content.sound = .default
            
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
                content.relevanceScore = 1.0
            }
            
            // Add URL to open SOTERIA
            if let url = URL(string: "soteria://purchase-intent") {
                content.userInfo["url"] = url.absoluteString
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: "purchase_intent_\(UUID().uuidString)", content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ [Extension] Purchase intent prompt notification sent")
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
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "🛑 SOTERIA Moment"
            content.body = "You're about to open a shopping app. Take a moment to pause and think."
            content.categoryIdentifier = "SOTERIA_MOMENT"
            content.userInfo = ["type": "soteria_moment"]
            content.badge = 1
            
            // Make notification as prominent as possible
            if #available(iOS 15.0, *) {
                // Use timeSensitive interruption level - this should show even when user is in another app
                content.interruptionLevel = .timeSensitive
                // Set maximum relevance score to make it most likely to show
                content.relevanceScore = 1.0
            }
            
            // Set thread identifier to group related notifications
            content.threadIdentifier = "soteria_moment"
            
            // Use the default sound - for time-sensitive notifications, this should be prominent
            // Note: Time-sensitive notifications can play sounds even when device is on silent
            content.sound = UNNotificationSound.default
            
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
