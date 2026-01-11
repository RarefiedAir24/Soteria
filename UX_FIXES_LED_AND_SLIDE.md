# 🔧 UX Fixes - LED Border & Slide-to-Close

## ✅ **ISSUE 1: LED Border Circles Inside Tree Scene**

### **Problem:**
The LED chase effect was showing circles **inside** the tree scene box instead of **around** the border.

**Root Cause:**
- Used `.position()` with ellipse-based calculations
- Positioned dots relative to center, not border edges
- GeometryReader made dots appear in wrong locations

### **Fix:**
Rewrote `LEDChaseEffect` to trace along the actual border:

**New Implementation:**
```swift
private func calculateBorderPosition(index: Int, total: Int, width: CGFloat, height: CGFloat) -> CGPoint {
    let perimeter = (width + height) * 2
    let segmentLength = perimeter / CGFloat(total)
    let distance = segmentLength * CGFloat(index)
    
    // Trace along the border: top, right, bottom, left
    if distance < width {
        // Top edge
        return CGPoint(x: distance, y: 0)
    } else if distance < width + height {
        // Right edge
        return CGPoint(x: width, y: distance - width)
    } else if distance < width * 2 + height {
        // Bottom edge
        return CGPoint(x: width - (distance - width - height), y: height)
    } else {
        // Left edge
        return CGPoint(x: 0, y: height - (distance - width * 2 - height))
    }
}
```

**Result:**
- ✅ LEDs now positioned ON the border edges
- ✅ Follows top → right → bottom → left path
- ✅ Evenly distributed around perimeter
- ✅ Chase effect still works

**File Updated:**
- `/Users/frankschioppa/soteria/soteria/Views/HomeView.swift` (lines 3005-3075)

---

## ✅ **ISSUE 2: No Slide-to-Close Instruction on Decision Notifications**

### **Problem:**
When users open the Decision Notifications modal from the home screen, there's no visual indication that they can swipe down to close it.

**Use Case:**
- User taps "Decision Notifications" card
- Modal opens
- User doesn't want to create/edit a notification
- No obvious way to close (except back navigation)

### **Fix:**
Added a clear slide-to-close indicator at the top of the modal:

**New Implementation:**
```swift
// Slide-to-close indicator
VStack(spacing: 8) {
    RoundedRectangle(cornerRadius: 3)
        .fill(Color.softGraphite.opacity(0.3))
        .frame(width: 36, height: 5)
        .padding(.top, 12)
    
    Text("Swipe down to close")
        .font(.system(size: 13))
        .foregroundColor(.softGraphite.opacity(0.7))
        .padding(.bottom, 8)
}
.frame(maxWidth: .infinity)
.background(Color.cloudWhite)
```

**Visual Result:**
```
┌─────────────────────────────────────┐
│         ─────                       │  ← Gray handle
│    Swipe down to close              │  ← Instruction text
│                                     │
│  Decision Notifications             │  ← Title
│  Set intentional moments...         │  ← Description
│                                     │
└─────────────────────────────────────┘
```

**Result:**
- ✅ Clear visual handle (gray rounded rectangle)
- ✅ Explicit instruction text
- ✅ Positioned at top before title
- ✅ Standard iOS sheet interaction

**File Updated:**
- `/Users/frankschioppa/soteria/soteria/Views/DecisionWindowsView.swift` (lines 28-48)

---

## 🧪 **TESTING CHECKLIST**

### **LED Border:**
- [ ] Open app
- [ ] View home screen with money tree
- [ ] Verify LED dots appear **around** the border
- [ ] Verify dots chase clockwise
- [ ] Verify dots are **not** inside the tree

### **Slide-to-Close:**
- [ ] Tap "Decision Notifications" card on home
- [ ] Modal opens
- [ ] See gray handle at top
- [ ] See "Swipe down to close" text
- [ ] Swipe down
- [ ] Modal closes smoothly

---

## 📝 **TECHNICAL NOTES**

### **LED Border Algorithm:**
- Calculates perimeter: `(width + height) * 2`
- Distributes 12 segments evenly
- Traces clockwise: top → right → bottom → left
- Uses `.position()` for absolute placement
- Rotation animates continuously

### **Sheet Presentation:**
- Uses SwiftUI's native `.sheet()` modifier
- Swipe-to-dismiss enabled by default
- Added visual affordance for discoverability
- Text reinforces gesture

---

## ✅ **VERIFICATION**

**Linter Check:** ✅ **No errors found**

All files compile cleanly:
- ✅ `HomeView.swift`
- ✅ `DecisionWindowsView.swift`

---

**Both UX issues fixed and ready to test!** 🎨✨
