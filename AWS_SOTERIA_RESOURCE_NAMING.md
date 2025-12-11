# AWS Resource Naming Convention for Soteria

This document defines the naming convention for all AWS resources used by Soteria (renamed from Rever) to ensure complete isolation from Wordflect and other projects.

## Naming Convention

All AWS resources should be prefixed with `soteria-` or use the pattern `soteria_*` to clearly identify them as Soteria-specific resources.

## Resource Naming List

### API Gateway
- **API Name:** `soteria-api`
- **Stage:** `prod`, `dev`, or `sandbox`
- **Example URL:** `https://{api-id}.execute-api.{region}.amazonaws.com/prod`

### Lambda Functions
- `soteria-sync-user-data` - Sync user data to DynamoDB
- `soteria-get-user-data` - Get user data from DynamoDB
- `soteria-plaid-create-link-token` (if Plaid is still used)
- `soteria-plaid-exchange-token` (if Plaid is still used)
- `soteria-plaid-transfer` (if Plaid is still used)

### DynamoDB Tables
- `soteria-user-data` - Stores all user data (app names, purchase intents, etc.)
- `soteria-app-usage` - Stores app usage sessions
- `soteria-unblock-events` - Stores unblock event metrics
- `soteria-goals` - Stores savings goals
- `soteria-regrets` - Stores regret entries
- `soteria-moods` - Stores mood tracking data
- `soteria-quiet-hours` - Stores quiet hours schedules
- `soteria-plaid-access-tokens` - Stores Plaid access tokens (if Plaid is used)

### AWS Secrets Manager
- **Secret Name:** `soteria/plaid/credentials` (if Plaid is used)
- **Keys:**
  - `PLAID_CLIENT_ID`
  - `PLAID_SECRET`
  - `PLAID_ENV`

### IAM Roles
- `soteria-lambda-role` - IAM role for Lambda functions
- `soteria-api-gateway-role` - IAM role for API Gateway (if needed)

### IAM Policies
- `soteria-lambda-policy` - Policy for Lambda functions
- `soteria-secrets-policy` - Policy to access Secrets Manager
- `soteria-dynamodb-policy` - Policy to access DynamoDB

### CloudWatch Log Groups
- `/aws/lambda/soteria-sync-user-data`
- `/aws/lambda/soteria-get-user-data`
- `/aws/lambda/soteria-plaid-create-link-token` (if used)
- `/aws/lambda/soteria-plaid-exchange-token` (if used)
- `/aws/lambda/soteria-plaid-transfer` (if used)

### CloudWatch Alarms (if needed)
- `soteria-api-error-rate`
- `soteria-lambda-duration`

## Resource Tags

All resources should be tagged with:

```
Project: Soteria
Environment: prod|dev|sandbox
ManagedBy: InfrastructureAsCode (if using IaC)
```

## Migration from Rever

If you have existing `rever-` prefixed resources, you can either:

1. **Keep both** (recommended for gradual migration)
   - Old `rever-*` resources remain for backward compatibility
   - New `soteria-*` resources are created
   - Gradually migrate data and update iOS app

2. **Delete old and recreate** (clean slate)
   - Delete `rever-*` resources
   - Create new `soteria-*` resources
   - Update iOS app to use new endpoints

## Verification

To verify isolation, you can list resources with:

```bash
# List Lambda functions
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `soteria-`)].FunctionName'

# List DynamoDB tables
aws dynamodb list-tables --query 'TableNames[?starts_with(@, `soteria-`)]'

# List API Gateways
aws apigateway get-rest-apis --query 'items[?starts_with(name, `soteria-`)].name'

# List Secrets
aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `soteria/`)].Name'
```

## Wordflect Resources (For Reference)

To ensure no conflicts, Wordflect resources likely use:
- Prefix: `wordflect-` or `wf-`
- Separate API Gateway
- Separate Lambda functions
- Separate DynamoDB tables

**Never share resources between Soteria and Wordflect.**

## Old Rever Resources

Old `rever-*` resources can be:
- Kept for backward compatibility
- Deleted after migration is complete
- Tagged with `Status: Deprecated` for tracking

