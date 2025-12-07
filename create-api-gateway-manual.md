# Manual API Gateway Creation Guide

If you prefer to create the API Gateway through the AWS Console, follow these steps:

## Step 1: Create REST API

1. Go to [AWS API Gateway Console](https://console.aws.amazon.com/apigateway)
2. Click **"Create API"**
3. Select **"REST API"** → Click **"Build"**
4. Choose **"New API"**
5. Enter:
   - **API name:** `rever-plaid-api`
   - **Description:** `API Gateway for Rever app - Plaid integration`
   - **Endpoint Type:** Regional
6. Click **"Create API"**

## Step 2: Create Resources

### Create `/plaid` resource:
1. Click on **"/"** (root resource)
2. Click **"Actions"** → **"Create Resource"**
3. Enter:
   - **Resource Name:** `plaid`
   - **Resource Path:** `/plaid` (auto-filled)
4. Click **"Create Resource"**

### Create `/plaid/create-link-token`:
1. Click on **"/plaid"** resource
2. Click **"Actions"** → **"Create Resource"**
3. Enter:
   - **Resource Name:** `create-link-token`
   - **Resource Path:** `/create-link-token`
4. Click **"Create Resource"**

### Create `/plaid/exchange-public-token`:
1. Click on **"/plaid"** resource
2. Click **"Actions"** → **"Create Resource"**
3. Enter:
   - **Resource Name:** `exchange-public-token`
   - **Resource Path:** `/exchange-public-token`
4. Click **"Create Resource"**

### Create `/plaid/transfer`:
1. Click on **"/plaid"** resource
2. Click **"Actions"** → **"Create Resource"**
3. Enter:
   - **Resource Name:** `transfer`
   - **Resource Path:** `/transfer`
4. Click **"Create Resource"**

## Step 3: Create Methods (After Lambda Functions Exist)

**Note:** You'll need to create Lambda functions first, then come back to connect them.

For each resource (`/plaid/create-link-token`, `/plaid/exchange-public-token`, `/plaid/transfer`):

1. Click on the resource
2. Click **"Actions"** → **"Create Method"**
3. Select **"POST"** from dropdown
4. Click the checkmark ✓
5. Configure:
   - **Integration type:** Lambda Function
   - **Use Lambda Proxy integration:** ✅ (checked)
   - **Lambda Region:** Your region (e.g., `us-east-1`)
   - **Lambda Function:** Select the corresponding function:
     - `rever-plaid-create-link-token`
     - `rever-plaid-exchange-token`
     - `rever-plaid-transfer`
6. Click **"Save"**
7. Click **"OK"** when prompted to give API Gateway permission to invoke Lambda

## Step 4: Enable CORS

For each resource with a POST method:

1. Click on the resource
2. Click **"Actions"** → **"Enable CORS"**
3. Configure:
   - **Access-Control-Allow-Origin:** `*` (or your app's domain)
   - **Access-Control-Allow-Headers:** `Content-Type,X-Amz-Date,Authorization,X-Api-Key`
   - **Access-Control-Allow-Methods:** `POST,OPTIONS`
4. Click **"Enable CORS and replace existing CORS headers"**

## Step 5: Deploy API

1. Click **"Actions"** → **"Deploy API"**
2. Select:
   - **Deployment stage:** `[New Stage]`
   - **Stage name:** `prod` (or `dev` for development)
   - **Stage description:** `Production stage for Rever API`
3. Click **"Deploy"**

## Step 6: Get Invoke URL

1. After deployment, you'll see the **Invoke URL** at the top
2. Format: `https://{api-id}.execute-api.{region}.amazonaws.com/prod`
3. **Copy this URL** - you'll need it to update `PlaidService.swift`

## Step 7: Update iOS App

Open `rever/Services/PlaidService.swift` and update:
```swift
private let awsApiGatewayURL = "YOUR_INVOKE_URL_HERE"
```

## Verification

To verify the API Gateway was created correctly:

1. Go to API Gateway Console
2. You should see `rever-plaid-api` in the list
3. Click on it to see the resources
4. Verify all three endpoints exist:
   - `/plaid/create-link-token`
   - `/plaid/exchange-public-token`
   - `/plaid/transfer`

