# Fixing rsync "Operation not permitted" Errors

## The Problem

You're seeing rsync errors when Xcode tries to copy the Plaid LinkKit framework:
- `unreadable directory: Operation not permitted`
- `rsync_sender` errors
- `child exited with status 1`

This happens because rsync can't access the framework's `_CodeSignature` directory due to macOS sandbox restrictions.

## What I've Done

✅ Cleared DerivedData completely
✅ Updated Podfile to disable code signing on copy for frameworks
✅ Reinstalled pods

## Next Steps in Xcode

### 1. Clean Build Folder
- **Product** → **Clean Build Folder** (⇧⌘K)

### 2. Fix Framework Embedding Settings

1. **Select your project** in Xcode navigator
2. **Select the `soteria` target**
3. Go to **Build Phases** tab
4. Expand **"Embed Pods Frameworks"** (or **"Embed Frameworks"**)
5. Find `LinkKit.framework` in the list
6. **Uncheck "Code Sign On Copy"** for LinkKit.framework
7. Make sure it's set to **"Embed & Sign"** or **"Embed Without Signing"**

### 3. Alternative: Manual Framework Configuration

If the above doesn't work:

1. In **Build Phases** → **Embed Pods Frameworks**
2. **Remove** `LinkKit.framework` from the list
3. Click **+** to add it manually
4. Navigate to: `Pods/Plaid/LinkKit.xcframework`
5. Select the framework
6. Set to **"Embed Without Signing"** (not "Embed & Sign")
7. Make sure **"Code Sign On Copy"** is **unchecked**

### 4. Build Settings Fix

1. Select target → **Build Settings**
2. Search for **"Code Signing"**
3. Set **"Code Sign On Copy"** to **NO**
4. Search for **"Enable User Script Sandboxing"**
5. Set to **NO**

### 5. Try Building Again

After making these changes:
1. **Clean Build Folder** (⇧⌘K)
2. **Build** (⌘B)

## If Still Failing

### Nuclear Option: Use Static Framework

If dynamic framework embedding continues to fail, you can try using static linking:

1. Edit `Podfile`:
```ruby
use_frameworks! :linkage => :static
```

2. Run `pod install`
3. Clean and rebuild

### Alternative: Check Permissions

Sometimes it's a file permissions issue:

```bash
# Fix permissions on Pods directory
chmod -R 755 Pods/
chmod -R 755 ~/Library/Developer/Xcode/DerivedData/
```

## Why This Happens

- XCFrameworks contain code signatures that macOS sandbox protects
- rsync (used by Xcode to copy frameworks) hits sandbox restrictions
- Code signing during copy requires additional permissions
- This is a known issue with XCFrameworks in CocoaPods

## Verification

After fixes:
1. ✅ Build completes without rsync errors
2. ✅ App runs successfully
3. ✅ Plaid Link SDK loads correctly

If build succeeds but you still see warnings (not errors), those can be safely ignored.

