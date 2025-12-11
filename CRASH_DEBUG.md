# Debugging App Crash on Launch

## Current Issue
App crashes on launch with `__abort_with_payload()` - this is the system function that terminates the app.

## What I've Done
1. ✅ Made Firebase initialization safer (check if already configured, verify file exists)
2. ✅ Copied GoogleService-Info.plist to `soteria/` folder
3. ✅ Verified plist is valid

## Next Steps to Debug

### 1. Check Console Logs
Look for any error messages BEFORE the abort. The crash log should show:
- What function called `abort_with_payload`
- Any error messages from Firebase
- Any assertion failures

### 2. Verify GoogleService-Info.plist in Bundle
In Xcode:
1. Select the project (blue icon)
2. Select the `soteria` target
3. Go to "Build Phases"
4. Expand "Copy Bundle Resources"
5. Verify `GoogleService-Info.plist` is listed
6. If not, click "+" and add it

### 3. Try Disabling Firebase Temporarily
Comment out `FirebaseApp.configure()` to see if that's the issue:
```swift
// FirebaseApp.configure() // Temporarily disabled for testing
```

### 4. Check Service Initialization Order
The services are initialized as `@StateObject` properties BEFORE `init()` runs.
If any service tries to use Firebase in its `init()`, it might crash.

### 5. Run with Debugger
1. Set a breakpoint at the start of `SoteriaApp.init()`
2. Step through to see where it crashes
3. Check the stack trace

## Most Likely Causes
1. **Firebase can't find GoogleService-Info.plist** - File not in bundle
2. **Firebase packages not properly linked** - Missing frameworks
3. **Service initialization crash** - One of the services is crashing

## Quick Test
Try this in `SoteriaApp.init()`:
```swift
print("🔍 [App] Bundle resources: \(Bundle.main.paths(forResourcesOfType: "plist", inDirectory: nil))")
```

This will show all plist files in the bundle.

