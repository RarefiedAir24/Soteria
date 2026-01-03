# Notification Solution Implementation Guide

## Problem Summary

**Issue**: Notifications work on first trigger but stop firing after the first notification.

**Root Cause**: DeviceActivity events only fire once per monitoring interval (minimum 15 minutes). If a user opens an app twice within 15 minutes, the second open won't trigger a notification.

**Constraint**: DeviceActivity requires minimum 15-minute intervals (30-second intervals cause build errors).

## Recommended Solution: Interval-Based Notifications

### Implementation

Add proactive notifications that fire when each monitoring interval starts, ensuring users are notified even if events don't fire.

### Code Changes

#### 1. Add Notification in `intervalDidStart`

**File**: `SoteriaMonitor/DeviceActivityMonitorExtension.swift`

```swift
override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    print("🔔 [Extension] intervalDidStart FIRED!")
    
    // Send proactive notification when Quiet Hours interval starts
    // This ensures user gets notified even if events don't fire
    sendQuietHoursActiveNotification()
}

private func sendQuietHoursActiveNotification() {
    // Rate limiting: Max 1 notification per 15 minutes (interval duration)
    let lastNotification = UserDefaults.standard.double(forKey: "lastQuietHoursNotification")
    let timeSinceLastNotification = Date().timeIntervalSince1970 - lastNotification
    guard timeSinceLastNotification >= 900 else { 
        print("⏭️ [Extension] Skipping notification - sent recently (rate limiting)")
        return 
    }
    
    Task {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        guard settings.authorizationStatus == .authorized else {
            print("⚠️ [Extension] Notifications not authorized!")
            return
        }
        
        // Get active goal information for personalized message
        let goalInfo = getActiveGoalInfo()
        
        var titleText: String
        var bodyText: String
        
        if let goal = goalInfo {
            titleText = "💰 Quiet Hours Active"
            bodyText = "You have a save goal in progress: '\(goal.name)' (\(goal.progressPercent)% complete). Be mindful of your spending. Tap to reflect."
        } else {
            titleText = "🛑 Quiet Hours Active"
            bodyText = "Be mindful of your spending. Tap to reflect before shopping."
        }
        
        let content = UNMutableNotificationContent()
        content.title = titleText
        content.body = bodyText
        content.userInfo = [
            "type": "quiet_hours_active",
            "action": "show_purchase_intent_prompt"
        ]
        content.sound = .default
        
        // Time-sensitive notification (shows even when app is in foreground)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // Add deep link to open Soteria
        if let url = URL(string: "soteria://purchase-intent") {
            content.userInfo["url"] = url.absoluteString
        }
        
        let request = UNNotificationRequest(
            identifier: "quiet_hours_active_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastQuietHoursNotification")
            print("✅ [Extension] Quiet Hours active notification sent")
        } catch {
            print("❌ [Extension] Failed to send Quiet Hours notification: \(error)")
        }
    }
}
```

#### 2. Reduce Rate Limiting for Event-Based Notifications

**File**: `SoteriaMonitor/DeviceActivityMonitorExtension.swift`

```swift
// Reduce from 1.0 to 0.5 seconds to allow more frequent notifications
private let minNotificationInterval: TimeInterval = 0.5 // Reduced from 1.0
```

#### 3. Handle Notification in Main App

**File**: `soteria/SoteriaApp.swift` or `soteria/SoteriaApp.swift`

```swift
// In NotificationDelegate
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    
    if let type = userInfo["type"] as? String, type == "quiet_hours_active" {
        // Show purchase intent prompt when user taps notification
        NotificationCenter.default.post(name: NSNotification.Name("ShowPurchaseIntentPrompt"), object: nil)
    }
    
    completionHandler()
}
```

## Expected Behavior

### User Experience

1. **Quiet Hours Start (8:00 PM)**
   - Interval starts → Notification sent: "🛑 Quiet Hours Active"
   - User can tap to open Soteria and reflect

2. **User Opens Amazon (8:05 PM)**
   - Event fires → App-specific notification: "You're about to open Amazon..."
   - User can tap to open Soteria

3. **User Opens Amazon Again (8:10 PM)**
   - Event already fired → No event-based notification
   - BUT: Next interval starts at 8:15 PM → Proactive notification sent

4. **User Opens DoorDash (8:20 PM)**
   - New interval started at 8:15 PM → Event can fire
   - Event fires → App-specific notification: "You're about to open DoorDash..."

### Notification Frequency

- **Proactive**: Every 15 minutes when interval starts (maximum)
- **Event-based**: Every time app opens (if event fires)
- **Combined**: User gets notified regularly, even if events don't fire

## Testing

1. **Test Scenario 1**: Open app → Close → Reopen within 15 minutes
   - **Expected**: First open gets notification, second open doesn't (event already fired)
   - **But**: Proactive notification will appear at next interval start

2. **Test Scenario 2**: Open app → Close → Reopen after 15 minutes
   - **Expected**: Both opens get notifications (interval reset)

3. **Test Scenario 3**: Wait for interval to start
   - **Expected**: Proactive notification appears every 15 minutes

## Alternative: Re-enable Blocking

If interval-based notifications don't provide sufficient coverage, consider re-enabling blocking:

```swift
// In DeviceActivityService.swift
// Re-enable blocking
await MainActor.run {
    self.store.shield.applications = self.selectedApps.applicationTokens
}
```

**Trade-off**: More intrusive but more reliable (blocking screen always shows)

## SMS Notifications: Not Recommended

**Why SMS is not a good solution**:
- ❌ Cost: ~$0.01-0.05 per SMS (adds up quickly)
- ❌ Doesn't solve the problem: Still need DeviceActivity to detect app launches
- ❌ Delayed: 5-30 seconds (user might have already made purchase)
- ❌ Privacy: Requires phone number
- ❌ Scalability: Costs grow with usage

**Cost Example**:
- 10 notifications/day × 30 days = 300 SMS/month
- 300 × $0.01 = $3/month per user
- 1,000 users = $3,000/month
- 10,000 users = $30,000/month

**Verdict**: SMS should only be considered if DeviceActivity proves completely unreliable after implementing interval-based notifications.

