# Fix Missing Firebase Packages

## The Problem

Xcode can't find Firebase packages (FirebaseCore, FirebaseAuth, etc.). This is a Swift Package Manager dependency resolution issue.

## Quick Fix in Xcode

### Method 1: Resolve Packages (Easiest)

1. **Open** `soteria.xcworkspace` in Xcode
2. **Select the project** (top item in navigator - the blue icon)
3. **Select the project** (not target) in the editor - you should see "PROJECT" and "TARGETS" sections
4. Go to **"Package Dependencies"** tab (at the top)
5. You should see Firebase packages listed
6. Click **"Resolve Package Versions"** button (or right-click → Resolve Package Versions)
7. Wait for packages to download and resolve

### Method 2: Reset and Resolve

If Method 1 doesn't work:

1. **File** → **Packages** → **Reset Package Caches**
2. Wait for it to complete
3. **File** → **Packages** → **Resolve Package Versions**
4. Wait for packages to download

### Method 3: Update Packages

1. **File** → **Packages** → **Update to Latest Package Versions**
2. Wait for packages to update

### Method 4: Add Firebase Manually (If Not Present)

If Firebase packages aren't listed at all:

1. **Select the project** (blue icon)
2. **Select the project** (not target) in editor
3. Go to **"Package Dependencies"** tab
4. Click **"+"** button
5. Enter Firebase URL: `https://github.com/firebase/firebase-ios-sdk`
6. Click **"Add Package"**
7. Select the packages you need:
   - ✅ FirebaseCore
   - ✅ FirebaseAuth
   - ✅ (Any others your app uses)
8. Click **"Add Package"**

## Verify Firebase is Added

After resolving, check:
1. **Package Dependencies** tab should show Firebase packages
2. Packages should have checkmarks (resolved)
3. No red error indicators

## Common Issues

### "Couldn't update repository submodules"
- This is a network/Git issue
- Try: **File** → **Packages** → **Reset Package Caches**
- Then resolve again

### Packages Keep Failing
- Check your internet connection
- Try closing and reopening Xcode
- Try: **File** → **Packages** → **Reset Package Caches**
- Then: **File** → **Packages** → **Update to Latest Package Versions**

## After Resolving

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)
3. Firebase errors should be gone

## What Firebase Packages Do You Need?

Based on your code, you likely need:
- **FirebaseCore** - Core Firebase functionality
- **FirebaseAuth** - Authentication (you use `Auth.auth()`)

Check your imports in code to see which other Firebase packages you might need.

