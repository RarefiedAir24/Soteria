# Complete Backend Setup Guide for App Token Mapping

## Overview

This guide walks you through setting up the complete backend infrastructure for automatic app naming using token hash mapping.

## Prerequisites

- AWS CLI installed and configured
- AWS account with appropriate permissions
- Node.js installed (for Lambda function)
- API Gateway already created (or create new one)

## Step 1: Create DynamoDB Table

### Option A: Using Script (Recommended)

```bash
chmod +x create-app-token-mappings-table.sh
./create-app-token-mappings-table.sh
```

### Option B: Manual (AWS Console)

1. Go to [DynamoDB Console](https://console.aws.amazon.com/dynamodb)
2. Click "Create table"
3. **Table name:** `soteria-app-token-mappings`
4. **Partition key:** `token_hash` (String)
5. **Settings:** Use default settings
6. **Billing mode:** On-demand (Pay per request)
7. Click "Create table"

### Verify Table Creation

```bash
aws dynamodb describe-table \
  --table-name soteria-app-token-mappings \
  --region us-east-1
```

## Step 2: Deploy Lambda Function

### Option A: Using Script (Recommended)

```bash
chmod +x deploy-app-name-lambda.sh
./deploy-app-name-lambda.sh
```

### Option B: Manual

1. **Navigate to Lambda directory:**
   ```bash
   cd lambda/soteria-get-app-name
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create deployment package:**
   ```bash
   zip -r function.zip index.js node_modules package.json
   ```

4. **Create Lambda function (AWS Console):**
   - Go to [Lambda Console](https://console.aws.amazon.com/lambda)
   - Click "Create function"
   - **Function name:** `soteria-get-app-name`
   - **Runtime:** Node.js 18.x
   - **Architecture:** x86_64
   - Click "Create function"

5. **Upload code:**
   - In function page, click "Upload from" → ".zip file"
   - Select `function.zip`
   - Click "Save"

6. **Configure environment variables:**
   - Go to Configuration → Environment variables
   - Add: `APP_TOKEN_MAPPINGS_TABLE` = `soteria-app-token-mappings`

7. **Configure IAM role:**
   - Go to Configuration → Permissions
   - Ensure role has DynamoDB read permissions:
     ```json
     {
       "Effect": "Allow",
       "Action": [
         "dynamodb:GetItem",
         "dynamodb:BatchGetItem",
         "dynamodb:Query"
       ],
       "Resource": "arn:aws:dynamodb:us-east-1:*:table/soteria-app-token-mappings"
     }
     ```

## Step 3: Create API Gateway Endpoint

### Option A: Using Script (Provides Instructions)

```bash
chmod +x create-api-gateway-endpoint.sh
./create-api-gateway-endpoint.sh YOUR_API_GATEWAY_ID
```

### Option B: Manual (AWS Console) - Recommended

1. **Go to API Gateway Console:**
   - [API Gateway Console](https://console.aws.amazon.com/apigateway)
   - Select your API (or create new one: `soteria-api`)

2. **Create `/soteria` resource (if it doesn't exist):**
   - Click on root resource `/`
   - Actions → Create Resource
   - **Resource Name:** `soteria`
   - **Resource Path:** `/soteria`
   - Click "Create Resource"

3. **Create `/soteria/app-name` resource:**
   - Click on `/soteria` resource
   - Actions → Create Resource
   - **Resource Name:** `app-name`
   - **Resource Path:** `/app-name`
   - **Enable CORS:** Yes
   - Click "Create Resource"

4. **Create POST method:**
   - Click on `/soteria/app-name` resource
   - Actions → Create Method → Select `POST` → Click checkmark
   - **Integration type:** Lambda Function
   - **Use Lambda Proxy integration:** ✅ Yes
   - **Lambda Function:** `soteria-get-app-name`
   - **Lambda Region:** `us-east-1`
   - Click "Save"
   - Click "OK" when prompted to grant API Gateway permission

5. **Enable CORS:**
   - Click on `/soteria/app-name` resource
   - Actions → Enable CORS
   - **Access-Control-Allow-Origin:** `*`
   - **Access-Control-Allow-Headers:** `Content-Type,Authorization`
   - **Access-Control-Allow-Methods:** `POST,OPTIONS`
   - Click "Enable CORS and replace existing CORS headers"

6. **Deploy API:**
   - Actions → Deploy API
   - **Deployment stage:** `prod` (or create new)
   - Click "Deploy"

7. **Get Endpoint URL:**
   - Note the "Invoke URL" from the stage
   - Full endpoint: `https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/soteria/app-name`

## Step 4: Grant API Gateway Permission

### Option A: Using Script

```bash
chmod +x grant-api-gateway-permission.sh
./grant-api-gateway-permission.sh
# Enter your API Gateway ID when prompted
```

### Option B: Manual

The permission is usually granted automatically when you create the method in API Gateway Console. If not:

1. Go to Lambda Console → `soteria-get-app-name`
2. Configuration → Permissions
3. Add permission if needed (usually done automatically)

## Step 5: Update iOS App

1. **Edit `soteria/Services/AWSDataService.swift`:**
   ```swift
   private let apiGatewayURL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"
   ```
   Replace `YOUR_API_ID` with your actual API Gateway ID.

2. **Build and test:**
   - Select apps in iOS app
   - Check console logs for backend lookup
   - Verify app names are auto-populated

## Step 6: Populate Database

### Get Token Hashes from iOS App

1. **Select apps in iOS app:**
   - Go to Settings → App Monitoring → Select Apps
   - Select apps (e.g., Amazon, Uber Eats)
   - Wait 6+ seconds

2. **Check console logs:**
   - Look for: `🔍 [DeviceActivityService] Token 0 hash: 1234567890`
   - Copy the hash values

3. **Add mappings to database:**

   **Option A: Using Script**
   ```bash
   # Edit populate-app-mappings.sh
   # Add your mappings:
   declare -A APP_MAPPINGS=(
       ["1234567890"]="Amazon"
       ["0987654321"]="Uber Eats"
       ["1122334455"]="DoorDash"
   )
   
   chmod +x populate-app-mappings.sh
   ./populate-app-mappings.sh
   ```

   **Option B: Manual (AWS Console)**
   - Go to DynamoDB Console → `soteria-app-token-mappings` table
   - Click "Create item"
   - Add:
     - `token_hash`: `1234567890` (your hash)
     - `app_name`: `Amazon`
     - `created_at`: Current timestamp
     - `updated_at`: Current timestamp
   - Click "Create item"

   **Option C: AWS CLI**
   ```bash
   aws dynamodb put-item \
     --table-name soteria-app-token-mappings \
     --item '{
       "token_hash": {"S": "1234567890"},
       "app_name": {"S": "Amazon"},
       "created_at": {"N": "1701234567890"},
       "updated_at": {"N": "1701234567890"}
     }' \
     --region us-east-1
   ```

## Step 7: Test End-to-End

1. **Test Lambda function:**
   ```bash
   aws lambda invoke \
     --function-name soteria-get-app-name \
     --payload '{"httpMethod":"POST","body":"{\"token_hashes\":[\"1234567890\"]}"}' \
     --region us-east-1 \
     response.json
   
   cat response.json
   ```

2. **Test from iOS app:**
   - Select apps
   - Wait 6+ seconds
   - Check console logs:
     - `🔍 [DeviceActivityService] Starting auto-naming from backend...`
     - `✅ [DeviceActivityService] Backend returned X app name(s)`
     - `✅ [DeviceActivityService] Auto-named app 0: Amazon`

3. **Verify app names:**
   - Check that apps are named correctly
   - Names should persist across app restarts

## Troubleshooting

### Lambda Function Not Found
- Ensure function is deployed: `./deploy-app-name-lambda.sh`
- Check function name matches exactly

### API Gateway Permission Denied
- Run: `./grant-api-gateway-permission.sh`
- Or manually add permission in Lambda Console

### No App Names Returned
- Check DynamoDB table has mappings
- Verify token hashes match exactly
- Check Lambda CloudWatch logs for errors

### CORS Errors
- Ensure CORS is enabled on API Gateway endpoint
- Check CORS headers in API Gateway Console

## Verification Checklist

- [ ] DynamoDB table created: `soteria-app-token-mappings`
- [ ] Lambda function deployed: `soteria-get-app-name`
- [ ] API Gateway endpoint created: `POST /soteria/app-name`
- [ ] API Gateway deployed to `prod` stage
- [ ] API Gateway permission granted to Lambda
- [ ] iOS app updated with API Gateway URL
- [ ] Database populated with at least one app mapping
- [ ] End-to-end test successful

## Next Steps

1. **Populate more apps:**
   - As users select apps, collect token hashes
   - Add mappings to database
   - Build comprehensive app database over time

2. **Monitor:**
   - Check CloudWatch logs for Lambda function
   - Monitor DynamoDB read capacity
   - Track API Gateway requests

3. **Optimize:**
   - Consider caching popular app names
   - Add rate limiting if needed
   - Monitor costs

## Cost Estimation

**DynamoDB (Pay per request):**
- ~$0.25 per million reads
- ~$1.25 per million writes

**Lambda:**
- First 1M requests free
- $0.20 per 1M requests after

**API Gateway:**
- First 1M requests free/month
- $3.50 per million requests after

**Estimated monthly cost for 10K users:**
- ~$5-10/month (assuming 1 lookup per user per day)

