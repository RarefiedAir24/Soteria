# Notification/Banner System Analysis & Enhancement Plan

## Current Issue

**Problem**: Notifications only appear on the **first** app launch, not on subsequent launches.

**User Experience**:
1. ✅ User selects Amazon app and turns on monitoring
2. ✅ User closes Soteria and opens Amazon → **Banner appears** (no app logo)
3. ✅ Clicking banner opens Soteria
4. ❌ User closes Amazon and reopens it → **No banner appears**

## Root Cause Analysis

### DeviceActivity Event Behavior

DeviceActivity events are designed for **usage tracking**, not **launch detection**:

1. **Event Threshold**: Events fire when app is open for **1 second** (threshold)
2. **One-Time Firing**: Once an event fires, it **doesn't fire again** until the monitoring interval resets
3. **Interval Reset**: Events only reset when the monitoring interval restarts (could be hours later)

**Current Code**:
```swift
let event = DeviceActivityEvent(
    applications: [appToken],
    threshold: DateComponents(second: 1)  // Fires after 1 second
)
```

**What Happens**:
- First launch: App opens → 1 second passes → Event fires → Notification sent ✅
- Second launch: App opens → Event already fired → No event → No notification ❌

### Rate Limiting

There's also a 5-second rate limit that prevents notifications:
```swift
private let minNotificationInterval: TimeInterval = 5.0 // 5 seconds between notifications
```

This is too aggressive for detecting every app launch.

## Solutions

### Solution 1: Shorter Monitoring Intervals (Recommended)

**Approach**: Use shorter monitoring intervals that reset more frequently, allowing events to fire again.

**Implementation**:
- Instead of one long interval (e.g., 8pm-10pm), use multiple short intervals (e.g., every 5 minutes)
- When interval resets, events can fire again
- This allows notifications on every app launch

**Pros**:
- ✅ Works with existing DeviceActivity system
- ✅ No major code changes
- ✅ Reliable

**Cons**:
- ⚠️ More frequent interval resets (minor overhead)
- ⚠️ Events reset every interval (but that's what we want)

### Solution 2: Remove Rate Limiting for App Launches

**Approach**: Keep rate limiting but make it smarter - only limit if the same app opens within a very short time (spam prevention).

**Implementation**:
- Reduce rate limit from 5 seconds to 1-2 seconds
- Only prevent notifications if the **same app** opens within the limit
- Allow notifications for different app launches

**Pros**:
- ✅ Simple change
- ✅ Prevents spam while allowing legitimate notifications

**Cons**:
- ⚠️ Still limited by DeviceActivity event behavior (main issue)

### Solution 3: Combine with App State Monitoring

**Approach**: Use DeviceActivity for initial detection, then monitor app state changes to detect subsequent launches.

**Implementation**:
- DeviceActivity detects first launch
- Extension monitors when app goes to background/foreground
- Detect when app comes to foreground again → send notification

**Pros**:
- ✅ Works for every app launch
- ✅ More reliable

**Cons**:
- ⚠️ More complex
- ⚠️ Requires additional monitoring logic

### Solution 4: Use Notification Categories with Actions

**Approach**: Send notifications that don't rely solely on DeviceActivity events.

**Implementation**:
- Use background app refresh or other mechanisms
- Send notifications based on app state changes
- Use notification actions for better UX

**Pros**:
- ✅ More control
- ✅ Better UX

**Cons**:
- ⚠️ Requires significant changes
- ⚠️ May not work reliably in background

## Recommended Solution: Hybrid Approach

### Phase 1: Immediate Fixes (Quick Wins)

1. **Reduce Rate Limiting**:
   - Change from 5 seconds to 1 second
   - Only limit if same app opens within 1 second (spam prevention)

2. **Add App Logo to Notifications**:
   - Use `UNNotificationAttachment` to add app icon
   - Load app icon from system or cache

3. **Improve Notification Timing**:
   - Use `eventWillReachThresholdWarning` more aggressively
   - Ensure notifications are sent immediately (0.1s delay)

### Phase 2: Enhanced Detection (Better Solution)

1. **Shorter Monitoring Intervals**:
   - Break long intervals into 5-minute chunks
   - Events reset every 5 minutes, allowing them to fire again
   - This enables notifications on every app launch

2. **Smart Event Reset**:
   - When app closes, mark event as "available" again
   - Use UserDefaults to track app state
   - Reset events when app goes to background

### Phase 3: Advanced Features (Future)

1. **App Logo in Notifications**:
   - Cache app icons when apps are selected
   - Include icon in notification content
   - Use `UNNotificationAttachment`

2. **Better Notification Content**:
   - Show app name prominently
   - Include goal progress if available
   - Add quick actions (e.g., "Save Instead", "Continue Shopping")

## Implementation Priority

1. **High Priority**: Reduce rate limiting + Add app logo
2. **Medium Priority**: Shorter monitoring intervals
3. **Low Priority**: Advanced notification features

## Technical Details

### Current Rate Limiting Code
```swift
private let minNotificationInterval: TimeInterval = 5.0 // Too long!
```

**Change to**:
```swift
private let minNotificationInterval: TimeInterval = 1.0 // 1 second - prevents spam but allows legitimate notifications
```

### Current Event Threshold
```swift
threshold: DateComponents(second: 1)  // Minimum is 1 second
```

**This is already optimal** - can't go lower.

### Monitoring Interval Reset
Events reset when `intervalDidStart` is called. If we use shorter intervals, events reset more frequently.

## Next Steps

1. ✅ Analyze current system (this document)
2. ⏳ Implement Phase 1 fixes (rate limiting + app logo)
3. ⏳ Test with shorter monitoring intervals
4. ⏳ Implement Phase 2 if needed
5. ⏳ Add advanced features (Phase 3)

