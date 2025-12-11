# Xcode Settings Check for Plaid LinkKit

## Current View
You're on the **Info** tab of project settings.

## Step 1: Check Framework Embedding (CRITICAL)

1. **Click the "General" tab** (next to "Info" tab)
2. **Scroll down** to find **"Frameworks, Libraries, and Embedded Content"** section
3. **Look for** `LinkKit.framework` in the list
4. **Check the dropdown** next to it - it should say:
   - ✅ **"Embed & Sign"** (CORRECT)
   - ❌ **"Do Not Embed"** (WRONG - will cause dyld crash)

**If it says "Do Not Embed":**
- Click the dropdown
- Change it to **"Embed & Sign"**
- This is critical - missing this causes the dyld crash!

## Step 2: Check Bitcode (CRITICAL)

1. **Click the "Build Settings" tab** (next to "General" tab)
2. **Click in the search bar** at the top right
3. **Type**: `bitcode`
4. **Find** "Enable Bitcode" setting
5. **Check the value** - it should be:
   - ✅ **"No"** (CORRECT)
   - ❌ **"Yes"** (WRONG - Plaid doesn't support Bitcode)

**If it says "Yes":**
- Click on the value
- Change it to **"No"**
- This is required - Plaid LinkKit doesn't support Bitcode

## Step 3: Verify Deployment Target

1. **Stay on "General" tab**
2. **Look for "Deployment Info"** section
3. **Check "iOS"** - should be **15.0** or higher ✅
   - Minimum required: **13.0**
   - You have: **15.0** ✅

## Step 4: After Making Changes

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Run `pod install`** in terminal:
   ```bash
   cd /Users/frankschioppa/soteria && pod install
   ```
3. **Product** → **Build** (⌘B)
4. **Test the app** - dyld crash should be fixed!

## What to Report Back

Please let me know:
1. ✅/❌ Framework Embedding: "Embed & Sign" or "Do Not Embed"?
2. ✅/❌ Bitcode: "No" or "Yes"?
3. ✅/❌ Deployment Target: What version?

These are the most common causes of the dyld crash!

