# Fix Plaid API Gateway Integration

## Problem
Getting "Internal server error" when trying to connect accounts via Plaid.

## Root Cause
The API Gateway integration with Lambda might not be properly configured, or the Lambda function might be failing.

## Solution

### Step 1: Check Lambda Function Status
```bash
aws lambda get-function --function-name soteria-plaid-create-link-token --region us-east-1
```

### Step 2: Test Lambda Function Directly
```bash
aws lambda invoke \
  --function-name soteria-plaid-create-link-token \
  --payload '{"httpMethod":"POST","body":"{\"user_id\":\"test123\",\"client_name\":\"Soteria\",\"products\":[\"auth\",\"balance\"],\"country_codes\":[\"US\"],\"language\":\"en\"}"}' \
  --region us-east-1 \
  response.json && cat response.json
```

### Step 3: Check API Gateway Integration
The Lambda function expects API Gateway proxy integration format. Verify:
1. Integration type is "Lambda Function"
2. "Use Lambda Proxy integration" is **checked**
3. Lambda function name is correct: `soteria-plaid-create-link-token`

### Step 4: Reconnect API Gateway to Lambda (if needed)
```bash
# Get resource ID
RESOURCE_ID=$(aws apigateway get-resources \
  --rest-api-id ue1psw3mt3 \
  --region us-east-1 \
  --query "items[?path=='/soteria/plaid/create-link-token'].id" \
  --output text)

# Update integration
aws apigateway put-integration \
  --rest-api-id ue1psw3mt3 \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:516141816050:function:soteria-plaid-create-link-token/invocations" \
  --region us-east-1
```

### Step 5: Redeploy API Gateway
```bash
aws apigateway create-deployment \
  --rest-api-id ue1psw3mt3 \
  --stage-name prod \
  --region us-east-1
```

### Step 6: Check CloudWatch Logs
```bash
aws logs tail /aws/lambda/soteria-plaid-create-link-token --follow --region us-east-1
```

## Common Issues

1. **Lambda Proxy Integration Not Enabled**: The Lambda function expects `event.httpMethod` and `event.body`, which requires proxy integration.

2. **Lambda Permissions**: API Gateway needs permission to invoke the Lambda function.

3. **CORS Issues**: Make sure CORS is configured on the API Gateway resource.

4. **Lambda Function Errors**: Check CloudWatch logs for actual Lambda errors.

## Quick Fix Script

Run this to fix the integration:

```bash
#!/bin/bash
API_ID="ue1psw3mt3"
REGION="us-east-1"
ACCOUNT_ID="516141816050"
FUNCTION_NAME="soteria-plaid-create-link-token"

# Get resource ID
RESOURCE_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region $REGION \
  --query "items[?path=='/soteria/plaid/create-link-token'].id" \
  --output text)

# Update integration
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}/invocations" \
  --region $REGION

# Redeploy
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region $REGION

echo "✅ API Gateway integration updated and redeployed"
```

