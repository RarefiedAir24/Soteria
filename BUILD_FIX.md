# Build Issues Fix

## Sandbox Error Fix

If you're seeing sandbox errors like:
```
Sandbox: rsync(20726) deny(1) file-read-data .../Plaid/LinkKit.framework/_CodeSignature
```

## Steps to Fix:

### 1. Clean Build (Already Done)
✅ Cleared DerivedData
✅ Reinstalled Pods

### 2. In Xcode:
1. **Clean Build Folder**: `Product` → `Clean Build Folder` (⇧⌘K)
2. **Close Xcode completely**
3. **Reopen Xcode**
4. **Open the workspace**: Make sure you open `soteria.xcworkspace` (NOT `.xcodeproj`)
5. **Build**: `Product` → `Build` (⌘B)

### 3. If Still Failing:

**Check Code Signing:**
1. Select your project in Xcode
2. Select the `soteria` target
3. Go to `Signing & Capabilities`
4. Make sure "Automatically manage signing" is checked
5. Select your development team

**Check Build Settings:**
1. Select the `soteria` target
2. Go to `Build Settings`
3. Search for "Code Signing"
4. Make sure "Code Signing Identity" is set to "Apple Development" or your team

**Check Framework Search Paths:**
1. In `Build Settings`, search for "Framework Search Paths"
2. Make sure `$(inherited)` is included
3. Make sure `$(SRCROOT)/Pods` is included

### 4. Nuclear Option (if nothing else works):

```bash
# Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf Pods
rm -rf soteria.xcworkspace
pod install

# Then reopen Xcode and build
```

## Common Causes:

1. **Wrong file opened**: Opening `.xcodeproj` instead of `.xcworkspace`
2. **Stale build cache**: DerivedData needs clearing
3. **Pods not properly integrated**: Need to reinstall
4. **Code signing issues**: Framework not properly signed
5. **Build settings**: Missing framework search paths

## Verification:

After cleaning, verify:
- ✅ `soteria.xcworkspace` exists
- ✅ `Pods` directory exists
- ✅ `Pods/Plaid` exists
- ✅ Xcode shows `Pods` project in navigator

