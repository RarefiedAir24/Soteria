# Face ID Setup Instructions

## Required: Add NSFaceIDUsageDescription to Info.plist

The app **will crash** if this key is missing when trying to use Face ID.

### How to Add:

1. **Open Xcode**
2. **Select your project** in the navigator
3. **Select the "soteria" target**
4. **Go to the "Info" tab**
5. **Click the "+" button** to add a new key
6. **Add**: `Privacy - Face ID Usage Description` (or `NSFaceIDUsageDescription`)
7. **Set the value to**: `"Use Face ID to quickly sign in to your account"`

### Alternative: Add to Info.plist file directly

If you have a separate Info.plist file, add:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to quickly sign in to your account</string>
```

### Verify:

After adding, the app will:
- ✅ Prompt for Face ID permission on first use
- ✅ Not crash when Face ID button is pressed
- ✅ Show Face ID dialog properly

---

## Fixed Issues:

1. ✅ **LAContext reuse** - Now creates a fresh context for each authentication attempt
2. ✅ **Threading** - All UI updates are on MainActor
3. ✅ **Error handling** - Better error handling for all cases
4. ✅ **State management** - Proper state updates during authentication

---

## Testing:

1. Sign in manually first (to save credentials)
2. Sign out
3. Press "Sign in with Face ID" button
4. Face ID dialog should appear
5. Authenticate with Face ID
6. Should sign in automatically

---

**Note**: The crash is NOT because of local testing - it's because the Info.plist key is missing. Add it and the crash will be fixed!

