# AWS Cognito Migration Plan - Replace Firebase Auth

## Overview
Replace Firebase Authentication with AWS Cognito to consolidate on AWS and fix the broken app.

## Current State
- ✅ AWS infrastructure ready (API Gateway, Lambda, DynamoDB)
- ❌ Firebase Auth disabled (breaking the app)
- ❌ AWSDataService depends on Firebase tokens
- ❌ AuthService depends on Firebase

## Migration Steps

### Phase 1: Set Up AWS Cognito

1. **Create Cognito User Pool**
   ```bash
   aws cognito-idp create-user-pool \
     --pool-name soteria-users \
     --policies PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true} \
     --auto-verified-attributes email \
     --region us-east-1
   ```

2. **Create User Pool Client**
   ```bash
   aws cognito-idp create-user-pool-client \
     --user-pool-id <POOL_ID> \
     --client-name soteria-ios \
     --generate-secret \
     --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
     --region us-east-1
   ```

3. **Save Configuration**
   - User Pool ID
   - Client ID
   - Region (us-east-1)

### Phase 2: Update iOS App

#### 2.1 Add AWS SDK
Update `Podfile`:
```ruby
pod 'AWSCognitoIdentityProvider', '~> 2.40.0'
pod 'AWSCore', '~> 2.40.0'
```

#### 2.2 Create CognitoAuthService
New file: `soteria/Services/CognitoAuthService.swift`
- Replace Firebase Auth with Cognito
- Sign up, sign in, sign out
- Token management
- User state management

#### 2.3 Update AuthService
- Remove all Firebase code
- Use CognitoAuthService internally
- Keep same public API (minimal changes to views)

#### 2.4 Update AWSDataService
- Replace Firebase token retrieval with Cognito token
- Update `getUserId()` to use Cognito user ID
- Update all `getIDToken()` calls

#### 2.5 Update Lambda Functions
- Update Lambda authorizers to validate Cognito tokens
- Replace Firebase token validation with Cognito JWT verification

### Phase 3: Data Migration (if needed)

If you have existing Firebase users:
1. Export user data from Firebase
2. Create Cognito users programmatically
3. Migrate user data to DynamoDB

### Phase 4: Testing

1. Test sign up flow
2. Test sign in flow
3. Test token refresh
4. Test AWS API calls with Cognito tokens
5. Test data sync to DynamoDB

## Benefits

✅ **Single Provider** - Everything on AWS
✅ **No Firebase Dependencies** - Remove broken Firebase code
✅ **Better Control** - Full control over auth flow
✅ **Cost Effective** - Cognito free tier: 50K MAU
✅ **Scalable** - Cognito scales automatically
✅ **Secure** - Industry-standard JWT tokens

## Implementation Priority

1. **High Priority** (Fix broken app):
   - Set up Cognito User Pool
   - Create CognitoAuthService
   - Update AuthService
   - Update AWSDataService

2. **Medium Priority** (Full migration):
   - Update Lambda authorizers
   - Remove all Firebase code
   - Update documentation

3. **Low Priority** (Future):
   - User migration (if needed)
   - Advanced Cognito features (MFA, etc.)

## Estimated Time

- **Phase 1** (Cognito Setup): 30 minutes
- **Phase 2** (iOS Updates): 2-3 hours
- **Phase 3** (Lambda Updates): 1 hour
- **Phase 4** (Testing): 1-2 hours

**Total: ~5-7 hours**

## Next Steps

1. Create Cognito User Pool
2. Install AWS SDK in Podfile
3. Create CognitoAuthService
4. Update AuthService to use Cognito
5. Update AWSDataService
6. Test end-to-end flow
7. Remove Firebase dependencies

