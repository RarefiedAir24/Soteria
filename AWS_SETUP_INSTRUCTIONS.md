# AWS Setup Instructions for Soteria

Complete step-by-step guide to set up AWS infrastructure for Soteria data sync.

## Prerequisites

- AWS CLI installed and configured
- AWS account with appropriate permissions
- Node.js installed (for Lambda functions)
- Firebase project configured (for authentication)

## Step 1: Create API Gateway

Run the script to create the new API Gateway:

```bash
./create-soteria-api-gateway.sh
```

This will:
- Create `soteria-api` API Gateway
- Create `/soteria/sync` and `/soteria/data` endpoints
- Create `/plaid/*` endpoints (if still using Plaid)

**Important:** Save the API Gateway ID that's printed at the end. You'll need it for:
1. Updating the iOS app
2. Connecting Lambda functions

## Step 2: Create DynamoDB Tables

Run the script to create all DynamoDB tables:

```bash
./create-soteria-dynamodb-tables.sh
```

This creates 8 tables:
- `soteria-user-data` - App names and general user data
- `soteria-purchase-intents` - Purchase intent records
- `soteria-goals` - Savings goals
- `soteria-regrets` - Regret entries
- `soteria-moods` - Mood tracking data
- `soteria-quiet-hours` - Quiet hours schedules
- `soteria-app-usage` - App usage sessions
- `soteria-unblock-events` - Unblock event metrics

## Step 3: Create IAM Role and Policies

Run the script to create the IAM role for Lambda functions:

```bash
./create-soteria-lambda-role.sh
```

This creates:
- `soteria-lambda-role` - IAM role for Lambda functions
- `soteria-dynamodb-policy` - Policy for DynamoDB access
- Attaches `AWSLambdaBasicExecutionRole` for CloudWatch Logs

**Important:** Save the Role ARN that's printed. You'll need it when deploying Lambda functions.

## Step 4: Install Lambda Dependencies

Before deploying Lambda functions, install dependencies:

```bash
cd lambda/soteria-sync-user-data
npm install --production
cd ../soteria-get-user-data
npm install --production
cd ../..
```

## Step 5: Deploy Lambda Functions

Run the deployment script:

```bash
./deploy-soteria-lambdas.sh
```

This will:
- Package Lambda functions
- Create or update Lambda functions in AWS
- Configure timeouts and memory
- Tag functions appropriately

## Step 6: Connect Lambda Functions to API Gateway

After deploying Lambda functions, connect them to API Gateway:

### For `/soteria/sync` endpoint:

```bash
# Get your API Gateway ID (from Step 1)
API_ID="your-api-id-here"
SYNC_RESOURCE_ID="your-sync-resource-id"

# Create POST method
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $SYNC_RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE \
  --region us-east-1

# Connect to Lambda
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $SYNC_RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:YOUR_ACCOUNT_ID:function:soteria-sync-user-data/invocations" \
  --region us-east-1
```

### For `/soteria/data` endpoint:

```bash
DATA_RESOURCE_ID="your-data-resource-id"

# Create GET method
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $DATA_RESOURCE_ID \
  --http-method GET \
  --authorization-type NONE \
  --region us-east-1

# Connect to Lambda
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $DATA_RESOURCE_ID \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:YOUR_ACCOUNT_ID:function:soteria-get-user-data/invocations" \
  --region us-east-1
```

## Step 7: Configure CORS

Enable CORS on both endpoints:

```bash
# For /soteria/sync
aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $SYNC_RESOURCE_ID \
  --http-method POST \
  --status-code 200 \
  --response-parameters "method.response.header.Access-Control-Allow-Origin=true" \
  --region us-east-1

# For /soteria/data
aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $DATA_RESOURCE_ID \
  --http-method GET \
  --status-code 200 \
  --response-parameters "method.response.header.Access-Control-Allow-Origin=true" \
  --region us-east-1
```

## Step 8: Deploy API Gateway

Deploy the API Gateway to the `prod` stage:

```bash
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region us-east-1
```

## Step 9: Get API Gateway URL

Get the invoke URL:

```bash
aws apigateway get-stage \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region us-east-1 \
  --query 'invokeUrl' \
  --output text
```

The URL will be in format:
```
https://{api-id}.execute-api.us-east-1.amazonaws.com/prod
```

## Step 10: Update iOS App

1. Open `soteria/Services/AWSDataService.swift`
2. Update the `apiGatewayURL` property with your API Gateway URL:

```swift
private let apiGatewayURL = "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod"
```

3. Enable AWS sync in services (optional, defaults to UserDefaults):

```swift
// In DeviceActivityService
deviceActivityService.useAWS = true

// In PurchaseIntentService
purchaseIntentService.useAWS = true
```

## Step 11: Grant Lambda Permissions

Allow API Gateway to invoke Lambda functions:

```bash
# For sync function
aws lambda add-permission \
  --function-name soteria-sync-user-data \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:YOUR_ACCOUNT_ID:$API_ID/*/*" \
  --region us-east-1

# For get function
aws lambda add-permission \
  --function-name soteria-get-user-data \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:YOUR_ACCOUNT_ID:$API_ID/*/*" \
  --region us-east-1
```

## Testing

### Test API Gateway Endpoints

```bash
# Test sync endpoint
curl -X POST https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod/soteria/sync \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_123",
    "data_type": "app_names",
    "data": {"0": "Amazon", "1": "Target"}
  }'

# Test get endpoint
curl "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod/soteria/data?user_id=test_user_123&data_type=app_names"
```

### Test from iOS App

1. Enable AWS sync in the app
2. Create some data (app names, purchase intents, etc.)
3. Check CloudWatch logs for Lambda invocations
4. Verify data in DynamoDB tables

## Troubleshooting

### Lambda Function Not Found
- Make sure you deployed Lambda functions before connecting to API Gateway
- Check function names match exactly

### Permission Denied
- Verify IAM role has DynamoDB permissions
- Check Lambda function has permission to be invoked by API Gateway

### CORS Errors
- Make sure CORS is configured on API Gateway
- Check response headers include `Access-Control-Allow-Origin`

### Data Not Syncing
- Check CloudWatch logs for Lambda functions
- Verify API Gateway URL is correct in iOS app
- Ensure user is authenticated (Firebase Auth)

## Cost Estimation

- **API Gateway:** Free tier: 1M requests/month
- **Lambda:** Free tier: 1M requests/month, 400,000 GB-seconds
- **DynamoDB:** Free tier: 25GB storage, 200M read/write units/month

For development/testing, you should stay well within free tier limits.

## Next Steps

After setup is complete:
1. Test data sync from iOS app
2. Monitor CloudWatch logs
3. Gradually enable AWS sync for all services
4. Consider adding error handling and retry logic
5. Add data migration from UserDefaults to AWS (optional)

