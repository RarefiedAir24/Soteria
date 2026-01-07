# TestFlight Upload via Transporter

**Date**: January 2026  
**Current Version**: 1.0  
**Current Build**: 2

---

## ✅ Version Numbers

- **Marketing Version**: `1.0`
- **Build Number**: `2`
- **Display in App**: `1.0 (2)`

---

## 🚀 Step-by-Step: Upload via Transporter

### Step 1: Verify Version in Xcode

1. **Open Xcode**
2. **Select Project** → `soteria` target
3. **Go to "General" tab**
4. **Verify**:
   - **Version**: `1.0`
   - **Build**: `2` ✅

---

### Step 2: Select Build Destination

1. **In Xcode toolbar** (top)
2. **Click device selector** (next to Play/Stop buttons)
3. **Select**: **"Any iOS Device"** or a connected physical device
   - ⚠️ **DO NOT** select a simulator

---

### Step 3: Clean Build Folder (Recommended)

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. Wait for cleaning to complete

---

### Step 4: Archive the App

1. **Product** → **Archive**
2. **Wait for archive** (5-10 minutes)
   - Xcode compiles the app
   - Organizer window opens automatically when done

---

### Step 5: Export Archive to .ipa File

1. **In Organizer window** (opens after archive):
   - **Select your archive** (click on it in the list)
   - Click **"Distribute App"** button (blue button on the right)

2. **Choose Distribution Method**:
   - Select **"App Store Connect"**
   - Click **"Next"**

3. **Choose Distribution Options**:
   - Select **"Upload"**
   - Click **"Next"**

4. **App Thinning**:
   - Select **"All compatible device variants"** (recommended)
   - Click **"Next"**

5. **Review**:
   - Verify app info (Version 1.0, Build 2)
   - **IMPORTANT**: Click **"Export"** button (NOT "Upload")
   - This creates the `.ipa` file

6. **Choose Export Location**:
   - A file picker dialog appears
   - **Choose a folder** (e.g., Desktop, Downloads, or create a "builds" folder)
   - Click **"Export"**
   - Wait for export to complete (1-2 minutes)

7. **Find Your .ipa File**:
   - Navigate to the folder you chose
   - Look for a folder with date/time (e.g., `soteria 2026-01-07 15.45.00`)
   - Inside that folder: **`soteria.ipa`** file
   - **Note the location** - you'll need it for Transporter!

---

### Step 6: Upload via Transporter

1. **Open Transporter App**:
   - Download from Mac App Store if not installed
   - Search for "Transporter" in App Store
   - Install and open

2. **Sign In**:
   - Sign in with your Apple ID (same as App Store Connect)

3. **Add Your Build**:
   - Click **"+"** button or drag and drop
   - Navigate to the exported `.ipa` file
   - Select it and click **"Add"**

4. **Upload**:
   - Your build appears in the list
   - Click **"Deliver"** button
   - Wait for upload to complete (10-30 minutes)
   - Progress shown in Transporter

5. **Verify Upload**:
   - Status changes to "Delivered" when complete
   - You'll see "Successfully delivered" message

---

### Step 7: Verify in App Store Connect

1. **Go to** [App Store Connect](https://appstoreconnect.apple.com)
2. **Navigate to**: My Apps → Soteria Savings → TestFlight
3. **Check Build Status**:
   - Build should appear with status "Processing"
   - Wait for processing to complete (30-60 minutes)
   - Status changes to "Ready to Test" when done

---

## 📱 After Upload Completes

### Processing Time
- **Upload**: 10-30 minutes (in Transporter)
- **Processing**: 30-60 minutes (in App Store Connect)
- **Total**: ~1-2 hours before ready to test
- **Email**: You'll receive email when processing completes

### Testing in TestFlight

1. **Install TestFlight** (if not installed)
   - Download from App Store
   - Sign in with your Apple ID

2. **Receive Build**:
   - Email notification when ready
   - Or check TestFlight app

3. **Install & Test**:
   - Open TestFlight app
   - Tap **"Soteria Savings"**
   - Tap **"Install"**
   - Test all features
   - Verify version shows `1.0 (2)` in Profile → App Information

---

## 🔄 For Next Build

When uploading again:

1. **Increment Build Number**:
   - Current: Build `2`
   - Next: Build `3`
   - Update in Xcode → General tab

2. **Export new archive**:
   - Archive → Distribute App → Export
   - Upload new `.ipa` via Transporter

---

## ✅ Quick Checklist

### Before Upload:
- [x] Build number incremented (1 → 2) ✅
- [ ] Version verified in Xcode
- [ ] Clean build folder
- [ ] Selected "Any iOS Device"

### Archive & Export:
- [ ] Archive created successfully
- [ ] Exported `.ipa` file created
- [ ] `.ipa` file saved to known location

### Transporter Upload:
- [ ] Transporter app installed
- [ ] Signed in to Transporter
- [ ] `.ipa` file added to Transporter
- [ ] Upload completed ("Delivered" status)

### After Upload:
- [ ] Build appears in App Store Connect → TestFlight
- [ ] Build status: "Processing" → "Ready to Test"
- [ ] Received processing complete email
- [ ] Tested in TestFlight app
- [ ] Version displays correctly: `1.0 (2)`

---

## 🎯 Key Differences: Transporter vs Xcode Upload

| Feature | Xcode Upload | Transporter |
|---------|--------------|-------------|
| **Location** | Xcode Organizer | Standalone App |
| **Export Required** | No (direct upload) | Yes (export `.ipa` first) |
| **Upload Method** | Built into Xcode | Separate app |
| **Progress Tracking** | Xcode Organizer | Transporter app |
| **Advantages** | Integrated workflow | Can upload multiple builds, resume uploads |

---

## 📝 Notes

- **Export Location**: Remember where you saved the `.ipa` file
- **Transporter**: Can upload multiple builds at once
- **Resume**: Transporter can resume interrupted uploads
- **Build Number**: Must increment for each upload (2 → 3 → 4...)
- **Version Display**: Automatically shows in Profile → App Information

---

**Ready to upload via Transporter!** Follow the steps above to export and upload your build.

