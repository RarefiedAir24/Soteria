# CRITICAL: Startup Delay Fix

## Problem

The app is experiencing 26-59 second delays on startup. The logs show:
- `QuietHoursService.loadSchedules()` taking 59 seconds
- JSON decode taking 21.6 seconds
- `RootView.task` taking 26+ seconds

## Root Cause

The `Task.detached` in `QuietHoursService.init()` is somehow blocking, even though we're not awaiting `loadSchedules()`. The JSON decode is taking 21+ seconds and blocking the background task.

## Solution

**CRITICAL FIX NEEDED:**

1. **QuietHoursService.init()** - The `Task.detached` must return immediately
2. **loadSchedules()** - JSON decode must be in a separate, lower-priority task
3. **RootView.task** - Must not wait for any service initialization

## Immediate Action

The JSON decode is the bottleneck. We need to:
1. Defer JSON decode even more (30+ seconds after startup)
2. Or make it truly fire-and-forget
3. Or load schedules on-demand instead of at startup

## Quick Fix

**Option 1: Defer loadSchedules() significantly**
```swift
private init() {
    // Don't load schedules at all during init
    // Load them on-demand when first accessed
}
```

**Option 2: Make JSON decode truly non-blocking**
```swift
private func loadSchedules() {
    Task.detached(priority: .background) {
        // Wait 30+ seconds before loading
        try? await Task.sleep(nanoseconds: 30_000_000_000)
        // Then load...
    }
}
```

**Option 3: Load on-demand**
```swift
private var _schedules: [QuietHoursSchedule] = []
var schedules: [QuietHoursSchedule] {
    if _schedules.isEmpty {
        loadSchedules() // Load on first access
    }
    return _schedules
}
```

## Current Status

- ❌ `QuietHoursService.init()` taking 59 seconds
- ❌ JSON decode taking 21.6 seconds
- ❌ `RootView.task` taking 26+ seconds
- ❌ App stuck on splash screen

## Expected After Fix

- ✅ `QuietHoursService.init()` completes in < 0.1 seconds
- ✅ JSON decode happens 30+ seconds after startup (or on-demand)
- ✅ `RootView.task` completes in ~1.5 seconds (just splash screen delay)
- ✅ App loads in < 5 seconds

