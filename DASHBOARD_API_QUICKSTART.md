# Dashboard API Quick Start

Quick setup guide for the Dashboard API endpoint.

## Prerequisites

- AWS CLI configured
- DynamoDB tables created (see `create-soteria-dynamodb-tables.sh`)
- IAM role created (see `create-soteria-lambda-role.sh`)
- API Gateway created (see `create-soteria-api-gateway.sh`)

## Quick Setup (3 Steps)

### Step 1: Install Dependencies

```bash
cd lambda/soteria-get-dashboard
npm install --production
cd ../..
```

### Step 2: Deploy Lambda Function

```bash
./deploy-soteria-lambdas.sh
```

This will deploy all Lambda functions including `soteria-get-dashboard`.

### Step 3: Connect to API Gateway

```bash
# Get your API Gateway ID
API_ID=$(aws apigateway get-rest-apis \
    --query "items[?name=='soteria-api'].id" \
    --output text \
    --region us-east-1)

# Run the setup script
./setup-dashboard-api.sh $API_ID
```

Or use the existing connection script (it will auto-create the resource):

```bash
./connect-api-gateway-lambdas.sh $API_ID
```

### Step 4: Deploy API Gateway

```bash
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --region us-east-1
```

## Test the Endpoint

```bash
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"
USER_ID="your-firebase-user-id"

curl -X GET "${API_URL}/soteria/dashboard?user_id=${USER_ID}" \
  -H "Content-Type: application/json"
```

## What It Does

The Dashboard API:
- ✅ Aggregates data from 6 DynamoDB tables in parallel
- ✅ Pre-computes: total saved, streak, active goal, risk level, etc.
- ✅ Returns all data in a single response (< 1 second)
- ✅ Eliminates need for multiple local calculations

## iOS App Integration

The iOS app (`AWSDataService.swift` and `HomeView.swift`) already includes:
- ✅ Caching system (loads instantly from cache)
- ✅ Background API calls (non-blocking)
- ✅ Fallback to local services (if API fails)

**The app will automatically use the dashboard API once it's deployed!**

## Troubleshooting

**Lambda not found?**
```bash
aws lambda get-function --function-name soteria-get-dashboard
```

**API Gateway 404?**
- Check if resource exists: `aws apigateway get-resources --rest-api-id $API_ID`
- Make sure you deployed to `prod` stage

**Slow responses?**
- Check CloudWatch logs: `/aws/lambda/soteria-get-dashboard`
- Consider adding DynamoDB indexes
- Increase Lambda memory if needed

## Full Documentation

See `DASHBOARD_API_SETUP.md` for complete documentation.

