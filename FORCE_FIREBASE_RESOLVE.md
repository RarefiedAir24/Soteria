# Force Firebase Package Resolution

## The Problem

Even though packages are configured correctly, Xcode still shows "Missing package product" errors. This is an Xcode UI refresh issue.

## Solution: Force Resolution in Xcode

### Method 1: Reset Everything

1. **Close Xcode completely**
2. **Delete DerivedData**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/soteria-*
   ```
3. **Reopen** `soteria.xcworkspace` in Xcode
4. **Wait** for Xcode to index and resolve packages (watch the progress bar)
5. **File** → **Packages** → **Resolve Package Versions**
6. Wait for completion
7. **Product** → **Clean Build Folder** (⇧⌘K)
8. **Product** → **Build** (⌘B)

### Method 2: Check Package Dependencies Tab

1. **Select the project** (blue icon)
2. **Select the project** (not target) in editor
3. Go to **"Package Dependencies"** tab
4. You should see **firebase-ios-sdk** listed
5. If it shows an error or warning:
   - Click on it
   - Try to update or resolve
   - Make sure **FirebaseCore** and **FirebaseAuth** are checked

### Method 3: Re-add Firebase (If Needed)

If packages still don't resolve:

1. **Select the project** → **Package Dependencies** tab
2. **Remove** the firebase-ios-sdk package (if present)
3. Click **"+"** to add package
4. Enter: `https://github.com/firebase/firebase-ios-sdk`
5. Click **"Add Package"**
6. Select **FirebaseCore** and **FirebaseAuth**
7. Click **"Add Package"**

### Method 4: Verify Package.resolved

The `Package.resolved` file shows Firebase is configured. Xcode just needs to recognize it:

1. In Xcode, go to **File** → **Packages** → **Reset Package Caches**
2. Then **File** → **Packages** → **Resolve Package Versions**
3. Wait for completion

## Quick Command Line Fix

I've already resolved packages via command line. Now you need to:

1. **Close Xcode**
2. **Reopen** `soteria.xcworkspace`
3. **Wait** for Xcode to refresh (watch the progress indicator)
4. **Build** (⌘B)

## Verification

After resolving:
- ✅ No "Missing package product" errors
- ✅ Packages show as resolved in Package Dependencies tab
- ✅ Build succeeds

## If Still Failing

The packages ARE configured correctly (I verified the project file). This is purely an Xcode UI refresh issue. Try:
- Closing and reopening Xcode
- Resetting package caches
- Waiting for Xcode to finish indexing

