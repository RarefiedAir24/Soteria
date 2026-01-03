# Notification System Analysis & Recommendations

## Current Problem

**Issue**: Notifications work on first trigger but stop firing after the first notification.

**User Flow**:
1. ✅ User sets quiet hour (e.g., 8pm-10pm)
2. ✅ User adds apps to quiet hour schedule (e.g., Amazon, DoorDash)
3. ✅ User opens Amazon at 8:30pm → **Notification fires** ✅
4. ❌ User closes Amazon and reopens at 8:35pm → **No notification** ❌
5. ❌ User opens DoorDash at 8:40pm → **No notification** ❌

## Root Cause Analysis

### DeviceActivity Framework Limitations

**The Core Issue**: DeviceActivity events are designed for **usage tracking**, not **launch detection**.

1. **One-Time Firing**: Once an event fires, it **doesn't fire again** until the monitoring interval resets
2. **Interval-Based Reset**: Events only reset when the monitoring interval restarts (currently every 2 minutes)
3. **Threshold-Based**: Events fire when app is open for 1+ second, not on launch

**Current Implementation**:
```swift
let event = DeviceActivityEvent(
    applications: [appToken],
    threshold: DateComponents(second: 1)  // Fires after 1 second of usage
)
```

**What Happens**:
- **First launch**: App opens → 1 second passes → Event fires → Notification sent ✅
- **Second launch (within 2 minutes)**: App opens → Event already fired → No event → No notification ❌
- **After 2 minutes**: Interval resets → Events can fire again → Notification sent ✅

### Current Mitigations (Not Sufficient)

1. **2-Minute Intervals**: Events reset every 2 minutes, but user might open app multiple times within 2 minutes
2. **1-Second Rate Limiting**: Prevents spam but doesn't solve the core issue
3. **eventWillReachThresholdWarning**: Fires before threshold, but still subject to one-time firing

## Solution Comparison

### ⚠️ Critical Constraint: DeviceActivity Minimum Interval

**DeviceActivity requires minimum 15-minute intervals** - shorter intervals cause build errors.

**Current Implementation**:
- Uses adaptive intervals: 15, 30, or 60 minutes (based on schedule length)
- Minimum: 15 minutes (iOS requirement)
- Maximum: ~20 schedules (iOS limit)

**This means**: Even with 15-minute intervals, if a user opens an app twice within 15 minutes, the second open won't trigger a notification.

### Option 1: Send Notification on Every Interval Start (Recommended)

**Approach**: Send notification proactively when each monitoring interval starts, not just when events fire

**Key Insight**: DeviceActivity intervals reset every 15+ minutes. When an interval starts, we can send a notification that says "Quiet Hours are active - be mindful of your spending."

**Implementation**:
1. **Send notification in `intervalDidStart`** - Every time a monitoring interval starts
2. **Include deep link** - Notification opens Soteria with purchase intent prompt
3. **Track last notification time** - Prevent spam (max 1 per 15 minutes)

**Code Changes**:
```swift
// In DeviceActivityMonitorExtension.swift
override func intervalDidStart(for activity: DeviceActivityName) {
    // Send proactive notification when interval starts
    // This ensures user gets notified even if events don't fire
    sendQuietHoursActiveNotification()
}

private func sendQuietHoursActiveNotification() {
    // Check rate limiting (max 1 per 15 minutes)
    let lastNotification = UserDefaults.standard.double(forKey: "lastQuietHoursNotification")
    let timeSinceLastNotification = Date().timeIntervalSince1970 - lastNotification
    guard timeSinceLastNotification >= 900 else { return } // 15 minutes
    
    // Send notification
    let content = UNMutableNotificationContent()
    content.title = "🛑 Quiet Hours Active"
    content.body = "Be mindful of your spending. Tap to reflect before shopping."
    content.userInfo = ["type": "quiet_hours_active"]
    
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
    
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastQuietHoursNotification")
}
```

**Pros**:
- ✅ Works every 15 minutes (when interval resets)
- ✅ No event firing limitations
- ✅ Proactive (user knows Quiet Hours are active)
- ✅ No additional costs
- ✅ Reliable

**Cons**:
- ⚠️ Not app-specific (general notification)
- ⚠️ May be too frequent (every 15 minutes)

### Option 2: Track App Launches via Extension State (Alternative)

**Approach**: Use extension state to track when apps are opened, regardless of events

**Implementation**:
1. **Monitor shield state changes** - When blocking is applied/removed
2. **Track app access attempts** - Use extension to detect when user tries to open app
3. **Send notification on every access attempt** - Not just when event fires

**Code Changes**:
```swift
// In DeviceActivityMonitorExtension.swift
override func intervalDidStart(for activity: DeviceActivityName) {
    // Clear tracking state when interval starts
    clearAppAccessTracking()
}

// Track when user tries to access blocked apps
// This happens even if events don't fire
func trackAppAccessAttempt(appIndex: Int) {
    let key = "appAccessAttempt_\(appIndex)_\(Date().timeIntervalSince1970)"
    UserDefaults.standard.set(true, forKey: key)
    
    // Send notification immediately
    sendPurchaseIntentPromptNotification(appName: getAppName(forIndex: appIndex), appIndex: appIndex)
}
```

**Pros**:
- ✅ Can detect every app launch attempt
- ✅ Works even if events don't fire
- ✅ App-specific notifications

**Cons**:
- ⚠️ Requires extension to detect access attempts
- ⚠️ May not work if extension doesn't fire
- ⚠️ More complex implementation

### Option 3: Use Blocking Screen as Primary Mechanism (Current Approach)

**Approach**: The blocking screen already shows every time - use it as the notification mechanism

**Current Flow**:
1. User opens app during quiet hours
2. DeviceActivity blocks the app → Shows blocking screen
3. User taps "Continue" → App opens + Notification sent

**Problem**: Notification only fires on first block, not subsequent blocks

**Solution**: The blocking screen IS the notification - it always shows. The issue is the in-app prompt after unblocking.

**Implementation**:
1. **Always show purchase intent prompt** when app opens after blocking
2. **Track blocking events** - Use UserDefaults to track when blocking occurred
3. **Check on app launch** - If blocking occurred recently, show prompt

**Pros**:
- ✅ Works every time (blocking screen always shows)
- ✅ No interval limitations
- ✅ Immediate (user sees blocking screen instantly)
- ✅ No additional costs
- ✅ More reliable than push notifications

**Cons**:
- ⚠️ Requires blocking to be active (user can disable)
- ⚠️ User must see blocking screen (can't be in background)

### Option 2: Track App Launches via URL Schemes (Alternative)

**Approach**: Use URL schemes to detect when apps are opened

**Implementation**:
1. Register URL schemes for monitored apps (if possible)
2. Use `UIApplicationDelegate` to detect app launches
3. Send notification when app launches during quiet hours

**Pros**:
- ✅ Can detect every launch
- ✅ No interval limitations

**Cons**:
- ❌ Not all apps support URL schemes
- ❌ Requires app to be in foreground
- ❌ Less reliable than DeviceActivity
- ❌ May not work for all apps

### Option 3: Background App Refresh + App State Monitoring (Not Recommended)

**Approach**: Use Background App Refresh to periodically check app state

**Implementation**:
1. Enable Background App Refresh
2. Periodically check which apps are in foreground
3. Send notification if monitored app is open during quiet hours

**Pros**:
- ✅ Can detect app launches

**Cons**:
- ❌ Battery drain (constant checking)
- ❌ Delayed detection (not immediate)
- ❌ Requires Background App Refresh permission
- ❌ Less reliable
- ❌ May not work if app is killed

### Option 4: SMS Notifications (Not Recommended - See Previous Analysis)

**Cost**: ~$0.01-0.05 per SMS
**Scalability**: Poor (costs grow with usage)
**Reliability**: Good, but delayed (5-30 seconds)
   
2. **Use `eventWillReachThresholdWarning` as primary trigger**
   - Fires BEFORE threshold is reached
   - More reliable than `eventDidReachThreshold`
   
3. **Clear event state manually**
   - Track which events have fired
   - Manually reset after notification is sent
   - Allows immediate re-firing

**Pros**:
- ✅ Works with existing DeviceActivity framework
- ✅ No external dependencies
- ✅ No additional costs
- ✅ Reliable and immediate
- ✅ Works offline

**Cons**:
- ⚠️ More frequent interval resets (minor overhead)
- ⚠️ Still subject to iOS limitations

**Code Changes Needed**:
```swift
// Reduce interval to 30 seconds
let intervalSchedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: startHour, minute: startMinute),
    intervalEnd: DateComponents(hour: endHour, minute: endMinute),
    repeats: true
)

// Clear event state after notification
func resetEventState(for eventName: DeviceActivityEvent.Name) {
    // Manually reset event to allow re-firing
}
```

### Option 2: SMS Notifications (Not Recommended)

**Approach**: Send SMS when app is opened during quiet hours

**Implementation**:
1. User provides phone number
2. When app opens, send SMS via Twilio/MessageBird
3. SMS contains deep link to Soteria app

**Pros**:
- ✅ Works even if app is closed
- ✅ More reliable delivery
- ✅ Can't be ignored as easily

**Cons**:
- ❌ **Cost**: ~$0.01-0.05 per SMS (adds up quickly)
- ❌ **Requires phone number**: Privacy concern, additional signup step
- ❌ **Can't detect app launches directly**: Still need DeviceActivity
- ❌ **Delayed delivery**: SMS can take 5-30 seconds
- ❌ **No immediate feedback**: User might have already made purchase
- ❌ **Requires backend service**: Twilio/MessageBird integration
- ❌ **International costs**: Higher costs for international users
- ❌ **Spam concerns**: Users might mark as spam
- ❌ **Not scalable**: Cost grows with usage

**Cost Analysis**:
- 10 notifications/day × 30 days = 300 SMS/month
- 300 × $0.01 = $3/month per user
- 1,000 users = $3,000/month
- 10,000 users = $30,000/month

**Verdict**: ❌ **Not recommended** - Too expensive and doesn't solve the core problem

### Option 3: Hybrid Approach (Best of Both Worlds)

**Approach**: Fix DeviceActivity + Add SMS as fallback

**Implementation**:
1. **Primary**: Use fixed DeviceActivity (30-second intervals)
2. **Fallback**: If DeviceActivity fails 3+ times, send SMS
3. **User choice**: Let users opt-in to SMS for critical moments

**Pros**:
- ✅ Reliable primary method (DeviceActivity)
- ✅ Fallback for critical moments (SMS)
- ✅ Cost-effective (SMS only when needed)
- ✅ User control (opt-in)

**Cons**:
- ⚠️ More complex implementation
- ⚠️ Still requires phone number for SMS

## Recommended Solution

### Option 1: Send Notification on Every Interval Start (Best for Current Constraints)

**Why This Is Best**:
1. **Works within DeviceActivity constraints** - No need for shorter intervals
2. **No additional costs** - Uses existing iOS framework
3. **Reliable** - Intervals always start, so notifications always send
4. **Privacy-friendly** - No phone number needed
5. **Scalable** - No per-notification costs

**Implementation Steps**:

1. **Send notification when interval starts**
   ```swift
   // In DeviceActivityMonitorExtension.swift
   override func intervalDidStart(for activity: DeviceActivityName) {
       super.intervalDidStart(for: activity)
       
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
           let content = UNMutableNotificationContent()
           content.title = "🛑 Quiet Hours Active"
           content.body = "Be mindful of your spending. Tap to reflect before shopping."
           content.userInfo = ["type": "quiet_hours_active", "action": "show_purchase_intent_prompt"]
           content.sound = .default
           
           // Time-sensitive notification
           if #available(iOS 15.0, *) {
               content.interruptionLevel = .timeSensitive
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

2. **Keep existing event-based notifications as backup**
   - `eventWillReachThresholdWarning` still sends notifications when events fire
   - This provides app-specific notifications when events work
   - Interval-based notifications provide general reminders when events don't fire

3. **Reduce rate limiting for event-based notifications**
   ```swift
   // Current: 1 second rate limit
   // Reduce to 0.5 seconds to allow more frequent notifications
   private let minNotificationInterval: TimeInterval = 0.5 // Reduced from 1.0
   ```

**User Experience**:
- **Every 15 minutes**: User gets "Quiet Hours Active" notification (proactive reminder)
- **When app opens**: User gets app-specific notification (if event fires)
- **Result**: User is always aware of Quiet Hours, even if events don't fire

### Option 2: Use Blocking + Track Unblock Events (Alternative)

**Approach**: Use blocking screen as primary mechanism, track when user unblocks

**Implementation**:
1. **Enable blocking** - Set `shield.applications` to block apps
2. **Track unblock events** - When user taps "Continue" on blocking screen
3. **Send notification on unblock** - Every time user unblocks, send notification

**Code Changes**:
```swift
// In DeviceActivityService.swift
// Re-enable blocking
await MainActor.run {
    self.store.shield.applications = self.selectedApps.applicationTokens
}

// In DeviceActivityMonitorExtension.swift
// Track when user unblocks (eventDidReachThreshold fires when user taps through)
override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    // User tapped through blocking screen - send notification
    sendPurchaseIntentPromptNotification(...)
}
```

**Pros**:
- ✅ Blocking screen always shows (reliable)
- ✅ User can't ignore (must interact with blocking screen)
- ✅ Works every time

**Cons**:
- ⚠️ Requires blocking (user can disable)
- ⚠️ Overrides Screen Time settings
- ⚠️ More intrusive

## Testing Plan

1. **Test Scenario 1**: Open app → Close → Reopen within 30 seconds
   - **Expected**: Notification should fire on both opens
   
2. **Test Scenario 2**: Open app → Close → Reopen after 30 seconds
   - **Expected**: Notification should fire on both opens (interval reset)
   
3. **Test Scenario 3**: Rapid open/close (within 0.5 seconds)
   - **Expected**: Rate limiting prevents spam, but legitimate opens still get notifications

## Cost Comparison

| Solution | Setup Cost | Per Notification | Monthly (300 notifications) | Scalability |
|----------|-----------|------------------|----------------------------|-------------|
| **DeviceActivity (Fixed)** | $0 | $0 | $0 | ✅ Excellent |
| **SMS (Twilio)** | $0 | $0.01-0.05 | $3-15 | ❌ Poor |
| **Hybrid** | $0 | $0-0.05 | $0-15 | ⚠️ Moderate |

## Recommendation

**✅ Fix DeviceActivity Implementation (Option 1)**

**Reasons**:
1. Solves the problem without additional costs
2. Immediate delivery (better UX than SMS)
3. No privacy concerns (no phone number needed)
4. Scalable to millions of users
5. Works offline

**SMS should only be considered if**:
- DeviceActivity proves unreliable after fixes
- Users explicitly request SMS as an option
- You have budget for SMS costs
- You need guaranteed delivery (SMS is more reliable than push)

## Next Steps

### Recommended: Implement Interval-Based Notifications

1. **Add notification in `intervalDidStart`** - Send proactive notification every 15 minutes when Quiet Hours interval starts
2. **Keep existing event-based notifications** - As backup for app-specific notifications
3. **Reduce rate limiting** - From 1 second to 0.5 seconds for event-based notifications
4. **Test thoroughly** - Verify notifications appear every 15 minutes and when apps open
5. **Monitor performance** - Track notification delivery rates

### Alternative: Re-enable Blocking (If Notifications Aren't Enough)

If interval-based notifications don't provide sufficient coverage:

1. **Re-enable blocking** - Set `shield.applications` to block apps
2. **Track unblock events** - Every time user taps through blocking screen, send notification
3. **Always show prompt** - When app opens after unblock, show purchase intent prompt

**Trade-off**: More intrusive but more reliable

## Alternative: Background App Refresh + URL Scheme

If DeviceActivity continues to be unreliable, consider:
- Use Background App Refresh to check app usage periodically
- Use URL schemes to detect when apps are opened
- Less reliable but might work as fallback

**However, this is not recommended** as it's less reliable than DeviceActivity and requires more battery usage.

