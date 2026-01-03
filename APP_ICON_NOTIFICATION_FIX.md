# App Icon Not Showing in Notifications - Fix Guide

## Issue
The Soteria app icon is not appearing in notification banners, even though it's uploaded in Xcode assets.

## Root Cause
The app icon file (`Asset 1.png`) is referenced in `Contents.json` but may not be properly saved or assigned in Xcode.

## Solution Steps

### Step 1: Verify Icon in Xcode
1. Open Xcode
2. Navigate to: `soteria/Assets.xcassets/AppIcon.appiconset`
3. Check if you see your icon image in the **Universal** slot (1024x1024)
4. If the slot is empty or shows a placeholder, the icon isn't properly assigned

### Step 2: Properly Add the Icon
1. In Xcode, click on the **Universal** slot (the one that says "1024x1024")
2. Drag and drop your 1024x1024 PNG icon image directly onto the slot
3. **Important**: Make sure the image actually appears in the slot (not just a reference)
4. The file should automatically be saved to: `soteria/Assets.xcassets/AppIcon.appiconset/Asset 1.png`

### Step 3: Verify File Exists
After adding the icon in Xcode:
1. Check if the file exists: `soteria/Assets.xcassets/AppIcon.appiconset/Asset 1.png`
2. If it doesn't exist, try:
   - Right-click the slot in Xcode → "Show in Finder"
   - Or manually copy your icon file to that location

### Step 4: Clean Build
1. In Xcode: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Delete the app from your device/simulator
3. Rebuild the app: **Product → Build** (Cmd+B)
4. Run the app: **Product → Run** (Cmd+R)

### Step 5: Verify Icon Appears
1. Check the home screen - your app icon should appear
2. Send a test notification - the icon should appear in the notification banner
3. If still not showing, check:
   - Icon is exactly 1024x1024 pixels
   - Icon is PNG format (no transparency for app icon)
   - Icon is square (not rectangular)

## Common Issues

### Issue 1: Icon Shows in Xcode but Not in App
**Cause**: Icon not properly saved or build cache issue
**Fix**: Clean build folder and rebuild

### Issue 2: Icon Shows in App but Not in Notifications
**Cause**: iOS caches notification icons
**Fix**: 
- Delete app completely from device
- Restart device (optional but helps)
- Reinstall app

### Issue 3: Icon File Missing
**Cause**: Icon not properly added to asset catalog
**Fix**: 
- Remove icon from Xcode (delete from slot)
- Re-add icon by dragging directly onto the Universal slot
- Make sure it saves to the correct location

## Verification Checklist

- [ ] Icon is 1024x1024 pixels
- [ ] Icon is PNG format
- [ ] Icon is square (not rectangular)
- [ ] Icon appears in Xcode's AppIcon asset catalog
- [ ] Icon is assigned to the Universal slot
- [ ] File exists at: `soteria/Assets.xcassets/AppIcon.appiconset/Asset 1.png`
- [ ] Clean build performed
- [ ] App rebuilt and reinstalled
- [ ] Icon appears on home screen
- [ ] Icon appears in notification banners

## Technical Details

### How iOS Uses App Icons in Notifications

1. **Automatic**: iOS automatically uses the app icon from the asset catalog
2. **Source**: The icon comes from `AppIcon.appiconset` in your Assets.xcassets
3. **Size**: iOS generates all required sizes from your 1024x1024 image
4. **Cannot Override**: You cannot programmatically change the notification icon - it's always your app icon

### Project Configuration

Your project is correctly configured:
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` ✅
- Asset catalog location: `soteria/Assets.xcassets/AppIcon.appiconset` ✅
- Contents.json references: `Asset 1.png` ✅

The only missing piece is the actual `Asset 1.png` file.

## Next Steps

1. Follow Step 2 above to properly add the icon in Xcode
2. Verify the file exists after adding
3. Clean build and reinstall
4. Test notifications to confirm icon appears

If the icon still doesn't appear after following these steps, the issue may be:
- Icon file format/corruption
- Xcode asset catalog corruption
- iOS system cache (try restarting device)

