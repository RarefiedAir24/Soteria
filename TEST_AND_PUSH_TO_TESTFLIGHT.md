# How to Test & Push to TestFlight

**Status**: AppIcon fixed - Ready to test and push

---

## 🧪 Step 1: Test Locally First

### Quick Test in Xcode:

1. **Clean Build**:
   - **Product** → **Clean Build Folder** (⇧⌘K)

2. **Build & Run**:
   - **Product** → **Run** (⌘R)
   - Or click the Play button
   - Select your device or simulator

3. **Check App Icon**:
   - Look at the home screen (if on device)
   - Verify the icon looks correct
   - Check it's not transparent

4. **Test App Functionality**:
   - Launch the app
   - Test core features
   - Verify everything works

---

## 🚀 Step 2: Push to TestFlight

### Option A: Archive & Upload (Recommended)

1. **Select Device**:
   - In Xcode, select **"Any iOS Device"** (not simulator)

2. **Clean Build**:
   - **Product** → **Clean Build Folder** (⇧⌘K)

3. **Archive**:
   - **Product** → **Archive**
   - Wait 5-10 minutes for archive to complete
   - Organizer window opens automatically

4. **Upload**:
   - In Organizer, select your archive
   - Click **"Distribute App"**
   - Choose **"App Store Connect"** → **"Upload"**
   - Follow prompts (automatic signing)
   - Click **"Upload"**
   - Wait 5-15 minutes

5. **Check Status**:
   - Go to **App Store Connect** → **Soteria Savings** → **TestFlight**
   - Build will show **"Processing"** (10-30 minutes)
   - You'll get an email when ready

---

### Option B: Command Line (Alternative)

If you prefer command line:

```bash
# 1. Clean
cd /Users/frankschioppa/soteria
xcodebuild clean -workspace soteria.xcworkspace -scheme soteria

# 2. Archive
xcodebuild archive \
  -workspace soteria.xcworkspace \
  -scheme soteria \
  -configuration Release \
  -archivePath ./build/soteria.xcarchive \
  -allowProvisioningUpdates

# 3. Export
xcodebuild -exportArchive \
  -archivePath ./build/soteria.xcarchive \
  -exportOptionsPlist ./build/ExportOptions.plist \
  -exportPath ./build/export \
  -allowProvisioningUpdates

# 4. Upload via Transporter or Xcode Organizer
```

---

## 📱 Step 3: Test in TestFlight

### After Processing Completes:

1. **Install TestFlight**:
   - Download from App Store (if not installed)
   - Sign in with your Apple ID

2. **Receive Invitation**:
   - You'll get an email when build is ready
   - Or check TestFlight app

3. **Install & Test**:
   - Open TestFlight app
   - Tap **"Soteria Savings"**
   - Tap **"Install"**
   - Test all features

---

## 🔄 Version Numbering

### For This Build:

Since this is a **bug fix** (icon transparency), increment **Build Number**:

**Current**: Version 1.0, Build 1  
**New**: Version 1.0, Build 2

### How to Update:

1. **In Xcode**:
   - Select project → `soteria` target
   - **General** tab
   - **Build**: Change from `1` to `2`
   - **Version**: Keep as `1.0`

2. **Or in project.pbxproj**:
   - `CURRENT_PROJECT_VERSION = 2`
   - `MARKETING_VERSION = 1.0`

---

## ✅ Quick Checklist

### Before Pushing:
- [ ] AppIcon transparency removed ✅
- [ ] Tested locally (build & run)
- [ ] Build number incremented (1 → 2)
- [ ] All changes committed (optional but recommended)

### Push Process:
- [ ] Clean build folder
- [ ] Archive created
- [ ] Uploaded to App Store Connect
- [ ] Build processing in TestFlight

### After Push:
- [ ] Check TestFlight status
- [ ] Wait for processing email
- [ ] Test in TestFlight app
- [ ] Verify icon looks correct

---

## 🎯 Recommended Workflow

1. **Test Locally** (5 minutes)
   - Build & Run
   - Verify icon and functionality

2. **Archive** (10 minutes)
   - Product → Archive
   - Wait for completion

3. **Upload** (15 minutes)
   - Distribute App → Upload
   - Wait for upload

4. **Wait for Processing** (30 minutes)
   - Check App Store Connect
   - Wait for email

5. **Test in TestFlight** (ongoing)
   - Install from TestFlight
   - Test all features

---

## 📝 Notes

- **Build Number**: Must increment for each upload (1 → 2 → 3...)
- **Version Number**: Only changes for major releases (1.0 → 1.1 → 2.0)
- **Processing Time**: Usually 10-30 minutes, can take up to 1 hour
- **Icon Fix**: This build includes the fixed opaque icon

---

**Ready to push!** Start with local testing, then archive and upload to TestFlight.

