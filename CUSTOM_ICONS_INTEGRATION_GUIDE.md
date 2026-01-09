# 🎨 Custom Icons Integration Guide - 16 Animals

## 📦 **Complete Animal Collection:**

| # | Name | Icon Name | Points | Size | Unlock | File Name |
|---|------|-----------|--------|------|--------|-----------|
| 1 | Snail | 🐌 | 80 | Small | Starter | `snail.pdf` |
| 2 | Rabbit | 🐰 | 100 | Medium | Starter | `rabbit.pdf` |
| 3 | Chicken | 🐔 | 120 | Small | Starter | `chicken.pdf` |
| 4 | Hen | 🐓 | 150 | Medium | 200 pts | `hen.pdf` |
| 5 | Duck | 🦆 | 190 | Small | $300 | `duck.pdf` |
| 6 | Rooster | 🦆 | 200 | Medium | 400 pts | `rooster.pdf` |
| 7 | Sheep | 🐑 | 210 | Medium | 500 pts | `sheep.pdf` |
| 8 | Pig | 🐷 | 220 | Medium | 600 pts | `pig.pdf` |
| 9 | Goat | 🐐 | 240 | Medium | $800 | `goat.pdf` |
| 10 | Cow | 🐄 | 250 | Large | $1,000 | `cow.pdf` |
| 11 | Donkey | 🫏 | 270 | Large | 1 goal | `donkey.pdf` |
| 12 | Bull | 🐂 | 280 | Large | 2 goals | `bull.pdf` |
| 13 | Deer | 🦌 | 300 | Large | $1,500 | `deer.pdf` |
| 14 | Horse | 🐴 | 350 | Large | $2,000 | `horse.pdf` |
| 15 | Llama | 🦙 | 380 | Large | 3 goals | `llama.pdf` |
| 16 | Buffalo | 🦬 | 400 | Large | $5,000 | `buffalo.pdf` |

---

## 🔧 **Step 1: Add Icons to Xcode Assets**

### **Method: Drag & Drop All at Once**

1. **Open Xcode**
2. Navigate to: `soteria/Assets.xcassets`
3. **Create 16 new Image Sets** (Right-click → New Image Set)
   - Name them exactly: `snail`, `rabbit`, `chicken`, `hen`, `duck`, `rooster`, `sheep`, `pig`, `goat`, `cow`, `donkey`, `bull`, `deer`, `horse`, `llama`, `buffalo`

4. **For EACH icon:**
   - Drag your `.pdf` or `.svg` file into the image well
   - Select the image set in the left panel
   - In **Attributes Inspector** (right panel):
     - ✅ **Scales**: "Single Scale"
     - ✅ **Resizing**: "Preserve Vector Data"
     - ✅ **Render As**: "Original Image" (to keep colors)

---

## 🔗 **Step 2: Update Icon Names in Catalog**

Once assets are added, update `soteria/Models/SceneItem.swift`:

```swift
// Replace emoji with asset name
iconName: "snail",    // was "🐌"
iconName: "rabbit",   // was "🐇"
iconName: "chicken",  // was "🐔"
iconName: "hen",      // was "🐓"
iconName: "duck",     // was "🦆"
iconName: "rooster",  // was "🐓"
iconName: "sheep",    // was "🐑"
iconName: "pig",      // was "🐷"
iconName: "goat",     // was "🐐"
iconName: "cow",      // was "🐄"
iconName: "donkey",   // was "🫏"
iconName: "bull",     // was "🐂"
iconName: "deer",     // was "🦌"
iconName: "horse",    // was "🐴"
iconName: "llama",    // was "🦙"
iconName: "buffalo",  // was "🦬"
```

---

## ✅ **Current Status:**

### **Already Implemented:**
✅ **SceneItem catalog** with all 16 animals  
✅ **SceneItemIcon view** (auto-detects emoji vs custom image)  
✅ **Flip orientation feature** (tap to flip left/right)  
✅ **Loyalty shop** integration  
✅ **Scene editor** integration  
✅ **Money tree scene** integration  
✅ **Cloud sync** for placements  
✅ **Unlock requirements** configured  

### **Ready to Test:**
1. ✅ Purchase items in loyalty shop
2. ✅ Place on scene
3. ✅ Drag to reposition
4. ✅ Tap to flip orientation
5. ✅ Remove from scene editor
6. ✅ Persistence across app restarts

---

## 🧪 **Testing Checklist:**

- [ ] All 16 icons render in loyalty shop
- [ ] Icons match between shop/scene/editor (consistency)
- [ ] Purchase mechanics work (point deduction)
- [ ] Placement on scene works
- [ ] Drag & drop repositioning works
- [ ] Tap-to-flip works (left/right orientation)
- [ ] Icons scale correctly (small/medium/large)
- [ ] Unlock requirements work
- [ ] Persistence works (app restart)
- [ ] Cloud sync works (reinstall)
- [ ] Performance is good with all 16 items placed

---

## 🎯 **Integration Summary:**

**Files Modified:**
- ✅ `soteria/Models/SceneItem.swift` - 16 animals added
- ✅ `soteria/Models/SceneItemPlacement.swift` - flip support
- ✅ `soteria/Views/SceneItemIcon.swift` - custom image rendering
- ✅ `soteria/Views/LoyaltyShopView.swift` - shop display
- ✅ `soteria/Views/MoneyTreeView.swift` - scene display with flip
- ✅ `soteria/Views/SceneEditorView.swift` - management UI
- ✅ `soteria/Services/SceneManager.swift` - flip logic

**Assets to Add:**
- [ ] 16 vector files (`.pdf` or `.svg`)

**Once assets are added, the system is 100% ready!** 🚀

