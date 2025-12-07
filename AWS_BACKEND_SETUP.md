# AWS Backend Setup for Plaid Integration - REVER ONLY

**⚠️ IMPORTANT: This setup is specific to Rever and will NOT impact Wordflect or any other AWS resources.**

This guide explains how to set up AWS Lambda functions and API Gateway for Plaid integration, isolated to the Rever application.

## Architecture

```
Rever iOS App → Rever API Gateway → Rever Lambda Functions → Plaid API
              (Firebase Auth)        (Node.js/Python)
```

## Isolation Strategy

To ensure complete isolation from Wordflect and other projects:

1. **Separate API Gateway** - Create a dedicated API Gateway for Rever
2. **Separate Lambda Functions** - All functions prefixed with `rever-`
3. **Separate DynamoDB Table** - Table name: `rever-plaid-access-tokens`
4. **Separate Secrets** - Store in AWS Secrets Manager with `rever/` prefix
5. **Clear Naming Convention** - All resources prefixed with `rever-` or `rever_`

## Required AWS Services (Rever-Specific)

1. **AWS Lambda** - Serverless functions to handle Plaid API calls (prefixed: `rever-plaid-*`)
2. **API Gateway** - REST API endpoints (named: `rever-api` or `rever-plaid-api`)
3. **AWS Secrets Manager** - Store Plaid credentials securely (path: `rever/plaid/*`)
4. **DynamoDB** - Store access tokens (table: `rever-plaid-access-tokens`)
5. **AWS Cognito** (Optional) - For additional authentication layer

## Lambda Functions to Create (Rever-Specific)

All Lambda functions should be named with `rever-` prefix to avoid conflicts:

### 1. Create Link Token (`rever-plaid-create-link-token`)

**API Gateway Path:** `/plaid/create-link-token`

**Purpose:** Creates a Plaid link token for the user

**Request:**
```json
{
  "user_id": "firebase_user_id",
  "client_name": "Rever",
  "products": ["auth", "transactions"],
  "country_codes": ["US"],
  "language": "en"
}
```

**Response:**
```json
{
  "link_token": "link-sandbox-xxx"
}
```

**Lambda Function (Node.js):**
```javascript
const plaid = require('plaid');

const client = new plaid.Client({
  clientID: process.env.PLAID_CLIENT_ID,
  secret: process.env.PLAID_SECRET,
  env: plaid.environments.sandbox, // or production
});

exports.handler = async (event) => {
  try {
    // Verify Firebase token (optional, can use API Gateway authorizer)
    const userId = JSON.parse(event.body).user_id;
    
    const response = await client.createLinkToken({
      user: {
        client_user_id: userId,
      },
      client_name: 'Rever',
      products: ['auth', 'transactions'],
      country_codes: ['US'],
      language: 'en',
    });
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        link_token: response.link_token,
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
```

### 2. Exchange Public Token (`rever-plaid-exchange-token`)

**API Gateway Path:** `/plaid/exchange-public-token`

**Purpose:** Exchanges Plaid public token for access token

**Request:**
```json
{
  "public_token": "public-sandbox-xxx",
  "user_id": "firebase_user_id"
}
```

**Response:**
```json
{
  "access_token": "access-sandbox-xxx",
  "item_id": "item-xxx",
  "accounts": [
    {
      "account_id": "acc-xxx",
      "name": "Plaid Savings",
      "mask": "0000",
      "type": "depository",
      "subtype": "savings"
    }
  ],
  "institution_name": "First Platypus Bank"
}
```

**Lambda Function (Node.js):**
```javascript
exports.handler = async (event) => {
  try {
    const { public_token, user_id } = JSON.parse(event.body);
    
    // Exchange public token for access token
    const response = await client.exchangePublicToken(public_token);
    
    // Get account information
    const accountsResponse = await client.getAccounts(response.access_token);
    
    // Store access token in DynamoDB (keyed by user_id and item_id)
    // TODO: Store in DynamoDB for later use
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        access_token: response.access_token,
        item_id: response.item_id,
        accounts: accountsResponse.accounts,
        institution_name: accountsResponse.item.institution_id, // You may need to fetch this separately
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
```

### 3. Transfer to Savings (`rever-plaid-transfer`)

**API Gateway Path:** `/plaid/transfer`

**Purpose:** Initiates a transfer to a savings account

**Request:**
```json
{
  "account_id": "acc-xxx",
  "amount": 100.00,
  "user_id": "firebase_user_id"
}
```

**Response:**
```json
{
  "transfer_id": "transfer-xxx",
  "status": "pending"
}
```

**Lambda Function (Node.js):**
```javascript
exports.handler = async (event) => {
  try {
    const { account_id, amount, user_id } = JSON.parse(event.body);
    
    // Retrieve access token from DynamoDB using user_id and account_id
    // TODO: Fetch from DynamoDB
    
    // Create transfer authorization
    const authResponse = await client.transferAuthorizationCreate({
      access_token: accessToken,
      account_id: account_id,
      type: 'credit',
      network: 'ach',
      amount: amount.toString(),
      ach_class: 'ppd',
      user: {
        legal_name: 'User Name', // Get from user profile
      },
    });
    
    // Create the transfer
    const transferResponse = await client.transferCreate({
      idempotency_key: `transfer-${user_id}-${Date.now()}`,
      access_token: accessToken,
      account_id: account_id,
      authorization_id: authResponse.authorization.id,
      type: 'credit',
      network: 'ach',
      amount: amount.toString(),
      ach_class: 'ppd',
      user: {
        legal_name: 'User Name',
      },
      description: 'Rever savings transfer',
    });
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        transfer_id: transferResponse.transfer.id,
        status: transferResponse.transfer.status,
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
```

## API Gateway Setup (Rever-Specific)

1. **Create NEW REST API** in API Gateway
   - **Name:** `rever-plaid-api` (or `rever-api` if you want to add more endpoints later)
   - **Description:** "API Gateway for Rever app - Plaid integration"
   - **⚠️ DO NOT use existing Wordflect API Gateway**

2. **Create Resources:**
   - `/plaid/create-link-token` (POST) → `rever-plaid-create-link-token` Lambda
   - `/plaid/exchange-public-token` (POST) → `rever-plaid-exchange-token` Lambda
   - `/plaid/transfer` (POST) → `rever-plaid-transfer` Lambda
   
3. **Resource Naming:**
   - All resources should be clearly named with `rever-` prefix
   - This ensures no conflicts with Wordflect or other projects

3. **Configure CORS** for all endpoints:
   - Access-Control-Allow-Origin: `*` (or your app's domain)
   - Access-Control-Allow-Headers: `Content-Type, Authorization`
   - Access-Control-Allow-Methods: `POST, OPTIONS`

4. **Set up Authorization** (Optional but recommended):
   - Use API Gateway Authorizer with Firebase tokens
   - Or validate Firebase tokens in Lambda functions

5. **Deploy API** to a stage (e.g., `prod`)

6. **Get API Gateway URL:**
   - Format: `https://{api-id}.execute-api.{region}.amazonaws.com/{stage}`
   - Update `awsApiGatewayURL` in `PlaidService.swift`

## Environment Variables for Lambda (Rever-Specific)

Store in AWS Secrets Manager with `rever/` prefix:

**Secrets Manager Path:** `rever/plaid/credentials`

Or use Lambda environment variables (prefixed for clarity):
- `REVER_PLAID_CLIENT_ID` - Your Plaid client ID
- `REVER_PLAID_SECRET` - Your Plaid secret
- `REVER_PLAID_ENV` - `sandbox`, `development`, or `production`

**⚠️ IMPORTANT:** Use separate secrets from Wordflect. Never share credentials between projects.

## DynamoDB Table Structure (Rever-Specific)

Create a NEW table to store access tokens (separate from Wordflect):

**Table Name:** `rever-plaid-access-tokens`

**⚠️ IMPORTANT:** This is a separate table from any Wordflect tables. No shared resources.

**Schema:**
- `user_id` (Partition Key) - Firebase user ID
- `item_id` (Sort Key) - Plaid item ID
- `access_token` - Encrypted access token
- `account_id` - Account ID
- `institution_name` - Bank name
- `created_at` - Timestamp

## Security Best Practices

1. **Never store Plaid credentials in client code**
2. **Use AWS Secrets Manager** for Plaid credentials (with `rever/` prefix)
3. **Encrypt access tokens** in DynamoDB
4. **Validate Firebase tokens** in Lambda functions
5. **Use IAM roles** with least privilege for Lambda (separate roles for Rever)
6. **Enable CloudWatch Logs** for monitoring (use `rever-` prefix in log groups)
7. **Set up API Gateway throttling** to prevent abuse
8. **Use separate IAM roles** - Create dedicated IAM roles for Rever Lambda functions
9. **Tag all resources** - Tag all AWS resources with `Project: Rever` for easy identification

## Resource Isolation Checklist

Before deploying, ensure:

- [ ] New API Gateway created (not using Wordflect's)
- [ ] Lambda functions named with `rever-` prefix
- [ ] DynamoDB table named `rever-plaid-access-tokens`
- [ ] Secrets stored in `rever/plaid/*` path
- [ ] IAM roles prefixed with `rever-`
- [ ] CloudWatch log groups prefixed with `/aws/lambda/rever-`
- [ ] All resources tagged with `Project: Rever`
- [ ] No shared resources with Wordflect

## Testing

1. Use Plaid's sandbox environment for testing
2. Test credentials:
   - Username: `user_good`
   - Password: `pass_good`
3. Test the full flow:
   - Create link token
   - Connect account
   - Exchange token
   - Transfer funds

## Deployment Steps

1. Create Lambda functions with code above
2. Set environment variables
3. Create API Gateway REST API
4. Connect Lambda functions to API Gateway
5. Configure CORS
6. Deploy API
7. Update `awsApiGatewayURL` in iOS app
8. Test end-to-end

## Cost Estimation

- **Lambda:** Free tier includes 1M requests/month
- **API Gateway:** Free tier includes 1M requests/month
- **DynamoDB:** Free tier includes 25GB storage
- **Plaid:** Check Plaid pricing at plaid.com/pricing

## Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Plaid API Documentation](https://plaid.com/docs/api/)
- [Plaid Node.js SDK](https://github.com/plaid/plaid-node)

