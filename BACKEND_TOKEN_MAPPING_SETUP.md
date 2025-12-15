# Backend Token Mapping Setup Guide

## Overview

This guide explains how to set up the backend infrastructure for automatic app naming using ApplicationToken hash mapping.

## Architecture

```
iOS App → API Gateway → Lambda Function → DynamoDB
         (Token Hashes)  (Lookup)        (Hash → App Name)
```

## Components

### 1. DynamoDB Table: `soteria-app-token-mappings`

**Purpose:** Store mappings between ApplicationToken hashes and app names.

**Schema:**
- **Partition Key:** `token_hash` (String) - Hash of ApplicationToken
- **Attributes:**
  - `app_name` (String) - Display name of the app (e.g., "Amazon", "Uber Eats")
  - `bundle_id` (String, optional) - Bundle identifier if known
  - `category` (String, optional) - App category (e.g., "Shopping", "Food Delivery")
  - `created_at` (Number) - Timestamp when mapping was created
  - `updated_at` (Number) - Timestamp when mapping was last updated

**Example Item:**
```json
{
  "token_hash": "1234567890",
  "app_name": "Amazon",
  "bundle_id": "com.amazon.Amazon",
  "category": "Shopping",
  "created_at": 1701234567890,
  "updated_at": 1701234567890
}
```

### 2. Lambda Function: `soteria-get-app-name`

**Purpose:** Look up app names from token hashes.

**Endpoint:** `POST /soteria/app-name`

**Request:**
```json
{
  "token_hashes": ["hash1", "hash2", "hash3"]
}
```

**Response:**
```json
{
  "success": true,
  "app_names": {
    "hash1": "Amazon",
    "hash2": "Uber Eats",
    "hash3": "DoorDash"
  },
  "found_count": 3,
  "total_requested": 3
}
```

### 3. API Gateway Endpoint

**Path:** `/soteria/app-name`  
**Method:** `POST`  
**Integration:** Lambda Function (`soteria-get-app-name`)

## Setup Steps

### Step 1: Create DynamoDB Table

```bash
aws dynamodb create-table \
  --table-name soteria-app-token-mappings \
  --attribute-definitions \
    AttributeName=token_hash,AttributeType=S \
  --key-schema \
    AttributeName=token_hash,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 2: Deploy Lambda Function

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

4. **Create Lambda function:**
   ```bash
   aws lambda create-function \
     --function-name soteria-get-app-name \
     --runtime nodejs18.x \
     --role arn:aws:iam::YOUR_ACCOUNT_ID:role/soteria-lambda-role \
     --handler index.handler \
     --zip-file fileb://function.zip \
     --timeout 30 \
     --memory-size 256 \
     --environment Variables="{APP_TOKEN_MAPPINGS_TABLE=soteria-app-token-mappings}" \
     --region us-east-1
   ```

5. **Grant API Gateway permission:**
   ```bash
   aws lambda add-permission \
     --function-name soteria-get-app-name \
     --statement-id apigateway-invoke \
     --action lambda:InvokeFunction \
     --principal apigateway.amazonaws.com \
     --source-arn "arn:aws:execute-api:us-east-1:YOUR_ACCOUNT_ID:YOUR_API_ID/*/*" \
     --region us-east-1
   ```

### Step 3: Create API Gateway Endpoint

1. **Create resource:**
   - Go to API Gateway Console
   - Select your API (e.g., `soteria-api`)
   - Create resource: `/soteria/app-name`

2. **Create method:**
   - Select `/soteria/app-name` resource
   - Create `POST` method
   - Integration type: Lambda Function
   - Lambda function: `soteria-get-app-name`
   - Enable CORS

3. **Deploy API:**
   - Deploy to `prod` stage
   - Note the API Gateway URL

### Step 4: Update iOS App

Update `AWSDataService.swift` with the correct API Gateway URL:

```swift
private let apiGatewayURL = "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod"
```

## Populating the Database

### Option 1: Manual Entry (Initial Setup)

You'll need to populate the database with known app mappings. This can be done:

1. **Manually via AWS Console:**
   - Go to DynamoDB Console
   - Select `soteria-app-token-mappings` table
   - Add items with token_hash and app_name

2. **Via Lambda function (bulk import):**
   - Create a separate Lambda function for bulk imports
   - Or use AWS CLI to batch write items

### Option 2: User Feedback Loop (Future)

1. When backend doesn't find a mapping, use generic name
2. Allow users to edit/correct the name
3. Send corrected mapping back to backend
4. Backend updates database with user-provided name
5. Future users with same token hash get correct name

### Option 3: App Store API (Advanced)

1. Use App Store Search API to identify apps
2. Match token hash to bundle identifier
3. Look up app name from App Store
4. Store mapping in database

## Testing

### Test Lambda Function Locally

```bash
# Create test event
cat > test-event.json << EOF
{
  "httpMethod": "POST",
  "body": "{\"token_hashes\": [\"1234567890\", \"0987654321\"]}"
}
EOF

# Invoke function
aws lambda invoke \
  --function-name soteria-get-app-name \
  --payload file://test-event.json \
  --region us-east-1 \
  response.json

# Check response
cat response.json
```

### Test from iOS App

1. Select apps in the app
2. Check console logs for:
   - `🔍 [DeviceActivityService] Starting auto-naming from backend...`
   - `✅ [DeviceActivityService] Backend returned X app name(s)`
   - `✅ [DeviceActivityService] Auto-named app X: AppName`

## Monitoring

### CloudWatch Metrics

Monitor Lambda function:
- Invocations
- Duration
- Errors
- Throttles

Monitor DynamoDB:
- Read capacity
- Write capacity
- Throttled requests

### Logs

Check CloudWatch Logs for:
- Lambda function logs: `/aws/lambda/soteria-get-app-name`
- API Gateway logs (if enabled)

## Cost Estimation

**DynamoDB:**
- PAY_PER_REQUEST pricing
- ~$0.25 per million reads
- ~$1.25 per million writes

**Lambda:**
- First 1M requests free
- $0.20 per 1M requests after

**API Gateway:**
- First 1M requests free/month
- $3.50 per million requests after

**Estimated monthly cost for 10K users:**
- ~$5-10/month (assuming 1 app lookup per user per day)

## Security

1. **Authentication:** API Gateway validates Firebase ID tokens
2. **Rate Limiting:** Consider adding rate limits to prevent abuse
3. **Input Validation:** Lambda validates token_hashes array
4. **Error Handling:** Graceful fallback to generic names

## Next Steps

1. ✅ Create DynamoDB table
2. ✅ Deploy Lambda function
3. ✅ Create API Gateway endpoint
4. ✅ Update iOS app with API URL
5. ⏳ Populate database with initial app mappings
6. ⏳ Test end-to-end flow
7. ⏳ Monitor and optimize

## Notes

- Token hashes are generated from `ApplicationToken.hashValue`
- Hash values are consistent for the same app on the same device
- Hash values may differ across devices (privacy feature)
- Consider building a mapping service that learns from user corrections

