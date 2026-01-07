# Export Error Troubleshooting

**Error**: "Exporting for App Store Distribution failed"

---

## 🔍 Common Causes & Solutions

### 1. **Code Signing Issues**

**Symptoms**: Export fails with signing errors

**Solutions**:
- ✅ Use **"Automatically manage signing"** (recommended)
- ✅ Verify Team ID: `4P5YXTJ7U7` (Montebay Innovations LLC)
- ✅ Check Bundle ID matches: `io.montebay.soteria`

### 2. **Missing App Icon**

**Symptoms**: Export fails with icon errors

**Solutions**:
- ✅ Check `Assets.xcassets/AppIcon.appiconset`
- ✅ Ensure 1024x1024 icon exists
- ✅ Verify all required icon sizes

### 3. **Entitlements Issues**

**Symptoms**: Export fails with entitlement errors

**Solutions**:
- ✅ Check `soteria.entitlements` file
- ✅ Verify all capabilities are valid
- ✅ Ensure Pass Type ID is configured

### 4. **Framework Issues**

**Symptoms**: Export fails with framework errors

**Solutions**:
- ✅ Ensure CocoaPods are installed: `pod install`
- ✅ Use `.xcworkspace` not `.xcodeproj`
- ✅ Verify framework embedding settings

---

## ✅ Quick Fixes to Try

### Fix 1: Clean and Rebuild
```bash
# In Xcode:
Product → Clean Build Folder (⇧⌘K)
Product → Archive
```

### Fix 2: Verify Signing
1. **Xcode** → **Project Settings** → **Signing & Capabilities**
2. **Team**: Montebay Innovations LLC
3. **Bundle ID**: `io.montebay.soteria`
4. **Signing**: Automatic

### Fix 3: Check Export Options
- ✅ **Method**: App Store Connect
- ✅ **Include Symbols**: Yes
- ✅ **Include Bitcode**: No
- ✅ **Automatically manage signing**: Yes

---

## 📋 What to Check

### In Xcode Export Dialog:

1. **Distribution Method**:
   - ✅ App Store Connect (not Ad Hoc)

2. **Distribution Options**:
   - ✅ Upload (not Export)

3. **App Store Connect Options**:
   - ✅ Include symbols for debugging
   - ❌ Include bitcode (deprecated)

4. **Signing**:
   - ✅ Automatically manage signing
   - ✅ Team: Montebay Innovations LLC

---

## 🔧 Alternative: Use Already Exported IPA

**Good News**: We already exported the IPA successfully via command line!

**Location**: `build/export/soteria.ipa` (10MB)

**You can**:
1. **Use Transporter app** to upload the existing IPA
2. **Or** fix the Xcode export issue and try again

---

## ⚠️ The Warnings Are OK

All those warnings are **non-blocking**:
- ✅ They're just deprecation warnings
- ✅ They won't prevent export
- ✅ Can be fixed later

**The actual error** is something else - need to see the full error message.

---

## 🎯 Next Steps

1. **Check the full error message** in Xcode (click "Download Logs")
2. **Or** use the already-exported IPA: `build/export/soteria.ipa`
3. **Upload via Transporter** app (easiest)

---

**Can you share the full error message from Xcode?** (Click "Download Logs" in the error dialog)

