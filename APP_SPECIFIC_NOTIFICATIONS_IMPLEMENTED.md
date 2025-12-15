# App-Specific Notifications Implementation ✅

## What Was Implemented

### 1. **Separate Events Per App** ✅
- **Before**: One `DeviceActivityEvent` monitored all apps
- **After**: One event per app (e.g., `soteria.moment.0`, `soteria.moment.1`)
- **Benefit**: Event name contains app index → we can identify which app was opened

### 2. **App Name Extraction** ✅
- Extension extracts app index from event name (`soteria.moment.0` → index `0`)
- Uses internal app naming system (`getAppName(forIndex:)`)
- Loads app names from shared `UserDefaults` (`appNamesMapping`)

### 3. **App-Specific Notification Messages** ✅
- **Food apps** (Uber Eats, DoorDash): "Take a moment before ordering on [App Name]"
- **Shopping apps** (Amazon, eBay): "Take a moment before shopping on [App Name]"
- Uses user-provided app names from your naming system

### 4. **Time-Sensitive Notifications** ✅
- Added entitlement: `com.apple.developer.usernotifications.time-sensitive`
- Updated authorization to request `.timeSensitive` permission
- Notifications show as banners even when user is in another app

### 5. **Removed Hard Blocking** ✅
- Set `shield.applications = nil` (no blocking)
- Prevents Screen Time conflicts
- Uses notifications instead of blocking

## How It Works

### Example: User with 3 Apps

**Setup:**
- App 0: "Amazon" (user named it)
- App 1: "Uber Eats" (user named it)
- App 2: "DoorDash" (user named it)

**Events Created:**
```swift
"soteria.moment.0" → [Amazon only]
"soteria.moment.1" → [Uber Eats only]
"soteria.moment.2" → [DoorDash only]
```

**User Opens Uber Eats:**
1. Event `soteria.moment.1` fires
2. Extension extracts index: `1`
3. Gets app name: `"Uber Eats"`
4. Sends notification: **"Take a moment before ordering on Uber Eats"**

## Code Changes

### DeviceActivityService.swift
- Creates separate events per app index
- Event names: `"soteria.moment.{index}"`
- Removed blocking (`shield.applications = nil`)

### DeviceActivityMonitorExtension.swift
- Extracts app index from event name
- `getAppName(forIndex:)` helper function
- App-specific notification messages
- Time-sensitive interruption level

### Entitlements
- Added `com.apple.developer.usernotifications.time-sensitive` to both:
  - `soteria/soteria.entitlements`
  - `SoteriaMonitor/SoteriaMonitor.entitlements`

### SoteriaApp.swift
- Updated notification authorization to request `.timeSensitive` permission

## Testing Checklist

- [ ] Create Quiet Hours schedule
- [ ] Add multiple apps (e.g., Amazon, Uber Eats)
- [ ] Name apps using App Naming feature
- [ ] Enable Quiet Hours
- [ ] Open Amazon → Should see: "Take a moment before shopping on Amazon"
- [ ] Open Uber Eats → Should see: "Take a moment before ordering on Uber Eats"
- [ ] Verify notifications show as banners in-app (time-sensitive)
- [ ] Verify no blocking screen appears (apps open normally)
- [ ] Verify notifications deep link to Soteria when tapped

## User Experience

### Before
- Hard blocking screen (Apple's restricted screen)
- No app identification
- Generic notification: "Take a moment to reflect"
- Screen Time conflicts

### After
- ✅ Apps open normally (no blocking)
- ✅ App-specific notifications: "Take a moment before shopping on Amazon"
- ✅ Uses user-provided app names
- ✅ No Screen Time conflicts
- ✅ Time-sensitive banners show in-app

## Next Steps

1. **Test with multiple apps** to verify app-specific notifications work
2. **User onboarding**: Guide users to enable time-sensitive notifications in Settings
3. **Monitor**: Check logs to ensure app index extraction works correctly
4. **Iterate**: Adjust notification messages based on user feedback

## Notes

- App names are loaded from `UserDefaults` key: `"appNamesMapping"`
- Event name format: `"soteria.moment.{index}"` where index is 0-based
- If app name not found, falls back to: `"App {index + 1}"`
- Time-sensitive notifications require iOS 15+
- User must enable time-sensitive notifications in Settings → Soteria → Notifications

