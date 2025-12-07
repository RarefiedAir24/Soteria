# Plaid Integration Setup Guide

This guide will help you set up Plaid Link integration for Rever using AWS Lambda backend.

## Step 1: Get Plaid Credentials

1. Sign up for a Plaid account at https://dashboard.plaid.com/signup
2. Navigate to **Team Settings** → **Keys**
3. Copy your `client_id` and `secret` for the sandbox environment
4. Update `PlaidService.swift` with your credentials:
   ```swift
   private let plaidClientId = "YOUR_ACTUAL_CLIENT_ID"
   private let plaidSecret = "YOUR_ACTUAL_SECRET"
   ```

## Step 2: Install CocoaPods and Add Plaid Link SDK

1. **Install CocoaPods** (if not already installed):
   ```bash
   sudo gem install cocoapods
   ```

2. **Navigate to project directory:**
   ```bash
   cd /Users/frankschioppa/Desktop/rever
   ```

3. **Install the pods:**
   ```bash
   pod install
   ```

4. **Important:** From now on, always open `rever.xcworkspace` (not `.xcodeproj`) in Xcode

5. **Verify installation:**
   - Open `rever.xcworkspace` in Xcode
   - Check that `Pods` project appears in the navigator
   - Build the project to verify it compiles

## Step 3: Update PlaidService

1. Uncomment the `import LinkKit` line in `PlaidService.swift` (after pods are installed)
2. Update `PlaidLinkView.swift` to use the actual Plaid Link SDK (see comments in file)
3. The service is already configured to use AWS Lambda backend

## Step 4: Set Up AWS Backend

**See `AWS_BACKEND_SETUP.md` for complete AWS setup instructions.**

You need AWS Lambda functions to:
1. Create link tokens (calls Plaid's `/link/token/create`)
2. Exchange public tokens for access tokens (calls Plaid's `/item/public_token/exchange`)
3. Handle transfers (calls Plaid's Transfer API)

### AWS API Gateway Endpoints Required:

#### POST `/plaid/create-link-token`
Creates a Plaid link token for the user.

**Request:**
```json
{
  "user_id": "firebase_user_id",
  "client_name": "Rever",
  "products": ["auth", "transactions"],
  "country_codes": ["US"],
  "language": "en"
}
```

**Headers:**
```
Authorization: Bearer {firebase_id_token}
```

**Response:**
```json
{
  "link_token": "link-sandbox-xxx"
}
```

#### POST `/plaid/exchange-public-token`
Exchanges a public token for an access token.

**Request:**
```json
{
  "public_token": "public-sandbox-xxx",
  "user_id": "firebase_user_id"
}
```

**Headers:**
```
Authorization: Bearer {firebase_id_token}
```

**Response:**
```json
{
  "access_token": "access-sandbox-xxx",
  "item_id": "item-xxx",
  "accounts": [...],
  "institution_name": "Bank Name"
}
```

#### POST `/plaid/transfer`
Initiates a transfer to a savings account.

**Request:**
```json
{
  "account_id": "account-xxx",
  "amount": 100.00,
  "user_id": "firebase_user_id"
}
```

**Headers:**
```
Authorization: Bearer {firebase_id_token}
```

**Response:**
```json
{
  "transfer_id": "transfer-xxx",
  "status": "pending"
}
```

## Step 5: Update AWS API Gateway URL

After deploying your AWS Lambda functions and API Gateway, update `awsApiGatewayURL` in `PlaidService.swift`:
```swift
private let awsApiGatewayURL = "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod"
```

## Step 6: Secure Token Storage

**Important:** Access tokens should be stored securely using Keychain, not UserDefaults.

Update `PlaidService.swift` to use Keychain for storing access tokens:
```swift
import Security

private func saveAccessToken(_ token: String, forAccount accountId: String) {
    // Store in Keychain
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: accountId,
        kSecValueData as String: token.data(using: .utf8)!
    ]
    SecItemAdd(query as CFDictionary, nil)
}
```

## Step 7: Test in Sandbox

1. Use Plaid's sandbox test credentials:
   - Username: `user_good`
   - Password: `pass_good`
   - Institution: Any sandbox institution

2. Test the full flow:
   - Create link token
   - Connect account
   - Exchange token
   - Transfer funds

## Step 8: Move to Production

1. Request production access in Plaid Dashboard
2. Update `plaidEnvironment` to `"production"`
3. Update credentials to production keys
4. Test with real bank accounts

## Resources

- [Plaid iOS SDK Documentation](https://plaid.com/docs/link/ios/)
- [Plaid API Reference](https://plaid.com/docs/api/)
- [Plaid Quickstart Guide](https://plaid.com/docs/quickstart/)
- [Plaid Transfer API](https://plaid.com/docs/api/transfer/)

## Current Implementation Status

✅ UI components ready
✅ Service structure in place
⏳ Plaid Link SDK integration (needs SDK added)
⏳ Backend API endpoints (need to be implemented)
⏳ Secure token storage (should use Keychain)

