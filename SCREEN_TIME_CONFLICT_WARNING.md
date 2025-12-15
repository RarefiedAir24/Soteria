# Screen Time Conflict Warning

## Critical Issue Identified

**Problem**: Soteria will override existing Screen Time restrictions set by the user through Apple's Settings.

## How It Works

1. **ManagedSettingsStore is Shared**: The `ManagedSettingsStore` is a system-wide resource that only one app can control at a time.

2. **Soteria Takes Control**: When Soteria sets `store.shield.applications = appsTokens`, it immediately takes control of app blocking.

3. **Existing Restrictions Overridden**: If the user has already set up app restrictions through:
   - Apple's Screen Time Settings
   - Another app using FamilyControls
   - Parental controls
   
   These restrictions will be **replaced** by Soteria's restrictions.

4. **When Soteria Stops**: When Soteria clears `store.shield.applications = nil`, it removes ALL restrictions, including any that Screen Time was managing.

## Current Implementation

The code now:
- ✅ Detects if there are existing restrictions before setting shield
- ✅ Logs warnings when overriding existing restrictions
- ⚠️ **Still overrides** - doesn't prevent the override, just warns

## Limitations

**We Cannot**:
- Read which apps Screen Time is blocking (privacy restriction)
- Merge restrictions (union of both sets)
- Detect if restrictions are from Screen Time vs another app
- Preserve Screen Time restrictions when Soteria takes control

**We Can**:
- Detect if restrictions exist (by checking `store.shield.applications?.count`)
- Warn the user before taking control
- Log when we override existing restrictions

## Recommended Solutions

### Option 1: User Warning (Recommended)
Show an alert when user first enables monitoring:
```
"Enabling Soteria monitoring will take control of your Screen Time restrictions. 
Any existing app restrictions set in Settings → Screen Time will be replaced by 
Soteria's restrictions. Continue?"
```

### Option 2: Check Before Setting
Before setting `store.shield.applications`, check if it's already set:
- If set and different from ours → Warn user
- If set and matches ours → No action needed
- If not set → Proceed normally

### Option 3: Merge Restrictions (Complex)
Try to merge Soteria's restrictions with existing ones:
- Get existing `store.shield.applications`
- Union with Soteria's selected apps
- Set combined set
- **Problem**: Can't read which apps are in existing restrictions (privacy)

### Option 4: Don't Clear When Stopping
When Soteria stops monitoring, don't clear `shield.applications` if we didn't set them:
- Track if we set the shield
- Only clear if we set it
- **Problem**: Can't tell if we set it vs Screen Time

## Current Status

✅ **Detection Added**: Code now detects existing restrictions
⚠️ **Warning Logged**: Warnings are logged to console
❌ **No User Alert**: User is not warned in UI
❌ **Still Overrides**: Restrictions are still overridden

## Next Steps

1. Add user-facing alert when enabling monitoring if restrictions exist
2. Consider not clearing restrictions when stopping (if we can detect we didn't set them)
3. Document this behavior in app onboarding/help

## Technical Details

### ManagedSettingsStore Behavior
- Only one app can control `shield.applications` at a time
- Setting it immediately takes control
- Clearing it removes all restrictions (not just ours)
- Cannot read which apps are restricted (privacy)

### Detection Method
```swift
let currentShieldCount = store.shield.applications?.count ?? 0
let ourAppCount = selectedApps.applicationTokens.count

if currentShieldCount > 0 && ourAppCount == 0 {
    // Existing restrictions detected
}
```

This is imperfect because:
- If user has 2 apps restricted in Screen Time
- And Soteria also wants to restrict 2 apps (same or different)
- We can't tell if they're the same apps or different

