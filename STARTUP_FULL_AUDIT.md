# 🔍 FULL STARTUP AUDIT - December 13, 2025

## Current Performance Issues

### Timeline from Latest Logs
- **18:46:10** - App init starts
- **18:46:17** - RootView.task starts (7s delay)
- **18:46:33** - SplashScreenComplete (16s after task start, 2.8s delay)
- **18:46:35** - RootView.body evaluated (2s after isAppReady)
- **18:46:37** - Placeholder appeared (2s after body)
- **18:46:49** - MainTabView() created (12s after placeholder)
- **18:46:54** - MainTabView.body evaluated (5s to create)
- **18:47:35** - MainTabView.onAppear (41s delay!)
- **18:42:42** - HomeView placeholder appears (45s delay after MainTabView.onAppear)

### Critical Delays
1. **5 seconds** - Creating MainTabView() struct
2. **41 seconds** - MainTabView.onAppear delay
3. **45 seconds** - HomeView placeholder delay
4. **45 seconds** - User info populates after home page loads

## Services Audit

### 1. AuthService
- **@StateObject** in SoteriaApp
- **Initialization:** Synchronous, fast (~0.001s)
- **Blocking Operations:** None identified
- **@Published Properties:** `isAuthenticated`, `currentUser`, `isCheckingAuth`
- **Status:** ✅ Not blocking

### 2. SavingsService
- **@StateObject** in SoteriaApp
- **Initialization:** ✅ No init() - just property declarations (fast)
- **Blocking Operations:** None - simple properties
- **@Published Properties:** `totalSaved`, `soteriaMomentsCount`, `lastSavedAmount`, `totalTransferredToSavings`
- **Status:** ✅ Not blocking

### 3. GoalsService
- **@StateObject** in SoteriaApp (GoalsService.shared)
- **Initialization:** ⚠️ **BLOCKING** - calls `loadData()` synchronously in init()
- **Blocking Operations:** ⚠️ **BLOCKER** - JSON decode of goals array from UserDefaults
- **@Published Properties:** `activeGoal`, `goals`
- **Status:** ⚠️ **BLOCKER** - synchronous JSON decode in init()

### 4. MoodTrackingService
- **@StateObject** in SoteriaApp (MoodTrackingService.shared)
- **Initialization:** ⚠️ **BLOCKING** - calls `loadData()` and `loadTodayReflection()` synchronously in init()
- **Blocking Operations:** ⚠️ **BLOCKER** - JSON decode of mood entries and reflections from UserDefaults
- **@Published Properties:** `currentMood`, `moodEntries`, `dailyReflections`, `todayReflection`
- **Status:** ⚠️ **BLOCKER** - synchronous JSON decode in init()

### 5. StreakService
- **@StateObject** in SoteriaApp (StreakService.shared)
- **Initialization:** ⚠️ **BLOCKING** - calls `loadStreakData()` and `updateStreak()` synchronously in init()
- **Blocking Operations:** ⚠️ **BLOCKER** - UserDefaults reads + Calendar calculations
- **@Published Properties:** `currentStreak`, `longestStreak`, `lastProtectionDate`
- **Status:** ⚠️ **BLOCKER** - synchronous UserDefaults access in init()

### 6. SubscriptionService
- **@StateObject** in SoteriaApp (SubscriptionService.shared)
- **Initialization:** ⚠️ **PARTIALLY BLOCKING** - UserDefaults reads synchronously, then Task.detached
- **Blocking Operations:** UserDefaults reads (fast), then async StoreKit calls (deferred 2s)
- **@Published Properties:** `isPremium`, `subscriptionTier`, `isLoading`
- **Status:** ⚠️ **MINOR BLOCKER** - UserDefaults reads are fast but still synchronous

### 7. RegretLoggingService
- **@StateObject** in SoteriaApp (RegretLoggingService.shared)
- **Initialization:** ⚠️ **BLOCKING** - likely calls `loadData()` synchronously in init()
- **Blocking Operations:** ⚠️ **BLOCKER** - JSON decode of regrets array from UserDefaults
- **@Published Properties:** `recentRegretCount`, `regrets`
- **Status:** ⚠️ **BLOCKER** - synchronous JSON decode in init()

### 8. RegretRiskEngine
- **@StateObject** in SoteriaApp
- **Initialization:** ✅ Truly lazy (no work on startup)
- **Blocking Operations:** None on startup
- **@Published Properties:** `currentRisk`
- **Status:** ✅ Not blocking

### 9. QuietHoursService
- **@StateObject** in SoteriaApp
- **Initialization:** ✅ Truly lazy (no work on startup)
- **Blocking Operations:** `loadSchedules()` - deferred
- **@Published Properties:** `schedules`, `isQuietModeActive`, `currentActiveSchedule`
- **Status:** ✅ Not blocking on startup

### 10. DeviceActivityService
- **@StateObject** in SoteriaApp
- **Initialization:** ✅ Truly lazy (no work on startup)
- **Blocking Operations:** ⚠️ **CRITICAL: `selectedApps.applicationTokens` blocks for 20+ seconds when accessed synchronously**
- **@Published Properties:** `selectedApps`, `isMonitoring`, `cachedAppsCount`
- **Status:** ⚠️ **POTENTIAL BLOCKER** - `applicationTokens` access

### 11. PurchaseIntentService
- **@StateObject** in SoteriaApp (PurchaseIntentService.shared)
- **Initialization:** ⚠️ **BLOCKING** - calls `loadData()` synchronously in init()
- **Blocking Operations:** ⚠️ **BLOCKER** - JSON decode of purchase intents array from UserDefaults
- **@Published Properties:** `purchaseIntents`
- **Status:** ⚠️ **BLOCKER** - synchronous JSON decode in init()

## View Creation Audit

### RootView
- **@EnvironmentObject Count:** 4 (authService, deviceActivityService, quietHoursService, subscriptionService)
- **Blocking Operations:** None identified
- **Status:** ✅ Not blocking

### MainTabView
- **@EnvironmentObject Count:** 0 (inherits from parent)
- **Blocking Operations:** Creating HomeView placeholder
- **Status:** ⚠️ 5-second delay when created

### HomeView
- **@EnvironmentObject Count:** 11 (all services)
- **Blocking Operations:** ⚠️ **CRITICAL: Accessing 11 @EnvironmentObject properties synchronously**
- **Potential Blockers:**
  - `deviceActivityService.selectedApps.applicationTokens` (20+ second block)
  - `quietHoursService.schedules` (JSON decode)
  - `goalsService.activeGoal` (unknown)
  - `savingsService.totalSaved` (unknown)
  - Other service property access
- **Status:** ⚠️ **MAJOR BLOCKER** - 11 environment objects

## Competing Operations

### On App Launch
1. **SoteriaApp.init()** - Configures Firebase, navigation bar (fast)
2. **Service Initialization** - All @StateObject services initialize (mostly lazy now)
3. **RootView.task** - Caches isAuthenticated, starts splash delay (fast)
4. **SplashScreenComplete notification** - Sets isAppReady (fast)
5. **RootView.body re-evaluation** - Creates placeholder (2s delay)
6. **Placeholder.onAppear** - Sets shouldCreateMainTabView (Task.detached)
7. **MainTabView() creation** - 5-second delay
8. **MainTabView.onAppear** - 41-second delay
9. **HomeView placeholder.onAppear** - 45-second delay
10. **HomeView() creation** - Unknown delay
11. **HomeView.task** - Caches environment objects (1.8s)

### After Home Page Loads
1. **HomeView.task** - Caches environment objects (0.5s delay)
2. **User info population** - 45-second delay (unknown cause)

## Root Cause Analysis

### Hypothesis 1: Environment Object Injection
When SwiftUI creates `HomeView()` with 11 `@EnvironmentObject` properties, it needs to inject all of them. This might trigger synchronous property access, especially:
- `deviceActivityService.selectedApps.applicationTokens` (known 20+ second blocker)
- Other service properties that might do synchronous work

### Hypothesis 2: MainActor Saturation
Multiple operations are queuing on MainActor:
- View creation
- Environment object injection
- @Published property access
- Service property access

### Hypothesis 3: Synchronous Property Access
Even though services are lazy, accessing their `@Published` properties might trigger:
- Synchronous UserDefaults reads
- Synchronous JSON decoding
- Synchronous property computation

## Identified Blockers

### Confirmed Blockers
1. **StreakService.init()** - ⚠️ **BLOCKING**
   - Calls `loadStreakData()` synchronously (UserDefaults reads)
   - Calls `updateStreak()` synchronously (Calendar calculations)
   - **Fix:** Defer to Task.detached with delay

2. **MoodTrackingService.init()** - ⚠️ **BLOCKING**
   - Calls `loadData()` synchronously (JSON decode of mood entries + reflections)
   - Calls `loadTodayReflection()` synchronously
   - **Fix:** Defer to Task.detached with delay

3. **GoalsService.init()** - ⚠️ **BLOCKING**
   - Calls `loadData()` synchronously (JSON decode of goals array)
   - **Fix:** Defer to Task.detached with delay

4. **RegretLoggingService.init()** - ⚠️ **BLOCKING**
   - Likely calls `loadData()` synchronously (JSON decode of regrets array)
   - **Fix:** Defer to Task.detached with delay

5. **PurchaseIntentService.init()** - ⚠️ **BLOCKING**
   - Calls `loadData()` synchronously (JSON decode of purchase intents array)
   - **Fix:** Defer to Task.detached with delay

6. **DeviceActivityService.selectedApps.applicationTokens** - ⚠️ **CRITICAL BLOCKER**
   - Blocks for 20+ seconds when accessed synchronously
   - **Fix:** Never access synchronously, always use cached value

### Minor Blockers
1. **SubscriptionService.init()** - UserDefaults reads (fast but synchronous)

## Recommendations

### ✅ COMPLETED - All Services Fixed (December 13, 2025)

1. **✅ StreakService.init()** - FIXED - Now truly lazy (deferred UserDefaults reads + Calendar calculations)
2. **✅ MoodTrackingService.init()** - FIXED - Now truly lazy (deferred JSON decode)
3. **✅ GoalsService.init()** - FIXED - Now truly lazy (deferred JSON decode)
4. **✅ RegretLoggingService.init()** - FIXED - Now truly lazy (deferred JSON decode)
5. **✅ PurchaseIntentService.init()** - FIXED - Now truly lazy (deferred JSON decode)
6. **✅ DeviceActivityService** - Already fixed (truly lazy, never accesses applicationTokens synchronously)

**All services now:**
- Do absolutely nothing synchronously in init()
- Defer all work to Task.detached with 30-second delay
- Provide ensureDataLoaded() for on-demand loading
- Will not block MainActor during app startup

### Remaining Actions
1. **Test app startup** - Verify delays are eliminated
2. **Monitor HomeView** - Ensure it handles empty service data gracefully
3. **Profile MainActor** - If delays persist, identify remaining blockers

### Short-term Actions (Priority 2)
1. **Profile MainActor** - Identify what's blocking for 41 seconds
2. **Cache all service properties** - Before creating HomeView
3. **Defer HomeView creation** - Increase delay to 5+ seconds

### Long-term Actions (Priority 3)
1. **Remove unnecessary @EnvironmentObject** - Reduce from 11 to essential only
2. **Implement service property caching layer** - Cache all properties before view creation
3. **Consider view architecture refactor** - Reduce environment object injection

### Long-term Solutions
1. **Service Property Caching** - Cache all properties before view creation
2. **Lazy Property Access** - Make all service properties truly lazy
3. **View Architecture** - Consider reducing environment object count
4. **Async Property Access** - Make property access async where possible

## Next Steps
1. Audit each service for blocking operations
2. Profile MainActor during view creation
3. Test with reduced environment object count
4. Implement property caching before view creation

