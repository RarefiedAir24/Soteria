# AWS Resource Naming Convention for Rever

**⚠️ DEPRECATED: This document is for the old "Rever" naming. See `AWS_SOTERIA_RESOURCE_NAMING.md` for the new Soteria naming convention.**

This document defines the naming convention for all AWS resources used by Rever to ensure complete isolation from Wordflect and other projects.

## Naming Convention

All AWS resources should be prefixed with `rever-` or use the pattern `rever_*` to clearly identify them as Rever-specific resources.

## Resource Naming List

### API Gateway
- **API Name:** `rever-plaid-api` or `rever-api`
- **Stage:** `prod`, `dev`, or `sandbox`
- **Example URL:** `https://{api-id}.execute-api.{region}.amazonaws.com/prod`

### Lambda Functions
- `rever-plaid-create-link-token`
- `rever-plaid-exchange-token`
- `rever-plaid-transfer`
- `rever-plaid-get-accounts` (if needed in future)

### DynamoDB Tables
- `rever-plaid-access-tokens` - Stores Plaid access tokens per user
- `rever-user-goals` (if needed in future)
- `rever-savings-history` (if needed in future)

### AWS Secrets Manager
- **Secret Name:** `rever/plaid/credentials`
- **Keys:**
  - `PLAID_CLIENT_ID`
  - `PLAID_SECRET`
  - `PLAID_ENV`

### IAM Roles
- `rever-plaid-lambda-role` - IAM role for Lambda functions
- `rever-plaid-api-gateway-role` - IAM role for API Gateway (if needed)

### IAM Policies
- `rever-plaid-lambda-policy` - Policy for Lambda functions
- `rever-plaid-secrets-policy` - Policy to access Secrets Manager
- `rever-plaid-dynamodb-policy` - Policy to access DynamoDB

### CloudWatch Log Groups
- `/aws/lambda/rever-plaid-create-link-token`
- `/aws/lambda/rever-plaid-exchange-token`
- `/aws/lambda/rever-plaid-transfer`

### CloudWatch Alarms (if needed)
- `rever-plaid-api-error-rate`
- `rever-plaid-lambda-duration`

## Resource Tags

All resources should be tagged with:

```
Project: Rever
Environment: prod|dev|sandbox
ManagedBy: InfrastructureAsCode (if using IaC)
```

## Verification

To verify isolation, you can list resources with:

```bash
# List Lambda functions
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `rever-`)].FunctionName'

# List DynamoDB tables
aws dynamodb list-tables --query 'TableNames[?starts_with(@, `rever-`)]'

# List API Gateways
aws apigateway get-rest-apis --query 'items[?starts_with(name, `rever-`)].name'

# List Secrets
aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `rever/`)].Name'
```

## Wordflect Resources (For Reference)

To ensure no conflicts, Wordflect resources likely use:
- Prefix: `wordflect-` or `wf-`
- Separate API Gateway
- Separate Lambda functions
- Separate DynamoDB tables

**Never share resources between Rever and Wordflect.**

