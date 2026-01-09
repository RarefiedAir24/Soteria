# 🎨 Custom Icon Pack Integration Guide

## Overview
The loyalty shop now supports **custom image assets** in addition to emojis and SF Symbols. Icons shown in the shop are **guaranteed to match** what appears on the scene.

---

## ✅ **Current Status**

### **Updated Animal Icons (Full Body)**
- 🐇 Rabbit (was 🐰 face)
- 🐕 Dog (new)
- 🐈 Cat (new)
- 🕊️ Dove (was generic bird head)
- 🦜 Parrot (new)
- 🐢 Turtle (new)
- 🐿️ Squirrel, 🦔 Hedgehog, 🦋 Butterfly, 🐝 Bee, 🐞 Ladybug (already full body)

### **Rendering System**
Created unified `SceneItemIcon` view that automatically detects and renders:
1. **Emoji** (1-2 characters, no tint)
2. **SF Symbols** (contains `.`, with tint)
3. **Custom Images** (from Assets.xcassets, with tint)

---

## 📦 **How to Add Custom Icons from Your Icon Pack**

### **Step 1: Prepare Your Icon Files**
Ensure your icons are:
- **Format**: PNG or PDF (vector preferred)
- **Size**: At least 256x256px (or vector)
- **Background**: Transparent
- **Color**: Single color (black/white) for best tinting, or full color if you prefer

### **Step 2: Add to Xcode Assets**
1. Open Xcode
2. Navigate to `soteria/Assets.xcassets`
3. Right-click → **New Image Set**
4. Name it (e.g., `rabbit_custom`, `bird_custom`)
5. Drag your icon files into the slots:
   - **1x**: 256x256px
   - **2x**: 512x512px
   - **3x**: 768x768px
   - Or drag a single PDF for all resolutions

### **Step 3: Update SceneItem Catalog**
Edit `soteria/Models/SceneItem.swift`:

```swift
SceneItem(
    id: "rabbit",
    name: "Rabbit",
    description: "A friendly rabbit hopping near your tree",
    pointCost: 100,
    category: .animal,
    iconName: "rabbit_custom",  // ← Change to your asset name
    position: .ground,
    size: .medium,
    unlockRequirement: nil
)
```

### **Step 4: Test**
1. Build and run the app
2. Open Loyalty Shop → icons should render
3. Purchase item → same icon appears on scene
4. Open Scene Editor → same icon shown

---

## 🎨 **Rendering Modes**

### **Option A: Template (Tintable Icons)**
Best for: Consistent UI, adaptive colors

```swift
// In Assets.xcassets, set:
Render As: Template Image

// Result: Icon changes color based on context:
// - Blue in shop (available)
// - Green on scene (purchased)
// - Gray (locked)
```

### **Option B: Original (Full Color Icons)**
Best for: Detailed, colorful illustrations

```swift
// In Assets.xcassets, set:
Render As: Original Image

// Result: Icon keeps original colors everywhere
```

---

## 📋 **Icon Pack Checklist**

When you upload your icon pack, I'll need:

- [ ] **File format** (PNG, SVG, PDF?)
- [ ] **Naming convention** (e.g., `rabbit.png`, `bird-1.svg`)
- [ ] **Categories**:
  - [ ] Animals (how many?)
  - [ ] Plants (how many?)
  - [ ] Decorations (how many?)
- [ ] **Color style** (single color for tinting, or full color?)
- [ ] **License** (can we use these commercially?)

---

## 🔄 **Quick Batch Update Script**

If you have many icons to add, I can create a script to:
1. Batch import all icons to Assets.xcassets
2. Auto-generate SceneItem entries
3. Map icon names to categories

Just provide the icon pack structure and I'll build the automation.

---

## 🎯 **Consistency Guarantee**

The `SceneItemIcon` view is used in **all 3 places**:
1. ✅ Loyalty Shop (preview card)
2. ✅ Money Tree Scene (placed items)
3. ✅ Scene Editor (inventory)

**Result**: Users see exactly the same icon in the shop as they get on their scene.

---

## 📤 **Ready for Your Icon Pack**

Upload your icon pack and let me know:
1. Format (PNG/SVG/PDF)
2. Total number of icons
3. Categories you want
4. Preferred rendering mode (tintable vs full color)

I'll integrate them all at once! 🚀

