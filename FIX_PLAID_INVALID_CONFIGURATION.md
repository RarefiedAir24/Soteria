# Fix: Plaid "INVALID_CONFIGURATION" Error

## Error Message
```
"link token can only be configured for one Link flow"
Error Code: INVALID_CONFIGURATION
```

## Root Cause

This error occurs when your Plaid dashboard has **conflicting configurations** - typically when both web and mobile configurations are set up simultaneously.

## Solution: Check Plaid Dashboard

### Step 1: Access Plaid Dashboard

1. Go to: https://dashboard.plaid.com/
2. Log in with your Plaid account
3. Navigate to **Team Settings** → **API** (or **Settings** → **API**)

### Step 2: Check Mobile Configuration

**For iOS:**
- **iOS Bundle ID**: Should be `io.montebay.soteria`
- This should be configured in the dashboard

### Step 3: Remove Web Configuration

**Critical:** For iOS apps, you must **remove or clear** web-specific settings:

1. **Redirect URI**: Should be **empty** or **removed**
2. **Webhook URL**: Should be **empty** or **removed**

If you have both iOS bundle ID AND web redirect URI configured, Plaid will reject the link token request with this error.

### Step 4: Verify Environment

- Make sure you're in **Sandbox** environment
- Verify sandbox credentials are being used

## Quick Fix Options

### Option 1: Clear Web Configuration (Recommended)

1. Go to Plaid Dashboard → API Settings
2. **Remove** or **clear** the Redirect URI field
3. **Remove** or **clear** the Webhook URL field
4. **Keep** only the iOS Bundle ID: `io.montebay.soteria`
5. Save changes
6. Try connecting again

### Option 2: Use Unique User ID

If a previous link token is still active:

```swift
// In PlaidService.swift, the user_id is already unique (Firebase UID)
// But you can test with a timestamp-based ID
let testUserId = "\(userId)_\(Date().timeIntervalSince1970)"
```

### Option 3: Wait and Retry

Link tokens expire after a few minutes. If you just created one:
- Wait 5-10 minutes
- Try again

## Verification

After fixing the dashboard:

1. **Clear web redirect URI** ✅
2. **Clear webhook URL** ✅
3. **Keep iOS bundle ID**: `io.montebay.soteria` ✅
4. **Environment**: Sandbox ✅

## Test

Try connecting from the iOS app again. The error should be resolved.

## If Still Not Working

1. **Contact Plaid Support:**
   - Go to Dashboard → Support
   - Explain: "Getting INVALID_CONFIGURATION error when creating link token for iOS app"
   - Ask them to check your account configuration

2. **Check Plaid Documentation:**
   - https://plaid.com/docs/link/ios/
   - Verify your configuration matches the requirements

## Current Status

✅ **Connection working** - App can reach local dev server  
✅ **Server working** - Local dev server can call Plaid API  
❌ **Plaid API rejecting** - Dashboard configuration issue

The fix is in the Plaid dashboard, not in the code.

