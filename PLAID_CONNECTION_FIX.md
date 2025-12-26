# Plaid Connection Error Fix

## Current Issue

The app shows: "Bank connection is temporarily unavailable. Plaid integration is being updated to fix a startup issue."

## Status

✅ **Code is re-enabled** - The connection code is active  
❌ **Plaid API error** - The Plaid API is returning a 400 error

## The Problem

The Plaid API is rejecting the link token creation request with:
- **Error Code:** `INVALID_CONFIGURATION`
- **Error Message:** "link token can only be configured for one Link flow"

This suggests there might be a configuration issue in your Plaid dashboard.

## Solutions

### Option 1: Check Plaid Dashboard Configuration

1. Go to: https://dashboard.plaid.com/
2. Navigate to **Team Settings** → **API**
3. Check if there are any conflicting configurations
4. Verify the sandbox environment is properly set up

### Option 2: Test with Different User ID

The error might be related to the `client_user_id`. Try:
- Using a unique user ID each time
- Or clearing any existing link tokens for that user

### Option 3: Verify Plaid Credentials

Make sure the credentials in `local-dev-server/.env` are correct:
```env
PLAID_CLIENT_ID=your_client_id_here
PLAID_SECRET=your_secret_here
PLAID_ENV=sandbox
```

### Option 4: Check Server Logs

View detailed error information:
```bash
tail -f local-dev-server/server.log
```

Then try connecting from the iOS app and watch for the actual Plaid error response.

## Testing

1. **Server is running** ✅ - http://localhost:8000
2. **iOS app configured** ✅ - Uses localhost in DEBUG mode
3. **Try connecting** - The error should now show more details

## Next Steps

1. Check the server logs when you try to connect
2. Look for the actual Plaid API error response
3. Share the error details for further debugging

The connection code is working - we just need to resolve the Plaid API configuration issue.

