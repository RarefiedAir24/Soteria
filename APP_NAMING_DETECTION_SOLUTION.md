# Using App Naming to Identify Specific Apps

## The Solution

**Yes!** We can leverage app naming by creating **separate DeviceActivityEvents for each app**. This way, when an event fires, we know exactly which app it is.

## How It Works

### Current Approach (One Event for All Apps)
```swift
// One event monitors all apps
let event = DeviceActivityEvent(
    applications: [Amazon, Uber Eats, DoorDash],  // All apps
    threshold: DateComponents(second: 1)
)
// When event fires → We don't know which app
```

### New Approach (One Event Per App)
```swift
// Create separate events for each app
let amazonEvent = DeviceActivityEvent(
    applications: [Amazon],  // Only Amazon
    threshold: DateComponents(second: 1)
)
let uberEvent = DeviceActivityEvent(
    applications: [Uber Eats],  // Only Uber Eats
    threshold: DateComponents(second: 1)
)
let doorDashEvent = DeviceActivityEvent(
    applications: [DoorDash],  // Only DoorDash
    threshold: DateComponents(second: 1)
)

// When amazonEvent fires → We know it's Amazon!
// When uberEvent fires → We know it's Uber Eats!
```

## Implementation

### Step 1: Create Events Per App Index

```swift
// Instead of one event with all apps
let appsTokens = selectedApps.applicationTokens
let event = DeviceActivityEvent(applications: appsTokens, ...)

// Create one event per app
var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
for (index, appToken) in appsTokens.enumerated() {
    let eventName = DeviceActivityEvent.Name("soteria.moment.\(index)")
    let event = DeviceActivityEvent(
        applications: [appToken],  // Single app
        threshold: DateComponents(second: 1)
    )
    events[eventName] = event
}
```

### Step 2: Extension Identifies App from Event Name

```swift
override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    // Event name format: "soteria.moment.0", "soteria.moment.1", etc.
    // Extract index from event name
    let eventNameString = event.rawValue
    if let indexString = eventNameString.split(separator: ".").last,
       let appIndex = Int(indexString) {
        
        // Get app name from index
        let appName = getAppName(forIndex: appIndex)
        
        // Send notification with app name
        sendNotification(
            title: "🛑 SOTERIA Moment",
            body: "Take a moment before shopping on \(appName)"
        )
    }
}
```

## Benefits

✅ **App-Specific Notifications**
- "Take a moment before shopping on Amazon"
- "Take a moment before ordering on Uber Eats"
- "Take a moment before ordering on DoorDash"

✅ **Uses Existing App Naming**
- Leverages your internal naming system
- No additional setup needed
- Works with user-provided names

✅ **Reliable Identification**
- Event name contains the app index
- Index maps to app name
- No guessing or inference needed

## Example Scenarios

### User 1: 1 App (Amazon)
- Creates event: `soteria.moment.0` → [Amazon]
- Opens Amazon → Event `soteria.moment.0` fires
- Extension extracts index: 0
- Gets app name: "Amazon"
- Notification: "Take a moment before shopping on Amazon"

### User 2: 3 Apps (Uber Eats, DoorDash, Amazon)
- Creates events:
  - `soteria.moment.0` → [Uber Eats]
  - `soteria.moment.1` → [DoorDash]
  - `soteria.moment.2` → [Amazon]
- Opens DoorDash → Event `soteria.moment.1` fires
- Extension extracts index: 1
- Gets app name: "DoorDash"
- Notification: "Take a moment before ordering on DoorDash"

## Implementation Details

### Event Name Format
- Pattern: `"soteria.moment.{index}"`
- Example: `"soteria.moment.0"`, `"soteria.moment.1"`, `"soteria.moment.2"`
- Index corresponds to position in `selectedApps.applicationTokens` array

### App Name Lookup
```swift
// In extension (via UserDefaults or shared container)
func getAppName(forIndex index: Int) -> String {
    // Load from UserDefaults (shared between app and extension)
    if let data = UserDefaults.standard.data(forKey: "appNamesMapping"),
       let appNames = try? JSONDecoder().decode([Int: String].self, from: data) {
        return appNames[index] ?? "App \(index + 1)"
    }
    return "App \(index + 1)"
}
```

### Notification Customization
```swift
// Customize notification based on app name
let appName = getAppName(forIndex: appIndex)
let notificationBody: String

if appName.lowercased().contains("food") || 
   appName.lowercased().contains("eat") || 
   appName.lowercased().contains("door") {
    notificationBody = "Take a moment before ordering food on \(appName)"
} else {
    notificationBody = "Take a moment before shopping on \(appName)"
}
```

## Limitations

⚠️ **Multiple Events**
- More DeviceActivity events to manage
- Slightly more complex setup
- But still manageable (one per app)

⚠️ **Event Limits**
- DeviceActivity may have limits on number of events
- But typically supports many events (10+ should be fine)

## Code Changes Needed

1. **DeviceActivityService**: Create events per app instead of one event
2. **Extension**: Extract app index from event name
3. **Extension**: Load app names from UserDefaults
4. **Extension**: Customize notification with app name

## Summary

✅ **Yes, we can use app naming to identify specific apps!**
- Create one DeviceActivityEvent per app
- Event name includes app index
- Extension extracts index and gets app name
- Customize notification with app name

This gives you app-specific notifications like:
- "Take a moment before shopping on Amazon"
- "Take a moment before ordering on Uber Eats"

Instead of generic:
- "Take a moment to reflect before you shop"

