# How to Find the "General" Tab in Xcode

## The Issue
You're looking at **PROJECT** settings, but the "General" tab is in **TARGET** settings.

## Solution: Select the Target

### Step 1: Find TARGETS Section
In the **left sidebar** (Project Navigator), you should see:
- **PROJECT** section (currently selected - shows "soteria")
- **TARGETS** section (below PROJECT)

### Step 2: Select the Target
1. **Click on "soteria"** in the **TARGETS** section
   - It should have an app icon (blue square with "A")
   - NOT the project icon (yellow folder)

### Step 3: Now You'll See the General Tab
Once you select the **TARGET**, you'll see tabs at the top:
- **General** ← This is what we need!
- Signing & Capabilities
- Resource Tags
- Info
- Build Settings
- Build Phases
- Build Rules

### Step 4: Check Framework Embedding
1. **Click "General" tab**
2. **Scroll down** to find **"Frameworks, Libraries, and Embedded Content"**
3. **Look for** `LinkKit.framework`
4. **Check** if it says "Embed & Sign" or "Do Not Embed"

## Visual Guide

```
Left Sidebar:
├── PROJECT
│   └── soteria  ← You're here (shows Info, Build Settings tabs)
│
└── TARGETS
    └── soteria  ← Click HERE (shows General, Signing, Info, Build Settings tabs)
        └── SoteriaMonitor
```

## Quick Check: Bitcode (While You're There)

After checking Framework Embedding:
1. **Click "Build Settings" tab** (in TARGET settings)
2. **Search**: `bitcode`
3. **Check**: "Enable Bitcode" should be **NO**

