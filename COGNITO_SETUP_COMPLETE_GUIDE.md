# Complete AWS Cognito Setup Guide

This guide will walk you through setting up AWS Cognito authentication for Soteria.

## Prerequisites

- AWS CLI installed and configured
- AWS account with appropriate permissions
- Node.js installed (for Lambda functions)
- Your API Gateway ID (from existing setup)

## Step-by-Step Setup

### Step 1: Create Cognito User Pool

Run the setup script:

```bash
./create-cognito-user-pool.sh
```

This will:
- Create a Cognito User Pool named `soteria-users`
- Create a User Pool Client named `soteria-ios`
- Output the User Pool ID and Client ID

**Save these values!** You'll need them for the next steps.

**Expected Output:**
```
User Pool ID: us-east-1_XXXXXXXXX
Client ID: xxxxxxxxxxxxxxxxxxxxxx
Client Secret: xxxxxxxxxxxxxxxxxxxxxx (if generated)
```

### Step 2: Install Lambda Dependencies

Before deploying Lambda functions, install dependencies:

```bash
cd lambda/soteria-auth-signup && npm install --production && cd ../..
cd lambda/soteria-auth-signin && npm install --production && cd ../..
cd lambda/soteria-auth-refresh && npm install --production && cd ../..
cd lambda/soteria-auth-reset-password && npm install --production && cd ../..
```

Or install all at once:

```bash
for dir in lambda/soteria-auth-*; do
    echo "Installing dependencies in $dir..."
    cd "$dir" && npm install --production && cd ../..
done
```

### Step 3: Deploy Lambda Functions

Run the deployment script:

```bash
./deploy-auth-lambdas.sh
```

This script will:
- Ask for your User Pool ID and Client ID
- Deploy all 4 authentication Lambda functions
- Set environment variables (USER_POOL_ID, CLIENT_ID, CLIENT_SECRET)

**Functions deployed:**
- `soteria-auth-signup` - User registration
- `soteria-auth-signin` - User login
- `soteria-auth-refresh` - Token refresh
- `soteria-auth-reset-password` - Password reset

### Step 4: Connect Lambda Functions to API Gateway

Run the connection script:

```bash
./connect-auth-lambdas-to-api-gateway.sh
```

This script will:
- Ask for your API Gateway ID
- Create/update API Gateway endpoints:
  - `POST /soteria/auth/signup`
  - `POST /soteria/auth/signin`
  - `POST /soteria/auth/refresh`
  - `POST /soteria/auth/reset-password`
- Enable CORS on all endpoints
- Grant API Gateway permission to invoke Lambda functions
- Deploy the API Gateway

**Expected Output:**
```
API Gateway URL: https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod
Endpoints created:
  POST https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/signup
  POST https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/signin
  POST https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/refresh
  POST https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/reset-password
```

### Step 5: Update CognitoAuthService (if needed)

If your API Gateway URL is different from the default, update `soteria/Services/CognitoAuthService.swift`:

```swift
private let baseURL: String = "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod/soteria/auth"
```

Replace `YOUR-API-ID` with your actual API Gateway ID.

## Verification

### Test Sign Up

```bash
curl -X POST https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "tokens": {
    "accessToken": "...",
    "idToken": "...",
    "refreshToken": "...",
    "userId": "...",
    "email": "test@example.com"
  }
}
```

### Test Sign In

```bash
curl -X POST https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!"
  }'
```

### Test Token Refresh

```bash
curl -X POST https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "YOUR_REFRESH_TOKEN"
  }'
```

## Troubleshooting

### Lambda Function Not Found
- Make sure you ran `deploy-auth-lambdas.sh` successfully
- Check function names match exactly

### Permission Denied
- Verify IAM role `soteria-lambda-role` exists
- Check Lambda functions have permission to be invoked by API Gateway
- Verify Cognito permissions in IAM role

### CORS Errors
- Make sure CORS is configured on API Gateway endpoints
- Check response headers include `Access-Control-Allow-Origin`

### Authentication Fails
- Verify User Pool ID and Client ID are correct in Lambda environment variables
- Check CloudWatch logs for Lambda functions
- Verify email is verified in Cognito (if required)

### API Gateway Returns 500
- Check CloudWatch logs for Lambda functions
- Verify Lambda functions are deployed correctly
- Check environment variables are set

## CloudWatch Logs

To view Lambda function logs:

```bash
# View signup logs
aws logs tail /aws/lambda/soteria-auth-signup --follow

# View signin logs
aws logs tail /aws/lambda/soteria-auth-signin --follow

# View refresh logs
aws logs tail /aws/lambda/soteria-auth-refresh --follow

# View reset-password logs
aws logs tail /aws/lambda/soteria-auth-reset-password --follow
```

## Next Steps

After setup is complete:

1. ✅ Test authentication flow in the iOS app
2. ✅ Verify tokens are stored correctly
3. ✅ Test token refresh on app launch
4. ✅ Update existing Lambda authorizers to validate Cognito tokens
5. ✅ Test data sync with Cognito authentication

## Cost Estimation

- **Cognito**: Free tier: 50,000 MAU (Monthly Active Users)
- **Lambda**: Free tier: 1M requests/month, 400,000 GB-seconds
- **API Gateway**: Free tier: 1M requests/month

For development/testing, you should stay well within free tier limits.

## Support

For issues:
- Check CloudWatch logs
- Verify all environment variables are set
- Ensure API Gateway is deployed to `prod` stage
- Review AWS Cognito documentation

