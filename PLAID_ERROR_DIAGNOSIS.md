# Plaid Connection Error Diagnosis

## Error: "Internal server error" when connecting accounts

### Current Status
- ✅ Lambda function exists: `soteria-plaid-create-link-token`
- ✅ Lambda has credentials configured
- ✅ API Gateway integration is set up (AWS_PROXY)
- ✅ Lambda permissions are correct
- ❌ Getting "Internal server error" from API Gateway

### Most Likely Causes

1. **Lambda Function Error**: The Lambda is throwing an error when executing
2. **Plaid SDK Issue**: The Plaid client might be failing to initialize
3. **Missing Dependencies**: Node modules might not be properly packaged

### How to Diagnose

#### Step 1: Check CloudWatch Logs (AWS Console)
1. Go to AWS Console → CloudWatch → Log Groups
2. Find: `/aws/lambda/soteria-plaid-create-link-token`
3. Check recent log streams for errors
4. Look for:
   - Plaid API errors
   - Missing environment variables
   - Module import errors

#### Step 2: Test Lambda Function (AWS Console)
1. Go to AWS Console → Lambda → Functions
2. Select `soteria-plaid-create-link-token`
3. Click "Test" tab
4. Create a test event:
```json
{
  "httpMethod": "POST",
  "body": "{\"user_id\":\"test123\",\"client_name\":\"Soteria\",\"products\":[\"auth\",\"balance\"],\"country_codes\":[\"US\"],\"language\":\"en\"}"
}
```
5. Click "Test" and check the execution result

#### Step 3: Verify Environment Variables
Check that these are set in Lambda configuration:
- `PLAID_CLIENT_ID`: `your_client_id_here`
- `PLAID_SECRET`: `your_secret_here`
- `PLAID_ENV`: `sandbox`

#### Step 4: Check Lambda Code Package
The Lambda function needs the `plaid` npm package. Verify:
1. Lambda function code size should be > 1MB (includes node_modules)
2. Check if `node_modules/plaid` exists in the deployment package

### Quick Fix: Redeploy Lambda

If dependencies are missing, redeploy:

```bash
cd lambda/soteria-plaid-create-link-token
npm install --production
cd ../..
./deploy-soteria-lambdas.sh
```

### Common Errors

1. **"Cannot find module 'plaid'"**
   - Fix: Redeploy Lambda with dependencies

2. **"Invalid client_id or secret"**
   - Fix: Check environment variables in Lambda configuration

3. **"Plaid API error"**
   - Fix: Check Plaid dashboard for API status
   - Verify credentials are for sandbox environment

4. **"Timeout"**
   - Fix: Increase Lambda timeout (currently 30s)

### Next Steps

1. **Check CloudWatch Logs** - This will show the actual error
2. **Test Lambda in Console** - Verify it works independently
3. **Redeploy if needed** - Ensure all dependencies are included

### If Still Failing

Share the CloudWatch log output and we can diagnose further.

