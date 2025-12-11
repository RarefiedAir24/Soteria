# Fix: Remove Framework Embedding for Static Linking

## The Problem

Even though we set static linking in the Podfile, Xcode is still trying to **embed** the LinkKit framework, which causes rsync errors. With static linking, frameworks should NOT be embedded.

## The Fix (Must Do in Xcode)

### Step 1: Remove LinkKit from Embed Phase

1. **Open** `soteria.xcworkspace` in Xcode
2. **Select the project** (top item in navigator)
3. **Select the `soteria` target** (not the project)
4. Go to **"Build Phases"** tab
5. **Expand** "Embed Pods Frameworks" (or look for "Embed Frameworks")
6. **Find** `LinkKit.framework` in the list
7. **Select it** and press **Delete** (or click the **-** button)
8. **Remove it completely** from the list

### Step 2: Verify Build Settings

1. Still in **Build Settings** tab
2. Search for **"Always Embed Swift Standard Libraries"**
3. Set to **NO**
4. Search for **"Embed Frameworks"** 
5. Make sure it's not forcing embedding

### Step 3: Clean and Build

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)

## Why This Happens

- CocoaPods creates the "Embed Pods Frameworks" phase automatically
- Even with static linking, it might still add frameworks to embed
- Static frameworks are **linked into the binary**, not embedded separately
- The embed phase tries to copy the framework → rsync fails → build fails

## Verification

After removing LinkKit from embed phase:
- ✅ No rsync errors
- ✅ Build succeeds
- ✅ App runs
- ✅ Plaid SDK works (it's statically linked into your binary)

## Alternative: Disable Embed Phase Entirely

If you want to be more aggressive:

1. In **Build Phases**
2. Find **"Embed Pods Frameworks"**
3. You can **disable the entire phase** by unchecking it
4. Or just remove LinkKit from it (safer)

## Important

**With static linking, you should NOT embed frameworks.** The code is compiled directly into your app binary, so no separate framework file is needed.

