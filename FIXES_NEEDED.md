# Fixes Needed in Xcode

## Issue 1: Missing Firebase Packages

Firebase packages need to be resolved via Swift Package Manager in Xcode.

### Fix in Xcode:
1. **Open** `soteria.xcworkspace` in Xcode
2. **Select the project** in navigator (top item)
3. **Select the project** (not target) in the editor
4. Go to **"Package Dependencies"** tab
5. Click **"Resolve Package Versions"** or **"Update to Latest Package Versions"**
6. Wait for packages to resolve

If that doesn't work:
1. Go to **File** → **Packages** → **Reset Package Caches**
2. Then **File** → **Packages** → **Resolve Package Versions**

## Issue 2: rsync Errors with Static Linking

Even with static linking, Xcode might still be trying to process the XCFramework. 

### Fix in Xcode:

1. **Select the project** in navigator
2. **Select the `soteria` target**
3. Go to **Build Phases** tab
4. Look for **"Embed Pods Frameworks"** or **"Embed Frameworks"**
5. **Remove** `LinkKit.framework` from the list (if it's there)
6. With static linking, frameworks shouldn't need to be embedded

### Alternative: Check Build Settings

1. Select target → **Build Settings**
2. Search for **"Always Embed Swift Standard Libraries"**
3. Set to **NO**
4. Search for **"Embed Frameworks"**
5. Make sure it's not forcing framework embedding

### If Still Failing: Force Static Library Extraction

The XCFramework might need to be processed differently. Try:

1. **Clean Build Folder** (⇧⌘K)
2. **Delete DerivedData** (via Xcode: **File** → **Project Settings** → **Derived Data** → **Delete**)
3. **Close Xcode completely**
4. **Reopen** and build

## Quick Fix Sequence

1. ✅ Open `soteria.xcworkspace` (NOT `.xcodeproj`)
2. ✅ Resolve Firebase packages (Package Dependencies tab)
3. ✅ Clean Build Folder (⇧⌘K)
4. ✅ Remove LinkKit from Embed Frameworks if present
5. ✅ Build (⌘B)

## Verification

After fixes:
- ✅ Firebase packages resolve
- ✅ No rsync errors
- ✅ Build succeeds
- ✅ App runs

