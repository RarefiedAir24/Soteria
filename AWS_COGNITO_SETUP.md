# AWS Cognito Setup Instructions

## Overview
After migrating from Firebase to AWS Cognito, you need to set up the Cognito User Pool and Lambda functions to handle authentication.

## Step 1: Create Cognito User Pool

Run this command in AWS CLI:

```bash
aws cognito-idp create-user-pool \
  --pool-name soteria-users \
  --policies PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true} \
  --auto-verified-attributes email \
  --region us-east-1
```

**Save the User Pool ID** from the response.

## Step 2: Create User Pool Client

```bash
aws cognito-idp create-user-pool-client \
  --user-pool-id YOUR_USER_POOL_ID \
  --client-name soteria-ios \
  --generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --region us-east-1
```

**Save the Client ID** from the response.

## Step 3: Create Lambda Functions for Auth

You need to create Lambda functions to handle:
- `/soteria/auth/signup` - User registration
- `/soteria/auth/signin` - User login
- `/soteria/auth/refresh` - Token refresh
- `/soteria/auth/reset-password` - Password reset

These functions will use the AWS Cognito SDK to interact with your User Pool.

## Step 4: Update CognitoAuthService

After creating the User Pool, update `soteria/Services/CognitoAuthService.swift`:

1. Replace `YOUR_USER_POOL_ID` with your actual User Pool ID
2. Replace `YOUR_CLIENT_ID` with your actual Client ID

## Step 5: Connect Lambda to API Gateway

Add the auth endpoints to your existing API Gateway:
- `/soteria/auth/signup` → `soteria-auth-signup` Lambda
- `/soteria/auth/signin` → `soteria-auth-signin` Lambda
- `/soteria/auth/refresh` → `soteria-auth-refresh` Lambda
- `/soteria/auth/reset-password` → `soteria-auth-reset-password` Lambda

## Step 6: Update Lambda Authorizers

Update your existing Lambda authorizers to validate Cognito JWT tokens instead of Firebase tokens.

## Testing

1. Test sign up flow
2. Test sign in flow
3. Test token refresh
4. Test API calls with Cognito tokens

## Notes

- Cognito tokens are JWT tokens, similar to Firebase
- Token expiration is typically 1 hour (configurable)
- Refresh tokens last 30 days (configurable)
- All tokens are stored securely in UserDefaults

