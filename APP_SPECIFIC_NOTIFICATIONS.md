# App-Specific Time-Sensitive Notifications

## How It Works

### Current Setup
- **DeviceActivity monitors specific apps** per user
- User 1 selects: Amazon
- User 2 selects: Uber Eats, DoorDash
- Each user's `selectedApps` contains only their chosen apps

### Detection Flow
1. **User opens app** (e.g., Amazon)
2. **DeviceActivity extension fires** `eventDidReachThreshold`
3. **Extension checks**: Is this app in the user's Quiet Hours list?
4. **If yes**: Send time-sensitive notification
5. **If no**: Don't send (app not monitored)

### Key Point
**DeviceActivity already knows which specific apps to monitor** - it's built into the event system. When the event fires, it's because one of the user's selected apps was opened.

## Implementation

### Option 1: Generic Notification (Simpler)
- When any monitored app opens during Quiet Hours → send notification
- Notification: "Take a moment to reflect before you shop"
- Works for all apps (Amazon, Uber Eats, DoorDash, etc.)
- User knows it's about the app they just opened

**Pros:**
- ✅ Simple implementation
- ✅ Works for all apps
- ✅ User context is clear (they just opened the app)

**Cons:**
- ⚠️ Not app-specific in message

### Option 2: App-Specific Notification (More Complex)
- Detect which specific app was opened
- Customize notification per app
- "Take a moment before shopping on Amazon"
- "Reflect before ordering food"

**Challenge:**
- DeviceActivity doesn't directly tell us which app
- But we can infer from context or use app names

**Implementation:**
1. Store app names in UserDefaults (already doing this)
2. When event fires, check which apps are in shield
3. Match to app name
4. Customize notification message

**Pros:**
- ✅ More personalized
- ✅ Clearer context

**Cons:**
- ⚠️ More complex
- ⚠️ May not always identify exact app

## Recommended Approach

### Hybrid: Generic but Context-Aware

**How:**
1. When DeviceActivity event fires → send notification
2. Notification is generic but context-aware
3. User knows it's about the app they just opened
4. Deep link opens Soteria with reflection prompt

**Notification Content:**
- Title: "🛑 SOTERIA Moment"
- Body: "Take a moment to reflect before you shop"
- Or: "You're about to make a purchase. Pause and think."

**Why This Works:**
- User just opened Amazon → notification appears
- User knows it's about Amazon (they just opened it)
- No need to specify app name
- Simpler, more reliable

## Technical Details

### DeviceActivity Event Configuration

```swift
// Current implementation
let event = DeviceActivityEvent(
    applications: appsTokens,  // User's selected apps
    threshold: DateComponents(second: 1)
)
```

**What This Means:**
- Event fires when ANY app in `appsTokens` is opened
- `appsTokens` is user-specific (their selected apps)
- So event only fires for their apps

### Extension Detection

```swift
override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    // This fires when user's selected app opens
    // We know it's one of their monitored apps
    // Check if Quiet Hours are active
    // Send notification
}
```

### Checking Quiet Hours

The extension can check:
1. Is Quiet Hours active? (via UserDefaults or shared container)
2. If yes → send notification
3. If no → don't send

## User-Specific Examples

### User 1: Amazon Only
- Quiet Hours: 8pm-10pm, Amazon selected
- Opens Amazon at 9pm → Notification sent ✅
- Opens Amazon at 2pm → No notification (not Quiet Hours) ✅
- Opens Instagram at 9pm → No notification (not monitored) ✅

### User 2: Uber Eats + DoorDash
- Quiet Hours: 6pm-11pm, Uber Eats + DoorDash selected
- Opens Uber Eats at 7pm → Notification sent ✅
- Opens DoorDash at 8pm → Notification sent ✅
- Opens Amazon at 7pm → No notification (not monitored) ✅

## Implementation Steps

1. **Remove Hard Blocking**
   - Don't set `shield.applications`
   - Keep DeviceActivity monitoring (for detection)

2. **Update Extension**
   - When event fires, check Quiet Hours status
   - Send time-sensitive notification
   - Don't block, just notify

3. **Notification Configuration**
   - Time-sensitive interruption level
   - Deep link to reflection prompt
   - Generic but context-aware message

4. **User Experience**
   - User opens Amazon during Quiet Hours
   - Notification banner appears at top
   - User taps → Opens Soteria reflection prompt
   - User reflects → Can continue or cancel

## Benefits

✅ **User-Specific**: Each user only gets notifications for their selected apps
✅ **Time-Specific**: Only during their Quiet Hours
✅ **App-Specific**: Only for apps they selected
✅ **No Blocking**: No Screen Time conflicts
✅ **Visible**: Time-sensitive shows in-app as banner
✅ **Simple**: Generic message, user knows context

## Next Steps

1. Test DeviceActivity detection (already works)
2. Add time-sensitive notification entitlement
3. Update extension to send notifications instead of blocking
4. Test with different user configurations
5. Verify notifications show in-app as banners

