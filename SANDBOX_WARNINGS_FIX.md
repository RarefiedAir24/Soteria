# Sandbox Warnings Fix for Plaid Framework

## About These Warnings

The sandbox warnings you're seeing are **common and usually non-critical**. They occur when Xcode's build system (rsync) tries to copy the Plaid LinkKit framework files. These are typically **warnings, not errors**, and your app should still build successfully.

## What I've Done

✅ Updated Podfile to disable user script sandboxing (which can cause these issues)
✅ Reinstalled pods with new settings

## Next Steps

### 1. Clean and Rebuild in Xcode

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)

### 2. Check if Build Actually Succeeds

These sandbox warnings often appear but **don't prevent the build from completing**. Check:
- Does the build finish?
- Does it say "Build Succeeded"?
- Can you run the app?

If yes to all, **you can ignore these warnings** - they're harmless.

### 3. If Build Actually Fails

If the build is actually failing (not just warnings), try:

**Option A: Disable Sandboxing for Build Scripts**
1. Select your project in Xcode
2. Select the `soteria` target
3. Go to **Build Phases**
4. Find **"Embed Pods Frameworks"** phase
5. Expand it and uncheck **"For install builds only"**
6. Or try disabling **"Code Sign On Copy"**

**Option B: Manual Framework Embedding**
1. In **Build Phases** → **Embed Frameworks**
2. Remove `LinkKit.framework` if it's there
3. Add it back manually:
   - Click **+**
   - Select `LinkKit.framework` from `Pods/Plaid/LinkKit.xcframework`
   - Set to **"Embed & Sign"**

**Option C: Update Build Settings**
1. Select target → **Build Settings**
2. Search for **"Enable User Script Sandboxing"**
3. Set to **NO**

## Why This Happens

- XCFrameworks (like Plaid's LinkKit) contain multiple architectures
- Xcode uses rsync to copy framework files during build
- macOS sandbox restrictions can block rsync from accessing certain framework internals
- This is a known issue with XCFrameworks in CocoaPods

## Verification

After applying fixes:
1. Clean build folder
2. Build again
3. Check if warnings persist (they might, but build should succeed)
4. Run the app to verify Plaid SDK works

## Important Note

**If your app builds and runs successfully, these warnings can be safely ignored.** They don't affect runtime functionality.

