# Critical Fix: Firebase Packages Not Resolving

## The Issue

Xcode shows "Missing package product 'FirebaseCore'" and "Missing package product 'FirebaseAuth'" even though:
- ✅ Packages are configured in project file
- ✅ Packages are downloaded
- ✅ Project file references are correct

## Root Cause

Xcode's package resolution system isn't recognizing the packages. This is a common Xcode bug.

## The Fix (Do This Now)

### Step 1: Close Xcode Completely
- **Quit Xcode** (⌘Q) - make sure it's fully closed, not just the window

### Step 2: Delete Package Resolution Files
Run this in Terminal:
```bash
cd /Users/frankschioppa/soteria
rm -rf soteria.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
rm -rf soteria.xcworkspace/xcshareddata/swiftpm
```

### Step 3: Reopen Xcode
1. **Open** `soteria.xcworkspace` in Xcode
2. **Wait** for Xcode to finish loading (watch progress bar)

### Step 4: Force Package Resolution
1. **Select the project** (blue icon at top)
2. **Select the project** (not target) in editor
3. Go to **"Package Dependencies"** tab
4. You should see **firebase-ios-sdk** listed
5. If it shows an error or warning:
   - **Right-click** on it
   - Select **"Update to Latest Package Versions"**
   - OR click the **refresh icon** next to it

### Step 5: Alternative - Re-add Package
If Step 4 doesn't work:

1. In **Package Dependencies** tab
2. **Remove** firebase-ios-sdk (select and delete)
3. Click **"+"** button
4. Enter: `https://github.com/firebase/firebase-ios-sdk`
5. Click **"Add Package"**
6. Select **FirebaseCore** and **FirebaseAuth**
7. Click **"Add Package"**

### Step 6: Clean and Build
1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)

## Why This Works

Deleting the swiftpm directories forces Xcode to completely re-resolve packages from scratch, which often fixes recognition issues.

## If Still Failing

Try this nuclear option:
1. Close Xcode
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/soteria-*`
3. Delete swiftpm dirs (as above)
4. Reopen Xcode
5. Resolve packages

The packages ARE there - Xcode just needs to recognize them properly!

