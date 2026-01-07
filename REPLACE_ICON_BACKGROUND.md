# Replace App Icon White Background with Mist Gray

**Goal**: Replace white background (#FFFFFF) with mistGray (#F2F4F7) in the app icon

---

## 🎨 Mist Gray Color

- **Hex**: `#F2F4F7`
- **RGB**: `242, 244, 247`
- **Description**: Very light gray with blue undertones

---

## ✅ Method 1: Using Image Editor (Easiest)

### In Photoshop/Preview/Figma:

1. **Open** `soteria/Assets.xcassets/AppIcon.appiconset/soteria-icon.png`

2. **Select white background**:
   - Use Magic Wand tool (tolerance: 10-20)
   - Or select by color: Select → Color Range → choose white

3. **Fill with mistGray**:
   - Color: `#F2F4F7` or RGB `242, 244, 247`
   - Fill the selection

4. **Export**:
   - 1024×1024 pixels
   - PNG format
   - No transparency (opaque)
   - Replace the original file

---

## ✅ Method 2: Using Preview (Mac Built-in)

1. **Open** the icon in Preview
2. **Tools** → **Adjust Color**
3. **Select white areas** (if possible)
4. **Or**: Use a different tool

**Better**: Use Photoshop, Figma, or another image editor

---

## ✅ Method 3: Manual Instructions

Since the icon needs to be edited in an image editor:

1. **Open** `soteria/Assets.xcassets/AppIcon.appiconset/soteria-icon.png` in your image editor

2. **Replace white (#FFFFFF) with mistGray (#F2F4F7)**:
   - Find and replace color
   - Or select white areas and fill with mistGray

3. **Save**:
   - Same location
   - Same filename
   - 1024×1024 pixels
   - PNG format
   - No transparency

---

## 📋 Quick Steps

1. Open icon in image editor (Photoshop, Figma, etc.)
2. Select white background areas
3. Fill with `#F2F4F7` (mistGray)
4. Export as PNG (1024×1024, opaque)
5. Replace file in Xcode

---

**The icon file is at**: `soteria/Assets.xcassets/AppIcon.appiconset/soteria-icon.png`

**Replace white (#FFFFFF) with mistGray (#F2F4F7)**!

