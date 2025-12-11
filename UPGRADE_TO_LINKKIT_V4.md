# Plaid LinkKit v4.7.9 Upgrade Instructions

## ✅ Completed Steps

1. ✅ Updated Podfile to `pod 'Plaid', '~> 4.1'`
2. ✅ Removed all custom post_install hooks that modified LinkKit embedding
3. ✅ Ran `pod deintegrate` to clean up old CocoaPods integration
4. ✅ Ran `pod repo update` to get latest specs
5. ✅ Ran `pod install` - **Successfully installed Plaid v4.7.9**

## 🔧 Next Steps (Do in Xcode)

### Step 1: Remove Manual LinkKit Embedding

1. **Open** `soteria.xcworkspace` in Xcode (NOT `.xcodeproj`)
2. **Select the project** in the left sidebar
3. **Select the `soteria` target** (not the project)
4. **Click "General" tab**
5. **Scroll down** to "Frameworks, Libraries, and Embedded Content"
6. **Find** `LinkKit.xcframework` or `LinkKit.framework` in the list
7. **Select it** and click the **"-"** button (or press Delete)
8. **Remove it completely** from the list

### Step 2: Verify Build Phases

1. **Click "Build Phases" tab**
2. **Look for** "Embed Frameworks" section (NOT "[CP] Embed Pods Frameworks")
3. **If you see** `LinkKit.framework` or `LinkKit.xcframework` in "Embed Frameworks":
   - **Expand** the section
   - **Select** LinkKit
   - **Press Delete** to remove it
4. **Keep** "[CP] Embed Pods Frameworks" - this is managed by CocoaPods

### Step 3: Clean Build Folder

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. Wait for it to complete

### Step 4: Build and Test

1. **Product** → **Build** (⌘B)
2. **Check for errors** - if you see API changes, see "API Migration" below
3. **Run on device/simulator**
4. **Test Plaid connection** - the dyld crash should be resolved!

## 🔄 API Migration (If Needed)

LinkKit v4.x may have API changes from v3.1.1. Check:

1. **Import statements** - should still be `import LinkKit`
2. **LinkKit initialization** - check `PlaidConnectionView.swift`
3. **Handler creation** - API may have changed
4. **Success/Exit callbacks** - verify parameter types

### Common v3 → v4 Changes:
- LinkKit handler creation may use different API
- Callback signatures may have changed
- Configuration options may be different

If you see compilation errors, check:
- [Plaid Link iOS SDK Documentation](https://plaid.com/docs/link/ios/)
- [Migration Guide](https://plaid.com/docs/link/ios/migration/)

## ✅ Verification Checklist

After completing all steps:

- [ ] Manual LinkKit embedding removed from General tab
- [ ] No LinkKit in "Embed Frameworks" build phase
- [ ] "[CP] Embed Pods Frameworks" still present (managed by CocoaPods)
- [ ] Clean build folder completed
- [ ] Build succeeds without errors
- [ ] App launches without dyld crash
- [ ] Plaid connection flow works

## 📋 What Changed

### Podfile
- **Before**: `pod 'Plaid', '~> 3.0'` (v3.1.1)
- **After**: `pod 'Plaid', '~> 4.1'` (v4.7.9)

### Post-Install Hooks
- **Removed**: All custom hooks that modified LinkKit embedding
- **Kept**: Only deployment target and sandbox settings

### Integration Method
- **Before**: Manual embedding + CocoaPods (caused conflicts)
- **After**: CocoaPods only (fully managed)

## 🐛 Troubleshooting

### If build fails with "LinkKit not found":
- Make sure you're opening `.xcworkspace`, not `.xcodeproj`
- Run `pod install` again
- Clean build folder

### If you still see duplicate embedding error:
- Verify manual LinkKit was removed from General tab
- Check Build Phases for any remaining LinkKit references
- Run `pod deintegrate && pod install` again

### If app crashes with different error:
- Check crash logs for new error details
- Verify NSCameraUsageDescription is in Info.plist
- Check if API changes require code updates

## 📚 References

- [Plaid Link iOS SDK Installation](https://plaid.com/docs/link/ios/)
- [Plaid LinkKit CocoaPods](https://cocoapods.org/pods/Plaid)
- [Migration Guide](https://plaid.com/docs/link/ios/migration/)

