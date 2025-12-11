# Demo Status - Current State

## ✅ Completed

1. **iOS App**
   - ✅ Plaid SDK installed (Plaid 3.1.1)
   - ✅ PlaidService.swift implemented
   - ✅ PlaidConnectionView.swift implemented
   - ✅ Integration with PauseView for virtual savings
   - ✅ Podfile fixed (SoteriaMonitor target)

2. **Lambda Functions**
   - ✅ All 4 functions have proper package.json
   - ✅ Code is complete and ready
   - ✅ Functions:
     - `soteria-plaid-create-link-token`
     - `soteria-plaid-exchange-token`
     - `soteria-plaid-get-balance`
     - `soteria-plaid-transfer`

3. **Scripts**
   - ✅ `create-soteria-api-gateway.sh` - Creates API Gateway with correct paths
   - ✅ `create-soteria-dynamodb-tables.sh` - Creates all tables including Plaid tables
   - ✅ `create-soteria-lambda-role.sh` - Creates IAM role
   - ✅ `deploy-soteria-lambdas.sh` - Deploys all Lambda functions
   - ✅ `add-soteria-plaid-credentials.sh` - Adds Plaid credentials
   - ✅ `connect-api-gateway-lambdas.sh` - Connects Lambda to API Gateway

4. **Documentation**
   - ✅ `DEMO_READINESS_CHECKLIST.md` - Complete checklist
   - ✅ `DEMO_SETUP_GUIDE.md` - Step-by-step setup guide
   - ✅ `DEMO_PREPARATION.md` - Demo flow and talking points

## ⏳ Pending (Need to Run)

1. **AWS Infrastructure Setup**
   - [ ] Create IAM role: `./create-soteria-lambda-role.sh`
   - [ ] Create DynamoDB tables: `./create-soteria-dynamodb-tables.sh`
   - [ ] Create API Gateway: `./create-soteria-api-gateway.sh`
   - [ ] Save API Gateway ID

2. **Lambda Deployment**
   - [ ] Install Lambda dependencies: `cd lambda && for dir in soteria-plaid-*; do cd $dir && npm install && cd ..; done`
   - [ ] Deploy Lambda functions: `./deploy-soteria-lambdas.sh`
   - [ ] Connect to API Gateway: `./connect-api-gateway-lambdas.sh API_ID`
   - [ ] Enable CORS on all endpoints
   - [ ] Deploy API Gateway to `prod` stage

3. **Plaid Configuration**
   - [ ] Get Plaid sandbox credentials from dashboard
   - [ ] Add credentials: `./add-soteria-plaid-credentials.sh CLIENT_ID SECRET`

4. **iOS App Configuration**
   - [ ] Update `PlaidService.swift` line 44 with API Gateway URL
   - [ ] Build and test in Xcode

5. **Testing**
   - [ ] Test link token creation
   - [ ] Test Plaid Link UI
   - [ ] Test account connection (use `user_good` / `pass_good`)
   - [ ] Test balance reading
   - [ ] Test virtual savings mode

## 📋 Quick Start Commands

```bash
# 1. Install Lambda dependencies
cd lambda
for dir in soteria-plaid-*; do cd $dir && npm install && cd ..; done
cd ..

# 2. Create AWS infrastructure
./create-soteria-lambda-role.sh
./create-soteria-dynamodb-tables.sh
./create-soteria-api-gateway.sh  # Save the API ID!

# 3. Deploy Lambda functions
./deploy-soteria-lambdas.sh

# 4. Connect to API Gateway (replace API_ID)
./connect-api-gateway-lambdas.sh API_ID

# 5. Enable CORS and deploy (use AWS Console or CLI)
# Then get the URL:
aws apigateway get-stage --rest-api-id API_ID --stage-name prod --region us-east-1 --query 'invokeUrl' --output text

# 6. Add Plaid credentials
./add-soteria-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET

# 7. Update iOS app
# Edit soteria/Services/PlaidService.swift line 44 with the API Gateway URL
```

## 🎯 Demo Flow

1. **Account Connection** (3 min)
   - Settings → Savings Settings → Connect Accounts
   - Plaid Link opens
   - Use: `user_good` / `pass_good`
   - Show connected accounts

2. **Balance Reading** (1 min)
   - Show account balances
   - Explain read-only access

3. **Virtual Savings** (2 min)
   - Block an app
   - Unblock → Choose to save
   - Show "Save $10?" prompt
   - Explain virtual savings mode

## 📝 Notes

- **For demo:** Virtual savings mode is sufficient (no real transfers needed)
- **Sandbox credentials:** `user_good` / `pass_good`
- **Focus:** Show connection flow and balance reading
- **Transfer API:** Can mention but may not work for same-bank in sandbox

## ⚠️ Known Issues

- API Gateway paths match PlaidService.swift (`/soteria/plaid/...`)
- All scripts are ready to run
- Need to get Plaid sandbox credentials

## 🚀 Next Action

**Run the Quick Start Commands above to set up AWS infrastructure and deploy.**

