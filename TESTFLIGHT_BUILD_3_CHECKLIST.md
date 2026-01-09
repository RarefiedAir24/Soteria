# TestFlight Build 3 Checklist

## ✅ Build Number Updated
- **Build Number**: `3` (updated from 2)
- **Marketing Version**: `1.0` (unchanged)
- **Display Version**: `v1.0 (3)`

---

## 📦 Pre-Archive Steps

### 1. Clean Build Folder
1. **Xcode** → **Product** → **Clean Build Folder** (⇧⌘K)
2. Wait for cleaning to complete

### 2. Select Device
- **Select "Any iOS Device"** (not a simulator)
- Located in the device selector at the top of Xcode

---

## 🏗️ Archive the App

1. **Product** → **Archive**
2. **Wait for archive** (5-10 minutes)
   - Xcode compiles the app
   - Organizer window should open automatically when done

---

## 📤 Export to .ipa

### Option A: Via Organizer (if it opens)

1. **In Organizer window**:
   - Select your archive
   - Click **"Distribute App"** button

2. **Follow export dialog**:
   - Choose **"App Store Connect"** → Next
   - Choose **"Upload"** → Next
   - Select **"All compatible device variants"** → Next
   - **Click "Export"** (NOT "Upload")
   - Choose export location (e.g., Desktop)
   - Wait for export (1-2 minutes)

3. **Find .ipa file**:
   - Navigate to export folder
   - Look for `soteria.ipa`

### Option B: Via Command Line (if Organizer doesn't open)

```bash
cd /Users/frankschioppa/soteria

# Find most recent archive
ARCHIVE_PATH=$(find ~/Library/Developer/Xcode/Archives -name "soteria*.xcarchive" -type d | sort -r | head -1)
echo "📦 Archive: $ARCHIVE_PATH"

# Export to .ipa
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist build/ExportOptions.plist \
  -exportPath build/export \
  -allowProvisioningUpdates

# Verify .ipa created
ls -lh build/export/*.ipa
```

**Location**: `/Users/frankschioppa/soteria/build/export/soteria.ipa`

---

## 🚀 Upload to TestFlight

### Using Transporter App

1. **Open Transporter** (from Applications or Spotlight)

2. **Add .ipa file**:
   - Drag and drop `soteria.ipa` into Transporter, OR
   - Click "+" button and navigate to the .ipa file

3. **Click "Deliver"** button

4. **Wait for upload** (10-30 minutes)
   - Progress shown in Transporter
   - You'll get a notification when complete

---

## ✅ Post-Upload

1. **Check App Store Connect**:
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Navigate to your app → TestFlight
   - Build should appear in "Processing" status

2. **Wait for Processing**:
   - Usually takes 15-60 minutes
   - You'll get an email when processing completes

3. **Test the Build**:
   - Once processed, add testers
   - Version will show as `v1.0 (3)` in app

---

## 📝 What's New in Build 3

- ✅ Version display on splash screen
- ✅ Shared version utility for consistency
- ✅ Updated build number tracking

---

## 🔍 Verify Version Display

After installing the TestFlight build:
1. **Splash Screen**: Should show `v1.0 (3)` at bottom
2. **Profile Screen**: Should show `1.0 (3)` in App Information section

---

**Ready to archive!** 🚀

