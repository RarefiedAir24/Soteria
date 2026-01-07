# How to Find Organizer and Export .ipa

If Organizer isn't visible, here are multiple ways to access it:

---

## 🔍 Method 1: Open Organizer from Xcode Menu

1. **In Xcode** (make sure Xcode is the active app)
2. **Click "Window" menu** (top menu bar)
3. **Look for "Organizer"** in the dropdown menu
4. **Click "Organizer"**

**Keyboard Shortcut**: The shortcut might be different. Try:
- `⇧⌘9` (Shift+Command+9)
- Or check what's listed next to "Organizer" in the Window menu

---

## 🔍 Method 2: Archive Again (Opens Organizer Automatically)

If you can't find Organizer, archive again - it will open automatically:

1. **In Xcode**:
   - Select **"Any iOS Device"** (not simulator)
   - **Product** → **Archive**
   - Wait for archive to complete
   - **Organizer should open automatically** when archive finishes

---

## 🔍 Method 3: Check Xcode Preferences

1. **Xcode** → **Preferences** (or Settings)
2. **Check "Behaviors" tab**:
   - Look for "Archive" behavior
   - Make sure "Show Organizer" is checked

---

## 🔍 Method 4: Use Command Line to Export

If Organizer still won't open, you can export via command line:

### Step 1: Find Your Archive

Archives are typically stored in:
```
~/Library/Developer/Xcode/Archives/[Date]/soteria [Date] [Time].xcarchive
```

### Step 2: Export via Command Line

```bash
cd /Users/frankschioppa/soteria

# Find your archive (most recent)
ARCHIVE_PATH=$(ls -t ~/Library/Developer/Xcode/Archives/*/soteria*.xcarchive | head -1)
echo "Archive found at: $ARCHIVE_PATH"

# Export the .ipa
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist <(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>4P5YXTJ7U7</string>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF
) \
  -exportPath ./build/export \
  -allowProvisioningUpdates
```

This will create: `./build/export/soteria.ipa`

---

## 🔍 Method 5: Check if Archive Already Exists

Your archive might already be created. Check:

```bash
# List all archives
ls -lt ~/Library/Developer/Xcode/Archives/*/soteria*.xcarchive 2>/dev/null | head -5
```

If you see archives listed, you can export one of them.

---

## ✅ Quick Solution: Archive Again

**Easiest method** - just archive again:

1. **Product** → **Archive**
2. **Wait for completion**
3. **Organizer should open automatically**

If it still doesn't open, use the command line method above.

---

## 📍 Where to Find Exported .ipa

After exporting (via Organizer or command line), the `.ipa` file will be in:

- **If exported via Organizer**: The folder you chose (Desktop, Downloads, etc.)
- **If exported via command line**: `./build/export/soteria.ipa`

---

**Try archiving again first - that's the easiest way to get Organizer to open!**

