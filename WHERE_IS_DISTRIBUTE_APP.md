# Where is "Distribute App" in Xcode?

## 📍 Location

"Distribute App" appears in the **Organizer window** after you create an archive.

---

## 🚀 Step-by-Step Process

### Step 1: Create Archive

1. **Open Xcode**
2. **Select "Any iOS Device"** (not a simulator) in the device selector
3. **Product** → **Archive**
4. **Wait for archive to complete** (5-10 minutes)

---

### Step 2: Organizer Window Opens

After the archive completes, Xcode **automatically opens the Organizer window**.

**If it doesn't open automatically:**
- **Window** → **Organizer** (or press `⇧⌘9` / Shift+Command+9)

---

### Step 3: Find "Distribute App"

In the **Organizer window**:

1. **You'll see**:
   - List of your archives
   - Each archive shows: Date, Version, Build number
   - Status: "Ready to Distribute"

2. **Select your archive** (the one you just created)

3. **Click the "Distribute App" button** (blue button on the right side)

---

## 📸 Visual Guide

```
┌─────────────────────────────────────────┐
│  Organizer - Archives                   │
├─────────────────────────────────────────┤
│                                          │
│  📦 soteria                             │
│     Jan 7, 2026, 3:45 PM                │
│     Version 1.0 (2)                     │
│     Ready to Distribute                  │
│                                          │
│     [Distribute App] ← CLICK HERE       │
│                                          │
└─────────────────────────────────────────┘
```

---

## 🔍 Alternative: If You Don't See It

### Option 1: Check Archive List

1. **Window** → **Organizer**
2. **Click "Archives" tab** (top of window)
3. **Select your archive**
4. **"Distribute App" button** appears on the right

### Option 2: Right-Click Archive

1. **Right-click** on your archive in the list
2. **Select "Distribute App"** from the context menu

---

## ✅ What Happens Next

After clicking "Distribute App":

1. **Distribution Method** dialog appears
2. **Select "App Store Connect"**
3. **Click "Next"**
4. **Follow the prompts** to upload

---

## 🎯 Quick Summary

1. **Archive** → Product → Archive
2. **Organizer opens** automatically (or Window → Organizer)
3. **Select archive** in the list
4. **Click "Distribute App"** button
5. **Follow prompts** to upload

---

**The "Distribute App" button only appears after you've created an archive!**

