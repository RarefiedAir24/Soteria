# 🔍 Startup Delay Diagnosis

## Current Issue
14-second delay between `isAppReady = true` and `RootView.body` re-evaluation.

## Timeline from Logs
- `isAppReady = true` set at 18:16:05
- `RootView.body` evaluated at 18:16:17 (12 seconds later)
- `MainTabView.body` evaluated at 18:16:20 (3 seconds after that)
- `MainTabView.onAppear` at 18:16:57 (37 seconds after MainTabView.body)

## Root Cause Hypothesis
MainActor is blocked for 14 seconds after `isAppReady = true` is set, preventing SwiftUI from re-evaluating `RootView.body`.

## Possible Causes
1. **Environment Object Injection** - When creating `MainTabView()`, SwiftUI needs to inject 11 `@EnvironmentObject` properties. Even if services are lazy, the injection itself might be blocking.

2. **SwiftUI View Update Queue** - SwiftUI queues view updates on MainActor. If MainActor is busy, updates can't be processed.

3. **Service Property Access** - Even though services are lazy, accessing them as `@EnvironmentObject` might trigger synchronous work.

## Next Steps
1. Add detailed logging to see exactly when MainTabView() is created
2. Check if environment object injection is blocking
3. Consider making MainTabView creation even more lazy (only create when placeholder appears)

## Streamlined Tasks Summary
**Removed:**
- Purchase intent checks (3 tasks)
- QuietHoursService auto-load
- DeviceActivityService auto-load  
- RegretRiskEngine Task.detached

**Remaining:**
- Splash screen delay (1.5s) - Required
- Auth state check - Required

**Result:** Only 2 essential tasks on startup, but still 14-second delay suggests something else is blocking.

