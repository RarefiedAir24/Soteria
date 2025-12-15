# Fix: Time-Sensitive Notifications Entitlement Error

## Error Message

```
Provisioning profile "iOS Team Provisioning Profile: io.montebay.soteria.SoteriaMonitor" 
doesn't include the com.apple.developer.usernotifications.time-sensitive entitlement.
```

## Solution Options

### Option 1: Enable Automatic Signing (Recommended)

**In Xcode:**

1. **Select the project** in Navigator (top-level "soteria")
2. **Select target:** `SoteriaMonitor`
3. **Go to "Signing & Capabilities" tab**
4. **Check "Automatically manage signing"**
5. **Select your Team** (if not already selected)
6. **Xcode will regenerate the provisioning profile** with the new entitlement

**If it still fails:**
- Clean build folder: `Product → Clean Build Folder` (Cmd+Shift+K)
- Delete derived data: `File → Project Settings → Derived Data → Delete`
- Restart Xcode
- Try building again

### Option 2: Update Provisioning Profile Manually

**In Apple Developer Portal:**

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles**
3. **Identifiers** → Find `io.montebay.soteria.SoteriaMonitor`
4. **Edit** the App ID
5. **Enable "Time Sensitive Notifications"** capability
6. **Save**
7. **Profiles** → Find your provisioning profile
8. **Edit** → **Regenerate** → **Download**
9. **In Xcode:** Replace the provisioning profile

### Option 3: Remove Entitlement Temporarily (Development Only)

**If you don't need time-sensitive notifications for development:**

1. **Edit `SoteriaMonitor/SoteriaMonitor.entitlements`:**
   - Remove or comment out the time-sensitive entitlement:
   ```xml
   <!-- <key>com.apple.developer.usernotifications.time-sensitive</key> -->
   <!-- <true/> -->
   ```

2. **Build and test**
3. **Re-add before production** (Option 1 or 2)

**Note:** This will disable time-sensitive notifications, but the app will still work.

### Option 4: Use Different Provisioning Profile

**If automatic signing doesn't work:**

1. **In Xcode:** Signing & Capabilities
2. **Uncheck "Automatically manage signing"**
3. **Manually select a provisioning profile** that includes the entitlement
4. **Or create a new provisioning profile** with the entitlement

## Why This Happens

When you add a new entitlement to the entitlements file, the provisioning profile must be updated to include it. The provisioning profile is a certificate that tells iOS what capabilities your app is allowed to use.

**Automatic signing** should handle this automatically, but sometimes Xcode needs a nudge (clean build, restart, etc.).

## Verification

After fixing, verify the entitlement is included:

1. **Build the app** (should succeed)
2. **Check provisioning profile:**
   - In Xcode: Signing & Capabilities → Show Profile
   - Should see `com.apple.developer.usernotifications.time-sensitive`

## For Production

**Before submitting to App Store:**

1. Ensure entitlement is enabled in Apple Developer Portal
2. Use automatic signing (recommended)
3. Or manually create/update provisioning profile with entitlement
4. Test time-sensitive notifications work on device

## Quick Fix (Try This First)

```bash
# Clean build folder
# In Xcode: Product → Clean Build Folder (Cmd+Shift+K)

# Or via command line:
cd /Users/frankschioppa/soteria
rm -rf ~/Library/Developer/Xcode/DerivedData/soteria-*

# Then rebuild in Xcode
```

Then:
1. **Enable automatic signing** in Xcode
2. **Select your team**
3. **Build again**

This usually fixes it!

