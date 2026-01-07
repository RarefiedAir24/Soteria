# TestFlight Upload Guide - Current Build

**Date**: January 2026  
**Current Version**: 1.0  
**Current Build**: 2 (incremented)

**Note**: This guide uses Xcode's built-in upload. For Transporter, see `TESTFLIGHT_UPLOAD_VIA_TRANSPORTER.md`

---

## ✅ Version Numbers Updated

- **Marketing Version**: `1.0` (user-facing version)
- **Build Number**: `2` (incremented from 1)
- **Display in App**: `1.0 (2)`

---

## 🚀 Step-by-Step: Upload to TestFlight

### Step 1: Verify Version in Xcode

1. **Open Xcode**
2. **Select Project** → `soteria` target
3. **Go to "General" tab**
4. **Verify**:
   - **Version**: `1.0`
   - **Build**: `2` ✅ (should be updated)

---

### Step 2: Select Build Destination

1. **In Xcode toolbar** (top)
2. **Click device selector** (next to Play/Stop buttons)
3. **Select**: **"Any iOS Device"** or a connected physical device
   - ⚠️ **DO NOT** select a simulator (can't archive simulators)

---

### Step 3: Clean Build Folder (Recommended)

1. **Product** → **Clean Build Folder** (⇧⌘K or Shift+Command+K)
2. Wait for cleaning to complete

**Why**: Ensures fresh build without cached artifacts

---

### Step 4: Archive the App

1. **Product** → **Archive**
2. **Wait for archive** (5-10 minutes)
   - Xcode compiles the app
   - Progress shown in activity viewer
   - Organizer window opens automatically when done

**What happens**:
- Compiles app
- Creates archive (.xcarchive)
- Validates code signing
- Prepares for distribution

---

### Step 5: Upload to App Store Connect

1. **Organizer window opens automatically** after archive completes
   - If it doesn't open: **Window** → **Organizer** (or press `⇧⌘9`)
   - You'll see your archive listed with "Ready to Distribute" status

2. **Select your archive** in the list (click on it)

3. **Click "Distribute App"** button (blue button on the right side of the Organizer window)

3. **Choose Distribution Method**:
   - Select **"App Store Connect"**
   - Click **"Next"**

4. **Choose Distribution Options**:
   - Select **"Upload"**
   - Click **"Next"**

5. **App Thinning**:
   - Select **"All compatible device variants"** (recommended)
   - Click **"Next"**

6. **Review**:
   - Verify app info
   - Click **"Upload"**

7. **Wait for Upload**:
   - Progress shown in Organizer
   - Can take 10-30 minutes depending on app size
   - Don't close Xcode during upload

---

### Step 6: Verify Upload in App Store Connect

1. **Go to** [App Store Connect](https://appstoreconnect.apple.com)
2. **Navigate to**: My Apps → Soteria Savings → TestFlight
3. **Check Build Status**:
   - Build should appear with status "Processing"
   - Wait for processing to complete (30-60 minutes)
   - Status changes to "Ready to Test" when done

---

## 📱 After Upload Completes

### Processing Time
- **Typical**: 30-60 minutes
- **Can take**: Up to 2 hours
- **You'll receive**: Email when processing completes

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

---

## 🔄 For Next Build

When uploading again:

1. **Increment Build Number**:
   - Current: Build `2`
   - Next: Build `3`
   - Update in Xcode → General tab

2. **Version Number**:
   - Keep `1.0` for bug fixes/minor updates
   - Change to `1.1` for new features
   - Change to `2.0` for major updates

---

## ✅ Quick Checklist

### Before Upload:
- [x] Build number incremented (1 → 2) ✅
- [ ] Version verified in Xcode
- [ ] Clean build folder
- [ ] Selected "Any iOS Device"

### Upload Process:
- [ ] Archive created successfully
- [ ] Upload completed without errors
- [ ] Build appears in App Store Connect

### After Upload:
- [ ] Build processing in TestFlight
- [ ] Received processing complete email
- [ ] Build status: "Ready to Test"
- [ ] Tested in TestFlight app
- [ ] Version displays correctly: `1.0 (2)`

---

## 🎯 Current Changes in This Build

This build includes:
- ✅ Responsive design for smaller screens
- ✅ Sign-up functionality on auth screen
- ✅ Decision notification persistence fixes
- ✅ Celebration animations for decision windows
- ✅ Custom message display fixes

---

## 📝 Notes

- **Build Number**: Must increment for each upload (2 → 3 → 4...)
- **Version Display**: Automatically shows in Profile → App Information
- **Processing**: Can take 30-60 minutes, be patient
- **TestFlight**: Builds are available for 90 days

---

**Ready to upload!** Follow the steps above to get this build to TestFlight.

