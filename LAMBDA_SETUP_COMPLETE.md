# Lambda Functions Setup Complete ✅

## Lambda Functions Created

All three Lambda functions have been successfully created:

1. **rever-plaid-create-link-token**
   - ARN: `arn:aws:lambda:us-east-1:516141816050:function:rever-plaid-create-link-token`
   - Runtime: Node.js 20.x
   - Handler: `index.handler`
   - Timeout: 30 seconds
   - Memory: 256 MB

2. **rever-plaid-exchange-token**
   - ARN: `arn:aws:lambda:us-east-1:516141816050:function:rever-plaid-exchange-token`
   - Runtime: Node.js 20.x
   - Handler: `index.handler`
   - Timeout: 30 seconds
   - Memory: 256 MB

3. **rever-plaid-transfer**
   - ARN: `arn:aws:lambda:us-east-1:516141816050:function:rever-plaid-transfer`
   - Runtime: Node.js 20.x
   - Handler: `index.handler`
   - Timeout: 60 seconds
   - Memory: 512 MB

## IAM Role Created

**Role Name:** `rever-plaid-lambda-role`
**Role ARN:** `arn:aws:iam::516141816050:role/rever-plaid-lambda-role`

**Policies Attached:**
- `AWSLambdaBasicExecutionRole` - For CloudWatch Logs
- `rever-plaid-lambda-policy` - For DynamoDB access
- `rever-plaid-secrets-policy` - For Secrets Manager access

## API Gateway Integration

All Lambda functions are connected to API Gateway:
- ✅ `/plaid/create-link-token` → `rever-plaid-create-link-token`
- ✅ `/plaid/exchange-public-token` → `rever-plaid-exchange-token`
- ✅ `/plaid/transfer` → `rever-plaid-transfer`

## Environment Variables

Currently set to:
- `PLAID_ENV=sandbox`
- `DYNAMODB_TABLE=rever-plaid-access-tokens`

**⚠️ IMPORTANT:** You need to add Plaid credentials:

### Option 1: Environment Variables (Quick for testing)
```bash
aws lambda update-function-configuration \
  --function-name rever-plaid-create-link-token \
  --environment "Variables={PLAID_ENV=sandbox,DYNAMODB_TABLE=rever-plaid-access-tokens,PLAID_CLIENT_ID=your_client_id,PLAID_SECRET=your_secret}" \
  --region us-east-1

# Repeat for other two functions
```

### Option 2: AWS Secrets Manager (Recommended for production)
1. Create secret: `rever/plaid/credentials`
2. Store: `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV`
3. Update Lambda functions to read from Secrets Manager

## Next Steps

1. **Add Plaid Credentials:**
   - Get credentials from Plaid Dashboard
   - Add to Lambda environment variables or Secrets Manager

2. **Create DynamoDB Table:**
   ```bash
   aws dynamodb create-table \
     --table-name rever-plaid-access-tokens \
     --attribute-definitions AttributeName=user_id,AttributeType=S AttributeName=item_id,AttributeType=S \
     --key-schema AttributeName=user_id,KeyType=HASH AttributeName=item_id,KeyType=RANGE \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

3. **Test the Endpoints:**
   - Use Postman or curl to test each endpoint
   - Verify CORS headers are returned
   - Test with Plaid sandbox credentials

4. **Update iOS App:**
   - API Gateway URL is already set in `PlaidService.swift`
   - Test the full flow from iOS app

## API Gateway URL

**Base URL:**
```
https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod
```

**Endpoints:**
- `POST https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod/plaid/create-link-token`
- `POST https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod/plaid/exchange-public-token`
- `POST https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod/plaid/transfer`

## Testing

Test with curl:
```bash
# Create link token
curl -X POST https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod/plaid/create-link-token \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test_user_123"}'
```

## Files Created

- `lambda/rever-plaid-create-link-token/index.js` - Lambda function code
- `lambda/rever-plaid-exchange-token/index.js` - Lambda function code
- `lambda/rever-plaid-transfer/index.js` - Lambda function code
- All packaged as ZIP files in `lambda/` directory

