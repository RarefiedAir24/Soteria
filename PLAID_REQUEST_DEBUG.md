# Plaid Request Debugging

## Request Found in Dashboard

**Request ID**: `le9L8wX9jaBAOBL`  
**Status**: `400` (Error)  
**Endpoint**: `/link/token/create`  
**Environment**: Sandbox  
**Timestamp**: 2 minutes ago  
**User Agent**: Plaid Node v21.0.0

## Next Steps: Get Error Details

### Step 1: View Request Details

1. In Plaid Dashboard, click on the request with ID `le9L8wX9jaBAOBL`
2. Look for sections:
   - **"Response"** or **"Error Response"**
   - **"Request Body"** or **"Payload"**

### Step 2: Check Error Response

Look for these fields in the error response:
- `error_code`: Should be `INVALID_CONFIGURATION`
- `error_message`: Should be "link token can only be configured for one Link flow"
- `error_type`: Should be `INVALID_REQUEST`

### Step 3: Check Request Body

Verify the request body includes:
```json
{
  "user": {
    "client_user_id": "..."
  },
  "client_name": "Soteria",
  "products": ["auth", "balance"],
  "country_codes": ["US"],
  "language": "en"
}
```

**Important**: Should NOT include:
- `redirect_uri` ❌
- `webhook` ❌
- `android_package_name` ❌ (unless you're testing Android)

### Step 4: Check Dashboard Configuration

While viewing the request, also check:
1. **Team Settings** → **API** → **Mobile**
   - iOS Bundle ID: `io.montebay.soteria` ✅
2. **Team Settings** → **API** → **Web**
   - Redirect URI: Should be **EMPTY** ✅
3. **Team Settings** → **API** → **Webhooks**
   - Webhook URL: Should be **EMPTY** (for testing) ✅

## Common Issues

### Issue 1: Dashboard Has Web Config
**Symptom**: Error says "link token can only be configured for one Link flow"  
**Fix**: Remove Redirect URI from dashboard

### Issue 2: Request Includes Web Parameters
**Symptom**: Request body includes `redirect_uri` or `webhook`  
**Fix**: Remove from code (should already be removed)

### Issue 3: Bundle ID Mismatch
**Symptom**: Dashboard bundle ID doesn't match app  
**Fix**: Verify dashboard has `io.montebay.soteria`

## What to Share

Please share:
1. The **error_code** from the response
2. The **error_message** from the response
3. The **request body** (if visible)
4. Whether **Redirect URI** is set in dashboard

This will help pinpoint the exact issue!

