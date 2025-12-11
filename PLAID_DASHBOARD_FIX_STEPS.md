# Step-by-Step: Fix Plaid "INVALID_CONFIGURATION" Error

## The Error
```
"link token can only be configured for one Link flow"
Error Code: INVALID_CONFIGURATION
```

## Root Cause
Your Plaid dashboard has **BOTH web and mobile configurations** enabled simultaneously. Plaid only allows ONE flow type per account.

## Solution: Remove Web Configuration

### Step 1: Log into Plaid Dashboard

1. Go to: **https://dashboard.plaid.com/**
2. Log in with your Plaid account
3. Make sure you're in the **Sandbox** environment (top right corner)

### Step 2: Navigate to API Settings

1. Click on your **team name** (top left)
2. Go to **Team Settings** → **API**
   - OR
3. Go to **Settings** → **API**

### Step 3: Find Web Configuration Section

Look for a section labeled:
- **"Web"** or **"Redirect URI"** or **"OAuth Redirect URI"**

### Step 4: Clear Web Redirect URI

1. Find the **Redirect URI** field
2. **DELETE** or **CLEAR** the value (make it empty)
3. **Save** changes

### Step 5: Find Webhook Configuration (Optional)

1. Look for **"Webhooks"** section
2. Find **Webhook URL** field
3. **DELETE** or **CLEAR** the value (for testing, can add later)
4. **Save** changes

### Step 6: Verify Mobile Configuration

1. Find **"Mobile"** section
2. Verify **iOS Bundle ID** is set to: `io.montebay.soteria`
3. If not set, add it now
4. **Save** changes

### Step 7: Final Checklist

After making changes, verify:

- [ ] **Redirect URI**: EMPTY (not set)
- [ ] **Webhook URL**: EMPTY (for testing)
- [ ] **iOS Bundle ID**: `io.montebay.soteria` (set)
- [ ] **Environment**: Sandbox
- [ ] **All changes saved**

### Step 8: Wait and Test

1. **Wait 2-3 minutes** for changes to propagate
2. Try connecting from iOS app again
3. Should work now!

## If You Can't Find These Settings

### Option A: Check Different Dashboard Views

Some Plaid dashboards organize settings differently:
- Try **Settings** → **Integrations**
- Try **Settings** → **Link**
- Try **Team** → **Settings** → **API**

### Option B: Contact Plaid Support

1. Go to Dashboard → **Support** or **Help**
2. Create a support ticket
3. Explain: "Getting INVALID_CONFIGURATION error: 'link token can only be configured for one Link flow'"
4. Ask them to:
   - Check your account configuration
   - Remove any web redirect_uri settings
   - Verify iOS bundle ID is configured: `io.montebay.soteria`
5. Provide your Client ID: `69352338b821ae002254a4e1`

## Alternative: Create New Test App

If you can't fix the existing configuration:

1. In Plaid Dashboard, create a **new test app**
2. Configure ONLY mobile settings:
   - iOS Bundle ID: `io.montebay.soteria`
   - NO redirect URI
   - NO webhook URL
3. Get new credentials
4. Update `.env` file with new credentials

## Verification Test

After fixing, test with:

```bash
curl -X POST http://localhost:8000/soteria/plaid/create-link-token \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_123",
    "client_name": "Soteria",
    "products": ["auth", "balance"],
    "country_codes": ["US"]
  }'
```

Should return: `{"link_token": "link-sandbox-..."}`

## Why This Happens

Plaid's API enforces that you can only use ONE Link flow type:
- **Web flow**: Requires redirect_uri, uses OAuth redirects
- **Mobile flow**: Requires bundle ID, uses native SDK

Having BOTH configured causes the conflict.

## Current Status

✅ **Connection**: Working  
✅ **Server**: Working  
✅ **Code**: Correct  
❌ **Dashboard**: Needs web config removed

**The fix is 100% in the Plaid dashboard, not in your code.**

