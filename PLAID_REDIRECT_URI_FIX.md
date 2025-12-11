# Plaid Redirect URI Configuration for iOS

## ❌ DO NOT Add Redirect URI for iOS

**For iOS apps using Plaid LinkKit SDK:**
- **Redirect URIs are NOT needed**
- **Redirect URIs are ONLY for:**
  - Web applications (OAuth redirect flow)
  - Android apps using OAuth (not Android SDK)

## ✅ Correct Configuration for iOS

### Step 1: Redirect URIs Section
- **Leave it EMPTY**
- **Do NOT add any redirect URI**
- Click "Cancel" if prompted to add one

### Step 2: Mobile Configuration
- Go to **Team Settings** → **API** → **Mobile**
- **iOS Bundle ID**: `io.montebay.soteria`
- This is the ONLY mobile configuration needed

### Step 3: Verify
- Redirect URIs: **EMPTY** ✅
- iOS Bundle ID: `io.montebay.soteria` ✅
- Webhook URL: **EMPTY** (for testing) ✅

## Why This Matters

Plaid enforces that you can only use ONE Link flow:
- **Web flow**: Requires redirect_uri (OAuth)
- **Mobile flow**: Requires bundle ID (native SDK)

Having BOTH causes the error:
```
"link token can only be configured for one Link flow"
```

## Current Issue

If you see redirect URIs in your dashboard:
1. **Remove them all**
2. Keep only the iOS Bundle ID
3. Save changes
4. Wait 2-3 minutes
5. Try connecting again

## Summary

**For iOS app:**
- ✅ iOS Bundle ID: `io.montebay.soteria`
- ❌ Redirect URI: NOT needed (leave empty)
- ❌ Webhook URL: NOT needed (for testing)

**The redirect URI section should be completely empty!**

