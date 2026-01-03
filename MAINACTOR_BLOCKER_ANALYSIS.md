# 🔴 MainActor Blocker Analysis - 155 Second Delay

## The Problem
**155.930 second gap** between `SplashScreenView.onAppear` (4.303s) and `SoteriaApp.init()` logging (160.232s).

## Critical Finding
The `SoteriaApp.init()` logging is **deferred to 60 seconds**, so the actual `init()` is being called much earlier. The 160s timestamp is when the deferred logging runs, not when `init()` actually runs.

## What's Actually Running on MainActor

### 1. Service Initialization Chain ⚠️ **SUSPECT #1**
When SwiftUI creates `@StateObject` or accesses `@EnvironmentObject`, it triggers service initialization:

**Services accessed during startup:**
- `AuthService` (via `@StateObject` in `SoteriaApp`)
- `SubscriptionService.shared` (accessed by `AuthService.startInitialization()`)
- `CognitoAuthService.shared` (lazy in `AuthService`, but might be accessed)
- `GoalsService.shared` (if accessed by any view)
- `OnboardingSurveyService.shared` (if accessed by any view)
- `SavingsReminderService.shared` (if accessed by any view)
- `PlaidService.shared` (if accessed by any view)
- `DeviceActivityService.shared` (if accessed by any view)

**Each service's `init()` does:**
- `SubscriptionService.init()`: UserDefaults reads (synchronous, MainActor)
- `GoalsService.init()`: Calls `StartupDiagnostics.shared.logServiceAccess()` (synchronous, MainActor)
- `OnboardingSurveyService.init()`: Calls `loadSurveyData()` → UserDefaults reads (synchronous, MainActor)
- `SavingsReminderService.init()`: Calls `loadSettings()` → UserDefaults reads (synchronous, MainActor)

### 2. SwiftUI View Hierarchy Creation ⚠️ **SUSPECT #2**
When `RootView.body` is evaluated, SwiftUI needs to:
- Create all child views
- Inject `@EnvironmentObject` properties
- Evaluate view bodies
- Access service properties

**If any view accesses a service property synchronously, it blocks MainActor.**

### 3. UserDefaults Reads ⚠️ **SUSPECT #3**
**87 UserDefaults reads** across 31 files. While individual reads are fast (< 1ms), if they're all happening synchronously on MainActor during startup, they could add up.

### 4. StartupDiagnostics Logging ⚠️ **SUSPECT #4**
Every service initialization calls `StartupDiagnostics.shared.logServiceAccess()`, which:
- Creates Date objects
- Calls `DispatchQueue.main.async` (but if MainActor is blocked, these queue up)
- Accesses UserDefaults for logging

## Root Cause Hypothesis

**The 155-second delay is likely caused by:**
1. **Service initialization chain** - When `AuthService` is created, it might trigger access to other services
2. **SwiftUI view evaluation** - When `RootView.body` is evaluated, it might access services synchronously
3. **UserDefaults saturation** - 87 UserDefaults reads happening synchronously on MainActor
4. **StartupDiagnostics overhead** - Logging itself might be contributing to blocking

## Solution

1. **Make ALL service initialization completely lazy** - Don't access `.shared` until absolutely needed
2. **Remove ALL UserDefaults reads from `init()`** - Defer to `onAppear` or background task
3. **Remove ALL logging from `init()`** - Defer to 60+ seconds after startup
4. **Make service property access async** - Use computed properties that return cached values initially

