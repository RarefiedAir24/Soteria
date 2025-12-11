# Demo Preparation Summary

## What's Ready ✅

Your codebase is **ready for demo setup**. All the code is in place:

- ✅ iOS app with Plaid integration
- ✅ All Lambda functions implemented
- ✅ Setup scripts created and fixed
- ✅ Plaid SDK installed
- ✅ Documentation complete

## What You Need to Do 🚀

### Step 1: Get Plaid Credentials (5 min)

1. Go to https://dashboard.plaid.com/developers/keys
2. Copy your **Sandbox** Client ID and Secret
3. Save them - you'll need them in Step 5

### Step 2: Set Up AWS Infrastructure (15-20 min)

Run these scripts in order:

```bash
cd /Users/frankschioppa/soteria

# 1. Create IAM role
./create-soteria-lambda-role.sh

# 2. Create DynamoDB tables
./create-soteria-dynamodb-tables.sh

# 3. Create API Gateway (SAVE THE API ID!)
./create-soteria-api-gateway.sh
```

**Important:** When you run the API Gateway script, it will print an API ID. **Save this!** You'll need it for the next steps.

### Step 3: Install Lambda Dependencies (2 min)

```bash
cd lambda
for dir in soteria-plaid-*; do
  cd $dir
  npm install
  cd ..
done
cd ..
```

### Step 4: Deploy Lambda Functions (5 min)

```bash
./deploy-soteria-lambdas.sh
```

### Step 5: Connect Lambda to API Gateway (2 min)

Replace `YOUR_API_ID` with the API ID from Step 2:

```bash
./connect-api-gateway-lambdas.sh YOUR_API_ID
```

### Step 6: Enable CORS and Deploy API Gateway (5 min)

**Option A: Using AWS Console (Easier)**
1. Go to AWS Console → API Gateway
2. Select `soteria-api`
3. For each endpoint (`/soteria/plaid/*`):
   - Click on the resource
   - Actions → Enable CORS
   - Click "Enable CORS and replace existing CORS headers"
4. Actions → Deploy API
   - Stage: `prod` (or create new)
   - Deploy

**Option B: Using CLI**
```bash
# Enable CORS (run for each endpoint)
aws apigateway put-method-response \
  --rest-api-id YOUR_API_ID \
  --resource-id RESOURCE_ID \
  --http-method POST \
  --status-code 200 \
  --response-parameters "method.response.header.Access-Control-Allow-Origin=true" \
  --region us-east-1

# Deploy
aws apigateway create-deployment \
  --rest-api-id YOUR_API_ID \
  --stage-name prod \
  --region us-east-1
```

### Step 7: Get API Gateway URL (1 min)

```bash
aws apigateway get-stage \
  --rest-api-id YOUR_API_ID \
  --stage-name prod \
  --region us-east-1 \
  --query 'invokeUrl' \
  --output text
```

**Save this URL!** It will look like:
```
https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod
```

### Step 8: Add Plaid Credentials (1 min)

```bash
./add-soteria-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET
```

### Step 9: Update iOS App (1 min)

1. Open `soteria/Services/PlaidService.swift`
2. Find line 44: `private let apiGatewayURL = "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod"`
3. Replace with your actual API Gateway URL from Step 7

### Step 10: Test! (10 min)

1. Open `soteria.xcworkspace` in Xcode
2. Build and run
3. Navigate to: Settings → Savings Settings
4. Tap "Connect Accounts"
5. Use Plaid sandbox credentials:
   - Username: `user_good`
   - Password: `pass_good`
   - Select any institution
6. Verify accounts appear with balances

## Demo Flow

1. **Show Account Connection** (3 min)
   - Settings → Savings Settings → Connect Accounts
   - Plaid Link opens
   - Connect with sandbox credentials
   - Show connected accounts

2. **Show Balance Reading** (1 min)
   - Point out account balances
   - Explain read-only access

3. **Show Virtual Savings** (2 min)
   - Block an app
   - Unblock → Choose to save
   - Show "Save $10?" prompt
   - Explain virtual savings mode

## Troubleshooting

**"Function not found"**
- Make sure you deployed Lambda functions (Step 4)

**"API Gateway 500 error"**
- Check CloudWatch Logs for the Lambda function
- Verify Plaid credentials are set (Step 8)
- Verify DynamoDB table exists

**"Plaid Link doesn't open"**
- Check API Gateway URL is correct in PlaidService.swift
- Check Xcode console for link token errors

**"Balance not showing"**
- Check DynamoDB has access tokens (after connecting account)
- Verify balance endpoint is connected

## Files to Reference

- `DEMO_SETUP_GUIDE.md` - Detailed step-by-step guide
- `DEMO_READINESS_CHECKLIST.md` - Complete checklist
- `DEMO_STATUS.md` - Current status and quick commands
- `DEMO_PREPARATION.md` - Demo flow and talking points

## Quick Verification

```bash
# Check API Gateway exists
aws apigateway get-rest-apis --query "items[?name=='soteria-api']" --region us-east-1

# Check Lambda functions
aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'soteria-plaid')].FunctionName" --region us-east-1

# Check DynamoDB tables
aws dynamodb list-tables --query "TableNames[?starts_with(@, 'soteria-plaid')]" --region us-east-1
```

## Estimated Time

- **Total setup time:** ~45-60 minutes
- **Testing time:** ~10-15 minutes
- **Total:** ~1 hour

## Ready to Start?

Begin with **Step 1** above. If you run into any issues, check the troubleshooting section or refer to `DEMO_SETUP_GUIDE.md` for more details.

Good luck with your demo! 🚀

