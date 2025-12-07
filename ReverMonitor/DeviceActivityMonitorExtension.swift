//
//  DeviceActivityMonitorExtension.swift
//  ReverMonitor
//
//  Created by Frank Schioppa on 12/6/25.
//

import DeviceActivity
import ManagedSettings
import UserNotifications

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("🔔 [Extension] intervalDidStart for activity: \(activity)")
        // Note: intervalDidStart fires when the monitoring schedule starts (e.g., at midnight)
        // NOT when a monitored app is opened. We should NOT send notifications here.
        // Only eventDidReachThreshold should trigger notifications.
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("🔔 [Extension] intervalDidEnd for activity: \(activity)")
        // Monitoring ended
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("🔔 [Extension] eventDidReachThreshold - Event: \(event), Activity: \(activity)")
        print("🔔 [Extension] Sending SOTERIA Moment notification...")
        // Event threshold reached - send notification
        sendSoteriaMomentNotification()
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
        // This fires BEFORE the threshold - we can use this to block the app
        // and show our intervention BEFORE the app fully opens
        blockAppAndNotify()
    }
    
    private func blockAppAndNotify() {
        // The app should already be blocked by ManagedSettings (set in DeviceActivityService)
        // When user tries to open a blocked app, iOS shows a blocking screen
        // We send a notification here that should be more visible since the app is blocked
        // The notification will open SOTERIA when tapped
        print("⚠️ [Extension] App is about to open - sending notification to open SOTERIA")
        sendSoteriaMomentNotification()
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
