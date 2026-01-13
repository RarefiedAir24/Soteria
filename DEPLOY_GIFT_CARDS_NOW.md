# 🚀 Deploy Gift Card Redemption - EXECUTE NOW!

**Last Updated:** January 12, 2026, 11:50 PM  
**Status:** Ready to Deploy! ✅

---

## ✅ What's Ready

1. ✅ Lambda function updated with Tremendous integration
2. ✅ Correct Tremendous product IDs mapped
3. ✅ LINK delivery implemented
4. ✅ Premium check, points check, monthly caps - all wired
5. ✅ iOS already syncing loyalty points to AWS
6. ✅ Deployment scripts created
7. ✅ Beautiful success screen ready

---

## 🎯 Deploy in 10 Minutes! (3 Simple Steps)

### **Step 1: Create DynamoDB Tables** (2 min)

```bash
cd /Users/frankschioppa/soteria
./create-gift-card-tables.sh
```

**What this does:**
- Creates `soteria-gift-card-redemptions` table
- Creates `soteria-monthly-redemption-caps` table
- Both use PAY_PER_REQUEST billing (no cost when not used)

**Expected output:**
```
✅ Table soteria-gift-card-redemptions created
✅ Table soteria-monthly-redemption-caps created
```

---

### **Step 2: Deploy Lambda Function** (3 min)

```bash
./deploy-gift-card-lambda.sh
```

**What this does:**
- Installs dependencies
- Packages Lambda function
- Deploys to AWS (creates or updates)
- Sets environment variables:
  - `TREMENDOUS_API_KEY`: Your sandbox key
  - `TREMENDOUS_ENV`: sandbox
  - `USER_DATA_TABLE`: soteria-user-data
  - `REDEMPTIONS_TABLE`: soteria-gift-card-redemptions
  - `MONTHLY_CAPS_TABLE`: soteria-monthly-redemption-caps

**Expected output:**
```
✅ soteria-redeem-gift-card deployed successfully!
```

---

### **Step 3: Connect to API Gateway** (5 min)

**Option A: Use existing API Gateway** (if you have one)

```bash
# Get your existing API Gateway ID
aws apigateway get-rest-apis --region us-east-1 --query 'items[?name==`soteria-api`].id' --output text

# Note the ID, you'll use it below
```

**Option B: Create new API Gateway endpoint**

I'll create a script for you...
