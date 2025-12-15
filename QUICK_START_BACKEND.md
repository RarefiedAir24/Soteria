# Quick Start: Backend Setup for App Token Mapping

## TL;DR - Run These Commands

```bash
# 1. Create DynamoDB table
./create-app-token-mappings-table.sh

# 2. Deploy Lambda function
./deploy-app-name-lambda.sh

# 3. Create API Gateway endpoint (manual - see below)
# Go to AWS Console → API Gateway → Create POST /soteria/app-name

# 4. Grant API Gateway permission
./grant-api-gateway-permission.sh
# Enter your API Gateway ID when prompted

# 5. Update iOS app with API Gateway URL
# Edit: soteria/Services/AWSDataService.swift
# Update: apiGatewayURL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"

# 6. Get token hashes from iOS app and populate database
# Select apps in iOS app, check console logs for hashes
# Edit populate-app-mappings.sh with your hashes
./populate-app-mappings.sh
```

## Detailed Steps

### 1. Create DynamoDB Table ✅

```bash
./create-app-token-mappings-table.sh
```

**What it does:**
- Creates table: `soteria-app-token-mappings`
- Partition key: `token_hash` (String)
- Billing: Pay per request

### 2. Deploy Lambda Function ✅

```bash
./deploy-app-name-lambda.sh
```

**What it does:**
- Installs npm dependencies
- Creates deployment package
- Creates/updates Lambda function: `soteria-get-app-name`
- Sets environment variable: `APP_TOKEN_MAPPINGS_TABLE`

**Requirements:**
- IAM role `soteria-lambda-role` must exist with DynamoDB read permissions

### 3. Create API Gateway Endpoint ⚠️ Manual

**Easiest via AWS Console:**

1. Go to [API Gateway Console](https://console.aws.amazon.com/apigateway)
2. Select your API (or create: `soteria-api`)
3. Create resource: `/soteria/app-name`
4. Create method: `POST`
5. Integration: Lambda Function → `soteria-get-app-name`
6. Enable CORS
7. Deploy to `prod` stage
8. Copy the Invoke URL

**Or use script for instructions:**
```bash
./create-api-gateway-endpoint.sh YOUR_API_GATEWAY_ID
```

### 4. Grant Permission ✅

```bash
./grant-api-gateway-permission.sh
```

Enter your API Gateway ID when prompted.

### 5. Update iOS App ⚠️ Manual

Edit `soteria/Services/AWSDataService.swift`:

```swift
private let apiGatewayURL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"
```

Replace `YOUR_API_ID` with your actual API Gateway ID.

### 6. Populate Database ⚠️ Manual

**Step 1: Get Token Hashes**
1. Open iOS app
2. Go to Settings → Select Apps
3. Select apps (e.g., Amazon)
4. Wait 6+ seconds
5. Check Xcode console for:
   ```
   🔍 [DeviceActivityService] Token 0 hash: 1234567890
   ```
6. Copy the hash value

**Step 2: Add to Database**

Edit `populate-app-mappings.sh`:
```bash
declare -A APP_MAPPINGS=(
    ["1234567890"]="Amazon"      # Your hash → App name
    ["0987654321"]="Uber Eats"   # Add more as you discover them
)
```

Run:
```bash
./populate-app-mappings.sh
```

**Or use AWS Console:**
- DynamoDB → `soteria-app-token-mappings` → Create item
- Add `token_hash` and `app_name`

## Testing

### Test Lambda Function

```bash
aws lambda invoke \
  --function-name soteria-get-app-name \
  --payload '{"httpMethod":"POST","body":"{\"token_hashes\":[\"YOUR_HASH\"]}"}' \
  --region us-east-1 \
  response.json

cat response.json
```

### Test from iOS App

1. Select apps in iOS app
2. Wait 6+ seconds
3. Check console logs:
   - `✅ [DeviceActivityService] Backend returned X app name(s)`
   - `✅ [DeviceActivityService] Auto-named app 0: Amazon`

## Common Issues

**"Function not found"**
- Run `./deploy-app-name-lambda.sh` again

**"Permission denied"**
- Run `./grant-api-gateway-permission.sh`

**"No app names returned"**
- Check DynamoDB table has mappings
- Verify token hashes match exactly

**"CORS error"**
- Enable CORS on API Gateway endpoint

## Next Steps

1. ✅ Backend is set up
2. ✅ Database is populated
3. ✅ iOS app is updated
4. 🎉 Apps are automatically named!

As more users select apps, collect their token hashes and add to database to build a comprehensive mapping.

