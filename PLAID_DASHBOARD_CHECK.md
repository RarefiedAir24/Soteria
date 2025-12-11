# Plaid Dashboard Configuration Check

## Error: "link token can only be configured for one Link flow"

This error means your Plaid account has conflicting configurations. You need to check your Plaid dashboard settings.

## Step 1: Check Plaid Dashboard

1. Go to: https://dashboard.plaid.com/
2. Log in with your Plaid account
3. Navigate to **Team Settings** → **API** or **Settings** → **API**

## Step 2: Check Link Configuration

Look for these settings:

### Mobile App Configuration
- **iOS Bundle ID**: Should be set to `io.montebay.soteria`
- **Android Package Name**: Should be empty or not conflicting

### Web App Configuration
- **Redirect URI**: Should be empty or not conflicting
- **Webhook URL**: Should be empty or not conflicting

## Step 3: Common Issues

### Issue 1: Both Web and Mobile Configured
**Problem:** You have both web redirect_uri and mobile bundle ID configured, which causes conflicts.

**Solution:**
- For iOS app testing, make sure web redirect_uri is **empty** or **removed**
- Only keep the iOS bundle ID: `io.montebay.soteria`

### Issue 2: Previous Link Token Still Active
**Problem:** A previous link token is still active and hasn't expired.

**Solution:**
- Link tokens expire after a few minutes
- Wait 5-10 minutes and try again
- Or use a different `client_user_id` in your request

### Issue 3: Sandbox Environment Issue
**Problem:** Sandbox environment might have conflicting test configurations.

**Solution:**
- Verify you're using sandbox credentials
- Check that sandbox environment settings are correct
- Try creating a new test app in Plaid dashboard

## Step 4: Verify Configuration

After checking the dashboard, verify your setup:

1. **iOS Bundle ID**: `io.montebay.soteria` ✅
2. **Web Redirect URI**: Empty or removed ✅
3. **Webhook URL**: Empty or removed ✅
4. **Environment**: Sandbox ✅

## Step 5: Test Again

1. Make sure dashboard settings are correct
2. Wait a few minutes (if previous token was the issue)
3. Try connecting from the iOS app again

## Alternative: Contact Plaid Support

If the issue persists:
1. Go to Plaid Dashboard → Support
2. Explain: "Getting INVALID_CONFIGURATION error: 'link token can only be configured for one Link flow'"
3. Ask them to check your account configuration

## Quick Test

Try creating a link token with a unique user ID:

```bash
curl -X POST http://localhost:8000/soteria/plaid/create-link-token \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_'$(date +%s)'",
    "client_name": "Soteria",
    "products": ["auth", "balance"],
    "country_codes": ["US"]
  }'
```

If this works, the issue was a previous active link token.

