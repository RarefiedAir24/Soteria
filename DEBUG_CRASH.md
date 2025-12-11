# Debugging Black Screen Crash

## Current Situation
- ✅ Build succeeds
- ❌ App crashes immediately on launch (black screen)
- ❌ Crashes in `__abort_with_payload` (system abort function)

## What We Need to See

### 1. Console Logs
Check the Xcode console for any error messages BEFORE the crash. Look for:
- Firebase errors
- Service initialization errors
- Any print statements from `SoteriaApp.init()`
- Any assertion failures

### 2. Full Stack Trace
In Xcode debugger:
1. Look at the **left sidebar** (Debug Navigator)
2. Expand **Thread 1** to see the full call stack
3. Look for frames ABOVE `__abort_with_payload`
4. The frame BEFORE `__abort_with_payload` is what's causing the crash

### 3. Other Threads
Check if there are other threads with errors:
- Look for threads with red error indicators
- Check if any thread shows a different crash location

## Most Likely Causes

1. **Firebase Configuration Failure**
   - `GoogleService-Info.plist` not found in bundle
   - Invalid Firebase configuration
   - Missing Firebase frameworks

2. **Service Initialization Crash**
   - One of the `@StateObject` services is crashing in `init()`
   - Force unwrap of nil value
   - Fatal error in service initialization

3. **Missing Framework**
   - Plaid SDK not properly linked
   - Firebase framework missing
   - System framework issue

## Quick Fixes to Try

### Option 1: Temporarily Disable Firebase
Comment out Firebase configuration to see if that's the issue:

```swift
// FirebaseApp.configure() // Temporarily disabled
```

### Option 2: Check Console Output
Run the app and immediately check the console - do you see:
- `✅ [App] Starting initialization...`?
- Any error messages?
- Or does it crash before any logs?

### Option 3: Add Exception Breakpoint
1. In Xcode: **Debug** → **Breakpoints** → **Create Exception Breakpoint**
2. Run again - it should break BEFORE the abort
3. Check the stack trace at that point

## Next Steps
Please share:
1. **Console logs** (any output before crash)
2. **Full stack trace** (expand Thread 1 in debugger)
3. **Any other threads** with errors

