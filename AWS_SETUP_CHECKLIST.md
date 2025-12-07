# AWS Setup Checklist for Rever

Use this checklist to track your AWS setup progress.

## Prerequisites
- [ ] AWS Account access
- [ ] Plaid account with credentials (client_id and secret)
- [ ] Firebase project set up (already done)

## Step 1: Create AWS Resources

### API Gateway
- [ ] Create new REST API named `rever-plaid-api`
- [ ] Create resources:
  - [ ] `/plaid/create-link-token` (POST)
  - [ ] `/plaid/exchange-public-token` (POST)
  - [ ] `/plaid/transfer` (POST)
- [ ] Configure CORS for all endpoints
- [ ] Deploy API to `prod` stage
- [ ] **Copy the Invoke URL** (you'll need this for Step 2)

**API Gateway URL Format:**
```
https://{api-id}.execute-api.{region}.amazonaws.com/prod
```

### Lambda Functions
- [ ] Create `rever-plaid-create-link-token` function
- [ ] Create `rever-plaid-exchange-token` function
- [ ] Create `rever-plaid-transfer` function
- [ ] Connect each Lambda to corresponding API Gateway endpoint
- [ ] Set up IAM roles for Lambda functions

### DynamoDB
- [ ] Create table `rever-plaid-access-tokens`
- [ ] Set up partition key: `user_id` (String)
- [ ] Set up sort key: `item_id` (String)
- [ ] Enable encryption at rest

### Secrets Manager
- [ ] Create secret: `rever/plaid/credentials`
- [ ] Store Plaid credentials:
  - [ ] `PLAID_CLIENT_ID`
  - [ ] `PLAID_SECRET`
  - [ ] `PLAID_ENV` (sandbox/development/production)

## Step 2: Update iOS App

### Update PlaidService.swift
- [ ] Open `rever/Services/PlaidService.swift`
- [ ] Find line: `private let awsApiGatewayURL = "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod"`
- [ ] Replace with your actual API Gateway URL from Step 1
- [ ] Example: `private let awsApiGatewayURL = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod"`

### Verify Configuration
- [ ] Build the project in Xcode
- [ ] Ensure no compilation errors
- [ ] Test Plaid Link flow (will need backend deployed first)

## Step 3: Test Integration

### Test in Sandbox
- [ ] Test link token creation
- [ ] Test Plaid Link UI (use sandbox credentials)
- [ ] Test token exchange
- [ ] Test account retrieval
- [ ] Test transfer (if Transfer API is enabled)

### Sandbox Test Credentials
- Username: `user_good`
- Password: `pass_good`
- Institution: Any sandbox institution

## Step 4: Production Setup

- [ ] Request production access from Plaid
- [ ] Update `PLAID_ENV` in Secrets Manager to `production`
- [ ] Update Lambda environment variables
- [ ] Test with real bank accounts
- [ ] Monitor CloudWatch logs
- [ ] Set up error alerts

## Current Status

**API Gateway URL:** ⏳ **PENDING** - Update after creating API Gateway

**Next Action:** Create API Gateway in AWS, then update `awsApiGatewayURL` in `PlaidService.swift`

## Quick Reference

**File to Update:** `rever/Services/PlaidService.swift` (line ~42)

**Current Value:**
```swift
private let awsApiGatewayURL = "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod"
```

**After AWS Setup:**
```swift
private let awsApiGatewayURL = "https://YOUR_ACTUAL_API_ID.execute-api.YOUR_REGION.amazonaws.com/prod"
```

