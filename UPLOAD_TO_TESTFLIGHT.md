# Upload to TestFlight - Quick Guide

**Status**: ✅ Archive Created Successfully  
**Location**: `build/export/soteria.ipa` (10MB)

---

## 🚀 Upload via Xcode Organizer (Easiest Method)

### Step 1: Open Organizer
1. **In Xcode**: **Window** → **Organizer** (⇧⌘9)
2. You should see your archive: **"soteria"** with today's date

### Step 2: Upload
1. **Select your archive** (soteria, today's date)
2. **Click "Distribute App"** button
3. **Choose**: **"App Store Connect"**
4. **Click "Next"**
5. **Choose**: **"Upload"**
6. **Click "Next"**
7. **Options**: **"Automatically manage signing"** (should be selected)
8. **Click "Next"**
9. **Review** and click **"Upload"**

### Step 3: Wait
- Upload takes 5-15 minutes
- You'll see progress in Organizer
- Status: "Uploaded" when complete

---

## 📱 Alternative: Use Transporter App

If you prefer the Transporter app:

1. **Open Transporter** app (from App Store or Applications)
2. **Drag** `build/export/soteria.ipa` into Transporter
3. **Sign in** with your Apple ID
4. **Click "Deliver"**
5. **Wait** for upload

---

## ✅ After Upload

1. **Go to App Store Connect**:
   - https://appstoreconnect.apple.com
   - **My Apps** → **Soteria Savings** → **TestFlight** tab

2. **Build Status**:
   - Will show **"Processing"** (10-30 minutes)
   - You'll get an **email** when ready
   - Status changes to **"Ready to Test"**

3. **Test the Build**:
   - Install TestFlight app on your device
   - You'll receive an email invitation
   - Install and test!

---

## 📋 What Was Created

- ✅ **Archive**: `build/soteria.xcarchive`
- ✅ **IPA File**: `build/export/soteria.ipa` (10MB)
- ✅ **Version**: 1.0 (Build 1)
- ✅ **Ready to Upload**: Yes

---

**Next**: Open Xcode Organizer and upload the archive!

