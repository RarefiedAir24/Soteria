# 🚀 READY TO DEPLOY! Execute These Commands

**Everything is committed and ready. Just run these commands!**

---

## 🎯 ONE COMMAND TO DEPLOY EVERYTHING

```bash
cd /Users/frankschioppa/soteria
./deploy-gift-cards-complete.sh
```

**That's it!** This master script will:
1. ✅ Create 2 DynamoDB tables
2. ✅ Deploy Lambda function
3. ✅ Add API Gateway endpoint
4. ✅ Show you the API URL for iOS app

**Time:** ~5-10 minutes

---

## 📱 After Deployment: Update iOS App

The script will show you an API URL like:

```
https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod/soteria/redeem-gift-card
```

### Update the iOS App:

**File:** `soteria/Services/LoyaltyPointsService.swift`  
**Line:** ~376

**Change this:**
```swift
let endpoint = "https://YOUR_API_GATEWAY_URL/redeem-gift-card"
```

**To this:**
```swift
let endpoint = "https://YOUR_ACTUAL_URL_FROM_SCRIPT/soteria/redeem-gift-card"
```

---

## 🧪 Test the Deployment

### Test 1: Call the endpoint directly

```bash
curl -X POST \
  https://YOUR_API_URL/soteria/redeem-gift-card \
  -H 'Content-Type: application/json' \
  -d '{
  "userId": "test-user-123",
  "giftCardId": "amazon_5",
  "pointsToSpend": 2500,
  "email": "supergeek@me.com",
  "brand": "Amazon",
  "amount": 5
}'
```

**Expected:** Should return reward link (or error if user doesn't exist)

### Test 2: Check Lambda logs

```bash
aws logs tail /aws/lambda/soteria-redeem-gift-card --follow
```

**Expected:** See log output from Lambda

### Test 3: Check DynamoDB tables

```bash
# Check redemptions table
aws dynamodb scan --table-name soteria-gift-card-redemptions --region us-east-1

# Check monthly caps table
aws dynamodb scan --table-name soteria-monthly-redemption-caps --region us-east-1
```

---

## ✅ Success Checklist

After running `./deploy-gift-cards-complete.sh`:

- [ ] Script completed without errors
- [ ] DynamoDB tables created (shown in output)
- [ ] Lambda deployed successfully (shown in output)
- [ ] API Gateway endpoint added (shown in output)
- [ ] API URL displayed and copied
- [ ] iOS app updated with new endpoint URL
- [ ] Test curl command works (returns response)
- [ ] Lambda logs show activity

---

## 🎁 What's Deployed

### DynamoDB Tables

**1. soteria-gift-card-redemptions**
- Stores all redemption records
- Keys: `redemptionId` (HASH), `timestamp` (RANGE)
- Attributes: userId, giftCardId, brand, amount, pointsSpent, rewardLink, etc.

**2. soteria-monthly-redemption-caps**
- Tracks monthly usage per user
- Keys: `userId` (HASH), `month` (RANGE)
- Attributes: totalRedeemed, redemptionCount, lastUpdated

### Lambda Function

**Name:** `soteria-redeem-gift-card`
- **Runtime:** Node.js 20.x
- **Timeout:** 30 seconds
- **Memory:** 512 MB
- **Environment Variables:**
  - `TREMENDOUS_API_KEY`: Your sandbox key
  - `TREMENDOUS_ENV`: sandbox
  - `USER_DATA_TABLE`: soteria-user-data
  - `REDEMPTIONS_TABLE`: soteria-gift-card-redemptions
  - `MONTHLY_CAPS_TABLE`: soteria-monthly-redemption-caps

**Features:**
- ✅ Verifies Cognito authentication
- ✅ Checks Premium status
- ✅ Validates points balance
- ✅ Checks monthly redemption cap
- ✅ Calls Tremendous API (LINK delivery)
- ✅ Deducts points
- ✅ Logs redemption
- ✅ Returns reward link instantly

### API Gateway Endpoint

**Endpoint:** `POST /soteria/redeem-gift-card`
- **Authorization:** AWS IAM (Cognito)
- **CORS:** Enabled
- **Integration:** AWS Lambda Proxy

---

## 🐛 Troubleshooting

### Error: "IAM role not found"

**Fix:**
```bash
# Check if role exists
aws iam get-role --role-name soteria-lambda-role

# If it doesn't exist, create it
# (You might already have a script for this)
```

### Error: "API Gateway not found"

**Fix:**
```bash
# Check if API Gateway exists
aws apigateway get-rest-apis --region us-east-1 --query 'items[?name==`soteria-api`]'

# If it doesn't exist, run:
./create-soteria-api-gateway.sh
```

### Error: "Lambda deployment failed"

**Fix:**
```bash
# Check Lambda role has correct permissions
# Lambda needs: DynamoDB read/write, CloudWatch logs

# Manually deploy Lambda:
cd lambda/soteria-redeem-gift-card
npm install
cd ..
zip -r soteria-redeem-gift-card.zip soteria-redeem-gift-card
aws lambda update-function-code \
  --function-name soteria-redeem-gift-card \
  --zip-file fileb://soteria-redeem-gift-card.zip \
  --region us-east-1
```

---

## 🎯 After Deployment Works

### Update iOS App Endpoint

1. Open `soteria/Services/LoyaltyPointsService.swift`
2. Find line ~376 (in `callRedemptionAPI` function)
3. Replace placeholder URL with your actual API Gateway URL
4. Build & run app
5. Test redemption in Gift Card Shop!

### Test Full Flow

1. Open Soteria app
2. Navigate to Gift Card Shop
3. Select Amazon $5 gift card
4. Tap "Redeem"
5. **Beautiful success screen appears! 🎉**
6. Tap "Claim Your Gift Card"
7. Safari opens with Tremendous reward page
8. User claims Amazon gift card
9. Success!

---

## 📊 Monitoring

### View Lambda logs in real-time:

```bash
aws logs tail /aws/lambda/soteria-redeem-gift-card --follow --region us-east-1
```

### Check redemption records:

```bash
aws dynamodb scan --table-name soteria-gift-card-redemptions --region us-east-1
```

### Check monthly caps:

```bash
aws dynamodb scan --table-name soteria-monthly-redemption-caps --region us-east-1
```

---

## 🚀 You're Ready!

Just run:

```bash
cd /Users/frankschioppa/soteria
./deploy-gift-cards-complete.sh
```

**And you'll have live gift card redemption in ~10 minutes!** 🎁

The script will guide you through everything and show you exactly what to update in the iOS app.

**LET'S GO!** 💪🚀
