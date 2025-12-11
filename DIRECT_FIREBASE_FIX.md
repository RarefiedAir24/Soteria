# Direct Fix: Remove and Re-add Firebase Package

## The Issue

Xcode UI is not recognizing Firebase packages even though they're configured. This is a common Xcode bug that requires removing and re-adding the package.

## The Fix (Do This in Xcode)

### Step 1: Remove Firebase Package

1. **Open** `soteria.xcworkspace` in Xcode
2. **Select the project** (blue icon at top of navigator)
3. **Select the project** (not target) in the editor
4. Go to **"Package Dependencies"** tab
5. Find **"firebase-ios-sdk"** in the list
6. **Select it** and press **Delete** (or right-click → Remove)
7. Confirm removal

### Step 2: Re-add Firebase Package

1. In the same **"Package Dependencies"** tab
2. Click the **"+"** button (bottom left)
3. In the search/URL field, enter:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
4. Click **"Add Package"**
5. Wait for it to fetch package information
6. In the package products list, check:
   - ✅ **FirebaseCore**
   - ✅ **FirebaseAuth**
7. Make sure **"Add to Target: soteria"** is selected
8. Click **"Add Package"**

### Step 3: Verify

1. In **Package Dependencies** tab, you should see:
   - firebase-ios-sdk with a checkmark ✅
   - FirebaseCore listed
   - FirebaseAuth listed

### Step 4: Clean and Build

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)

## Why This Works

Removing and re-adding forces Xcode to:
- Create fresh package references
- Re-resolve with current project location
- Properly link products to your target

## Alternative: Check Target Linkage

If re-adding doesn't work, verify the target linkage:

1. **Select the `soteria` target** (not project)
2. Go to **"General"** tab
3. Scroll to **"Frameworks, Libraries, and Embedded Content"**
4. You should see:
   - FirebaseCore
   - FirebaseAuth
5. If they're missing, click **"+"** and add them

## If Still Failing

Try this nuclear option:

1. Close Xcode
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/soteria-*`
3. Reopen Xcode
4. Remove and re-add Firebase package (as above)

**The key is removing the old package reference and creating a fresh one with the new project location!**

