# 🔍 Startup Performance Analysis - December 15, 2025

## Current Issue
**12.28 second delay** before app becomes interactive, even though we only wait 0.5 seconds.

## Root Cause
The `.task` modifier runs on MainActor. When MainActor is blocked, even `Task.sleep` is delayed. The 12-second delay means MainActor is saturated for ~11.78 seconds.

## What's Blocking MainActor

### 1. Notification Authorization (Async, but callback on MainActor)
- `UNUserNotificationCenter.current().requestAuthorization()` 
- Callback runs on MainActor
- **Impact:** Minor, but adds to MainActor queue

### 2. Service Initialization Chain
Even though services are "deferred", accessing `.shared` during view creation can trigger initialization:
- `AuthService` - Fast (sync token check only)
- `CognitoAuthService.shared` - Fast (just prints)
- Other services accessed via `.shared` - Should be lazy, but might trigger init()

### 3. View Recreation
- `AuthView` is being initialized **3 times** during startup
- `RootView` is being recreated
- Each recreation triggers environment object injection

### 4. SwiftUI View Update Queue
When `isAppReady = true` is set, SwiftUI needs to:
- Re-evaluate `RootView.body`
- Create `AuthView` struct
- Inject `@EnvironmentObject` (authService)
- Render the view

If MainActor is busy, these operations queue up.

## Solution

### Immediate Fix
1. **Move wait completely off MainActor** - Use `Task.detached` for the entire wait
2. **Add timeout** - Don't wait forever if MainActor is blocked
3. **Set state asynchronously** - Use `DispatchQueue.main.async` to update state

### Long-term Optimization
1. **Prevent view recreation** - Use stable view IDs
2. **Lazy service access** - Don't access services until needed
3. **Defer notification setup** - Already done, but verify it's not blocking

## Expected Result
- Splash screen shows immediately
- Wait happens off MainActor (0.5s actual wait, not delayed)
- UI appears in ~0.5-1 second total
- App is interactive immediately

