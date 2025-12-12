# 🚀 STARTUP PERFORMANCE FIX - CRITICAL CONFIGURATION

## ✅ WORKING SOLUTION (DO NOT CHANGE)

**Date:** December 12, 2025  
**Status:** ✅ WORKING - App launches in < 5 seconds  
**Commit:** After custom tab bar implementation + service optimizations

---

## 🎯 The Fix

### 1. Custom Tab Bar (Lazy Loading)
**File:** `soteria/Views/MainTabView.swift`

**CRITICAL:** Replaced `TabView` with custom `VStack` + `switch` statement to enable true lazy loading.

**Why it works:**
- `TabView` evaluates ALL children immediately (HomeView + GoalsView + SettingsView)
- Custom tab bar only creates the selected view
- Only `HomeView` is created at startup
- `GoalsView` and `SettingsView` are lazy-loaded when user switches tabs

**DO NOT:**
- ❌ Revert to `TabView` - this will bring back 60-120 second delays
- ❌ Remove the `switch` statement - this will evaluate all views
- ❌ Create all views upfront - defeats the purpose of lazy loading

**Code Pattern:**
```swift
VStack(spacing: 0) {
    // Only create selected view
    Group {
        switch selectedTab {
        case 0:
            NavigationView { HomeView() }
        case 1:
            NavigationView { 
                if shouldCreateGoalsView {
                    GoalsView()
                } else {
                    // Placeholder
                }
            }
        case 2:
            NavigationView { 
                if shouldCreateSettingsView {
                    SettingsView()
                } else {
                    // Placeholder
                }
            }
        default:
            EmptyView()
        }
    }
    
    // Custom tab bar at bottom
    CustomTabBar(selectedTab: $selectedTab)
}
```

---

### 2. Service Initialization (Non-Blocking)
**Files:** 
- `soteria/Services/QuietHoursService.swift`
- `soteria/Services/RegretRiskEngine.swift`
- `soteria/Services/DeviceActivityService.swift`

**CRITICAL:** All service initialization must be truly async and non-blocking.

#### QuietHoursService.loadSchedules()
**DO NOT:**
- ❌ Mark `loadSchedules()` as `@MainActor` - this blocks the main thread
- ❌ Use `await MainActor.run` in `init()` - this waits and blocks
- ❌ Do synchronous JSON decoding - this blocks for 20+ seconds

**DO:**
- ✅ Use `Task.detached(priority: .background)` in `init()`
- ✅ Call `loadSchedules()` directly (don't await it)
- ✅ Do JSON decoding in `Task.detached` inside `loadSchedules()`
- ✅ Only update `@Published` properties on `MainActor` after decoding

**Working Code:**
```swift
private init() {
    Task.detached(priority: .background) {
        // Don't await - just start it
        QuietHoursService.shared.loadSchedules()
    }
}

private func loadSchedules() {
    Task.detached(priority: .utility) {
        // Read UserDefaults in background
        let data = UserDefaults.standard.data(forKey: "quiet_hours_schedules")
        // Decode JSON in background
        let decoded = data.flatMap { try? JSONDecoder().decode([QuietHoursSchedule].self, from: $0) }
        // Update @Published on MainActor
        await MainActor.run {
            self.schedules = decoded ?? []
        }
    }
}
```

#### RegretRiskEngine.init()
**DO NOT:**
- ❌ Use `Task { @MainActor in }` - this blocks the main thread
- ❌ Do any synchronous work in `init()`

**DO:**
- ✅ Use `Task.detached(priority: .background)` in `init()`
- ✅ Defer all work to background tasks

**Working Code:**
```swift
private init() {
    Task.detached(priority: .background) {
        // All work deferred - no blocking
    }
}
```

---

### 3. RootView Splash Screen Timing
**File:** `soteria/SoteriaApp.swift` (RootView)

**CRITICAL:** Splash screen must show for minimum 1.5 seconds, then `MainTabView` appears.

**DO NOT:**
- ❌ Remove the 1.5-second delay - splash screen won't be visible
- ❌ Increase delay beyond 2 seconds - defeats performance improvements
- ❌ Set `isAppReady = true` immediately - no splash screen branding

**DO:**
- ✅ Show `SplashScreenView` when `isAppReady = false`
- ✅ Wait 1.5 seconds in `.task` before setting `isAppReady = true`
- ✅ This gives services time to initialize in background

**Working Code:**
```swift
.task {
    if authService.isAuthenticated {
        // Show splash screen for 1.5 seconds (branding)
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        await MainActor.run {
            isAppReady = true
        }
    }
}
```

---

### 4. HomeView Caching
**File:** `soteria/Views/HomeView.swift`

**CRITICAL:** All environment object accesses must be cached to avoid blocking during body evaluation.

**DO NOT:**
- ❌ Access `regretRiskEngine.currentRisk` directly in `body` - blocks for 2+ seconds
- ❌ Access `savingsService.totalSaved` directly in `body` - blocks for 2+ seconds
- ❌ Access any `@Published` properties synchronously in `body`

**DO:**
- ✅ Cache all values in `@State` variables
- ✅ Load cached values asynchronously in `.task` block
- ✅ Use cached values in `body` and computed properties

**Working Pattern:**
```swift
@State private var cachedRisk: RegretRiskAssessment? = nil
@State private var cachedTotalSaved: Double = 0.0
// ... more cached values

var body: some View {
    // Use cached values, not environment objects directly
    if let risk = cachedRisk {
        // Display risk
    }
}

.task {
    Task(priority: .utility) {
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        // Load values asynchronously
        cachedRisk = regretRiskEngine.currentRisk
        cachedTotalSaved = savingsService.totalSaved
        // ... more cached values
    }
}
```

---

## 📊 Performance Metrics

### Before Fix:
- ⏱️ Startup time: **60-120 seconds**
- 🐌 `TabView` evaluated all children immediately
- 🐌 `QuietHoursService.loadSchedules()` blocked for 20+ seconds
- 🐌 `RegretRiskEngine.init()` blocked for 9+ seconds
- 🐌 `HomeView.body` blocked accessing environment objects

### After Fix:
- ⚡ Startup time: **< 5 seconds**
- ✅ Only `HomeView` created at startup
- ✅ Services initialize in background (non-blocking)
- ✅ All environment object accesses cached
- ✅ Splash screen visible for 1.5 seconds

---

## 🔍 How to Verify It's Still Working

### Test Checklist:
1. ✅ App launches in < 5 seconds
2. ✅ Splash screen with logo appears for ~1.5 seconds
3. ✅ Navigation toolbar appears immediately after splash
4. ✅ HomeView loads without delay
5. ✅ No freezing or lockups during startup
6. ✅ GoalsView and SettingsView load when tabs are selected (lazy)

### Logs to Check:
```
✅ [QuietHoursService] Init started (all work deferred)
✅ [RegretRiskEngine] Init started (all work deferred)
🟢 [RootView] .task started
🟡 [RootView] App is authenticated - showing splash screen briefly
🟢 [RootView] App is ready - MainTabView will be created
🟢 [MainTabView] body evaluated, selectedTab: 0
🟢 [HomeView] body evaluated
```

**Red Flags (if you see these, something broke):**
- ❌ `QuietHoursService` taking 20+ seconds
- ❌ `RegretRiskEngine` taking 9+ seconds
- ❌ Gap of 30+ seconds between `RootView.task` and `MainTabView.body`
- ❌ `HomeView.body` taking 2+ seconds

---

## ⚠️ WARNING: Common Mistakes

### 1. Reverting to TabView
**DON'T DO THIS:**
```swift
TabView(selection: $selectedTab) {
    HomeView()  // ❌ Evaluated immediately
    GoalsView()  // ❌ Evaluated immediately
    SettingsView()  // ❌ Evaluated immediately
}
```

### 2. Making Services Blocking Again
**DON'T DO THIS:**
```swift
private init() {
    loadSchedules()  // ❌ Blocks main thread
}

@MainActor
private func loadSchedules() {
    // ❌ Synchronous JSON decoding blocks
    let data = UserDefaults.standard.data(forKey: "key")
    schedules = try! JSONDecoder().decode([Schedule].self, from: data)
}
```

### 3. Removing Splash Screen Delay
**DON'T DO THIS:**
```swift
.task {
    isAppReady = true  // ❌ No splash screen visible
}
```

### 4. Accessing Environment Objects Directly
**DON'T DO THIS:**
```swift
var body: some View {
    Text("\(regretRiskEngine.currentRisk?.riskLevel ?? 0)")  // ❌ Blocks!
}
```

---

## 🔧 If You Need to Add New Services

### Template for New Service:
```swift
class NewService: ObservableObject {
    static let shared = NewService()
    
    @Published var data: [Data] = []
    
    private init() {
        // ✅ Use Task.detached - never block
        Task.detached(priority: .background) {
            // Load data asynchronously
            await self.loadData()
        }
    }
    
    private func loadData() async {
        // ✅ Do I/O in background
        Task.detached(priority: .utility) {
            let data = UserDefaults.standard.data(forKey: "key")
            let decoded = try? JSONDecoder().decode([Data].self, from: data)
            // ✅ Update @Published on MainActor
            await MainActor.run {
                self.data = decoded ?? []
            }
        }
    }
}
```

---

## 📝 Summary

**The three critical fixes:**
1. **Custom Tab Bar** - Only creates selected view (lazy loading)
2. **Non-Blocking Services** - All initialization in background tasks
3. **Cached Environment Objects** - No synchronous access in view bodies

**DO NOT CHANGE THESE PATTERNS** - They are the foundation of fast startup performance.

---

**Last Updated:** December 12, 2025  
**Verified Working:** ✅ Yes  
**Performance:** < 5 seconds startup time

