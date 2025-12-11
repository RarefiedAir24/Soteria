# Remove LinkKit from Embed Phase - CRITICAL FIX

## The Problem

Even with static linking, Xcode is still trying to **embed** the LinkKit framework, causing rsync errors. With static linking, frameworks should NOT be embedded.

## The Fix (Do This in Xcode NOW)

### Step 1: Open Build Phases

1. **Open** `soteria.xcworkspace` in Xcode
2. **Select the project** (blue icon at top)
3. **Select the `soteria` target** (not the project) in the editor
4. Go to **"Build Phases"** tab (at the top)

### Step 2: Find Embed Phase

Look for one of these:
- **"Embed Pods Frameworks"** 
- **"Embed Frameworks"**
- **"[CP] Embed Pods Frameworks"**

### Step 3: Remove LinkKit

1. **Expand** the embed phase (click the triangle)
2. **Find** `LinkKit.framework` in the list
3. **Select** `LinkKit.framework`
4. Press **Delete** key (or click the **"-"** button at bottom)
5. **Remove it completely** from the list

### Step 4: Verify

After removing, the embed phase should NOT contain LinkKit.framework.

### Step 5: Clean and Build

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)

## Why This Is Needed

With **static linking** (`use_frameworks! :linkage => :static`):
- Framework code is **compiled into your app binary**
- No separate framework file is needed
- No embedding is required
- The embed phase tries to copy the framework → rsync fails → build fails

## Visual Guide

In Build Phases, you should see something like:
```
📦 Embed Pods Frameworks
  ├─ Pods_soteria.framework
  └─ LinkKit.framework  ← DELETE THIS ONE
```

After removal:
```
📦 Embed Pods Frameworks
  └─ Pods_soteria.framework  ← Only this should remain
```

## If You Don't See LinkKit in Embed Phase

If LinkKit isn't listed but you still get rsync errors:

1. Check **"Copy Files"** build phases
2. Check if there's a **"Run Script"** phase that's copying frameworks
3. In **Build Settings**, search for **"Embed Frameworks"**
4. Make sure it's not forcing framework embedding

## Alternative: Disable Entire Embed Phase

If removing LinkKit doesn't work:

1. In **Build Phases**
2. Find **"Embed Pods Frameworks"**
3. **Uncheck the entire phase** (click the checkbox to disable it)
4. With static linking, you don't need to embed any frameworks

## Verification

After removing LinkKit:
- ✅ No rsync errors
- ✅ Build succeeds
- ✅ App runs
- ✅ Plaid SDK works (it's statically linked into your binary)

**This is the fix - remove LinkKit from the embed phase!**

