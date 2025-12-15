# Blocking Screen & Purchase Intent Detection

## Current Situation

### The Restricted Screen (Apple's Default)
- **Cannot be edited**: The screen shown when apps are blocked is Apple's default DeviceActivity/FamilyControls screen
- **Limited customization**: We can only control which apps are blocked and when, not the UI of the blocking screen itself
- **User experience**: The screen shows a generic message with no instructions on what to do next

### How Detection Works

1. **User tries to open blocked app** → Apple shows restricted screen
2. **DeviceActivityMonitorExtension detects** → `eventDidReachThreshold` fires when user taps through
3. **Extension sets flag** → `shouldShowPurchaseIntentPrompt = true` in UserDefaults
4. **Extension sends notification** → Tries to open Soteria app
5. **Main app checks flag** → When app becomes active, checks for flag and shows prompt

## Issues Identified

1. ✅ **Fixed**: `checkForPurchaseIntentPrompt()` was never being called (handlers were disabled)
2. ⚠️ **Limitation**: Restricted screen is Apple's default - cannot add custom instructions
3. ⚠️ **Detection timing**: Extension might not always fire before user dismisses screen

## Solutions Implemented

### 1. Re-enabled Purchase Intent Detection
- **When app becomes active**: Checks for `shouldShowPurchaseIntentPrompt` flag
- **When app enters foreground**: Checks for flag
- **After initial setup**: Checks in `.task` modifier (handles case where user saw screen before app launched)
- **All checks are async**: Non-blocking to prevent startup delays

### 2. Fallback Detection
- If extension doesn't fire, fallback logic detects:
  - Quiet Hours are active
  - Monitoring is enabled
  - User opens Soteria app
- Shows prompt automatically (with 10-second cooldown to avoid spam)

## Next Steps & Recommendations

### Option 1: Improve Notification (Recommended)
- Make notification more prominent/urgent
- Add better messaging: "Tap to reflect on your purchase intent"
- Use critical interruption level (if user has enabled)

### Option 2: Add Instructions in Soteria App
- Show a banner/alert when Quiet Hours are active: "Apps are blocked. If you tried to access one, we'll prompt you when you return."
- Add to HomeView: "Quiet Hours Active - Apps Blocked" card with instructions

### Option 3: Extension Improvements
- Ensure extension is properly detecting app access
- Add more logging to debug when extension fires
- Test on physical device (extensions behave differently in simulator)

### Option 4: User Education
- Add onboarding/tutorial explaining:
  - What the restricted screen means
  - That they should return to Soteria to reflect
  - How the purchase intent prompt works

## Testing Checklist

- [ ] Test on physical device (extensions work differently)
- [ ] Verify extension logs appear in Console
- [ ] Test with Quiet Hours active
- [ ] Try opening blocked app → return to Soteria → verify prompt appears
- [ ] Check notification permissions are enabled
- [ ] Verify `shouldShowPurchaseIntentPrompt` flag is being set/cleared

## Technical Details

### Extension Detection Points
1. `eventWillReachThresholdWarning` - Fires BEFORE app opens (ideal for interception)
2. `eventDidReachThreshold` - Fires AFTER user taps through blocking screen

### Flag Management
- Set in extension: `UserDefaults.standard.set(true, forKey: "shouldShowPurchaseIntentPrompt")`
- Checked in main app: `UserDefaults.standard.bool(forKey: "shouldShowPurchaseIntentPrompt")`
- Cleared after showing: `UserDefaults.standard.set(false, forKey: "shouldShowPurchaseIntentPrompt")`

### Notification Flow
- Extension sends notification with `userInfo: ["type": "purchase_intent_prompt"]`
- Main app listens for `NSNotification.Name("OpenSOTERIA")` and `NSNotification.Name("ShowPurchaseIntentPrompt")`
- Also checks UserDefaults flag as fallback

