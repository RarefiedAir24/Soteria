# 🎚️ Quick Toggle Guide - Savings Tools Feature

## 🔴 **CURRENTLY: OFF** (No Partners Yet)

---

## ✅ **HOW TO TURN ON (For Testing/Demo)**

### **Step 1: Open Settings**
```
Home Screen → Settings (tab) → Developer Testing
```

### **Step 2: Toggle ON**
```
┌─────────────────────────────────────────┐
│ 🎚️ FEATURE FLAGS                       │
├─────────────────────────────────────────┤
│ Savings Tools                           │
│ Disabled - Badge hidden        [OFF]    │  ← Tap to turn ON
│                                         │
│ ℹ️ Why is this off?                     │
│ We don't have partner agreements yet.   │
└─────────────────────────────────────────┘
```

### **Step 3: See Badge**
```
Home Screen → Scroll to top

┌─────────────────────────────────────────┐
│ 💰 Activate Savings Tools          [→] │  ← Badge now visible!
└─────────────────────────────────────────┘
```

---

## 🔴 **HOW TO TURN OFF (Hide Badge)**

### **Step 1: Open Settings**
```
Home Screen → Settings (tab) → Developer Testing
```

### **Step 2: Toggle OFF**
```
┌─────────────────────────────────────────┐
│ 🎚️ FEATURE FLAGS                       │
├─────────────────────────────────────────┤
│ Savings Tools                           │
│ Enabled - Badge visible on home [ON]    │  ← Tap to turn OFF
└─────────────────────────────────────────┘
```

### **Step 3: Badge Gone**
```
Home Screen → Badge hidden immediately
```

---

## 🚀 **FOR PRODUCTION (Permanent ON)**

### **When Partners Secured:**

**File:** `soteria/Services/SavingsToolsService.swift`

**Change Line 16:**
```swift
// BEFORE (OFF):
private static let SAVINGS_TOOLS_ENABLED_DEFAULT = false

// AFTER (ON):
private static let SAVINGS_TOOLS_ENABLED_DEFAULT = true
```

**Then:**
1. Build app
2. Submit to App Store
3. All users see badge on launch

---

## 🎯 **WHEN TO USE EACH METHOD**

| **Scenario** | **Method** | **How** |
|-------------|------------|---------|
| Testing locally | Toggle in Dev Menu | Instant on/off |
| Demoing to partners | Toggle in Dev Menu | Show badge, then hide |
| TestFlight beta | Toggle in Dev Menu | Each tester controls it |
| Production launch (no partners) | Keep constant `false` | Badge hidden for all |
| Production launch (partners secured) | Change constant to `true` | Badge visible for all |
| Emergency disable | Change constant to `false` + hotfix | Hide for all users |

---

## 📱 **DEMO WORKFLOW**

### **Showing Partners the Feature:**

1. ✅ Open Developer Testing
2. ✅ Toggle Savings Tools **ON**
3. ✅ Go to home screen → Show badge
4. ✅ Tap badge → Show management view
5. ✅ Walk through activation flow
6. ✅ After demo: Toggle **OFF** (optional)

---

## 🔒 **SAFETY NOTES**

- ✅ Toggling preserves all data
- ✅ Can be toggled unlimited times
- ✅ No app restart required
- ✅ Changes instant
- ✅ Per-device setting

---

**That's it! Easy on/off control for whenever you're ready.** 🎚️✨
