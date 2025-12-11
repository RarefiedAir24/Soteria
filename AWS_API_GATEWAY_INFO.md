# AWS API Gateway Information - Rever

**⚠️ DEPRECATED: This is for the old "rever-plaid-api". See `AWS_MIGRATION_PLAN.md` for migrating to "soteria-api".**

## API Gateway Details

**API Name:** `rever-plaid-api` (OLD - Use `soteria-api` instead)
**API ID:** `vus7x2s6o7`
**Region:** `us-east-1`
**Created:** December 7, 2025

## Resources Created

### Root Resource
- **Path:** `/`
- **Resource ID:** `3lwrxzy173`

### Plaid Resource
- **Path:** `/plaid`
- **Resource ID:** `10hcx5`

### Endpoints
1. **Create Link Token**
   - **Path:** `/plaid/create-link-token`
   - **Resource ID:** `qylzql`
   - **Method:** POST (to be created when Lambda is ready)

2. **Exchange Public Token**
   - **Path:** `/plaid/exchange-public-token`
   - **Resource ID:** `eozfxc`
   - **Method:** POST (to be created when Lambda is ready)

3. **Transfer**
   - **Path:** `/plaid/transfer`
   - **Resource ID:** `xskcz9`
   - **Method:** POST (to be created when Lambda is ready)

## API Gateway URL

**Base URL:**
```
https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod
```

**Full Endpoints:**
- `https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod/plaid/create-link-token`
- `https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod/plaid/exchange-public-token`
- `https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod/plaid/transfer`

**⚠️ Note:** These URLs will only work after:
1. Lambda functions are created and connected
2. Methods (POST) are created for each resource
3. CORS is configured
4. API is deployed to `prod` stage

## Next Steps

1. ✅ API Gateway created
2. ✅ Resources created
3. ⏳ Create Lambda functions:
   - `rever-plaid-create-link-token`
   - `rever-plaid-exchange-token`
   - `rever-plaid-transfer`
4. ⏳ Connect Lambda functions to API Gateway resources
5. ⏳ Create POST methods for each resource
6. ⏳ Configure CORS
7. ⏳ Deploy API to `prod` stage
8. ✅ Update `PlaidService.swift` with API Gateway URL (DONE)

## Verification

To verify the API Gateway exists:
```bash
aws apigateway get-rest-api --rest-api-id vus7x2s6o7 --region us-east-1
```

To list all resources:
```bash
aws apigateway get-resources --rest-api-id vus7x2s6o7 --region us-east-1
```

## iOS App Configuration

The `PlaidService.swift` has been updated with the API Gateway URL:
```swift
private let awsApiGatewayURL = "https://vus7x2s6o7.execute-api.us-east-1.amazonaws.com/prod"
```

