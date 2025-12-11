# ✅ Ready for Testing!

## Setup Complete

All infrastructure is deployed and configured. You're ready to test the Plaid integration!

## What's Configured

### ✅ AWS Infrastructure
- **IAM Role**: `soteria-lambda-role` (with CloudWatch Logs and DynamoDB permissions)
- **DynamoDB Tables**: 
  - `soteria-plaid-access-tokens`
  - `soteria-plaid-transfers`
- **API Gateway**: `soteria-api` (ID: `ue1psw3mt3`)
  - URL: `https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod`
  - Endpoints:
    - `POST /soteria/plaid/create-link-token`
    - `POST /soteria/plaid/exchange-token`
    - `GET /soteria/plaid/balance`
    - `POST /soteria/plaid/transfer`

### ✅ Lambda Functions
- `soteria-plaid-create-link-token` ✅ Deployed with credentials
- `soteria-plaid-exchange-token` ✅ Deployed with credentials
- `soteria-plaid-get-balance` ✅ Deployed with credentials
- `soteria-plaid-transfer` ✅ Deployed with credentials

### ✅ Plaid Credentials
- **Client ID**: `69352338b821ae002254a4e1`
- **Environment**: `sandbox`
- **Status**: Configured in all Lambda functions

### ✅ iOS App
- **PlaidService.swift**: Updated with API Gateway URL
- **Plaid SDK**: Installed via CocoaPods

## Testing Steps

### 1. Build and Run the App
```bash
# Open in Xcode
open soteria.xcworkspace

# Build and run on simulator or device
```

### 2. Test Account Connection

1. Open the app
2. Navigate to: **Settings** → **Savings Settings**
3. Tap **"Connect Accounts"**
4. Plaid Link UI should open
5. Use sandbox test credentials:
   - **Username**: `user_good`
   - **Password**: `pass_good`
   - **Institution**: Select any sandbox institution (e.g., "First Platypus Bank")
6. Complete the connection flow
7. Verify accounts appear with balances

### 3. Test Balance Reading

1. After connecting accounts, verify balances are displayed
2. Check that checking and savings accounts show correct balances
3. Refresh should update balances

### 4. Test Virtual Savings

1. Block an app (if you have that feature)
2. Unblock and choose to save money
3. Should see "Save $10?" prompt
4. Confirm should record virtual savings

## Troubleshooting

### "Link token creation failed"
- Check CloudWatch Logs for `soteria-plaid-create-link-token`
- Verify Plaid credentials are correct
- Check API Gateway is accessible

### "Plaid Link doesn't open"
- Verify Plaid SDK is installed: `pod install`
- Check Xcode console for errors
- Verify API Gateway URL is correct in `PlaidService.swift`

### "Token exchange failed"
- Check DynamoDB table exists: `soteria-plaid-access-tokens`
- Verify Lambda has DynamoDB permissions
- Check CloudWatch Logs for `soteria-plaid-exchange-token`

### "Balance not showing"
- Check DynamoDB has access tokens (after connecting account)
- Verify balance endpoint is connected
- Check CloudWatch Logs for `soteria-plaid-get-balance`

## Quick Verification Commands

```bash
# Check Lambda functions
aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'soteria-plaid')].FunctionName" --region us-east-1

# Check DynamoDB tables
aws dynamodb list-tables --query "TableNames[?starts_with(@, 'soteria-plaid')]" --region us-east-1

# Check API Gateway
aws apigateway get-rest-api --rest-api-id ue1psw3mt3 --region us-east-1

# View Lambda logs
aws logs tail /aws/lambda/soteria-plaid-create-link-token --follow --region us-east-1
```

## Test Credentials

**Plaid Sandbox:**
- Username: `user_good`
- Password: `pass_good`
- Institution: Any sandbox institution

## Next Steps

1. ✅ Build and run the app
2. ✅ Test account connection
3. ✅ Test balance reading
4. ✅ Test virtual savings mode
5. ✅ Prepare for demo!

## API Gateway URL

```
https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod
```

This is already configured in `PlaidService.swift`.

---

**You're all set! Ready to test! 🚀**

