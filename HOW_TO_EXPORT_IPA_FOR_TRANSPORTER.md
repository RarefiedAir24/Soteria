# How to Export .ipa File for Transporter

After archiving, you need to **export** the archive to create the `.ipa` file that Transporter can upload.

---

## 🚀 Step-by-Step: Export Archive to .ipa

### Step 1: Archive Completes

After **Product → Archive** finishes:
- Organizer window opens automatically
- You'll see your archive listed

---

### Step 2: Export the Archive

1. **In Organizer window**:
   - **Select your archive** (click on it in the list)
   - You'll see: Date, Version 1.0 (2), "Ready to Distribute"

2. **Click "Distribute App"** button (blue button on the right)

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
   - Verify app info (Version 1.0, Build 2)
   - **IMPORTANT**: Click **"Export"** button (NOT "Upload")
   - This creates the `.ipa` file

7. **Choose Export Location**:
   - A file picker dialog appears
   - **Choose a folder** (e.g., Desktop, Downloads, or create a "builds" folder)
   - Click **"Export"**

8. **Wait for Export**:
   - Xcode creates the `.ipa` file
   - Takes 1-2 minutes
   - You'll see progress

---

### Step 3: Find Your .ipa File

After export completes:

1. **Navigate to the folder** you chose (e.g., Desktop or Downloads)

2. **Look for**:
   - Folder named something like `soteria 2026-01-07 15.45.00` (date/time)
   - Inside that folder: **`soteria.ipa`** file

3. **File location example**:
   ```
   ~/Desktop/soteria 2026-01-07 15.45.00/
     └── soteria.ipa  ← This is what you need!
   ```

---

### Step 4: Upload via Transporter

1. **Open Transporter app**

2. **Add the .ipa file**:
   - **Option A**: Drag and drop `soteria.ipa` into Transporter
   - **Option B**: Click "+" button → Navigate to and select `soteria.ipa`

3. **Click "Deliver"** button

4. **Wait for upload** (10-30 minutes)

---

## 📍 Common Export Locations

Xcode typically suggests or saves to:
- **Desktop** (most common)
- **Downloads** folder
- **Documents** folder
- **Or** a folder you specify

---

## 🔍 If You Can't Find the .ipa File

### Option 1: Check Recent Files
1. **Finder** → **Recent** (in sidebar)
2. Look for folders with today's date

### Option 2: Search for .ipa
1. **Spotlight** (⌘Space)
2. Search: `soteria.ipa`
3. Should find the file

### Option 3: Export Again
1. Go back to Organizer
2. Select archive
3. Click "Distribute App"
4. Follow export steps again
5. **Note the location** this time!

---

## ✅ Quick Checklist

- [ ] Archive completed
- [ ] Organizer window open
- [ ] Selected archive
- [ ] Clicked "Distribute App"
- [ ] Chose "App Store Connect" → "Upload"
- [ ] Clicked **"Export"** (not "Upload")
- [ ] Chose export location
- [ ] Found `soteria.ipa` file
- [ ] Ready to upload in Transporter

---

## 💡 Pro Tip

**Create a dedicated folder** for builds:
- Create folder: `~/Desktop/Soteria Builds`
- Export there each time
- Easy to find and organize

---

**The .ipa file is created when you click "Export" in the distribution dialog!**

