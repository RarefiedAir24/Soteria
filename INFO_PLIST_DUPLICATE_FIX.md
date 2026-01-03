# Fix: Multiple Commands Produce Info.plist

## The Problem
Xcode error: "Multiple commands produce '/Users/frankschioppa/Library/Developer/Xcode/DerivedData/soteria-auoncdkphkfhuibdycnmtipowcgp/Build/Products/Debug-iphoneos/soteria.app/Info.plist'"

This happens when Xcode tries to both:
1. Auto-generate Info.plist (because `GENERATE_INFOPLIST_FILE = YES`)
2. Copy an explicit Info.plist file (from "Copy Bundle Resources" or widget extension)

## Solution

### Option 1: Check Build Phases (Most Common Fix)

1. **Open Xcode**
2. **Select your project** in the navigator (soteria.xcodeproj)
3. **Select the "soteria" target** (main app target)
4. **Click "Build Phases" tab**
5. **Expand "Copy Bundle Resources"**
6. **Look for any "Info.plist" file** in the list
7. **If found:**
   - Select it
   - Click the **"-"** button to remove it
8. **Clean Build Folder:** Product → Clean Build Folder (⇧⌘K)
9. **Build again:** Product → Build (⌘B)

### Option 2: Check Widget Extension Configuration

If you have a widget extension (SoteriaWidget):

1. **Select the "SoteriaWidget" target**
2. **Go to "Build Settings" tab**
3. **Search for "INFOPLIST_FILE"**
4. **Make sure it's set to:** `soteria/SoteriaWidget/Info.plist`
5. **Make sure "GENERATE_INFOPLIST_FILE" is set to "NO"** for the widget target
6. **Clean and rebuild**

### Option 3: Verify Main App Settings

For the main "soteria" target:

1. **Select "soteria" target**
2. **Go to "Build Settings" tab**
3. **Search for "GENERATE_INFOPLIST_FILE"**
4. **Make sure it's "YES"** ✅
5. **Search for "INFOPLIST_FILE"**
6. **Make sure it's EMPTY** (not set to any path) ✅

### Option 4: Remove Derived Data (Nuclear Option)

If the above don't work:

1. **Close Xcode**
2. **Delete Derived Data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/soteria-*
   ```
3. **Open Xcode**
4. **Clean Build Folder:** Product → Clean Build Folder (⇧⌘K)
5. **Build again:** Product → Build (⌘B)

## Expected Configuration

**Main App Target (soteria):**
- `GENERATE_INFOPLIST_FILE = YES` ✅
- `INFOPLIST_FILE = ` (empty/not set) ✅
- No Info.plist in "Copy Bundle Resources" ✅

**Widget Extension Target (SoteriaWidget):**
- `GENERATE_INFOPLIST_FILE = NO` ✅
- `INFOPLIST_FILE = soteria/SoteriaWidget/Info.plist` ✅
- Info.plist file exists in widget directory ✅

## Verification

After fixing, the build should succeed without the duplicate Info.plist error.

