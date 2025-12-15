# 🔍 Startup Performance Findings - December 15, 2025

## Critical Issues Identified

### 1. UI Appearance Config: 2.278s ⚠️ FIXED
- **Location:** `SoteriaApp.init()`
- **Impact:** Blocks MainActor during app initialization
- **Fix:** Moved to `DispatchQueue.main.async` to prevent blocking

### 2. 9.361s Gap Between SoteriaApp.init() and AuthService.init()
- **Location:** Between app init and service initialization
- **Likely Cause:** SwiftUI initializing `@StateObject` properties
- **Status:** This is normal - `@StateObject` properties are initialized before `init()` runs, but logging happens during `init()`

### 3. asyncAfter(0.3s) Delayed to 4.285s ⚠️ CRITICAL
- **Location:** `RootView.onAppear`
- **Impact:** MainActor is blocked, so async operations queue up
- **Fix:** Already using `DispatchQueue.main.asyncAfter` - the delay is due to MainActor saturation

### 4. AuthView.body Evaluation: 10.035s Delay ⚠️ CRITICAL
- **Location:** Between `AuthView.init()` and `AuthView.body` evaluation
- **Impact:** View rendering is blocked for 10 seconds
- **Likely Cause:** MainActor is saturated, preventing SwiftUI from evaluating the view body
- **Status:** Need to identify what's blocking MainActor during this time

### 5. Notification Sleep: 126.85s Delay ⚠️ CRITICAL - FIXED
- **Location:** `SoteriaApp.task` - `Task.sleep(1s)`
- **Impact:** Task.sleep in `.task` runs on MainActor and gets delayed
- **Fix:** Moved to `Task.detached` so sleep happens off MainActor

## Root Cause Analysis

**MainActor is completely saturated** - even simple operations like:
- `asyncAfter(0.3s)` takes 4.3s
- `Task.sleep(1s)` takes 127s
- View body evaluation is delayed by 10s

This suggests something is blocking MainActor that we're not tracking. The gaps in the timeline indicate work happening that we're not logging.

## Next Steps

1. ✅ Fixed: UI appearance config moved to async
2. ✅ Fixed: Notification setup moved to Task.detached
3. 🔍 Need to identify: What's blocking MainActor during the 10s AuthView.body delay
4. 🔍 Need to identify: What's blocking MainActor during the 9s gap

## Recommendations

1. **Add more granular logging** to track SwiftUI view rendering
2. **Profile MainActor** to see what operations are queued
3. **Consider deferring view creation** until MainActor is free
4. **Investigate SwiftUI's internal operations** that might be blocking

