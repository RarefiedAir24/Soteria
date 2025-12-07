# Family Controls Setup Instructions

Follow these steps to add the FamilyControls framework and capability to your Xcode project:

## Step 1: Add Family Controls Capability

1. Open your project in Xcode
2. Select the **rever** target (main app, not the extension)
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Search for and add **Family Controls**
6. This will automatically add the entitlement to your app

## Step 2: Link FamilyControls Framework

1. Still in the **rever** target, go to the **General** tab
2. Scroll down to **Frameworks, Libraries, and Embedded Content**
3. Click the **+** button
4. Search for **FamilyControls.framework**
5. Select it and click **Add**
6. Make sure it's set to **Do Not Embed** (FamilyControls is a system framework)

## Step 3: Verify Entitlements File

The entitlements file `rever.entitlements` has been created with the family-controls entitlement. Verify it's linked:

1. Go to **Build Settings** for the **rever** target
2. Search for **Code Signing Entitlements**
3. Make sure it shows: `rever/rever.entitlements`

## Step 4: Request Authorization

The app needs to request Family Controls authorization. This is already handled in the code, but you'll need to:

1. Run the app on a device (Family Controls doesn't work in simulator)
2. When you tap "Select Apps to Monitor", iOS will prompt for authorization
3. Grant the permission in Settings → Screen Time → Family Controls

## Notes

- Family Controls requires iOS 15.0+
- Must run on a physical device (not simulator)
- User must grant Screen Time permissions
- The extension (ReverMonitor) already has the entitlement configured

