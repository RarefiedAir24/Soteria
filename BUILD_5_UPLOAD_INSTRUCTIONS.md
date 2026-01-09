# Upload Build 5 to TestFlight - Quick Guide

## 📊 **Current Status**

- ✅ **Local Build Number:** 5
- ✅ **Version:** 1.0
- ✅ **DerivedData Cleaned:** Ready to archive
- ❌ **Build 5 Archived:** NO
- ❌ **Build 5 Uploaded:** NO

**Archives that exist:**
- Build 1 (Jan 7)
- Build 2 (Jan 7)

**Missing builds:** 3, 4, 5 (never archived)

---

## 🎯 **What You Need To Do**

Build 5 was never archived or uploaded. You need to:
1. Create an archive (5-10 min)
2. Upload to TestFlight (5-10 min)
3. Wait for processing (15-60 min)
4. Complete export compliance if prompted (2 min)

**Total time:** ~30-90 minutes

---

## 📦 **STEP-BY-STEP INSTRUCTIONS**

### **STEP 1: Open Xcode and Clean** ✅ (Already Done)

- ✅ DerivedData already cleaned via command line
- In Xcode, do: **Product → Clean Build Folder** (`⇧⌘K`)

---

### **STEP 2: Select Correct Destination** ⚠️ **CRITICAL**

**Before archiving, you MUST:**

1. Look at the device/simulator dropdown (top left, next to play/stop buttons)
2. Click it and select: **"Any iOS Device (arm64)"**
   - ❌ NOT your iPhone
   - ❌ NOT a simulator
   - ✅ Must be "Any iOS Device (arm64)"

**If you don't see "Any iOS Device":**
- Select "Generic iOS Device" instead

**Why:** Archive option is only available when you select a generic device, not a specific simulator or connected device.

---

### **STEP 3: Create Archive**

1. **Product → Archive** (or press `⌃⌘B`)
2. Xcode will start building:
   - "Building for release"
   - "Archiving soteria"
   - "Creating .xcarchive"
3. **Wait 5-10 minutes** (don't interrupt)
4. When done, **Xcode Organizer** will open automatically

**If it fails:**
- Check for errors in the Issues navigator
- Most common: Signing issues (select "Automatically manage signing")
- Report the error and I'll help

---

### **STEP 4: Upload to TestFlight**

When **Xcode Organizer** opens:

1. ✅ **Verify:** Top archive shows **"soteria 1.0 (5)"** with today's date
2. Click **"Distribute App"** (blue button on right side)
3. Choose: **"TestFlight & App Store"**
4. Click **"Next"**
5. Choose: **"Upload"** (NOT Export)
6. Click **"Next"**
7. Distribution options:
   - ✅ Automatically manage signing (recommended)
   - ✅ Include bitcode (if shown)
   - Click **"Next"**
8. **Review Summary:**
   - App: soteria
   - Version: 1.0
   - Build: 5
   - Click **"Upload"**
9. **Wait 5-10 minutes** for upload
10. You'll see: ✅ **"Upload Successful"**

---

### **STEP 5: Check App Store Connect**

**Wait 15-30 minutes** after upload completes, then:

1. Go to: [App Store Connect](https://appstoreconnect.apple.com)
2. Log in with your Apple ID
3. Click **"My Apps"**
4. Select **"Soteria"**
5. Click **"TestFlight"** tab (at top)
6. Look for **"Build 5"** in the list

**What you might see:**

**Scenario A: "Processing" Status** ⏳
- Build 5 shows with "Processing" badge
- **Action:** Wait up to 1 hour
- Normal processing time

**Scenario B: "Missing Export Compliance" Warning** ⚠️ **(Most Common)**
- Yellow banner at top
- Build 5 listed but not available
- **Action:** Click "Provide Export Compliance Information"
  1. "Does your app use encryption?" → **YES**
  2. "Does it qualify for exemption?" → **YES**
  3. Select: "Standard iOS encryption (HTTPS)"
  4. Submit
- Build will be available in 5-10 minutes

**Scenario C: Build 5 Shows as "Ready to Submit"** ✅
- All good!
- Add to internal/external testing groups
- Send to testers

**Scenario D: No Build 5 Visible** ❌
- Wait longer (up to 1 hour)
- Check email for Apple messages about issues
- Come back to me if still not showing after 1 hour

---

## ⏱️ **Expected Timeline**

```
0 min  → Start archive in Xcode
10 min → Archive completes, Organizer opens
12 min → Click through upload wizard
20 min → Upload completes (you see "Upload Successful")
35 min → Build appears in App Store Connect (usually)
40 min → Export compliance prompt appears (if needed)
45 min → After export compliance, processing starts
60 min → Processing completes
65 min → Build 5 is live in TestFlight ✅
```

**Average total time:** 45-90 minutes from start to TestFlight availability

---

## 🚨 **Common Issues and Fixes**

### **Issue: "Archive" is Grayed Out**
**Cause:** Wrong device selected
**Fix:** 
- Select "Any iOS Device (arm64)" from device dropdown
- NOT a simulator, NOT your physical device

### **Issue: Signing Error During Archive**
**Cause:** Provisioning profile issues
**Fix:**
1. Select soteria target in Xcode
2. Go to "Signing & Capabilities" tab
3. Check "Automatically manage signing"
4. Select your team
5. Try archiving again

### **Issue: Upload Fails with "Invalid Bundle"**
**Cause:** Missing Info.plist or entitlements
**Fix:** Come back to me, we'll investigate

### **Issue: "Your session has expired"**
**Cause:** Not logged into App Store Connect in Xcode
**Fix:**
1. Xcode → Settings → Accounts
2. Click your Apple ID
3. Click "Download Manual Profiles"
4. Try uploading again

### **Issue: Build Shows in Organizer but Upload Button is Missing**
**Cause:** Archive wasn't created for distribution
**Fix:**
- Archive again with "Any iOS Device (arm64)" selected

---

## ✅ **Verification Checklist**

**Before archiving:**
- [ ] Xcode is open
- [ ] "Any iOS Device (arm64)" is selected
- [ ] Project builds successfully (⌘B)
- [ ] No errors in Issue Navigator

**During archive:**
- [ ] Archive process completes without errors
- [ ] Organizer opens automatically
- [ ] Build 5 shows in archives list

**During upload:**
- [ ] "Distribute App" button is available
- [ ] Selected "TestFlight & App Store"
- [ ] Upload completes with "Upload Successful" message

**After upload:**
- [ ] Waited 15-30 minutes
- [ ] Checked App Store Connect
- [ ] Build 5 is visible (processing or ready)
- [ ] Completed export compliance if prompted

---

## 📝 **Quick Reference**

**To Archive:**
- Device: "Any iOS Device (arm64)"
- Menu: Product → Archive
- Time: 5-10 minutes

**To Upload:**
- Open: Xcode Organizer (opens automatically after archive)
- Click: "Distribute App"
- Choose: "TestFlight & App Store" → Upload
- Time: 5-10 minutes

**To Check Status:**
- URL: https://appstoreconnect.apple.com
- Path: My Apps → Soteria → TestFlight
- Look for: Build 5

---

## 🎯 **Success Criteria**

You'll know it worked when:
1. ✅ Xcode shows "Upload Successful"
2. ✅ Email from Apple: "Your app is being processed"
3. ✅ Build 5 appears in App Store Connect
4. ✅ After export compliance, status changes to "Ready to Submit"
5. ✅ You can add Build 5 to testing groups
6. ✅ Testers can see and install Build 5

---

## 💡 **Pro Tips**

1. **Keep Xcode open** until you see "Upload Successful"
2. **Don't close Organizer** until upload completes
3. **Check your email** for Apple notifications about the build
4. **Export compliance:** Always select "Standard iOS encryption" for apps using HTTPS
5. **Build numbers:** Don't worry about missing 3 and 4, TestFlight doesn't require sequential numbers

---

## 🆘 **If You Get Stuck**

**After you start the archive:**
- Watch for any red errors
- Take a screenshot if something fails
- Report back with the error message

**If upload fails:**
- Check Xcode → Settings → Accounts
- Make sure you're logged in
- Verify your team shows up

**If build doesn't appear after 1 hour:**
- Check App Store Connect for any error messages
- Check email for Apple notifications
- Come back to me with what you see in App Store Connect

---

## 📋 **Ready to Start?**

✅ **You're ready!** Everything is prepared:
- Build number is set to 5
- DerivedData is cleaned
- Project should build successfully

**Next Step:** Open Xcode and start with STEP 2 (Select "Any iOS Device (arm64)")

---

**Good luck! This should take about 45-90 minutes total from start to TestFlight availability.**

---

## 🔍 **After Upload - Monitoring**

Check App Store Connect every 15 minutes:
- 0-15 min: Might not show yet (still uploading internally)
- 15-30 min: Usually appears with "Processing" status
- 30-45 min: Export compliance prompt (complete it)
- 45-60 min: Processing after compliance
- 60-90 min: Should be "Ready to Submit"

If nothing shows after 90 minutes, come back and we'll investigate.
