# 🚀 NEW FEATURES PERFORMANCE GUIDE

## ✅ CRITICAL: All New Features Must Follow Fast-Loading Patterns

**Date:** December 13, 2025  
**Status:** ✅ ACTIVE - All new features must comply

---

## 🎯 Core Principles

1. **Never block MainActor during startup** - All work must be deferred or run in background tasks
2. **Never access @Published properties synchronously during startup** - Use async access or caching
3. **Never do network calls during startup** - Defer all API calls until after app is fully loaded
4. **Never do heavy computation during init()** - All service initialization must return immediately

---

## 📋 Checklist for New Features

### ✅ Service Initialization
- [ ] Service `init()` returns immediately (< 0.1 seconds)
- [ ] All heavy work is deferred to `Task.detached(priority: .background)`
- [ ] No synchronous I/O (UserDefaults, file system, network)
- [ ] No synchronous JSON encoding/decoding
- [ ] `@Published` properties are only updated on MainActor after async work completes

### ✅ View Lifecycle
- [ ] `.task` blocks complete quickly (< 2 seconds)
- [ ] No synchronous access to `@Published` properties in `body`
- [ ] All environment object access is cached in `@State` variables
- [ ] Heavy data loading happens in `.task` with delays or background tasks

### ✅ Network Calls
- [ ] All API calls are deferred (30+ seconds after startup or on-demand)
- [ ] Network calls use `Task.detached` with appropriate priority
- [ ] Timeouts are set (10 seconds max)
- [ ] Errors are handled gracefully without blocking UI

### ✅ Property Access
- [ ] `@Published` properties are accessed asynchronously when possible
- [ ] Computed properties that do work are cached or made async
- [ ] Property observers (`didSet`) don't do blocking work
- [ ] All property access in `body` uses cached values

---

## 🔍 Features Added Today (December 13, 2025)

### 1. Backend Token Mapping for App Names
**Status:** ✅ COMPLIANT
- `autoNameAppsFromBackend()` is **disabled** during startup (commented out in `selectedApps.didSet`)
- Will run on-demand or 30+ seconds after startup
- Network calls use `Task.detached` with proper error handling

### 2. App-Specific Notifications
**Status:** ✅ COMPLIANT
- Notification logic runs in `DeviceActivityMonitorExtension` (separate process)
- No blocking operations in main app
- Uses time-sensitive notifications (non-blocking)

### 3. Purchase Intent Prompt Detection
**Status:** ✅ FIXED
- `checkForPurchaseIntentPrompt()` now accesses `@Published` properties asynchronously
- Wrapped in `Task { @MainActor in }` to avoid blocking
- Called from `Task.detached` in `.onAppear` (not during startup)
- Has startup guard (skips checks during first 3 seconds)

### 4. QuietHoursService Schedule Loading
**Status:** ✅ COMPLIANT
- `loadSchedules()` is deferred 30 seconds after startup
- JSON decode happens in `Task.detached(priority: .background)`
- `@Published` properties updated on MainActor after decode completes

---

## ⚠️ Common Mistakes to Avoid

### ❌ DON'T: Access @Published Properties Synchronously
```swift
// BAD - Blocks if property triggers work
let schedules = quietHoursService.schedules
```

```swift
// GOOD - Access asynchronously
Task { @MainActor in
    let schedules = self.quietHoursService.schedules
    // Use schedules here
}
```

### ❌ DON'T: Do Network Calls in init()
```swift
// BAD - Blocks startup
private init() {
    Task {
        let data = try await fetchData() // Blocks!
    }
}
```

```swift
// GOOD - Defer network calls
private init() {
    Task.detached(priority: .background) {
        try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
        let data = try await fetchData() // After app is loaded
    }
}
```

### ❌ DON'T: Do Heavy Work in didSet
```swift
// BAD - Blocks when property changes
@Published var selectedApps: FamilyActivitySelection {
    didSet {
        autoNameApps() // Blocks!
    }
}
```

```swift
// GOOD - Defer to background task
@Published var selectedApps: FamilyActivitySelection {
    didSet {
        Task.detached(priority: .utility) {
            await self.autoNameApps() // Non-blocking
        }
    }
}
```

---

## 📊 Performance Targets

- **App Startup:** < 5 seconds (splash screen to main view)
- **Service Init:** < 0.1 seconds per service
- **View Body Evaluation:** < 0.1 seconds
- **Network Calls:** Deferred 30+ seconds or on-demand
- **Heavy Computation:** Always in background tasks

---

## 🔧 Testing Checklist

Before committing new features, verify:
1. ✅ App launches in < 5 seconds
2. ✅ No freezing or lockups during startup
3. ✅ Splash screen appears for ~1.5 seconds
4. ✅ Navigation toolbar appears immediately
5. ✅ No warnings about "Publishing changes from background threads"
6. ✅ No synchronous property access in view bodies
7. ✅ All network calls are deferred or on-demand

---

## 📝 Summary

All new features added today (December 13, 2025) have been reviewed and updated to follow fast-loading patterns:

1. ✅ Backend token mapping - Disabled during startup
2. ✅ App-specific notifications - Runs in separate process
3. ✅ Purchase intent prompt - Accesses properties asynchronously
4. ✅ Schedule loading - Deferred 30 seconds

**All features are now compliant with the fast-loading architecture.**

---

**Last Updated:** December 13, 2025  
**Status:** ✅ All features compliant

