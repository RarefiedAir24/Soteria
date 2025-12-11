# Demo Setup Guide - Step by Step

This guide will walk you through setting up everything needed for the Plaid demo.

## Prerequisites

1. AWS CLI configured with credentials
2. Plaid sandbox credentials (get from https://dashboard.plaid.com/developers/keys)
3. Xcode installed
4. Node.js installed (for Lambda functions)

## Step 1: Install iOS Dependencies ✅

Already done! Plaid SDK is installed.

```bash
cd /Users/frankschioppa/soteria
pod install
```

**Next:** Open `soteria.xcworkspace` (not `.xcodeproj`) in Xcode.

## Step 2: Install Lambda Dependencies

```bash
cd /Users/frankschioppa/soteria/lambda

# Install dependencies for each Plaid function
cd soteria-plaid-create-link-token && npm install && cd ..
cd soteria-plaid-exchange-token && npm install && cd ..
cd soteria-plaid-get-balance && npm install && cd ..
cd soteria-plaid-transfer && npm install && cd ..
```

## Step 3: Create AWS Infrastructure

### 3a. Create IAM Role

```bash
cd /Users/frankschioppa/soteria
./create-soteria-lambda-role.sh
```

This creates the `soteria-lambda-role` with permissions for:
- CloudWatch Logs
- DynamoDB access

### 3b. Create DynamoDB Tables

```bash
./create-soteria-dynamodb-tables.sh
```

This creates:
- `soteria-plaid-access-tokens` (stores Plaid access tokens)
- `soteria-plaid-transfers` (stores transfer records)
- Other Soteria tables

### 3c. Create API Gateway

```bash
./create-soteria-api-gateway.sh
```

**IMPORTANT:** Save the API Gateway ID that's printed at the end!

This creates:
- `/soteria/plaid/create-link-token` (POST)
- `/soteria/plaid/exchange-token` (POST)
- `/soteria/plaid/balance` (GET)
- `/soteria/plaid/transfer` (POST)

## Step 4: Deploy Lambda Functions

```bash
./deploy-soteria-lambdas.sh
```

This deploys all 4 Plaid Lambda functions.

## Step 5: Connect Lambda to API Gateway

After creating the API Gateway, you need to:

1. Go to AWS Console → API Gateway
2. Select your `soteria-api`
3. For each endpoint, create a method and connect to the Lambda function:

**For `/soteria/plaid/create-link-token`:**
- Method: POST
- Integration: Lambda Function
- Function: `soteria-plaid-create-link-token`
- Enable Lambda Proxy Integration: ✅

**For `/soteria/plaid/exchange-token`:**
- Method: POST
- Integration: Lambda Function
- Function: `soteria-plaid-exchange-token`
- Enable Lambda Proxy Integration: ✅

**For `/soteria/plaid/balance`:**
- Method: GET
- Integration: Lambda Function
- Function: `soteria-plaid-get-balance`
- Enable Lambda Proxy Integration: ✅

**For `/soteria/plaid/transfer`:**
- Method: POST
- Integration: Lambda Function
- Function: `soteria-plaid-transfer`
- Enable Lambda Proxy Integration: ✅

4. Enable CORS on all endpoints:
   - Actions → Enable CORS
   - Access-Control-Allow-Origin: `*`
   - Access-Control-Allow-Headers: `Content-Type,Authorization`
   - Access-Control-Allow-Methods: `POST,GET,OPTIONS`

5. Deploy API:
   - Actions → Deploy API
   - Stage: `prod` (or create new)
   - Deploy

6. Get the Invoke URL:
   ```bash
   aws apigateway get-stage \
     --rest-api-id YOUR_API_ID \
     --stage-name prod \
     --region us-east-1 \
     --query 'invokeUrl' \
     --output text
   ```

## Step 6: Add Plaid Credentials

Get your Plaid sandbox credentials from https://dashboard.plaid.com/developers/keys

```bash
./add-soteria-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET
```

This sets environment variables on all Lambda functions.

## Step 7: Update iOS App

Open `soteria/Services/PlaidService.swift` and update line 44:

```swift
private let apiGatewayURL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"
```

Replace `YOUR_API_ID` with the actual API Gateway ID from Step 3c.

## Step 8: Test the Flow

1. **Build and run the app** in Xcode
2. **Navigate to:** Settings → Savings Settings
3. **Tap:** "Connect Accounts"
4. **Use Plaid sandbox credentials:**
   - Username: `user_good`
   - Password: `pass_good`
   - Select any institution
5. **Verify:** Accounts appear with balances
6. **Test virtual savings:**
   - Block an app
   - Unblock and choose to save
   - Should see "Save $10?" prompt

## Troubleshooting

### Lambda function not found
- Make sure you deployed the functions first
- Check function names match exactly

### API Gateway returns 500
- Check CloudWatch Logs for the Lambda function
- Verify Plaid credentials are set
- Verify DynamoDB table exists

### Plaid Link doesn't open
- Check that Plaid SDK is installed (pod install)
- Verify link token is created (check Xcode console)
- Check API Gateway URL is correct

### Balance not showing
- Check DynamoDB table has access tokens
- Verify balance endpoint is connected
- Check CloudWatch Logs for errors

## Quick Verification Commands

```bash
# Check if API Gateway exists
aws apigateway get-rest-apis --query "items[?name=='soteria-api']" --region us-east-1

# Check if Lambda functions exist
aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'soteria-plaid')].FunctionName" --region us-east-1

# Check if DynamoDB tables exist
aws dynamodb list-tables --query "TableNames[?starts_with(@, 'soteria-plaid')]" --region us-east-1

# Check Lambda environment variables
aws lambda get-function-configuration --function-name soteria-plaid-create-link-token --region us-east-1 --query 'Environment.Variables'
```

## Demo Day Checklist

- [ ] All Lambda functions deployed
- [ ] API Gateway created and deployed
- [ ] Plaid credentials added
- [ ] DynamoDB tables created
- [ ] iOS app updated with API Gateway URL
- [ ] Test account connection works
- [ ] Test balance reading works
- [ ] Test virtual savings works
- [ ] Have sandbox credentials ready (`user_good` / `pass_good`)

