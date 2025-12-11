# Demo Readiness Checklist for Plaid Call

## Critical Items (Must Complete Before Demo)

### 1. ✅ iOS App Setup
- [x] Plaid SDK added to Podfile
- [ ] Run `pod install` to install Plaid SDK
- [ ] Verify app builds without errors
- [ ] Test Plaid Link UI opens correctly

### 2. ⏳ AWS Infrastructure
- [ ] Create/verify API Gateway exists (`soteria-api`)
- [ ] Get API Gateway URL and update PlaidService.swift
- [ ] Create DynamoDB tables:
  - `soteria-plaid-access-tokens`
  - `soteria-plaid-transfers` (optional for demo)
- [ ] Create IAM role for Lambda functions (`soteria-lambda-role`)
- [ ] Deploy all 4 Lambda functions:
  - `soteria-plaid-create-link-token`
  - `soteria-plaid-exchange-token`
  - `soteria-plaid-get-balance`
  - `soteria-plaid-transfer` (optional for demo)

### 3. ⏳ Plaid Credentials
- [ ] Get Plaid sandbox credentials from dashboard
- [ ] Add credentials to Lambda functions using `add-soteria-plaid-credentials.sh`
- [ ] Verify credentials are set correctly

### 4. ⏳ API Gateway Configuration
- [ ] Create resources:
  - `/soteria/plaid/create-link-token` (POST)
  - `/soteria/plaid/exchange-token` (POST)
  - `/soteria/plaid/balance` (GET)
  - `/soteria/plaid/transfer` (POST, optional)
- [ ] Connect Lambda functions to resources
- [ ] Enable CORS on all endpoints
- [ ] Deploy to `prod` stage
- [ ] Get invoke URL and update PlaidService.swift

### 5. ⏳ Testing
- [ ] Test link token creation (API call works)
- [ ] Test Plaid Link UI opens
- [ ] Test account connection with sandbox credentials:
  - Username: `user_good`
  - Password: `pass_good`
- [ ] Test balance reading
- [ ] Test virtual savings mode in PauseView

## Quick Setup Commands

### 1. Install Plaid SDK
```bash
cd /Users/frankschioppa/soteria
pod install
```

### 2. Check if API Gateway exists
```bash
aws apigateway get-rest-apis --query "items[?name=='soteria-api']" --region us-east-1
```

### 3. Create API Gateway (if needed)
```bash
./create-soteria-api-gateway.sh
```

### 4. Create DynamoDB tables
```bash
./create-soteria-dynamodb-tables.sh
```

### 5. Create IAM role
```bash
./create-soteria-lambda-role.sh
```

### 6. Install Lambda dependencies
```bash
cd lambda
for dir in soteria-plaid-*; do
  cd $dir
  npm install
  cd ..
done
```

### 7. Deploy Lambda functions
```bash
./deploy-soteria-lambdas.sh
```

### 8. Add Plaid credentials
```bash
./add-soteria-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET
```

## Demo Flow to Test

1. **Account Connection**
   - Open app → Settings → Savings Settings
   - Tap "Connect Accounts"
   - Plaid Link should open
   - Use sandbox credentials: `user_good` / `pass_good`
   - Select any institution
   - Should see success and accounts listed

2. **Balance Reading**
   - After connection, accounts should show balances
   - Refresh should update balances

3. **Virtual Savings**
   - Block an app
   - Unblock and choose to save
   - Should see "Save $10?" prompt
   - Confirm should record virtual savings

## Current Status

- ✅ Code is ready (iOS app, Lambda functions)
- ⏳ AWS infrastructure needs setup
- ⏳ Plaid credentials need to be added
- ⏳ End-to-end testing needed

## Notes

- For demo, virtual savings mode is sufficient (no real transfers needed)
- Transfer API can be shown but may not work in sandbox for same-bank transfers
- Focus on showing the connection flow and balance reading

