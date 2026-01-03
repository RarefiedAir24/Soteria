# Persistence Confirmation: Quiet Hours, App Selection, and Monitoring Status

## Summary

✅ **Quiet Hours Schedules**: Persist across app restarts and signout/signin  
✅ **Monitoring Status**: Persists across app restarts and signout/signin  
⚠️ **Selected Apps**: Persist across app restarts, but system-managed (may vary)

---

## 1. Quiet Hours Schedules

### Storage Location
- **UserDefaults key**: `"quiet_hours_schedules"`
- **Format**: JSON-encoded array of `QuietHoursSchedule` objects
- **Service**: `QuietHoursService.swift`

### Persistence Behavior

#### ✅ App Restarts
- **Saved**: Automatically when schedules are added/updated/deleted via `saveSchedules()`
- **Loaded**: On-demand when `ensureSchedulesLoaded()` is called (in QuietHoursView or SettingsView)
- **Status**: ✅ **PERSISTS** - Schedules are saved to UserDefaults and loaded on app restart

#### ✅ Signout/Signin
- **Signout behavior**: `signOut()` only clears auth tokens (`cognito_user_id`, `cognito_user_email`, `cognito_id_token`, `cognito_refresh_token`)
- **UserDefaults NOT cleared**: Quiet Hours schedules remain in UserDefaults
- **Status**: ✅ **PERSISTS** - Schedules remain after signout and are available after signin

### Code References
- **Save**: `QuietHoursService.saveSchedules()` → `UserDefaults.standard.set(encoded, forKey: "quiet_hours_schedules")`
- **Load**: `QuietHoursService.loadSchedules()` → `UserDefaults.standard.data(forKey: "quiet_hours_schedules")`
- **Signout**: `CognitoAuthService.signOut()` → Only calls `clearTokens()` (doesn't clear schedules)

---

## 2. Selected Apps (FamilyActivitySelection)

### Storage Location
- **System-managed**: `FamilyActivitySelection` is managed by iOS, not stored in UserDefaults
- **Service**: `DeviceActivityService.swift`
- **Cached count**: `UserDefaults` key `"cachedSelectedAppsCount"` (for UI display only)

### Persistence Behavior

#### ✅ App Restarts
- **System persistence**: iOS automatically persists `FamilyActivitySelection` across app restarts
- **Restoration**: When `FamilyActivityPicker` opens, it automatically shows the previous selection
- **Status**: ✅ **PERSISTS** - System manages persistence automatically

#### ⚠️ Signout/Signin
- **System behavior**: `FamilyActivitySelection` is tied to the device, not the user account
- **Expected behavior**: Should persist across signout/signin (system-managed)
- **Status**: ⚠️ **LIKELY PERSISTS** - System-managed, but behavior may vary by iOS version

### Code References
- **System-managed**: `selectedApps: FamilyActivitySelection` - iOS handles persistence
- **Note**: Cannot be manually encoded/decoded from UserDefaults (system limitation)
- **Restoration**: Automatic when `FamilyActivityPicker` opens

---

## 3. Monitoring Status

### Storage Location
- **UserDefaults key**: `"isMonitoringActive"`
- **Service**: `DeviceActivityService.swift`

### Persistence Behavior

#### ✅ App Restarts
- **Saved**: Automatically when `isMonitoring` changes via `didSet` → `saveMonitoringState()`
- **Loaded**: On app launch via `loadMonitoringState()` (called in `ensureDataLoaded()`)
- **Status**: ✅ **PERSISTS** - Monitoring state is saved to UserDefaults and loaded on app restart

#### ✅ Signout/Signin
- **Signout behavior**: `signOut()` only clears auth tokens, does NOT clear `"isMonitoringActive"`
- **UserDefaults NOT cleared**: Monitoring status remains in UserDefaults
- **Status**: ✅ **PERSISTS** - Monitoring status remains after signout and is available after signin

### Code References
- **Save**: `DeviceActivityService.saveMonitoringState()` → `UserDefaults.standard.set(isMonitoring, forKey: "isMonitoringActive")`
- **Load**: `DeviceActivityService.loadMonitoringState()` → `UserDefaults.standard.bool(forKey: "isMonitoringActive")`
- **Signout**: `CognitoAuthService.signOut()` → Only calls `clearTokens()` (doesn't clear monitoring status)

### Important Note
- **Auto-start disabled**: Monitoring state is loaded but monitoring is NOT automatically started on app launch (to prevent startup delays)
- **Manual start required**: User must manually enable monitoring via Settings toggle after app restart

---

## Signout Behavior Analysis

### What Gets Cleared on Signout
```swift
// CognitoAuthService.signOut() only clears:
- cognito_user_id
- cognito_user_email
- cognito_id_token
- cognito_refresh_token
```

### What Does NOT Get Cleared on Signout
- ✅ Quiet Hours schedules (`quiet_hours_schedules`)
- ✅ Monitoring status (`isMonitoringActive`)
- ✅ Selected apps (system-managed, device-level)
- ✅ App names mapping (`appNamesMapping`)
- ✅ Cached app count (`cachedSelectedAppsCount`)
- ✅ All other UserDefaults data

### What Gets Cleared on Account Deletion
```swift
// SettingsView.deleteAccount() clears:
- All UserDefaults (via removePersistentDomain)
- AWS DynamoDB data
- Cognito user account
```

---

## Recommendations

### Current Behavior
All three items (Quiet Hours schedules, selected apps, monitoring status) **persist across app restarts and signout/signin**.

### If You Want to Clear on Signout
If you want to clear these on signout (user-specific data), you would need to:

1. **Modify `CognitoAuthService.signOut()`** to clear additional UserDefaults:
```swift
func signOut() {
    // ... existing code ...
    clearTokens()
    
    // Clear user-specific data
    UserDefaults.standard.removeObject(forKey: "quiet_hours_schedules")
    UserDefaults.standard.removeObject(forKey: "isMonitoringActive")
    // Note: FamilyActivitySelection cannot be cleared manually
}
```

2. **Consider user-specific keys**: Use user ID in keys (e.g., `"quiet_hours_schedules_\(userId)"`) to support multiple users on same device

### Current Design Decision
The current implementation treats these as **device-level preferences** that persist across signout/signin, which is reasonable for:
- Multiple users on same device
- User convenience (don't lose settings when signing out)
- Simplicity (no need to sync to cloud)

---

## Testing Checklist

To verify persistence:

1. **App Restart Test**:
   - ✅ Create Quiet Hours schedule
   - ✅ Select apps for monitoring
   - ✅ Enable monitoring
   - ✅ Force quit app
   - ✅ Relaunch app
   - ✅ Verify: Schedules, apps, and monitoring status are preserved

2. **Signout/Signin Test**:
   - ✅ Create Quiet Hours schedule
   - ✅ Select apps for monitoring
   - ✅ Enable monitoring
   - ✅ Sign out
   - ✅ Sign in (same or different user)
   - ✅ Verify: Schedules, apps, and monitoring status are preserved

3. **Account Deletion Test**:
   - ✅ Create Quiet Hours schedule
   - ✅ Select apps for monitoring
   - ✅ Enable monitoring
   - ✅ Delete account
   - ✅ Verify: All data is cleared (as expected)

