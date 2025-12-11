# Plaid Support Request Template

## Issue Summary

**Error**: `INVALID_CONFIGURATION`  
**Message**: "link token can only be configured for one Link flow"  
**Request ID**: `le9L8wX9jaBAOBL`  
**Environment**: Sandbox  
**Client ID**: `69352338b821ae002254a4e1`

## What We've Verified

✅ **No Redirect URI configured** - Dashboard shows no redirect URIs  
✅ **No Bundle ID field in dashboard** - Cannot find where to set iOS bundle ID  
✅ **Code is correct** - Link token request does NOT include:
   - `redirect_uri` ❌
   - `webhook` ❌
   - `ios_bundle_id` ❌ (not a valid parameter)

## Link Token Request

Our request includes only:
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

## App Details

- **Platform**: iOS
- **Bundle ID**: `io.montebay.soteria`
- **SDK**: Plaid LinkKit (CocoaPods)
- **Integration Type**: Native iOS app (not webview)

## Request to Plaid Support

We're getting an `INVALID_CONFIGURATION` error when creating link tokens for our iOS app. We've verified:

1. No redirect URIs are configured in the dashboard
2. No web-specific parameters in our link token requests
3. Code follows Plaid iOS integration guidelines

Could you please:
1. Check our account configuration in Sandbox environment
2. Verify there are no conflicting web/mobile settings
3. Confirm our account is properly configured for iOS mobile app integration
4. Let us know if there's a specific dashboard setting we need to configure

## Additional Information

- **Request ID**: `le9L8wX9jaBAOBL`
- **Timestamp**: 2025-12-11T02:23:12.220Z
- **User Agent**: Plaid Node v21.0.0
- **Endpoint**: `/link/token/create`

Thank you for your help!

