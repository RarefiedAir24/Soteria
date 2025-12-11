# Plaid LinkKit dyld Crash - Fix Checklist

Based on Plaid Support recommendations, here's what to check:

## ✅ Already Configured

1. **Integration Method**: CocoaPods (`pod 'Plaid', '~> 3.0'`)
   - ✅ Using CocoaPods (recommended alternative to SPM)
   - Note: Plaid recommends SPM, but CocoaPods should work

2. **Deployment Target**: iOS 15.0
   - ✅ Set to iOS 15.0 (requires 13.0+)
   - ✅ Meets minimum requirement

3. **NSCameraUsageDescription**: ✅ ADDED
   - ✅ Added to Info.plist: "Used for identity verification when connecting bank accounts"
   - This is required even if not using Identity Verification immediately

## ⚠️ Need to Check in Xcode

4. **Framework Embedding**: 
   - **Action Required**: In Xcode, go to:
     - Target → General → Frameworks, Libraries, and Embedded Content
     - Find `LinkKit.framework`
     - Must be set to **"Embed & Sign"** (not "Do Not Embed")
   - If it's "Do Not Embed", change it to "Embed & Sign"

5. **Bitcode**:
   - **Action Required**: In Xcode, go to:
     - Target → Build Settings → Search "bitcode"
     - Set **"Enable Bitcode"** to **NO**
   - Plaid LinkKit does NOT support Bitcode
   - If enabled, this can cause crashes

6. **Clean Build**:
   - **Action Required**: In Xcode:
     - Product → Clean Build Folder (⇧⌘K)
     - Product → Build (⌘B)

## 🔍 Additional Checks

7. **Framework Version Conflicts**:
   - Check if there are multiple versions of LinkKit
   - Remove any old/duplicate frameworks

8. **Stack Trace**:
   - If crash persists, check Xcode console for:
     - "dyld: Library not loaded: ..."
     - "image not found"
     - "Symbol not found: ..."

## Next Steps

1. **Add NSCameraUsageDescription** ✅ (Done)
2. **Check Framework Embedding** in Xcode (set to "Embed & Sign")
3. **Disable Bitcode** in Build Settings
4. **Clean Build Folder** (⇧⌘K)
5. **Rebuild** (⌘B)
6. **Test** - Try connecting accounts again

## If Still Crashing

After checking all the above:
1. Remove LinkKit completely from project
2. Re-add via CocoaPods: `pod install`
3. Verify framework is "Embed & Sign"
4. Clean and rebuild

## Alternative: Switch to SPM

If CocoaPods continues to cause issues, consider switching to SPM:
- Package URL: `https://github.com/plaid/plaid-link-ios-spm`
- Smaller download
- Avoids repository bloat

