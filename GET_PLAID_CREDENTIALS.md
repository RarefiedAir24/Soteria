# How to Get Plaid Credentials

## Step 1: Create Plaid Account

1. Go to [Plaid Dashboard](https://dashboard.plaid.com/signup)
2. Sign up for a developer account (free for sandbox)
3. Verify your email

## Step 2: Get Your Credentials

1. Log in to [Plaid Dashboard](https://dashboard.plaid.com/)
2. Navigate to **Team Settings** → **Keys**
3. You'll see credentials for different environments:
   - **Sandbox** - For testing (free)
   - **Development** - For development testing
   - **Production** - For live apps (requires approval)

## Step 3: Copy Your Sandbox Credentials

For initial testing, use **Sandbox** credentials:

- **Client ID**: Found in the "Sandbox" section
- **Secret**: Found in the "Sandbox" section (click to reveal)

**Example format:**
- Client ID: `5f8a9b2c3d4e5f6a7b8c9d0`
- Secret: `abc123def456ghi789jkl012mno345pqr`

## Step 4: Add Credentials to Lambda

Once you have your credentials, run:

```bash
cd /Users/frankschioppa/Desktop/rever
./add-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET
```

Or manually update each Lambda function in AWS Console:
1. Go to AWS Lambda Console
2. Select each function (`rever-plaid-create-link-token`, etc.)
3. Go to **Configuration** → **Environment variables**
4. Add:
   - `PLAID_CLIENT_ID` = your client ID
   - `PLAID_SECRET` = your secret
   - `PLAID_ENV` = `sandbox`

## Important Notes

- **Sandbox credentials are free** - perfect for testing
- **Never commit credentials to git** - they're sensitive
- **For production**, use AWS Secrets Manager instead of environment variables
- **Sandbox test credentials** for Plaid Link:
  - Username: `user_good`
  - Password: `pass_good`

## Quick Link

Get your credentials here: https://dashboard.plaid.com/developers/keys

