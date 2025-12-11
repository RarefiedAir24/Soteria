# Plaid Sandbox Quick Start

## ✅ What's Ready

1. **iOS App** - Plaid Link SDK integrated
2. **Lambda Functions** - All 4 functions ready
3. **UI Views** - Connection flow implemented
4. **Service Layer** - PlaidService ready

## 🚀 Quick Setup (5 Steps)

### Step 1: Install Pods
```bash
cd /Users/frankschioppa/Desktop/soteria
pod install
```

### Step 2: Get Plaid Credentials
1. Go to https://dashboard.plaid.com/developers/keys
2. Copy your **Sandbox** Client ID and Secret

### Step 3: Deploy Lambda Functions
```bash
cd lambda
# For each function:
cd soteria-plaid-create-link-token
npm install
zip -r function.zip index.js node_modules package.json
aws lambda create-function \
    --function-name soteria-plaid-create-link-token \
    --runtime nodejs18.x \
    --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-execution-role \
    --handler index.handler \
    --zip-file fileb://function.zip
```

### Step 4: Add Credentials
```bash
./add-soteria-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET
```

### Step 5: Update API Gateway URL
In `PlaidService.swift`, update:
```swift
private let apiGatewayURL = "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod"
```

## 🧪 Test It

1. Open app → Settings → Savings Settings
2. Tap "Connect Accounts"
3. Use sandbox credentials:
   - Username: `user_good`
   - Password: `pass_good`

## 📝 Full Setup Guide

See `PLAID_SANDBOX_SETUP.md` for detailed instructions.

