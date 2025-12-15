# How to Remove Firebase Frameworks (To Fix Crash)

## The Problem
The app crashes before any Swift code runs because Firebase frameworks are linked and being loaded by dyld (dynamic linker) at startup. Even though we've disabled Firebase in code, the frameworks are still linked in the project.

## Solution: Remove Firebase from Linked Frameworks

### Step 1: Open Xcode
1. Open `soteria.xcworkspace` (NOT `soteria.xcodeproj`)
2. Wait for Xcode to finish loading

### Step 2: Select the Project
1. Click the **blue icon** at the top of the file navigator (this is the project)
2. In the main editor area, you should see project settings

### Step 3: Select the Target
1. Under "TARGETS" in the left sidebar, click **"soteria"** (the main app target, not "SoteriaMonitor")

### Step 4: Go to Build Phases
1. Click the **"Build Phases"** tab at the top
2. You should see several sections like "Compile Sources", "Link Binary With Libraries", etc.

### Step 5: Remove Firebase Frameworks
1. Expand **"Link Binary With Libraries"** section
2. Look for:
   - `FirebaseCore.framework` (or just "FirebaseCore")
   - `FirebaseAuth.framework` (or just "FirebaseAuth")
   - `UserNotifications.framework` (if it's there)
3. Select each one and press **Delete** key (or click the "-" button)
4. Confirm removal if prompted

### Step 6: Clean Build
1. Go to **Product** → **Clean Build Folder** (or press ⇧⌘K)
2. Wait for it to finish

### Step 7: Try Building Again
1. Connect your device
2. Press **⌘R** to run
3. The app should now launch without crashing

## Alternative: If You Can't Find Build Phases

If you can't find "Build Phases":
1. Make sure you selected the **TARGET** (soteria), not the PROJECT
2. The tabs at the top should be: General, Signing & Capabilities, Resource Tags, Info, Build Settings, Build Phases, Build Rules
3. Click "Build Phases"

## What This Does

Removing Firebase from "Link Binary With Libraries" prevents dyld from trying to load the frameworks at app startup. This should fix the crash.

## After Testing

Once we confirm the crash is fixed, we can:
1. Re-enable Firebase properly
2. Re-add the frameworks
3. Fix any configuration issues

## Note

The code changes we made (commenting out Firebase imports) prevent compilation errors, but the crash is happening at the framework loading level (dyld), which happens before any Swift code runs. That's why we need to remove the frameworks from the linked libraries.

