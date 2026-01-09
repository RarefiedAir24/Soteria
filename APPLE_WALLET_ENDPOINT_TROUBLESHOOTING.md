# Apple Wallet Endpoint Troubleshooting

## ❌ Issue: "Apple Wallet pass endpoint not found. Backend setup required."

**This is NOT a TestFlight issue** - it's an API Gateway endpoint configuration issue.

---

## 🔍 Root Cause

The app is trying to call:
```
GET https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/apple-wallet/pass
```

But the API Gateway is returning a **404 Not Found**, which means:
- The endpoint route is not configured in API Gateway, OR
- The Lambda function is not connected to the route, OR
- The API Gateway deployment is not up to date

---

## ✅ Solution: Connect the Endpoint

You need to run the setup script to connect the Apple Wallet Lambda function to API Gateway:

### Step 1: Run the Connection Script

```bash
cd /Users/frankschioppa/soteria
./connect-apple-wallet-to-api-gateway.sh
```

This script will:
1. ✅ Check if the `/soteria/apple-wallet/pass` resource exists
2. ✅ Create it if it doesn't exist
3. ✅ Connect the Lambda function to the GET method
4. ✅ Set up CORS for cross-origin requests
5. ✅ Deploy to the `prod` stage

### Step 2: Verify the Endpoint

After running the script, test the endpoint:

```bash
# Test without auth (should return 401, not 404)
curl -I "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/apple-wallet/pass"
```

**Expected Results:**
- ✅ **401 Unauthorized** = Endpoint exists, just needs auth (GOOD!)
- ❌ **404 Not Found** = Endpoint not configured (NEEDS SETUP)

---

## 🔧 Manual Setup (If Script Fails)

If the script doesn't work, you can set it up manually:

### 1. Check API Gateway Resources

```bash
aws apigateway get-resources \
  --rest-api-id ue1psw3mt3 \
  --query "items[?contains(path, 'apple-wallet')]"
```

### 2. Check Lambda Function

```bash
aws lambda get-function \
  --function-name soteria-apple-wallet-pass \
  --query 'Configuration.{Name:FunctionName,State:State}'
```

### 3. Check if Route Exists

```bash
aws apigateway get-resources \
  --rest-api-id ue1psw3mt3 \
  --query "items[?path=='/soteria/apple-wallet/pass']"
```

---

## 📋 What the Script Does

The `connect-apple-wallet-to-api-gateway.sh` script:

1. **Creates Resource Path**: `/soteria/apple-wallet/pass`
2. **Creates GET Method**: Connects to Lambda function
3. **Sets Up Integration**: Links API Gateway → Lambda
4. **Configures CORS**: Allows cross-origin requests
5. **Grants Permissions**: Allows API Gateway to invoke Lambda
6. **Deploys to Prod**: Makes the endpoint live

---

## 🧪 Testing After Setup

### Test 1: Check Endpoint Exists

```bash
curl -I "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/apple-wallet/pass"
```

Should return **401 Unauthorized** (not 404).

### Test 2: Test with Auth Token

```bash
# Get your ID token from the app (check Xcode console logs)
# Then test:
curl -H "Authorization: Bearer YOUR_ID_TOKEN" \
  "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/apple-wallet/pass?user_id=YOUR_USER_ID&card_type=gold"
```

---

## ⚠️ Common Issues

### Issue 1: Lambda Function Not Found
**Error**: `Lambda function not found: soteria-apple-wallet-pass`

**Solution**: Deploy the Lambda function first:
```bash
cd lambda/soteria-apple-wallet-pass
# Deploy using your deployment method
```

### Issue 2: API Gateway Not Accessible
**Error**: `Could not find REST API with id ue1psw3mt3`

**Solution**: Verify the API Gateway ID is correct:
```bash
aws apigateway get-rest-apis --query 'items[].{Name:name,Id:id}'
```

### Issue 3: Deployment Not Applied
**Error**: Endpoint still returns 404 after setup

**Solution**: Force a new deployment:
```bash
aws apigateway create-deployment \
  --rest-api-id ue1psw3mt3 \
  --stage-name prod
```

---

## ✅ Quick Fix

**Run this command to set up the endpoint:**

```bash
cd /Users/frankschioppa/soteria
./connect-apple-wallet-to-api-gateway.sh
```

Then test in the app again - it should work!

---

## 📝 Summary

- ❌ **Not a TestFlight issue** - works the same in TestFlight and production
- ✅ **API Gateway endpoint needs to be connected**
- ✅ **Run the setup script** to connect Lambda to API Gateway
- ✅ **Test the endpoint** to verify it's working

**Next Step**: Run `./connect-apple-wallet-to-api-gateway.sh` 🚀

