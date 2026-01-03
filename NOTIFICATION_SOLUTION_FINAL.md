# Final Notification Solution: App Launch Detection Without DeviceActivity Events

## The Core Problem

**DeviceActivity Framework Limitations**:
- Events only fire **once per monitoring interval** (minimum 15 minutes)
- `eventWillReachThresholdWarning` also only fires once per interval
- Cannot use shorter intervals (minimum 15 minutes required)
- Blocking conflicts with system Screen Time settings

**User Requirement**:
- Notifications should fire **every time** user opens an app during Quiet Hours
- Notifications should be **app-specific** (not generic reminders)
- No unnecessary notifications (not every 15 minutes)

## The Real Solution: Track App Launches via Extension State

### Key Insight

Even though DeviceActivity events only fire once per interval, the **extension can detect app access attempts** through other means:

1. **Shield State Changes** - When blocking is applied/removed
2. **Interval State** - Track when intervals start/end
3. **UserDefaults Flags** - Set flags when apps are accessed

### Recommended Approach: Use Extension to Track Every App Access

**Implementation Strategy**:

1. **Track app access attempts in extension** - Not just when events fire
2. **Use UserDefaults to communicate** - Extension sets flags, main app checks
3. **Send notification on every access** - Not just when events fire

## Implementation

### Step 1: Track App Access in Extension (Even Without Events)

**File**: `SoteriaMonitor/DeviceActivityMonitorExtension.swift`

```swift
// Track app access attempts using a different mechanism
// This works even if events don't fire

override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    
    // Clear access tracking when interval starts
    // This allows tracking new accesses in the new interval
    clearAppAccessTracking()
}

// New method: Track app access attempts
// This is called whenever we detect an app might be accessed
private func trackAppAccessAttempt(appIndex: Int, appName: String) {
    let key = "appAccessAttempt_\(appIndex)"
    let lastAccessTime = UserDefaults.standard.double(forKey: key)
    let timeSinceLastAccess = Date().timeIntervalSince1970 - lastAccessTime
    
    // Rate limiting: Max 1 notification per 30 seconds per app
    guard timeSinceLastAccess >= 30 else {
        print("⏭️ [Extension] Skipping notification - sent recently for app \(appIndex)")
        return
    }
    
    // Send notification
    sendPurchaseIntentPromptNotification(appName: appName, appIndex: appIndex)
    
    // Update last access time
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: key)
}

private func clearAppAccessTracking() {
    // Clear all app access tracking when interval starts
    // This allows notifications to fire again in the new interval
    let appCount = UserDefaults.standard.integer(forKey: "selectedAppsCount")
    for i in 0..<appCount {
        UserDefaults.standard.removeObject(forKey: "appAccessAttempt_\(i)")
    }
}
```

### Step 2: Use Background Monitoring to Detect App Launches

**Problem**: Extension only runs when DeviceActivity events fire, which is once per interval.

**Solution**: Use a combination of approaches:

1. **DeviceActivity Events** (when they fire) - Primary detection
2. **Background App Refresh** (if enabled) - Periodic checks
3. **App State Monitoring** - When Soteria app becomes active

**File**: `soteria/Services/DeviceActivityService.swift`

```swift
// Monitor for app launches using Background App Refresh
func startBackgroundAppMonitoring() {
    // Check every 10 seconds if a monitored app is in foreground
    // This works even if DeviceActivity events don't fire
    Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
        self?.checkForMonitoredAppInForeground()
    }
}

private func checkForMonitoredAppInForeground() {
    // Check if Quiet Hours are active
    guard quietHoursService.isQuietModeActive else { return }
    
    // Check if any monitored app might be in foreground
    // We can't directly detect this, but we can check UserDefaults flags
    // set by the extension or use other heuristics
    
    // Check for recent app access flags
    let appCount = UserDefaults.standard.integer(forKey: "selectedAppsCount")
    for i in 0..<appCount {
        if let lastAccess = UserDefaults.standard.object(forKey: "appLastAccess_\(i)") as? Date {
            let timeSinceAccess = Date().timeIntervalSince(lastAccess)
            // If app was accessed recently (within last 30 seconds), send notification
            if timeSinceAccess < 30 && timeSinceAccess > 5 {
                // App was accessed - send notification
                let appName = getAppName(forIndex: i)
                sendAppAccessNotification(appName: appName, appIndex: i)
            }
        }
    }
}
```

### Step 3: Alternative - Use URL Schemes (Limited)

**Approach**: Some apps support URL schemes that can be used to detect launches

**Limitations**:
- Not all apps support URL schemes
- Requires app to register URL scheme
- Less reliable

**Not Recommended** - Too limited

## Best Solution: Improve Extension Detection

### The Real Fix: Make Extension Detect Every App Access

**Key Insight**: The extension runs in a separate process and can detect app access attempts even if events don't fire.

**Implementation**:

1. **Use `intervalDidStart` to reset tracking** - Clear flags when interval starts
2. **Track app access in `eventWillReachThresholdWarning`** - This fires BEFORE threshold
3. **Also track in `eventDidReachThreshold`** - Backup method
4. **Use UserDefaults to persist state** - Track which apps were accessed

**Code**:

```swift
// In DeviceActivityMonitorExtension.swift

// Track which apps have been accessed in current interval
private var accessedAppsInCurrentInterval: Set<Int> = []

override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    
    // Clear tracking when interval starts - allows notifications again
    accessedAppsInCurrentInterval.removeAll()
    print("🔄 [Extension] Interval started - cleared app access tracking")
}

override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventWillReachThresholdWarning(event, activity: activity)
    
    // Extract app index
    let appIndex = extractAppIndex(from: event)
    let appName = getAppName(forIndex: appIndex)
    
    // Check if we've already sent notification for this app in this interval
    // If not, send notification
    if !accessedAppsInCurrentInterval.contains(appIndex) {
        sendPurchaseIntentPromptNotification(appName: appName, appIndex: appIndex)
        accessedAppsInCurrentInterval.insert(appIndex)
    } else {
        print("⏭️ [Extension] Already sent notification for app \(appIndex) in this interval")
    }
}
```

**Problem**: This still only works when events fire, which is once per interval.

## The Actual Solution: Accept the Limitation or Use Blocking

### Reality Check

**iOS doesn't provide a reliable way to detect app launches without**:
1. DeviceActivity events (once per interval)
2. Blocking screen (conflicts with system settings)
3. Background App Refresh (requires permission, battery drain, delayed)

### Recommended: Re-enable Blocking with Better Conflict Handling

**Approach**: Re-enable blocking but handle Screen Time conflicts gracefully

**Implementation**:

1. **Check for existing restrictions** before applying blocking
2. **Warn user** if conflicts exist
3. **Allow user to choose** - Use Soteria blocking or keep system settings
4. **Track unblock events** - Every time user taps through, send notification

**Code**:

```swift
// In DeviceActivityService.swift
func updateBlockingStatus() async {
    // Check for existing restrictions
    let hasExisting = hasExistingRestrictions()
    
    if hasExisting {
        // Warn user about conflict
        print("⚠️ [DeviceActivityService] Existing Screen Time restrictions detected")
        // Could show alert to user asking if they want to override
    }
    
    // Apply blocking
    await MainActor.run {
        if quietHoursService.isQuietModeActive && isMonitoring {
            self.store.shield.applications = self.selectedApps.applicationTokens
        } else {
            self.store.shield.applications = nil
        }
    }
}
```

**Pros**:
- ✅ Blocking screen always shows (reliable)
- ✅ Can track every unblock event
- ✅ Works every time

**Cons**:
- ⚠️ Conflicts with system Screen Time
- ⚠️ More intrusive
- ⚠️ User can disable

### Alternative: Accept 15-Minute Limitation

**Reality**: With DeviceActivity's 15-minute minimum interval, notifications can only fire once per 15 minutes per app.

**User Experience**:
- First app open in 15-minute window → Notification ✅
- Second app open in same window → No notification ❌
- After 15 minutes → Notification can fire again ✅

**This might be acceptable** if:
- Users don't open apps multiple times within 15 minutes frequently
- The notification is effective enough on first trigger
- Users understand the limitation

## Final Recommendation

### Option 1: Re-enable Blocking (Most Reliable)

**Why**: Blocking screen always shows, can track every access attempt

**Implementation**:
1. Re-enable `shield.applications`
2. Handle Screen Time conflicts gracefully
3. Track unblock events to send notifications
4. Show purchase intent prompt when app opens after unblock

**Trade-off**: More intrusive but most reliable

### Option 2: Accept 15-Minute Limitation (Current Approach)

**Why**: Works within iOS constraints, no conflicts

**Implementation**:
1. Keep current DeviceActivity event-based notifications
2. Accept that notifications only fire once per 15 minutes
3. Improve notification content to maximize effectiveness
4. Add fallback detection when app becomes active

**Trade-off**: Less reliable but less intrusive

### Option 3: Hybrid Approach

**Why**: Best of both worlds

**Implementation**:
1. Use DeviceActivity events when they fire (app-specific)
2. Add Background App Refresh to periodically check (if enabled)
3. Show prompt when Soteria app becomes active during Quiet Hours
4. Accept that perfect detection isn't possible

**Trade-off**: Moderate reliability, moderate intrusiveness

## SMS: Still Not Recommended

SMS doesn't solve the detection problem - you still need to detect app launches, which has the same limitations.

**Cost**: ~$0.01-0.05 per SMS
**Reliability**: Good delivery, but still delayed (5-30 seconds)
**Detection**: Still requires DeviceActivity or blocking

**Verdict**: Only consider if all other options fail and you have budget for SMS costs.

