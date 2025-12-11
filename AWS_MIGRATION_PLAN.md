# AWS Migration Plan: Rever → Soteria

This document outlines the plan to migrate AWS resources from `rever-` prefix to `soteria-` prefix.

## Current State

### Existing Rever Resources
- **API Gateway:** `rever-plaid-api` (ID: `vus7x2s6o7`)
- **Lambda Functions:**
  - `rever-plaid-create-link-token`
  - `rever-plaid-exchange-token`
  - `rever-plaid-transfer`
- **IAM Role:** `rever-plaid-lambda-role`
- **DynamoDB Table:** `rever-plaid-access-tokens` (if created)
- **Secrets Manager:** `rever/plaid/credentials` (if created)

## Migration Strategy

### Option 1: Parallel Deployment (Recommended)
Keep old resources running while creating new ones. This allows:
- Zero downtime migration
- Gradual iOS app updates
- Easy rollback if issues occur

### Option 2: Clean Slate
Delete old resources and create new ones. This is cleaner but requires:
- Downtime during migration
- All iOS app updates at once
- No rollback option

**We recommend Option 1 for safety.**

## Migration Steps

### Phase 1: Create New Soteria Resources

1. **Create New API Gateway**
   ```bash
   ./create-soteria-api-gateway.sh
   ```
   - Name: `soteria-api`
   - Endpoints: `/soteria/sync`, `/soteria/data`, `/plaid/*` (if needed)

2. **Create DynamoDB Tables**
   ```bash
   # User data table
   aws dynamodb create-table \
     --table-name soteria-user-data \
     --attribute-definitions AttributeName=user_id,AttributeType=S AttributeName=data_type,AttributeType=S \
     --key-schema AttributeName=user_id,KeyType=HASH AttributeName=data_type,KeyType=RANGE \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1 \
     --tags Key=Project,Value=Soteria Key=Environment,Value=prod
   ```

3. **Create Lambda Functions**
   - `soteria-sync-user-data` - Save user data to DynamoDB
   - `soteria-get-user-data` - Get user data from DynamoDB
   - (Optionally rename Plaid functions if still using Plaid)

4. **Create IAM Roles**
   - `soteria-lambda-role` - With DynamoDB and Secrets Manager permissions

### Phase 2: Update iOS App

1. **Update API Gateway URL**
   - Replace old `rever-plaid-api` URL with new `soteria-api` URL
   - Update in any service files that reference AWS

2. **Update Service Classes**
   - Modify services to call new endpoints
   - Keep UserDefaults as fallback during migration

### Phase 3: Data Migration (If Needed)

If you have existing data in old DynamoDB tables:
```bash
# Export from old table
aws dynamodb scan --table-name rever-plaid-access-tokens > old-data.json

# Import to new table (with user_id updates if needed)
# Use AWS Data Pipeline or custom script
```

### Phase 4: Cleanup (After Verification)

Once new resources are working:
1. Tag old resources with `Status: Deprecated`
2. Monitor for 30 days
3. Delete old resources if no issues

## New API Gateway Endpoints

### Data Sync Endpoints

**POST /soteria/sync**
- Save user data to DynamoDB
- Body: `{ "user_id": "...", "data_type": "...", "data": {...} }`

**GET /soteria/data**
- Get user data from DynamoDB
- Query: `?user_id=...&data_type=...`

### Plaid Endpoints (If Still Using)

**POST /plaid/create-link-token**
**POST /plaid/exchange-public-token**
**POST /plaid/transfer**

## DynamoDB Schema

### soteria-user-data Table

**Partition Key:** `user_id` (String) - Firebase user ID
**Sort Key:** `data_type` (String) - Type of data (e.g., "app_names", "purchase_intents")

**Attributes:**
- `data` (Map) - The actual data
- `updated_at` (Number) - Timestamp
- `created_at` (Number) - Timestamp

**Data Types:**
- `app_names` - App name mappings
- `purchase_intents` - Purchase intent records
- `unblock_events` - Unblock event metrics
- `app_usage` - App usage sessions
- `goals` - Savings goals
- `regrets` - Regret entries
- `moods` - Mood tracking data
- `quiet_hours` - Quiet hours schedules

## Testing Checklist

- [ ] New API Gateway created and deployed
- [ ] Lambda functions created and connected
- [ ] DynamoDB tables created
- [ ] IAM roles and policies configured
- [ ] CORS configured on API Gateway
- [ ] iOS app updated with new API Gateway URL
- [ ] Test data sync (save and retrieve)
- [ ] Verify data persists correctly
- [ ] Test with multiple users
- [ ] Monitor CloudWatch logs for errors

## Rollback Plan

If issues occur:
1. Revert iOS app to use old `rever-plaid-api` URL
2. Old resources remain functional
3. Fix issues with new resources
4. Retry migration

## Cost Impact

- **API Gateway:** Free tier includes 1M requests/month
- **Lambda:** Free tier includes 1M requests/month
- **DynamoDB:** Free tier includes 25GB storage
- **Total:** Should remain within free tier for development

## Timeline

- **Phase 1:** 1-2 hours (creating resources)
- **Phase 2:** 1-2 hours (updating iOS app)
- **Phase 3:** 1 hour (data migration if needed)
- **Phase 4:** 30 days monitoring before cleanup

## Notes

- Old `rever-*` resources can coexist with new `soteria-*` resources
- No need to delete old resources immediately
- Tag old resources for easy identification
- Update documentation as you go

