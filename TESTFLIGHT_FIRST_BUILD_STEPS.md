# TestFlight First Build - Step by Step

**Date**: January 7, 2026  
**App**: Soteria Savings  
**Status**: Ready to Build and Upload

---

## ✅ Pre-Build Checklist

### Current Configuration:
- **Marketing Version**: `1.0`
- **Build Number**: `1`
- **Bundle ID**: `io.montebay.soteria`
- **Team**: `4P5YXTJ7U7` (Montebay Innovations LLC)
- **App Created**: ✅ "Soteria Savings" in App Store Connect
- **Subscriptions Created**: ✅ Monthly & Annual

---

## 🚀 Step-by-Step: Build and Upload

### Step 1: Verify Version Numbers in Xcode

1. **Open Xcode**
2. **Select Project** → `soteria` target
3. **Go to "General" tab**
4. **Verify**:
   - **Version**: `1.0`
   - **Build**: `1`

**Note**: These are correct for the first build. We'll increment build number for subsequent builds.

---

### Step 2: Select Build Destination

1. **In Xcode**, at the top toolbar
2. **Click the device selector** (next to Play/Stop buttons)
3. **Select**: **"Any iOS Device"** (or a connected physical device)
   - ⚠️ **DO NOT** select a simulator (can't archive simulators)

---

### Step 3: Clean Build Folder (Optional but Recommended)

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. Wait for cleaning to complete

**Why**: Ensures a fresh build without cached artifacts

---

### Step 4: Archive the App

1. **Product** → **Archive**
2. **Wait for archive to complete** (5-10 minutes)
   - Xcode will compile the app
   - You'll see progress in the activity viewer
   - When done, Organizer window will open automatically

**What happens**:
- Xcode compiles your app
- Creates an archive (.xcarchive file)
- Validates code signing
- Prepares for distribution

---

### Step 5: Upload to App Store Connect

1. **In Organizer window** (opens after archive):
   - You should see your archive listed
   - Status: "Ready to Distribute"

2. **Click "Distribute App"** button

3. **Choose Distribution Method**:
   - Select **"App Store Connect"**
   - Click **"Next"**

4. **Choose Distribution Options**:
   - Select **"Upload"**
   - Click **"Next"**

5. **Distribution Options**:
   - Select **"Automatically manage signing"** (recommended)
   - Xcode will handle code signing automatically
   - Click **"Next"**

6. **Review and Upload**:
   - Review the summary:
     - App: Soteria Savings
     - Bundle ID: io.montebay.soteria
     - Version: 1.0
     - Build: 1
   - Click **"Upload"**

7. **Wait for Upload**:
   - Upload progress will show
   - Usually takes 5-15 minutes depending on app size
   - You'll see "Upload Successful" when done

---

### Step 6: Wait for Processing

1. **Go to App Store Connect**:
   - https://appstoreconnect.apple.com
   - Navigate to **"My Apps"** → **"Soteria Savings"**

2. **Check TestFlight Tab**:
   - Click **"TestFlight"** tab
   - Your build will appear with status: **"Processing"**
   - Usually takes **10-30 minutes**

3. **You'll get an email** when processing is complete

---

### Step 7: After Processing Completes

Once build status changes to **"Ready to Test"**:

1. **Add TestFlight Testers** (optional):
   - Go to **"TestFlight"** tab
   - Click **"Internal Testing"** or **"External Testing"**
   - Add testers (email addresses)

2. **Test the Build**:
   - Install TestFlight app on your device
   - You'll receive an email invitation
   - Install and test the app

---

## ⚠️ Common Issues & Solutions

### Issue: "No signing certificate found"
**Solution**: 
- Go to Xcode → Preferences → Accounts
- Select your team
- Click "Download Manual Profiles"
- Try archiving again

### Issue: "Bundle ID not found"
**Solution**: 
- Verify bundle ID matches App Store Connect: `io.montebay.soteria`
- Check Team ID is correct: `4P5YXTJ7U7`

### Issue: "Upload failed"
**Solution**:
- Check internet connection
- Try uploading again
- Check Xcode → Window → Organizer for error details

### Issue: "Processing failed"
**Solution**:
- Check email for specific error
- Common: Missing required icons, invalid entitlements
- Fix and upload new build

---

## 📋 Post-Upload Checklist

- [ ] Archive created successfully
- [ ] Upload completed without errors
- [ ] Build appears in App Store Connect → TestFlight
- [ ] Build status: "Processing" (wait for completion)
- [ ] Build status: "Ready to Test" (after processing)
- [ ] TestFlight app installed on device
- [ ] Build installed and tested

---

## 🎯 Next Steps After First Build

1. **Test subscription flow** with sandbox accounts
2. **Test all app features** in TestFlight
3. **Gather feedback** from testers
4. **Fix any issues** found
5. **Increment build number** (1 → 2) for next build
6. **Upload new build** with fixes

---

## 📝 Version Numbering Strategy

### For Subsequent Builds:

**Marketing Version** (user-facing):
- `1.0` → `1.1` (new features)
- `1.1` → `2.0` (major update)

**Build Number** (always increment):
- `1` → `2` → `3` → `4` (each TestFlight upload)

**Example**:
- Version 1.0: Build 1, 2, 3, 4... (bug fixes)
- Version 1.1: Build 1, 2, 3... (new features)
- Version 2.0: Build 1, 2, 3... (major update)

---

**Status**: Ready to archive and upload  
**Next**: Follow steps above to create your first TestFlight build!

