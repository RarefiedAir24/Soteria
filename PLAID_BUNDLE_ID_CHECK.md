# Plaid iOS Bundle ID Configuration Check

## Current Status
- ✅ No redirect URI configured (good!)
- ❓ Need to verify iOS Bundle ID is set

## Critical: iOS Bundle ID Must Be Configured

For iOS apps, Plaid **requires** the bundle ID to be configured in the dashboard.

### Step 1: Check Dashboard

1. Go to: https://dashboard.plaid.com/
2. Navigate to **Team Settings** → **API** → **Mobile**
3. Look for **"iOS Bundle ID"** field

### Step 2: Verify Bundle ID

**Required Bundle ID**: `io.montebay.soteria`

**Check:**
- [ ] Is the iOS Bundle ID field **set** to `io.montebay.soteria`?
- [ ] Is it **exactly** `io.montebay.soteria` (no typos)?
- [ ] Is it in the **Sandbox** environment?

### Step 3: If Bundle ID is Missing

1. In **Team Settings** → **API** → **Mobile**
2. Enter: `io.montebay.soteria`
3. **Save** changes
4. Wait 2-3 minutes
5. Try connecting again

### Step 4: Verify Xcode Bundle ID

Also verify your Xcode project has the same bundle ID:

1. Open Xcode
2. Select your project
3. Go to **General** tab
4. Check **Bundle Identifier**: Should be `io.montebay.soteria`

## Why This Matters

Plaid needs to know:
- **Which app** is making the request (bundle ID)
- **What platform** it's for (iOS vs web vs Android)

Without the bundle ID configured, Plaid might be confused about the flow type.

## Other Things to Check

While in the dashboard, also verify:

1. **Webhooks** section:
   - Webhook URL: Should be **EMPTY** (for testing)
   
2. **Environment**:
   - Make sure you're in **Sandbox** (not Production)

3. **API Version**:
   - Should be using the default (2020-09-14) or latest

## Next Steps

1. **Check if bundle ID is set** in dashboard
2. **If not set**, add it: `io.montebay.soteria`
3. **Save** and wait 2-3 minutes
4. **Try connecting** again

If bundle ID is already set correctly, we may need to contact Plaid support to check for other configuration issues.

