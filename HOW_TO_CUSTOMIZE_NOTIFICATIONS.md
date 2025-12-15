# How to Customize Notification Messages

## ✅ App Icon Confirmed

**Status**: App icon is present and configured!
- **File**: `soteria/Assets.xcassets/AppIcon.appiconset/Asset 1.png`
- **Size**: 1024x1024 PNG (correct format)
- **Location**: This icon automatically appears in all notifications

The app icon shown in notifications comes from this file - iOS uses it automatically. You don't need to do anything else for the icon.

---

## 📝 How to Customize Notification Messages

There are **two types** of notifications you can customize:

### 1. **Purchase Intent Prompt** (App-Specific)
Shown when user opens a monitored app (e.g., Amazon, Uber Eats)

**File**: `SoteriaMonitor/DeviceActivityMonitorExtension.swift`  
**Method**: `sendPurchaseIntentPromptNotification()`

**Current Code** (lines 328-335):
```swift
let content = createCustomNotificationContent(
    title: "🛑 SOTERIA Moment",           // ← Change this
    subtitle: "Protection Alert",         // ← Change this
    body: bodyText,                       // ← Change this (see below)
    appName: appName,
    type: "purchase_intent_prompt",
    userInfo: ["appIndex": appIndex ?? -1]
)
```

**Body Text Logic** (lines 319-326):
```swift
let appNameLower = appName.lowercased()
let bodyText: String
if appNameLower.contains("food") || appNameLower.contains("eat") || 
   appNameLower.contains("door") || appNameLower.contains("uber") {
    bodyText = "Take a moment before ordering on \(appName)"  // ← Change this
} else {
    bodyText = "Take a moment before shopping on \(appName)"  // ← Change this
}
```

**To Customize**:
1. Change `title` parameter (line 329) - e.g., `"🛑 SOTERIA Protection"`
2. Change `subtitle` parameter (line 330) - e.g., `"Think Before You Buy"`
3. Change `bodyText` messages (lines 323 and 325) - customize the actual message text

**Example Customization**:
```swift
let content = createCustomNotificationContent(
    title: "💰 Financial Protection",
    subtitle: "Pause & Reflect",
    body: bodyText,
    appName: appName,
    type: "purchase_intent_prompt",
    userInfo: ["appIndex": appIndex ?? -1]
)

// And update body text:
if appNameLower.contains("food") || appNameLower.contains("eat") || 
   appNameLower.contains("door") || appNameLower.contains("uber") {
    bodyText = "Before you order, take a breath. Is this purchase aligned with your goals?"
} else {
    bodyText = "Before you shop, pause for a moment. Does this purchase serve your future self?"
}
```

---

### 2. **SOTERIA Moment** (General)
Shown for general protection moments

**File**: `SoteriaMonitor/DeviceActivityMonitorExtension.swift`  
**Method**: `sendSoteriaMomentNotification()`

**Current Code** (lines 404-409):
```swift
let content = createCustomNotificationContent(
    title: "🛑 SOTERIA Moment",           // ← Change this
    subtitle: "Protection Alert",         // ← Change this
    body: "You're about to open a shopping app. Take a moment to pause and think.",  // ← Change this
    type: "soteria_moment"
)
```

**To Customize**:
1. Change `title` parameter (line 405)
2. Change `subtitle` parameter (line 406)
3. Change `body` parameter (line 407) - the main message

**Example Customization**:
```swift
let content = createCustomNotificationContent(
    title: "🛡️ SOTERIA Protection",
    subtitle: "Mindful Spending",
    body: "You're about to make a purchase decision. Take 10 seconds to consider: Do you really need this?",
    type: "soteria_moment"
)
```

---

## 🎨 Notification Appearance

When the notification appears, it will show:

```
┌─────────────────────────────────┐
│ [App Icon]  🛑 SOTERIA Moment   │  ← Title
│            Protection Alert      │  ← Subtitle
│            Take a moment before │  ← Body
│            shopping on Amazon    │
└─────────────────────────────────┘
```

- **App Icon**: Automatically from `Asset 1.png` (cannot be changed programmatically)
- **Title**: Large, bold text at top
- **Subtitle**: Smaller text below title (iOS 10+)
- **Body**: Main message text

---

## 📋 Step-by-Step Customization Guide

### Step 1: Open the File
1. Open Xcode
2. Navigate to: `SoteriaMonitor/DeviceActivityMonitorExtension.swift`

### Step 2: Find the Notification Code
- **For app-specific notifications**: Look for `sendPurchaseIntentPromptNotification()` (around line 306)
- **For general notifications**: Look for `sendSoteriaMomentNotification()` (around line 375)

### Step 3: Edit the Text
Change the parameters in `createCustomNotificationContent()`:
- `title`: Main notification title
- `subtitle`: Subtitle text (optional, can be `nil`)
- `body`: Main message text

### Step 4: Rebuild
1. **Clean Build Folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Build**: Product → Build (Cmd+B)
3. **Run**: Product → Run (Cmd+R)

**Important**: Since this is in the extension, you need to rebuild the **entire project** (not just the main app).

### Step 5: Test
1. Open a monitored app (e.g., Amazon)
2. Check if the notification appears with your new text
3. Verify on:
   - Banner (when app is open)
   - Lock screen
   - Notification Center

---

## 💡 Customization Tips

1. **Keep it Short**: Notification banners have limited space
   - Title: 1-2 words or short phrase
   - Subtitle: 1-3 words
   - Body: 1-2 sentences max

2. **Use Emojis**: They make notifications more visually appealing
   - Examples: 🛑 🛡️ 💰 🎯 ⏸️

3. **Be Clear**: Users see notifications quickly - make the message clear and actionable

4. **Personalize**: Use `\(appName)` to include the app name in messages

5. **Test Different Messages**: Try different tones:
   - Supportive: "Take a moment to check in with yourself"
   - Direct: "Pause before purchasing"
   - Question-based: "Is this purchase aligned with your goals?"

---

## 🔍 Current Notification Text

### Purchase Intent Prompt (App-Specific)
- **Title**: "🛑 SOTERIA Moment"
- **Subtitle**: "Protection Alert"
- **Body (Food apps)**: "Take a moment before ordering on [App Name]"
- **Body (Shopping apps)**: "Take a moment before shopping on [App Name]"

### SOTERIA Moment (General)
- **Title**: "🛑 SOTERIA Moment"
- **Subtitle**: "Protection Alert"
- **Body**: "You're about to open a shopping app. Take a moment to pause and think."

---

## ⚠️ Important Notes

1. **Extension Target**: This code is in the `SoteriaMonitor` extension, not the main app
2. **Rebuild Required**: Changes require a full rebuild of the extension
3. **App Icon**: Cannot be changed programmatically - it's always from `Asset 1.png`
4. **Time-Sensitive**: Notifications use time-sensitive level for in-app visibility
5. **User Settings**: Users must enable time-sensitive notifications in Settings for banners to show in-app

---

## 🎯 Quick Reference

**File to Edit**: `SoteriaMonitor/DeviceActivityMonitorExtension.swift`

**Method 1** (App-Specific): `sendPurchaseIntentPromptNotification()` - Line ~306  
**Method 2** (General): `sendSoteriaMomentNotification()` - Line ~375

**Helper Function**: `createCustomNotificationContent()` - Line ~37  
(This function handles all the notification setup - you just pass in your text)

