# Quiet Hours Schedules Not Loading - Fix Applied

## Issue
Quiet Hours schedules were not appearing after app rebuild/launch, showing "No Quiet Hours Set" even though schedules were saved in UserDefaults.

## Root Cause
1. **QuietHoursService.init()** does nothing on startup (to prevent startup delays)
2. **Schedules are lazy-loaded** - only loaded when `ensureSchedulesLoaded()` is called
3. **QuietHoursView** never called `ensureSchedulesLoaded()` in `.onAppear`
4. **SettingsView** displays status but schedules weren't loaded, so it always showed "Inactive"

## Solution Applied (Option 1)
Added `ensureSchedulesLoaded()` calls to:
1. **QuietHoursView.onAppear** - Loads schedules when user opens Quiet Hours view
2. **SettingsView.task** - Loads schedules when Settings view appears (needed for status display)

## Files Modified
1. `soteria/Views/QuietHoursView.swift` - Line ~186
2. `soteria/Views/SettingsView.swift` - Line ~603

## How to Revert
If this fix causes any issues, remove the following lines:

### QuietHoursView.swift
Remove this line from `.onAppear`:
```swift
quietHoursService.ensureSchedulesLoaded()
```

### SettingsView.swift
Remove this block from `.task`:
```swift
// OPTION 1 FIX: Load schedules on-demand when SettingsView appears
// ... (entire comment block)
quietHoursService.ensureSchedulesLoaded()
```

## Why This Fix Works
- **Zero startup impact**: Schedules only load when views appear (lazy loading)
- **On-demand loading**: Data loads exactly when needed
- **No blocking**: `loadSchedules()` runs in background Task.detached
- **Preserves optimization**: Still maintains the startup performance improvements

## Alternative Solutions (Not Implemented)

### Option 2: Load on app launch with delay
Add to `QuietHoursService.init()`:
```swift
Task.detached(priority: .background) {
    try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
    await MainActor.run {
        self.loadSchedules()
    }
}
```
**Pros**: Schedules available even if view not opened  
**Cons**: Background task runs even if user never opens Quiet Hours

### Option 3: Load synchronously on init
Add to `QuietHoursService.init()`:
```swift
loadSchedules() // But make it synchronous and fast
```
**Pros**: Schedules always available  
**Cons**: Could block startup if JSON decode is slow

## Testing
1. Create a Quiet Hours schedule
2. Close and rebuild app
3. Open Settings → Should show "Active" if schedule is enabled
4. Open Quiet Hours view → Should show your schedule(s)
5. Verify schedules persist across app restarts

## Status
✅ **FIXED** - Schedules now load when views appear  
✅ **NO STARTUP IMPACT** - Still maintains lazy loading optimization  
✅ **REVERTIBLE** - Clear comments mark the fix for easy removal

