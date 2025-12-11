# AWS Setup Summary for Soteria

Quick reference for setting up AWS resources for Soteria (migrated from Rever).

## Quick Start

1. **Create New API Gateway:**
   ```bash
   ./create-soteria-api-gateway.sh
   ```
   This creates `soteria-api` with endpoints for data sync.

2. **Create DynamoDB Tables:**
   See `AWS_MIGRATION_PLAN.md` for table schemas.

3. **Create Lambda Functions:**
   - `soteria-sync-user-data` - Save user data
   - `soteria-get-user-data` - Get user data

4. **Update iOS App:**
   - Replace old API Gateway URL with new one
   - Update service classes to use new endpoints

## Key Resources

- **API Gateway:** `soteria-api`
- **DynamoDB Tables:** `soteria-user-data`, `soteria-app-usage`, etc.
- **Lambda Functions:** `soteria-*` prefix
- **IAM Roles:** `soteria-lambda-role`

## Documentation

- **`AWS_SOTERIA_RESOURCE_NAMING.md`** - Complete naming convention
- **`AWS_MIGRATION_PLAN.md`** - Detailed migration steps
- **`create-soteria-api-gateway.sh`** - Script to create API Gateway

## Old Resources (Deprecated)

Old `rever-*` resources can be kept for backward compatibility or deleted after migration:
- `rever-plaid-api` (API Gateway)
- `rever-plaid-*` (Lambda functions)
- `rever-plaid-lambda-role` (IAM role)

See `AWS_MIGRATION_PLAN.md` for migration strategy.

