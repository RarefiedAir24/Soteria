# Backend TestFlight Readiness Checklist

## 🔍 Current Backend Configuration

### API Gateway Endpoints

#### Main API Gateway: `ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod`
This is the primary API Gateway used by most services:

- **Plaid Integration** (`PlaidService.swift`)
  - `/plaid/create-link-token` (POST)
  - `/plaid/exchange-token` (POST)
  - `/plaid/transfer` (POST)
  - `/plaid/get-balance` (GET)

- **Authentication** (`CognitoAuthService.swift`)
  - `/soteria/auth/signup` (POST)
  - `/soteria/auth/signin` (POST)
  - `/soteria/auth/refresh` (POST)
  - `/soteria/auth/reset-password` (POST)
  - `/soteria/auth/confirm` (POST)

- **User Data** (`AWSDataService.swift`)
  - `/soteria/sync` (POST)
  - `/soteria/data` (GET)
  - `/soteria/app-name` (POST)

- **Avatar** (`AvatarService.swift`)
  - `/soteria/avatar/upload` (POST)
  - `/soteria/avatar/download` (GET)

- **Goal Photos** (`GoalPhotoService.swift`)
  - `/soteria/goal-photo/upload` (POST)
  - `/soteria/goal-photo/download` (GET)
  - `/soteria/goal-photo/delete` (DELETE)

- **Deposit Screenshots** (`DepositScreenshotAPIService.swift`)
  - `/soteria/deposit-screenshot/upload` (POST)
  - `/soteria/deposit-screenshot/download` (GET)

- **Shared Goals** (`SharedGoalService.swift`)
  - `/soteria/shared-goal/create` (POST)
  - `/soteria/shared-goal/invite` (POST)
  - `/soteria/shared-goal/accept` (POST)

- **Partner Loyalty** (`PartnerLoyaltyService.swift`)
  - `/soteria/partner/list` (GET)
  - `/soteria/partner/validate-member` (POST)
  - `/soteria/partner/redeem` (POST)

- **Apple Wallet** (`AppleWalletService.swift`)
  - `/soteria/apple-wallet/pass` (GET)

- **User Deletion** (`AuthService.swift`)
  - `/soteria/user/delete` (POST)

#### Member Number API Gateway: `g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod`
- **Member Numbers** (`MemberNumberService.swift`)
  - `/soteria/member-number` (GET)

---

## ✅ Pre-TestFlight Backend Checklist

### 1. AWS Infrastructure Verification

#### API Gateway Status
- [ ] **Main API Gateway** (`ue1psw3mt3`) is deployed to `prod` stage
- [ ] **Member Number API Gateway** (`g3ksyd36e5`) is deployed to `prod` stage
- [ ] All endpoints have CORS enabled
- [ ] All endpoints are publicly accessible (or have proper auth)
- [ ] API Gateway throttling limits are set appropriately

#### Lambda Functions Status
- [ ] All Lambda functions are deployed and active
- [ ] Lambda functions have proper IAM roles with required permissions
- [ ] Lambda environment variables are set correctly
- [ ] Lambda timeout settings are appropriate (recommend 30s for most)
- [ ] Lambda memory allocation is sufficient

**Key Lambda Functions to Verify:**
- [ ] `soteria-plaid-create-link-token`
- [ ] `soteria-plaid-exchange-token`
- [ ] `soteria-plaid-transfer`
- [ ] `soteria-plaid-get-balance`
- [ ] `soteria-auth-signup`
- [ ] `soteria-auth-signin`
- [ ] `soteria-auth-refresh`
- [ ] `soteria-auth-reset-password`
- [ ] `soteria-auth-confirm`
- [ ] `soteria-sync-user-data`
- [ ] `soteria-get-user-data`
- [ ] `soteria-get-app-name`
- [ ] `soteria-avatar-upload`
- [ ] `soteria-avatar-download`
- [ ] `soteria-goal-photo-upload`
- [ ] `soteria-goal-photo-download`
- [ ] `soteria-goal-photo-delete`
- [ ] `soteria-member-number`
- [ ] `soteria-partner-list`
- [ ] `soteria-partner-validate-member`
- [ ] `soteria-partner-redeem`
- [ ] `soteria-delete-user-data`

#### DynamoDB Tables
- [ ] All required tables exist and are active
- [ ] Table capacity is set appropriately (on-demand or provisioned)
- [ ] Backup is enabled (recommended for production)
- [ ] Point-in-time recovery is enabled (recommended)

**Required Tables:**
- [ ] `soteria-user-data`
- [ ] `soteria-purchase-intents`
- [ ] `soteria-goals`
- [ ] `soteria-regrets`
- [ ] `soteria-moods`
- [ ] `soteria-quiet-hours`
- [ ] `soteria-app-usage`
- [ ] `soteria-unblock-events`
- [ ] `soteria-app-token-mappings`
- [ ] `soteria-member-numbers`
- [ ] `soteria-partners`
- [ ] `soteria-redemptions`
- [ ] `rever-plaid-access-tokens` (or `soteria-plaid-access-tokens`)

#### S3 Buckets
- [ ] Avatar bucket exists and has proper permissions
- [ ] Goal photo bucket exists and has proper permissions
- [ ] Deposit screenshot bucket exists and has proper permissions
- [ ] CORS is configured on all buckets
- [ ] Lifecycle policies are set (if needed)

#### Secrets Manager
- [ ] Plaid credentials are stored securely
  - [ ] `PLAID_CLIENT_ID`
  - [ ] `PLAID_SECRET`
  - [ ] `PLAID_ENV` (should be `sandbox` for TestFlight)
- [ ] Unit API token is stored (if using Unit)
- [ ] Any other API keys are stored securely

### 2. Environment Configuration

#### Plaid Environment
- [ ] **CRITICAL**: Plaid is configured for **SANDBOX** environment
  - TestFlight builds should use sandbox, not production
  - Verify `PLAID_ENV` in Secrets Manager is set to `sandbox`
  - Verify Lambda functions read from correct secret

#### API Gateway URLs
- [ ] Verify all API Gateway URLs in iOS app match deployed endpoints
- [ ] Test endpoints are accessible (not blocked by firewall/VPC)
- [ ] Endpoints respond with proper error messages (not 500s)

### 3. Testing & Monitoring

#### Endpoint Testing
- [ ] Test authentication endpoints (signup, signin, refresh)
- [ ] Test Plaid endpoints with sandbox credentials
- [ ] Test data sync endpoints
- [ ] Test file upload/download endpoints
- [ ] Test member number generation
- [ ] Test partner loyalty endpoints

**Quick Test Commands:**
```bash
# Test member number API
curl "https://g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod/soteria/member-number?user_id=test-user"

# Test partner list
curl "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/partner/list"

# Test auth signup (will fail without proper body, but should return 400 not 500)
curl -X POST "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{}'
```

#### CloudWatch Monitoring
- [ ] CloudWatch logs are enabled for all Lambda functions
- [ ] Set up CloudWatch alarms for:
  - [ ] Lambda errors (error rate > 5%)
  - [ ] Lambda duration (p95 > 5s)
  - [ ] API Gateway 5xx errors
  - [ ] DynamoDB throttling
- [ ] Set up billing alerts (if using on-demand pricing)

### 4. Security & Permissions

#### IAM Roles
- [ ] Lambda execution roles have minimal required permissions
- [ ] API Gateway has proper resource policies
- [ ] S3 bucket policies restrict access appropriately
- [ ] DynamoDB access is restricted to Lambda functions

#### Authentication
- [ ] Cognito user pool is configured correctly
- [ ] Firebase authentication tokens are validated in Lambda
- [ ] API endpoints that require auth properly validate tokens

### 5. Cost Optimization

#### For TestFlight (Lower Traffic)
- [ ] DynamoDB tables use on-demand billing (or low provisioned capacity)
- [ ] Lambda functions use appropriate memory (128-256MB for most)
- [ ] S3 storage classes are appropriate (Standard is fine for TestFlight)
- [ ] CloudWatch log retention is set (7-14 days for TestFlight)

### 6. Deployment Scripts

#### Verify Deployment Scripts Are Ready
- [ ] All deployment scripts are in repository
- [ ] Scripts have proper error handling
- [ ] Scripts can be run multiple times safely (idempotent)

**Key Scripts:**
- [ ] `deploy-soteria-lambdas.sh`
- [ ] `connect-partner-lambdas-to-api-gateway.sh`
- [ ] `connect-auth-lambdas-to-api-gateway.sh`
- [ ] `connect-avatar-lambdas-to-api-gateway.sh`
- [ ] `connect-member-number-to-api-gateway.sh`
- [ ] `add-soteria-plaid-credentials.sh`

---

## 🚨 Critical Items for TestFlight

### Must-Have Before TestFlight
1. ✅ **Plaid in SANDBOX mode** (not production)
2. ✅ **All API Gateway endpoints deployed to `prod` stage**
3. ✅ **Authentication endpoints working**
4. ✅ **Basic data sync working**
5. ✅ **Error handling returns proper HTTP status codes**

### Nice-to-Have (Can Fix During Testing)
- CloudWatch alarms
- Detailed monitoring dashboards
- Cost optimization
- Advanced security hardening

---

## 🧪 Quick Verification Test

Run these tests to verify backend is ready:

```bash
# 1. Test API Gateway is accessible
curl -I "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/partner/list"

# 2. Test member number API
curl "https://g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod/soteria/member-number?user_id=test"

# 3. Test auth endpoint (should return 400, not 500)
curl -X POST "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected Results:**
- All endpoints should return HTTP responses (not connection errors)
- Auth endpoint should return 400 (bad request) not 500 (server error)
- Member number API should return JSON response

---

## 📋 Deployment Commands (If Needed)

If you need to redeploy or verify deployment:

```bash
# Deploy all Lambda functions
./deploy-soteria-lambdas.sh

# Connect Lambda functions to API Gateway
./connect-partner-lambdas-to-api-gateway.sh
./connect-auth-lambdas-to-api-gateway.sh
./connect-avatar-lambdas-to-api-gateway.sh
./connect-member-number-to-api-gateway.sh

# Add Plaid credentials to Secrets Manager
./add-soteria-plaid-credentials.sh
```

---

## ✅ Current Status

- **API Gateway URLs**: Configured in iOS app ✅
- **Lambda Functions**: Need verification ⚠️
- **DynamoDB Tables**: Need verification ⚠️
- **Plaid Environment**: Need confirmation (should be sandbox) ⚠️
- **S3 Buckets**: Need verification ⚠️
- **Secrets Manager**: Need verification ⚠️

---

## 🎯 Next Steps

1. **Verify AWS Console**: Check all resources are deployed
2. **Test Endpoints**: Run quick verification tests
3. **Confirm Plaid Sandbox**: Most critical for TestFlight
4. **Monitor First TestFlight Build**: Watch CloudWatch logs during first test

---

**Last Updated**: 2026-01-03
**Status**: Ready for verification ⚠️

