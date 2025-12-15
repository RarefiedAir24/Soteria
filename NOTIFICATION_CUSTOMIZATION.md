# Notification Customization Guide

## App Icon in Notifications

**Important**: The app icon shown in iOS notifications is **automatically** taken from your app's icon in the asset catalog. You **cannot** change it programmatically.

### How to Set/Update the App Icon:

1. **Location**: `soteria/Assets.xcassets/AppIcon.appiconset/`
2. **Required**: 1024x1024 PNG image for "Universal" slot
3. **Optional**: 
   - Dark mode version (1024x1024) for "Dark" slot
   - Tinted version (1024x1024) for "Tinted" slot (iOS 15+)

4. **To Update**:
   - Open Xcode
   - Navigate to `Assets.xcassets/AppIcon.appiconset`
   - Drag your 1024x1024 icon image into the "Universal" slot
   - Build and run - iOS will automatically use this icon in all notifications

**Note**: The icon you set in the asset catalog will appear in:
- Notification banners
- Notification Center
- Lock screen notifications
- Notification history

---

## Customizing Banner Notification Appearance

### Current Customization Options

The notification system now supports customizable:

1. **Title** - Main text at top of banner (e.g., "🛑 SOTERIA Moment")
2. **Subtitle** - Text below title (e.g., "Protection Alert")
3. **Body** - Main message text
4. **Sound** - Notification sound
5. **Badge** - App badge count
6. **Category** - For custom actions (future feature)

### Code Location

**File**: `SoteriaMonitor/DeviceActivityMonitorExtension.swift`

**Helper Function**: `createCustomNotificationContent()`

```swift
let content = createCustomNotificationContent(
    title: "🛑 SOTERIA Moment",        // Main title
    subtitle: "Protection Alert",        // Subtitle (optional)
    body: "Take a moment before shopping on Amazon",  // Message
    appName: "Amazon",                   // App name (optional)
    type: "purchase_intent_prompt",     // Notification type
    userInfo: ["appIndex": 0]            // Additional data
)
```

### Customizing Notification Text

#### For Purchase Intent Prompts:

**Location**: `sendPurchaseIntentPromptNotification()` method

**Current Implementation**:
- **Title**: "🛑 SOTERIA Moment"
- **Subtitle**: "Protection Alert"
- **Body**: 
  - Food apps: "Take a moment before ordering on [App Name]"
  - Shopping apps: "Take a moment before shopping on [App Name]"

**To Customize**:
1. Edit the `createCustomNotificationContent()` call in `sendPurchaseIntentPromptNotification()`
2. Change `title`, `subtitle`, or `body` parameters
3. Rebuild the extension

#### For General SOTERIA Moments:

**Location**: `sendSoteriaMomentNotification()` method

**Current Implementation**:
- **Title**: "🛑 SOTERIA Moment"
- **Subtitle**: "Protection Alert"
- **Body**: "You're about to open a shopping app. Take a moment to pause and think."

**To Customize**:
1. Edit the `createCustomNotificationContent()` call in `sendSoteriaMomentNotification()`
2. Change the text parameters
3. Rebuild the extension

---

## Advanced Customization (Future)

### Adding Image Attachments

To add images to notifications (iOS 10+):

```swift
// Create image attachment
if let imageURL = Bundle.main.url(forResource: "notification_image", withExtension: "png"),
   let attachment = try? UNNotificationAttachment(identifier: "image", url: imageURL, options: nil) {
    content.attachments = [attachment]
}
```

**Requirements**:
- Image must be in app bundle or accessible file system
- Max size: 10MB
- Supported formats: PNG, JPEG, GIF, HEIF

### Custom Notification Actions

To add action buttons to notifications:

1. **Register Categories** in `SoteriaApp.swift`:
```swift
let action1 = UNNotificationAction(identifier: "pause", title: "Pause", options: [])
let action2 = UNNotificationAction(identifier: "continue", title: "Continue", options: [.destructive])
let category = UNNotificationCategory(identifier: "SOTERIA_PURCHASE_INTENT", actions: [action1, action2], intentIdentifiers: [], options: [])
UNUserNotificationCenter.current().setNotificationCategories([category])
```

2. **Handle Actions** in `NotificationDelegate`:
```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    if response.actionIdentifier == "pause" {
        // Handle pause action
    }
    completionHandler()
}
```

---

## Notification Appearance in iOS

### Banner Display

When notification appears as banner:
- **Top**: App icon (from asset catalog)
- **Title**: Large, bold text
- **Subtitle**: Smaller text below title (if set)
- **Body**: Main message text
- **Time**: Appears on right side

### Lock Screen

When device is locked:
- Same layout as banner
- App icon on left
- Title, subtitle, body stacked vertically
- Time stamp

### Notification Center

When user pulls down:
- Same layout as lock screen
- Grouped by app
- Shows notification history

---

## Testing Customizations

1. **Build and Run** the app
2. **Trigger a notification** by opening a monitored app
3. **Check**:
   - Banner appearance
   - Lock screen appearance
   - Notification Center appearance
   - App icon display

---

## Current Notification Types

1. **`purchase_intent_prompt`** - Shown when user opens a monitored app
2. **`soteria_moment`** - General protection moment notification

Both use time-sensitive interruption level for in-app visibility.

---

## Notes

- **App Icon**: Cannot be changed programmatically - must update asset catalog
- **Subtitle**: Only visible in iOS 10+ notification banners
- **Time-Sensitive**: Requires user to enable in Settings → Notifications → Soteria → Time Sensitive Notifications
- **Extension**: Notification code runs in `SoteriaMonitor` extension, not main app
- **Rebuild Required**: Changes to extension require full rebuild of extension target

