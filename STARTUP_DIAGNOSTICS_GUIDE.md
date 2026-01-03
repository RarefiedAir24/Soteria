# 🔍 Startup Diagnostics Guide

## Overview
Comprehensive diagnostic logging has been added to track app startup performance and identify bottlenecks causing the 2-minute launch delay.

## What Was Added

### 1. StartupDiagnostics System
- **Location**: `soteria/Utilities/StartupDiagnostics.swift`
- **Purpose**: Centralized logging system that tracks:
  - Service initialization times
  - View initialization times
  - MainActor blocking operations
  - Timeline of all startup events

### 2. Instrumentation Points

#### SoteriaApp
- `init()` - Tracks app initialization
- `body` evaluation - Tracks when SwiftUI evaluates the app body
- `WindowGroup` creation - Tracks window creation
- `.task` modifier - Tracks notification setup
- UI appearance configuration

#### AuthService
- `init()` - Tracks service initialization
- UserDefaults reads - Tracks token cache access
- Token validation - Tracks token expiration checks

#### RootView
- `init()` - Tracks view initialization
- `body` evaluation - Tracks when body is evaluated
- AuthService property access - Tracks @Published property reads
- `onAppear` - Tracks when view appears
- `asyncAfter` blocks - Tracks delayed operations

#### MainTabView
- `init()` - Tracks view initialization
- `body` evaluation - Tracks body evaluation
- Service access (GoalsService, DeviceActivityService, etc.) - Tracks singleton access times
- HomeViewWrapper creation - Tracks home view creation

#### HomeViewWrapper & HomeView
- `init()` - Tracks view initialization
- `body` evaluation - Tracks body evaluation
- HomeView creation - Tracks home view instantiation

## How to Use

### 1. Run the App
Launch the app and watch the console output. All diagnostic messages are prefixed with `⏱️ [timestamp]`.

### 2. Look for These Patterns

#### Slow Service Initialization
```
⚠️ [Service] ServiceName.init() took X.XXXs (SLOW)
```
**Action**: Check if the service is doing synchronous work in `init()`

#### MainActor Blocking
```
🔴 [MainActor] BLOCKED for X.XXXs during: OperationName
```
**Action**: Move the operation off MainActor or defer it

#### Large Time Gaps
The summary will show gaps >0.1s between events:
```
⚠️ SLOW OPERATIONS (>0.1s):
  Gap of X.XXXs before: EventName
```
**Action**: Investigate what's happening during that gap

#### Slow View Creation
```
⚠️ [View] ViewName.init() took X.XXXs (SLOW)
```
**Action**: Check if the view is accessing services or doing work in `init()`

#### Slow Service Access
```
⚠️ [MainTabView] ServiceName.shared access took X.XXXs
```
**Action**: The singleton initialization is blocking - check the service's `init()`

### 3. Automatic Summary
After 5 seconds, a comprehensive summary is automatically printed showing:
- Total startup time
- Complete timeline of events
- All slow operations (>0.1s)
- Time gaps between events

## Expected Output Format

```
⏱️ [0.000s] 🚀 [StartupDiagnostics] App launch started [Main]
⏱️ [0.001s] 🔍 [SoteriaApp] init() started [Main]
⏱️ [0.002s] 🔍 [AuthService] init() started [Main]
⏱️ [0.003s] ✅ [Service] AuthService.init() completed (fast) [Main]
⏱️ [0.004s] ✅ [Service] SoteriaApp.init() completed (fast) [Main]
...
⏱️ [5.000s] 📊 STARTUP DIAGNOSTICS SUMMARY
================================================================================
Total startup time: 5.000s

Timeline:
[   0.000s] 🚀 [StartupDiagnostics] App launch started [Main]
[   0.001s] 🔍 [SoteriaApp] init() started [Main]
...

⚠️ SLOW OPERATIONS (>0.1s):
  Gap of 2.500s before: [RootView] body evaluation started
...
```

## Common Issues to Look For

### 1. Service Initialization Chain
If you see multiple services being accessed in sequence with delays:
```
⚠️ [MainTabView] DeviceActivityService.shared access took 1.234s
⚠️ [MainTabView] QuietHoursService.shared access took 0.567s
```
**Problem**: Services are initializing each other, creating a blocking chain
**Fix**: Make service dependencies lazy or remove them

### 2. MainActor Saturation
If you see many MainActor blocking messages:
```
🔴 [MainActor] BLOCKED for 0.500s during: Operation1
🔴 [MainActor] BLOCKED for 0.300s during: Operation2
```
**Problem**: Too many operations queuing on MainActor
**Fix**: Move operations to background threads

### 3. View Recreation
If you see the same view being initialized multiple times:
```
🔍 [HomeView] init() started
🔍 [HomeView] init() started  // Again!
```
**Problem**: Views are being recreated unnecessarily
**Fix**: Use stable view IDs or prevent unnecessary state changes

### 4. Synchronous Work in init()
If service init() takes a long time:
```
⚠️ [Service] ServiceName.init() took 2.500s (SLOW)
```
**Problem**: Service is doing synchronous work (UserDefaults, JSON decode, etc.)
**Fix**: Defer all work to Task.detached

## Next Steps

1. **Run the app** and capture the full diagnostic output
2. **Identify the largest time gaps** in the summary
3. **Check which operations are blocking MainActor**
4. **Review service initialization times** - any >0.1s is suspicious
5. **Look for patterns** - repeated slow operations indicate systemic issues

## Files Modified

- `soteria/SoteriaApp.swift` - Added diagnostics to app initialization
- `soteria/Services/AuthService.swift` - Added diagnostics to service init
- `soteria/Views/MainTabView.swift` - Added diagnostics to view creation
- `soteria/Views/HomeViewWrapper.swift` - Added diagnostics
- `soteria/Views/HomeView.swift` - Added diagnostics
- `soteria/Utilities/StartupDiagnostics.swift` - New diagnostic system

