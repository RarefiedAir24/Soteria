# Plaid Sandbox Setup Guide for Soteria

## Prerequisites

✅ You have Plaid sandbox access
✅ You have AWS account access
✅ You have your Plaid credentials (Client ID and Secret)

## Step 1: Get Your Plaid Sandbox Credentials

1. Log in to [Plaid Dashboard](https://dashboard.plaid.com/)
2. Navigate to **Team Settings** → **Keys**
3. Copy your **Sandbox** credentials:
   - **Client ID**: `xxxxxxxxxxxxxxxxxx`
   - **Secret**: `xxxxxxxxxxxxxxxxxx` (click to reveal)

## Step 2: Install Plaid Link SDK (iOS)

1. **Install CocoaPods** (if not already installed):
   ```bash
   sudo gem install cocoapods
   ```

2. **Navigate to project directory:**
   ```bash
   cd /Users/frankschioppa/Desktop/soteria
   ```

3. **Install the pods:**
   ```bash
   pod install
   ```

4. **Important:** From now on, always open `soteria.xcworkspace` (not `.xcodeproj`) in Xcode

5. **Verify installation:**
   - Open `soteria.xcworkspace` in Xcode
   - Check that `Pods` project appears in the navigator
   - Build the project to verify it compiles

## Step 3: Set Up AWS Lambda Functions

### Option A: Use the Script (Recommended)

1. **Make the script executable:**
   ```bash
   chmod +x add-soteria-plaid-credentials.sh
   ```

2. **Run the script with your credentials:**
   ```bash
   ./add-soteria-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET
   ```

### Option B: Manual Setup

For each Lambda function (`soteria-plaid-create-link-token`, `soteria-plaid-exchange-token`, `soteria-plaid-get-balance`, `soteria-plaid-transfer`):

1. Go to AWS Lambda Console
2. Select the function
3. Go to **Configuration** → **Environment variables**
4. Add:
   - `PLAID_CLIENT_ID` = your sandbox client ID
   - `PLAID_SECRET` = your sandbox secret
   - `PLAID_ENV` = `sandbox`
   - `DYNAMODB_TABLE` = `soteria-plaid-access-tokens`
   - `TRANSFER_TABLE` = `soteria-plaid-transfers`

## Step 4: Create DynamoDB Tables

### Table 1: `soteria-plaid-access-tokens`

```bash
aws dynamodb create-table \
    --table-name soteria-plaid-access-tokens \
    --attribute-definitions \
        AttributeName=user_id,AttributeType=S \
        AttributeName=account_id,AttributeType=S \
    --key-schema \
        AttributeName=user_id,KeyType=HASH \
        AttributeName=account_id,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

### Table 2: `soteria-plaid-transfers`

```bash
aws dynamodb create-table \
    --table-name soteria-plaid-transfers \
    --attribute-definitions \
        AttributeName=user_id,AttributeType=S \
        AttributeName=transfer_id,AttributeType=S \
    --key-schema \
        AttributeName=user_id,KeyType=HASH \
        AttributeName=transfer_id,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

## Step 5: Deploy Lambda Functions

1. **Navigate to lambda directory:**
   ```bash
   cd lambda
   ```

2. **For each function, create a deployment package:**
   ```bash
   # Example for create-link-token
   cd soteria-plaid-create-link-token
   npm install
   zip -r function.zip index.js node_modules package.json
   ```

3. **Deploy to AWS:**
   ```bash
   aws lambda update-function-code \
       --function-name soteria-plaid-create-link-token \
       --zip-file fileb://function.zip \
       --region us-east-1
   ```

   Repeat for all functions:
   - `soteria-plaid-create-link-token`
   - `soteria-plaid-exchange-token`
   - `soteria-plaid-get-balance`
   - `soteria-plaid-transfer`

## Step 6: Set Up API Gateway

1. **Create API Gateway** (or use existing `soteria-api`):
   ```bash
   # See create-soteria-api-gateway.sh
   ```

2. **Create endpoints:**
   - `POST /soteria/plaid/create-link-token` → `soteria-plaid-create-link-token`
   - `POST /soteria/plaid/exchange-token` → `soteria-plaid-exchange-token`
   - `GET /soteria/plaid/balance` → `soteria-plaid-get-balance`
   - `POST /soteria/plaid/transfer` → `soteria-plaid-transfer`

3. **Enable CORS** for all endpoints

4. **Deploy API** to `prod` stage

5. **Get API Gateway URL:**
   - Format: `https://{api-id}.execute-api.us-east-1.amazonaws.com/prod`
   - Copy this URL

## Step 7: Update iOS App

1. **Update `PlaidService.swift`:**
   - Find: `private let apiGatewayURL = "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod"`
   - Replace with your actual API Gateway URL

2. **Build and run the app**

## Step 8: Test the Integration

### Test Account Connection

1. Open the app
2. Go to **Settings** → **Savings Settings**
3. Tap **"Connect Accounts"**
4. Use Plaid's sandbox test credentials:
   - **Username**: `user_good`
   - **Password**: `pass_good`
   - **Institution**: Any sandbox institution (e.g., "First Platypus Bank")

### Test Transfer (Sandbox)

In sandbox, transfers are simulated. Test the flow:

1. Connect accounts (checking + savings)
2. Go to **PauseView** (when app is blocked)
3. Unblock and choose to save money
4. Transfer should be initiated (will be simulated in sandbox)

## Sandbox Test Credentials

Plaid provides these test credentials for sandbox:

- **Username**: `user_good`
- **Password**: `pass_good`
- **Institution**: Any sandbox institution

### Test Scenarios

- **Success**: Use `user_good` / `pass_good`
- **Insufficient Funds**: Use `user_good` / `pass_good` (some accounts have $0 balance)
- **Error Handling**: Plaid will return appropriate error codes

## Troubleshooting

### "Link token creation failed"
- Check Lambda function logs in CloudWatch
- Verify Plaid credentials are correct
- Check API Gateway is deployed

### "Token exchange failed"
- Check DynamoDB table exists
- Verify Lambda has DynamoDB permissions
- Check access token storage

### "Transfer failed"
- In sandbox, transfers are simulated
- Check Lambda function logs
- Verify account IDs are correct

### "Plaid Link SDK not found"
- Run `pod install`
- Open `.xcworkspace` (not `.xcodeproj`)
- Clean build folder (Cmd+Shift+K)

## Next Steps

Once sandbox is working:

1. Test all flows (connection, balance reading, transfers)
2. Test error handling
3. Prepare for production access request
4. Update to use AWS Secrets Manager for credentials (production)

## Quick Reference

- **Plaid Dashboard**: https://dashboard.plaid.com/
- **Plaid Docs**: https://plaid.com/docs/
- **Sandbox Test Credentials**: `user_good` / `pass_good`
- **API Gateway URL**: Update in `PlaidService.swift`

