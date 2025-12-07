# Rename Project from "rever" to "soteria"

## ⚠️ Important: Close Xcode First!

Before running the rename script, make sure Xcode is completely closed.

## Option 1: Use the Script (Recommended)

1. **Close Xcode completely**
2. **Run the script**:
   ```bash
   cd /Users/frankschioppa/Desktop/rever
   ./rename-project.sh
   ```
3. **Follow the prompts**
4. **After renaming**, open the new workspace:
   ```bash
   cd /Users/frankschioppa/Desktop/soteria
   open soteria.xcworkspace  # or soteria.xcodeproj if no CocoaPods
   ```

## Option 2: Manual Rename in Xcode (Safer)

1. **Open Xcode** with `rever.xcworkspace`
2. **Select the project** in the navigator (top item)
3. **Press Enter** on the project name to rename it
4. **Type "soteria"** and press Enter
5. **Xcode will prompt** to rename all references - click "Rename"
6. **Close Xcode**
7. **Manually rename the folder**:
   ```bash
   cd /Users/frankschioppa/Desktop
   mv rever soteria
   ```
8. **Rename the project files**:
   ```bash
   cd soteria
   mv rever.xcodeproj soteria.xcodeproj
   mv rever.xcworkspace soteria.xcworkspace
   ```

## After Renaming

1. **Update Display Name in Xcode**:
   - Select project → Target → General
   - Set "Display Name" to "SOTERIA"

2. **Update Product Name**:
   - Select project → Target → Build Settings
   - Search for "Product Name"
   - Set to "soteria"

3. **Update Bundle Identifier** (optional):
   - Select project → Target → General
   - Update Bundle Identifier if needed

4. **If using CocoaPods**:
   ```bash
   cd /Users/frankschioppa/Desktop/soteria
   pod install
   ```

5. **Clean and Rebuild**:
   - In Xcode: Product → Clean Build Folder (Cmd+Shift+K)
   - Then: Product → Build (Cmd+B)

## What Gets Renamed

- ✅ Project folder: `rever` → `soteria`
- ✅ Xcode project: `rever.xcodeproj` → `soteria.xcodeproj`
- ✅ Workspace: `rever.xcworkspace` → `soteria.xcworkspace`
- ✅ Project references in `project.pbxproj`
- ✅ Podfile target names
- ✅ Workspace contents

## Notes

- The extension name "ReverMonitor" can stay as-is (it's fine to have different names)
- CocoaPods will need to be reinstalled after renaming
- Git history will be preserved if you're using version control

---

**Recommendation**: Use Option 2 (Manual in Xcode) as it's safer and Xcode handles most references automatically.

