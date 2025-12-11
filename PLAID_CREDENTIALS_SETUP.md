# Plaid Credentials Setup

## Your Plaid Client ID
```
69352338b821ae002254a4e1
```

## Next Steps

### 1. Get Your Secret
1. Go to: https://dashboard.plaid.com/developers/keys
2. Find your **Sandbox Secret** (click to reveal)
3. Copy it

### 2. Add Credentials to Lambda Functions

Once you have both Client ID and Secret, run:

```bash
./add-soteria-plaid-credentials.sh 69352338b821ae002254a4e1 YOUR_SECRET
```

Replace `YOUR_SECRET` with your actual Secret from the dashboard.

### 3. Verify Setup

After running the script, verify the credentials are set:

```bash
aws lambda get-function-configuration \
  --function-name soteria-plaid-create-link-token \
  --region us-east-1 \
  --query 'Environment.Variables' \
  --output json
```

You should see:
- `PLAID_CLIENT_ID` = `69352338b821ae002254a4e1`
- `PLAID_SECRET` = (your secret)
- `PLAID_ENV` = `sandbox`

## Important Notes

- ⚠️ **Never commit your Secret to git**
- ✅ The Client ID is safe to share (it's public)
- ✅ Keep your Secret secure
- ✅ For production, use AWS Secrets Manager instead

## What This Does

The script will set environment variables on all 4 Lambda functions:
- `soteria-plaid-create-link-token`
- `soteria-plaid-exchange-token`
- `soteria-plaid-get-balance`
- `soteria-plaid-transfer`

## After Adding Credentials

1. Test link token creation
2. Test account connection in the app
3. Use sandbox test credentials: `user_good` / `pass_good`

