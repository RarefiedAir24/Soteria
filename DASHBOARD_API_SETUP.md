# Dashboard API Setup Guide

This guide explains how to set up the Dashboard API endpoint that provides pre-computed dashboard data for fast app loading.

## Overview

The Dashboard API (`/soteria/dashboard`) aggregates data from multiple DynamoDB tables and returns pre-computed metrics in a single response. This eliminates the need for multiple local calculations and JSON decoding, significantly speeding up app startup.

## Benefits

- **Instant Loading**: Cached data shows immediately (0ms delay)
- **Always Fresh**: API updates in background (non-blocking)
- **Faster**: Backend pre-computes everything (no local JSON decoding)
- **Resilient**: Falls back to local services if API fails

## Architecture

```
iOS App
  ↓ (1) Load cached data instantly
  ↓ (2) Fetch fresh data from API (background)
  ↓ (3) Update UI when API responds
  ↓
AWS API Gateway (/soteria/dashboard)
  ↓
Lambda Function (soteria-get-dashboard)
  ↓
DynamoDB Tables (parallel queries)
  - soteria-goals
  - soteria-regrets
  - soteria-plaid-transfers
  - soteria-unblock-events
  - soteria-quiet-hours
  - soteria-app-usage
```

## Setup Steps

### 1. Install Lambda Dependencies

```bash
cd lambda/soteria-get-dashboard
npm install --production
cd ../..
```

### 2. Deploy Lambda Function

The dashboard Lambda is included in the deployment script:

```bash
./deploy-soteria-lambdas.sh
```

This will deploy:
- `soteria-get-dashboard` (new)
- All other existing Lambda functions

### 3. Create API Gateway Resource (if needed)

If the `/soteria/dashboard` resource doesn't exist in your API Gateway, create it:

```bash
# Get your API Gateway ID
API_ID=$(aws apigateway get-rest-apis \
    --query "items[?name=='soteria-api'].id" \
    --output text \
    --region us-east-1)

# Get the /soteria resource ID
SOTERIA_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region us-east-1 \
    --query "items[?path=='/soteria'].id" \
    --output text)

# Create /soteria/dashboard resource
aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$SOTERIA_RESOURCE_ID" \
    --path-part "dashboard" \
    --region us-east-1
```

### 4. Connect Lambda to API Gateway

Run the connection script (it will automatically create the resource if needed):

```bash
./connect-api-gateway-lambdas.sh $API_ID
```

Or manually connect:

```bash
# Get dashboard resource ID
DASHBOARD_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region us-east-1 \
    --query "items[?path=='/soteria/dashboard'].id" \
    --output text)

# Create GET method
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method GET \
    --authorization-type NONE \
    --region us-east-1

# Connect to Lambda
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_ARN="arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:soteria-get-dashboard"

aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
    --region us-east-1

# Grant permission
aws lambda add-permission \
    --function-name soteria-get-dashboard \
    --statement-id "apigateway-get-dashboard" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT_ID}:${API_ID}/*/GET/soteria/dashboard" \
    --region us-east-1
```

### 5. Enable CORS

Enable CORS on the dashboard endpoint:

```bash
# Add OPTIONS method for CORS preflight
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region us-east-1

# Create mock integration for OPTIONS
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method OPTIONS \
    --type MOCK \
    --integration-http-method OPTIONS \
    --request-templates '{"application/json":"{\"statusCode\":200}"}' \
    --region us-east-1

# Add method response for OPTIONS
aws apigateway put-method-response \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers":true,"method.response.header.Access-Control-Allow-Methods":true,"method.response.header.Access-Control-Allow-Origin":true}' \
    --region us-east-1

# Add integration response for OPTIONS
aws apigateway put-integration-response \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,Authorization'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'"}' \
    --region us-east-1
```

### 6. Deploy API Gateway

Deploy the API Gateway to the `prod` stage:

```bash
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name prod \
    --region us-east-1
```

### 7. Test the Endpoint

Test the dashboard endpoint:

```bash
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"
USER_ID="your-user-id-here"

curl -X GET "${API_URL}/soteria/dashboard?user_id=${USER_ID}" \
  -H "Content-Type: application/json"
```

Expected response:

```json
{
  "success": true,
  "data": {
    "totalSaved": 150.00,
    "currentStreak": 5,
    "longestStreak": 10,
    "activeGoal": {
      "id": "goal-123",
      "name": "Vacation",
      "currentAmount": 500.00,
      "targetAmount": 2000.00,
      "progress": 0.25
    },
    "recentRegretCount": 2,
    "currentRisk": "medium",
    "isQuietModeActive": false,
    "soteriaMomentsCount": 15,
    "lastUpdated": 1703123456789
  }
}
```

## DynamoDB Tables Required

The Lambda function queries these tables:

1. **soteria-goals** - For active goals
2. **soteria-regrets** - For recent regret count
3. **soteria-plaid-transfers** - For total saved (sum of transfers)
4. **soteria-unblock-events** - For streak calculation
5. **soteria-quiet-hours** - For quiet mode status
6. **soteria-app-usage** - For Soteria moments count

Make sure all tables exist and have the correct schema.

## Performance Optimization

The Lambda function:
- Uses **parallel queries** (`Promise.all`) to fetch data simultaneously
- Has a **10-second timeout** (fast response expected)
- Uses **512MB memory** for faster execution
- Returns data in **< 1 second** for typical queries

## Error Handling

The Lambda function:
- Returns empty/default values if tables don't exist
- Handles missing data gracefully
- Logs errors to CloudWatch for debugging
- Never throws errors that would break the app

## iOS App Integration

The iOS app (`AWSDataService.swift`) already includes:
- `getDashboardData()` - Fetches from API
- `cacheDashboardData()` - Caches locally
- `getCachedDashboardData()` - Loads cached data instantly

The app automatically:
1. Loads cached data immediately (0ms)
2. Fetches fresh data in background
3. Updates UI when API responds
4. Falls back to local services if API fails

## Monitoring

Monitor the Lambda function in CloudWatch:
- **Logs**: `/aws/lambda/soteria-get-dashboard`
- **Metrics**: Invocations, Duration, Errors
- **Alarms**: Set up alerts for errors or slow responses

## Troubleshooting

### Lambda function not found
- Make sure you deployed it: `./deploy-soteria-lambdas.sh`
- Check function name: `aws lambda list-functions --query "Functions[?FunctionName=='soteria-get-dashboard']"`

### API Gateway 404
- Check if resource exists: `aws apigateway get-resources --rest-api-id $API_ID`
- Make sure you deployed to `prod` stage

### CORS errors
- Make sure OPTIONS method is configured
- Check response headers include CORS headers

### Slow responses
- Check CloudWatch logs for slow queries
- Consider adding indexes to DynamoDB tables
- Increase Lambda memory/timeout if needed

## Next Steps

1. ✅ Deploy Lambda function
2. ✅ Connect to API Gateway
3. ✅ Enable CORS
4. ✅ Deploy API Gateway
5. ✅ Test endpoint
6. ✅ Monitor in CloudWatch
7. ✅ Update iOS app (already done!)

The iOS app will automatically use the dashboard API once it's deployed and accessible.

