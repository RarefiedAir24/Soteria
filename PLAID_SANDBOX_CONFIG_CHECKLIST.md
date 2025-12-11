# Plaid Sandbox Configuration Checklist

## Information You Need to Get from Plaid Dashboard

### 1. Plaid Credentials (Required)
**Where to get:** https://dashboard.plaid.com/developers/keys

- [ ] **Client ID** (Sandbox)
  - Format: Alphanumeric string (e.g., `5f8a9b2c3d4e5f6a7b8c9d0`)
  - Found in: Team Settings → Keys → Sandbox section

- [ ] **Secret** (Sandbox)
  - Format: Long alphanumeric string (e.g., `abc123def456ghi789jkl012mno345pqr`)
  - Found in: Team Settings → Keys → Sandbox section
  - Note: Click to reveal (hidden by default)

### 2. Plaid Environment
- [ ] **Environment**: `sandbox` (for testing)
  - This is set in your Lambda environment variables
  - Options: `sandbox`, `development`, `production`

## Information You Need to Configure in AWS

### 3. Lambda Environment Variables
For each Lambda function, you need to set:

- [ ] `PLAID_CLIENT_ID` = Your sandbox Client ID
- [ ] `PLAID_SECRET` = Your sandbox Secret
- [ ] `PLAID_ENV` = `sandbox`
- [ ] `DYNAMODB_TABLE` = `soteria-plaid-access-tokens`
- [ ] `TRANSFER_TABLE` = `soteria-plaid-transfers` (for transfer function)

**Functions to configure:**
- [ ] `soteria-plaid-create-link-token`
- [ ] `soteria-plaid-exchange-token`
- [ ] `soteria-plaid-get-balance`
- [ ] `soteria-plaid-transfer`

### 4. DynamoDB Tables
- [ ] `soteria-plaid-access-tokens`
  - Partition key: `user_id` (String)
  - Sort key: `account_id` (String)
  
- [ ] `soteria-plaid-transfers` (optional for demo)
  - Partition key: `user_id` (String)
  - Sort key: `transfer_id` (String)

### 5. API Gateway Configuration
- [ ] API Gateway ID (from `create-soteria-api-gateway.sh`)
- [ ] API Gateway URL (format: `https://{api-id}.execute-api.us-east-1.amazonaws.com/prod`)
- [ ] Endpoints created:
  - [ ] `POST /soteria/plaid/create-link-token`
  - [ ] `POST /soteria/plaid/exchange-token`
  - [ ] `GET /soteria/plaid/balance`
  - [ ] `POST /soteria/plaid/transfer`
- [ ] CORS enabled on all endpoints
- [ ] API deployed to `prod` stage

### 6. IAM Role
- [ ] `soteria-lambda-role` created
- [ ] Permissions:
  - [ ] CloudWatch Logs access
  - [ ] DynamoDB access (for `soteria-*` tables)

## Information You Need to Update in iOS App

### 7. PlaidService.swift
- [ ] API Gateway URL updated (line 44)
  - Current: `"https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod"`
  - Replace with: Your actual API Gateway URL

## Test Credentials (Plaid Sandbox)

### 8. Plaid Link Test Credentials
These are provided by Plaid for sandbox testing:

- [ ] **Username**: `user_good`
- [ ] **Password**: `pass_good`
- [ ] **Institution**: Any sandbox institution (e.g., "First Platypus Bank")

## Quick Setup Commands

### Get Plaid Credentials
1. Go to: https://dashboard.plaid.com/developers/keys
2. Copy Sandbox Client ID and Secret

### Add Credentials to Lambda
```bash
./add-soteria-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET
```

### Create DynamoDB Tables
```bash
./create-soteria-dynamodb-tables.sh
```

### Create API Gateway
```bash
./create-soteria-api-gateway.sh
# Save the API ID that's printed!
```

### Update iOS App
Edit `soteria/Services/PlaidService.swift`:
```swift
private let apiGatewayURL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"
```

## Verification Checklist

After setup, verify:

- [ ] Can create link token (check CloudWatch logs)
- [ ] Plaid Link UI opens in app
- [ ] Can connect account with `user_good` / `pass_good`
- [ ] Token exchange succeeds
- [ ] Balance reading works
- [ ] Accounts appear in app with balances

## What You DON'T Need

- ❌ Production credentials (sandbox is sufficient for testing)
- ❌ Webhook URLs (not needed for basic testing)
- ❌ Custom Plaid Link configuration (defaults work)
- ❌ Additional Plaid products (Auth + Balance are enough for demo)

## Summary

**Minimum Required Info:**
1. Plaid Sandbox Client ID
2. Plaid Sandbox Secret
3. API Gateway URL (after creating API Gateway)
4. DynamoDB table names (standard: `soteria-plaid-access-tokens`)

**Everything else is configured via scripts or has defaults!**

