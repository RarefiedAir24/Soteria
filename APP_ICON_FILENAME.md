# App Icon Filename

**Question**: What should the filename be for the app icon?

**Answer**: The filename doesn't matter - Xcode will handle it automatically!

---

## 📁 Current Setup

**Location**: `soteria/Assets.xcassets/AppIcon.appiconset/`

**Current files**:
- `Asset 1.png` (Universal - 1024x1024)
- `Asset 2.png` (Dark appearance - optional)
- `Asset 3.png` (Tinted appearance - optional)

---

## ✅ How to Add Your Icon

### Method 1: Drag & Drop in Xcode (Recommended)

1. **Open Xcode**
2. **Navigate to**: `soteria/Assets.xcassets/AppIcon.appiconset`
3. **Click on "Universal" slot** (1024x1024)
4. **Drag your icon file** into the slot
5. **Xcode automatically**:
   - Copies the file
   - Renames it appropriately
   - Updates `Contents.json`

**You don't need to worry about the filename!**

---

### Method 2: Manual File Replacement

If you want to replace manually:

1. **Save your icon as**: `Asset 1.png` (or any name)
2. **Copy to**: `soteria/Assets.xcassets/AppIcon.appiconset/`
3. **Replace** the existing `Asset 1.png`
4. **Or** update `Contents.json` to reference your filename

---

## 📋 Filename Options

### Option 1: Use Current Name
- **Filename**: `Asset 1.png`
- **Location**: `soteria/Assets.xcassets/AppIcon.appiconset/Asset 1.png`
- **Replace** the existing file

### Option 2: Any Name (Xcode Handles It)
- **Filename**: `soteria-icon.png` (or any name)
- **Drag into Xcode** - it will rename automatically

### Option 3: Descriptive Name
- **Filename**: `AppIcon-1024.png`
- **Drag into Xcode** - it will handle it

---

## 🎯 Recommended Approach

**Just drag your icon into Xcode**:
1. Save your icon as any name (e.g., `soteria-icon.png`)
2. Open Xcode → `Assets.xcassets/AppIcon.appiconset`
3. Drag file into "Universal" slot
4. Xcode handles the rest!

**No need to worry about the filename** - Xcode manages it automatically.

---

## 📝 What Xcode Does

When you drag a file into the icon slot:
- ✅ Copies the file to the correct location
- ✅ Renames it to match the asset catalog structure
- ✅ Updates `Contents.json` with the correct reference
- ✅ Handles all the file management

---

## ✅ Summary

**Filename doesn't matter** - just:
1. Create your 1024×1024 PNG icon
2. Save it with any name you want
3. Drag it into Xcode's AppIcon slot
4. Xcode handles the filename automatically!

**Easy!** Just focus on creating a great icon design.

