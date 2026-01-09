# TestFlight Build Not Showing - Troubleshooting Guide

**Issue:** Build 4 not appearing in App Store Connect/TestFlight

---

## 🔍 **Quick Diagnosis**

### **Current Status:**
- **Local build number:** 5 (not 4)
- **Archives created:** January 7, 2026 (3 archives)
- **App Store Connect status:** Unknown (needs checking)

---

## ⚠️ **Most Common Cause: Export Compliance**

**90% of the time, this is the issue!**

If you uploaded the build but it's not showing up, it's probably stuck on **Export Compliance**.

### **How to Fix:**

1. **Go to:** [App Store Connect](https://appstoreconnect.apple.com)
2. **Navigate:** My Apps → Soteria → TestFlight tab
3. **Look for:** Yellow warning banner saying **"Missing Export Compliance"**
4. **Click:** "Provide Export Compliance Information"
5. **Answer the questions:**
   - "Is your app designed to use cryptography or does it contain or incorporate cryptography?" → **YES**
   - "Does your app qualify for any of the exemptions provided in Category 5, Part 2?" → **YES**
   - Select: **"Your app uses standard encryption in iOS"**
6. **Submit**

**After submitting:** Build should appear in TestFlight within 5-10 minutes.

---

## ⏳ **Other Possible Reasons**

### **Reason 1: Still Processing**
- **Timeline:** Builds take 15-60 minutes to process
- **Check:** App Store Connect → TestFlight → Look for "Processing" status
- **Action:** Wait up to 1 hour

### **Reason 2: Upload Failed**
- **Check:** Xcode → Window → Organizer → Look for upload errors
- **Common errors:**
  - Invalid provisioning profile
  - Missing entitlements
  - Bundle ID mismatch
- **Action:** Re-upload from Organizer

### **Reason 3: Wrong Build Number**
- **Current local:** Build 5
- **Looking for:** Build 4
- **Possible:** Build 4 never got uploaded, or you're already on build 5
- **Action:** Check what builds ARE in TestFlight (might be 3, 5, but not 4)

### **Reason 4: Email from Apple**
- **Check:** Your email for messages from Apple
- **Subject:** Usually "Your app has issues that need to be resolved"
- **Common issues:**
  - Missing icons
  - Invalid entitlements
  - SDK version mismatch
- **Action:** Fix issues and re-upload

---

## ✅ **Step-by-Step Verification**

### **Step 1: Check App Store Connect** (Do this NOW)

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **"My Apps"**
3. Select **"Soteria"**
4. Click **"TestFlight"** tab
5. Look at the builds listed

**What do you see?**
- [ ] Build 3 (previous build)
- [ ] Build 4 with "Processing" status
- [ ] Build 4 with "Missing Export Compliance" warning
- [ ] Build 5 (current build)
- [ ] No build 4 at all
- [ ] Yellow warning banner at top

**If you see a yellow banner:** Complete export compliance (steps above)

---

### **Step 2: Check Xcode Organizer**

1. Open **Xcode**
2. Go to **Window → Organizer** (or press `⌘⇧9`)
3. Select **Archives** tab
4. Look at your January 7 archives
5. Check the **upload status**

**What does it say?**
- [ ] "Uploaded" with checkmark ✅ → Good!
- [ ] "Upload Failed" ❌ → Need to retry
- [ ] "Preparing..." ⏳ → Still uploading
- [ ] No status → Never uploaded

**If failed or no status:** Re-upload from Organizer

---

### **Step 3: Check Email**

1. Search your email for "App Store Connect"
2. Look for messages from the last 2 days
3. Check for build processing updates

**Common email subjects:**
- "Your app is ready for testing" ✅ (good)
- "Your app has been submitted" (upload confirmed)
- "Your app has issues" ❌ (need to fix)

---

## 🔄 **How to Re-Upload**

If build 4 never got uploaded or failed:

### **From Xcode Organizer:**

1. **Open Xcode**
2. **Window → Organizer** (`⌘⇧9`)
3. **Select** your most recent archive (Jan 7, 16:38)
4. **Click** "Distribute App"
5. **Choose** "TestFlight & App Store"
6. **Select** "Upload" (not Export)
7. **Follow** the wizard:
   - App Store Connect distribution
   - Automatically manage signing
   - Upload
8. **Wait** for upload to complete (5-10 minutes)
9. **Check** App Store Connect after 15-30 minutes

---

## 🎯 **What Build Number Should You Use?**

**Current situation:**
- Local project: Build 5
- TestFlight: Build 4 missing?

**Options:**

**Option A: Upload Build 5** (Recommended)
- You're already on build 5 locally
- Upload current archive
- Build 5 will appear in TestFlight
- Easier than going backwards

**Option B: Create Build 4**
- Set build number back to 4: `xcrun agvtool new-version -all 4`
- Archive again
- Upload
- Confusing, not recommended

**Recommendation:** Just upload build 5 and move on. TestFlight doesn't require sequential build numbers.

---

## 📊 **Expected Timeline**

After successful upload:

```
0 min:  Upload starts from Xcode
5 min:  Upload completes
10 min: Build appears in App Store Connect (usually)
15 min: Export compliance prompt appears (if needed)
20 min: After compliance, build starts processing
30 min: Processing completes
40 min: Build available in TestFlight ✅
```

**Total:** 15-60 minutes from upload to TestFlight availability

---

## 🚨 **If Nothing Works**

### **Nuclear Option: Create Fresh Archive**

1. **Increment build:**
   ```bash
   cd /Users/frankschioppa/soteria
   xcrun agvtool next-version -all
   ```

2. **Clean:**
   - Product → Clean Build Folder (`⇧⌘K`)
   - Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/soteria-*`

3. **Archive:**
   - Product → Archive
   - Wait for archive to complete

4. **Upload:**
   - Organizer → Distribute
   - Upload to TestFlight

5. **Check:**
   - App Store Connect after 30 minutes
   - Complete export compliance if prompted

---

## 📝 **Checklist**

**Before contacting Apple Support:**

- [ ] Checked App Store Connect TestFlight tab
- [ ] Completed export compliance (if prompted)
- [ ] Checked Xcode Organizer for upload status
- [ ] Waited at least 1 hour after upload
- [ ] Checked email for Apple messages
- [ ] Verified bundle ID is correct (io.montebay.soteria)
- [ ] Confirmed signed in with correct Apple ID
- [ ] Have App Manager or Admin role in App Store Connect

**If all checked and still no build:**
- Contact Apple Developer Support
- Provide: App name, bundle ID, build number, upload timestamp

---

## 🎯 **Most Likely Solution**

Based on experience, **90% chance** it's one of these:

1. **Export compliance not completed** ← Check this first!
2. **Still processing** ← Wait 1 hour
3. **Upload actually failed** ← Check Organizer

**Next Step:**
Go to App Store Connect NOW and check for yellow warning banner about export compliance.

---

## 💡 **Pro Tip: Avoid This in Future**

**Add to Info.plist** to skip export compliance prompts:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This tells Apple you're only using standard iOS encryption (HTTPS).

**Where:** Since you auto-generate Info.plist, add to Build Settings:
1. Select soteria target
2. Build Settings tab
3. Search "Info.plist Values"
4. Add: `ITSAppUsesNonExemptEncryption = NO`

This prevents the export compliance prompt on every upload.

---

**Bottom Line:** Check App Store Connect for export compliance warning. That's almost always why builds don't show up. ✅
