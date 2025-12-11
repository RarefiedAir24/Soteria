# Logging Guide for Debugging Lockups

## Overview
I've added comprehensive logging throughout the app to identify what's causing the lockups. All logs include timestamps and duration measurements.

## Log Format

### Color Coding
- 🟢 **Green**: View lifecycle events (onAppear, body evaluation, task start/end)
- 🟡 **Yellow**: Background operations and async tasks
- ✅ **Green Check**: Service initialization
- ⚠️ **Warning**: Potential blocking operations

### Log Structure
```
[Component] Message at Timestamp (duration if applicable)
```

## What's Being Logged

### 1. View Lifecycle
- **RootView**: When body is evaluated, onAppear, task start/end
- **MainTabView**: onAppear, task start/end
- **HomeView**: When body is evaluated, onAppear, task start/end, all async operations
- **SettingsView**: When body is evaluated, onAppear, task start/end, **CRITICAL: selectedApps.applicationTokens.count access timing**

### 2. DeviceActivityService
- Service initialization start
- Background task start
- Each sleep operation (with duration)
- Critical data loading (loadSelection, loadMonitoringState, loadAppNamesMapping) - **each with timing**
- Heavy data loading (loadUnblockEvents, loadAppUsageSessions)
- Service initialization completion (total time)

### 3. HomeView Metrics Loading
- Task start
- Sleep operations
- getUnblockMetrics() call (with timing)
- getBehavioralPatterns() call (with timing)
- UI state updates

### 4. SettingsView Critical Operation
- **⚠️ BLOCKING OPERATION DETECTED**: When accessing `selectedApps.applicationTokens.count` takes > 0.1 seconds
- Full timing breakdown of the access operation

## How to Use the Logs

### Step 1: Run the App
1. Build and run the app
2. Open Xcode Console (View → Debug Area → Activate Console, or ⇧⌘C)
3. Watch the logs as the app loads

### Step 2: Identify the Lockup
Look for these patterns:

#### Pattern 1: Long Gap Between Logs
```
🟢 [HomeView] body evaluated at 2025-01-10 10:00:00
[LONG GAP - NO LOGS FOR 2+ MINUTES]
🟢 [HomeView] onAppear at 2025-01-10 10:02:15
```
**This indicates**: Something is blocking between body evaluation and onAppear.

#### Pattern 2: Blocking Operation Warning
```
🟡 [SettingsView] ⚠️ ACCESSING selectedApps.applicationTokens.count at 2025-01-10 10:00:00
[LONG GAP]
🟡 [SettingsView] ⚠️⚠️⚠️ BLOCKING OPERATION DETECTED: 120.5s
```
**This indicates**: The FamilyActivitySelection property access is blocking.

#### Pattern 3: Slow Service Operation
```
🟡 [DeviceActivityService] loadSelection() starting at 2025-01-10 10:00:00
[LONG GAP]
🟡 [DeviceActivityService] loadSelection() completed at 2025-01-10 10:02:00 (took 120.0s)
```
**This indicates**: A specific service operation is blocking.

#### Pattern 4: Body Evaluation Loop
```
🟢 [HomeView] body evaluated at 2025-01-10 10:00:00
🟢 [HomeView] body evaluated at 2025-01-10 10:00:01
🟢 [HomeView] body evaluated at 2025-01-10 10:00:02
[Repeating rapidly]
```
**This indicates**: The view is re-rendering continuously, possibly due to a state change loop.

### Step 3: Find the Last Log Before Lockup
1. Note the timestamp of the last log before the lockup
2. Identify which component was running
3. Check the duration of that operation

### Step 4: Share the Logs
When reporting the issue, share:
1. **The last 20-30 log lines** before the lockup
2. **Any log lines with "BLOCKING OPERATION DETECTED"**
3. **Any operations that took > 1 second** (these are suspicious)

## Expected Log Flow

### Normal App Launch
```
✅ [App] Starting initialization at ...
✅ [App] SoteriaApp init completed (total: 0.08s)
✅ [DeviceActivityService] Init started at ...
🟢 [RootView] body evaluated at ...
🟢 [RootView] onAppear at ...
🟢 [RootView] .task started at ...
🟢 [MainTabView] onAppear at ...
🟢 [HomeView] body evaluated at ...
🟢 [HomeView] onAppear at ...
🟢 [HomeView] .task started at ...
🟡 [DeviceActivityService] Background task started at ...
[Background operations continue...]
```

### If Lockup Occurs
The logs will show exactly where it stops, for example:
```
🟢 [HomeView] body evaluated at 10:00:00
[NO MORE LOGS FOR 2 MINUTES]
```

## Key Operations to Watch

1. **SettingsView.selectedApps.applicationTokens.count access** - This is the most likely culprit
2. **DeviceActivityService.loadSelection()** - Accesses FamilyActivitySelection
3. **DeviceActivityService.loadAppNamesMapping()** - JSON decoding
4. **HomeView.getBehavioralPatterns()** - Processes unblockEvents array

## Next Steps After Identifying the Issue

Once you identify which operation is blocking:
1. Share the specific log lines showing the blocking operation
2. I'll add additional fixes to make that operation truly async
3. We'll test again and verify the fix

