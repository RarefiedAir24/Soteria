# Fix: Local Network Permission

## Problem

iOS is blocking local network access with error:
- `Local network prohibited`
- `Code=-1009 "The Internet connection appears to be offline"`

## Root Cause

iOS 14+ requires apps to request permission to access local network resources. This is a privacy feature to prevent apps from scanning your local network without permission.

## Solution Applied

Added the required Info.plist keys to request local network access:

1. **NSLocalNetworkUsageDescription** - Explains why the app needs local network access
2. **NSBonjourServices** - Declares which Bonjour services the app uses

## What Changed

Updated `soteria.xcodeproj/project.pbxproj` to include:
- `INFOPLIST_KEY_NSLocalNetworkUsageDescription`
- `INFOPLIST_KEY_NSBonjourServices`

## Next Steps

1. **Rebuild the app in Xcode** (required for Info.plist changes)
2. **Run on your iPhone**
3. **iOS will prompt for local network permission** - Tap "Allow"
4. **Try connecting again** - Should work now!

## If Permission Prompt Doesn't Appear

1. Go to **Settings** → **Privacy & Security** → **Local Network**
2. Find **Soteria** in the list
3. Toggle it **ON**

## Alternative: Use iOS Simulator

If you want to avoid the permission prompt:
- Use **iOS Simulator** instead of physical device
- Simulator doesn't require local network permission
- Can access `localhost:8000` directly

## Verify

After granting permission, the connection should work. Check:
- Server is running: `curl http://localhost:8000/health`
- Mac and iPhone on same Wi-Fi network
- Firewall allows port 8000 (if enabled)

