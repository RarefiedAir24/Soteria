# Alternative Ways to Upload to TestFlight

Since Organizer menu isn't available, here are alternative methods:

---

## Method 1: Use Transporter App (Easiest)

### Step 1: Open Transporter
1. **Open "Transporter"** app
   - Search for "Transporter" in Spotlight (⌘Space)
   - Or find it in Applications folder
   - If not installed: Download from Mac App Store

### Step 2: Upload
1. **Drag and drop** `build/export/soteria.ipa` into Transporter
2. **Sign in** with your Apple ID (organization account)
3. **Click "Deliver"**
4. **Wait** for upload (5-15 minutes)

---

## Method 2: Command Line Upload (if you have API key)

If you have an App Store Connect API key set up:

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/export/soteria.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

**Note**: Requires API key setup in App Store Connect

---

## Method 3: Find Organizer in Xcode

Try these locations:
- **Xcode menu** → **Window** → **Organizer**
- **Keyboard shortcut**: ⇧⌘9
- **Or**: Product → Archive (if you archive again, Organizer opens automatically)

---

## Method 4: Archive Again (Opens Organizer)

1. **Product** → **Archive** (in Xcode)
2. Organizer window will open automatically after archive completes
3. Then follow upload steps

---

## ✅ Recommended: Use Transporter App

**Transporter is the easiest method** and doesn't require Xcode Organizer.

1. Open Transporter app
2. Drag `build/export/soteria.ipa` into it
3. Sign in and deliver

---

**Your IPA file is ready**: `build/export/soteria.ipa` (10MB)

