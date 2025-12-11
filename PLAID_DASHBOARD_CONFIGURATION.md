# Plaid Dashboard Configuration Guide

## Error: "link token can only be configured for one Link flow"

This error means your Plaid account has **conflicting configurations** between web and mobile.

## Required Dashboard Settings for iOS

### ✅ What You NEED:

1. **iOS Bundle ID**: `io.montebay.soteria`
   - Location: Dashboard → Team Settings → API → Mobile
   - This MUST be configured

### ❌ What You MUST REMOVE:

1. **Redirect URI** (Web configuration)
   - Location: Dashboard → Team Settings → API → Web
   - **Must be EMPTY or REMOVED**
   - Having this configured causes the conflict

2. **Webhook URL** (Web configuration)
   - Location: Dashboard → Team Settings → API → Webhooks
   - **Must be EMPTY or REMOVED** (for now)
   - Can add later if needed, but not for initial testing

## Step-by-Step Fix

### Step 1: Access Plaid Dashboard

1. Go to: https://dashboard.plaid.com/
2. Log in
3. Navigate to **Team Settings** → **API**

### Step 2: Configure Mobile Settings

1. Find **Mobile** section
2. **iOS Bundle ID**: Enter `io.montebay.soteria`
3. **Android Package Name**: Leave empty (or remove if set)
4. **Save**

### Step 3: Clear Web Settings

1. Find **Web** section
2. **Redirect URI**: **Clear this field** (make it empty)
3. **Save**

### Step 4: Clear Webhook Settings (Optional for Testing)

1. Find **Webhooks** section
2. **Webhook URL**: **Clear this field** (make it empty)
3. **Save**

### Step 5: Verify Environment

- Make sure you're in **Sandbox** environment
- Verify sandbox credentials match your `.env` file

## Verification Checklist

After updating dashboard:

- [ ] iOS Bundle ID: `io.montebay.soteria` ✅
- [ ] Redirect URI: **EMPTY** ✅
- [ ] Webhook URL: **EMPTY** (for testing) ✅
- [ ] Environment: **Sandbox** ✅

## Test Again

1. Wait 1-2 minutes for dashboard changes to propagate
2. Try connecting from iOS app
3. Should work now!

## If Still Not Working

### Option 1: Check for Active Link Tokens

Link tokens expire after a few minutes, but if you created one recently:
- Wait 5-10 minutes
- Try again with a fresh request

### Option 2: Verify Bundle ID

Double-check the bundle ID matches exactly:
- Dashboard: `io.montebay.soteria`
- Xcode: `io.montebay.soteria` (check in project.pbxproj)

### Option 3: Contact Plaid Support

If the error persists:
1. Go to Dashboard → Support
2. Explain: "Getting INVALID_CONFIGURATION error when creating link token for iOS app"
3. Ask them to verify your account configuration
4. Provide your Client ID: `69352338b821ae002254a4e1`

## Common Mistakes

❌ **Having both Redirect URI and iOS Bundle ID configured**  
✅ **Only iOS Bundle ID should be configured**

❌ **Using web redirect_uri in link token request**  
✅ **Don't include redirect_uri for mobile apps**

❌ **Mismatched bundle ID**  
✅ **Bundle ID must match exactly: `io.montebay.soteria`**

## Current Configuration

Your app is configured for:
- **Platform**: iOS
- **Bundle ID**: `io.montebay.soteria`
- **Environment**: Sandbox
- **Products**: `auth`, `balance`

Make sure your Plaid dashboard matches this configuration!

