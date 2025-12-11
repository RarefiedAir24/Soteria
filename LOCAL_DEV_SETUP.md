# Local Development Setup Guide

This guide explains how to set up and use the local development server for testing Plaid integration without deploying to AWS.

## Why Local Development?

**Benefits:**
- ✅ **Faster iteration** - Test changes instantly (no deployment)
- ✅ **Cost savings** - No AWS Lambda invocations during development
- ✅ **Better debugging** - See logs and errors immediately
- ✅ **Offline testing** - Can test without internet (with mocked responses)

## Prerequisites

- Node.js 20.x or later
- npm or yarn
- Docker (optional, but recommended)
- Plaid sandbox credentials

## Setup Steps

### 1. Install Dependencies

```bash
cd local-dev-server
npm install
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env and add your Plaid credentials
# Get them from: https://dashboard.plaid.com/team/keys
```

Required environment variables:
```env
PLAID_CLIENT_ID=your_client_id_here
PLAID_SECRET=your_secret_here
PLAID_ENV=sandbox
PORT=8000
```

### 3. Start Server

**Option A: Using Docker (Recommended)**
```bash
# From project root
docker-compose up

# Server runs at http://localhost:8000
```

**Option B: Using Node.js Directly**
```bash
cd local-dev-server
npm start

# Or with auto-reload
npm run dev
```

### 4. Verify Server is Running

```bash
curl http://localhost:8000/health
```

Should return:
```json
{
  "status": "ok",
  "message": "Soteria local dev server is running"
}
```

## iOS App Configuration

The iOS app is already configured to use the local server in DEBUG mode:

```swift
#if DEBUG
private let apiGatewayURL = "http://localhost:8000"
#else
private let apiGatewayURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
#endif
```

### Testing with iOS Simulator

The simulator can access `localhost:8000` directly - no changes needed!

### Testing with Physical Device

If testing on a physical device:

1. **Find your Mac's IP address:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   # Example: 192.168.1.100
   ```

2. **Update PlaidService.swift:**
   ```swift
   #if DEBUG
   private let apiGatewayURL = "http://192.168.1.100:8000"  // Your Mac's IP
   #endif
   ```

3. **Allow firewall connections:**
   - System Settings → Network → Firewall
   - Allow connections on port 8000

## Development Workflow

### Typical Development Cycle

1. **Start local server:**
   ```bash
   docker-compose up
   ```

2. **Make changes to Lambda functions:**
   - Edit files in `lambda/` directory
   - Copy changes to `local-dev-server/routes/`

3. **Test in iOS app:**
   - Run app in DEBUG mode
   - Test Plaid integration
   - Check server logs for debugging

4. **Deploy to AWS when ready:**
   ```bash
   ./deploy-soteria-lambdas.sh
   ```

### Hot Reload (Development)

If using `npm run dev` (nodemon), the server will automatically restart when you change files.

With Docker, you can also enable hot reload by mounting the code directory (already configured in `docker-compose.yml`).

## Available Endpoints

All endpoints match the AWS Lambda function paths:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/soteria/plaid/create-link-token` | POST | Create Plaid Link token |
| `/soteria/plaid/exchange-public-token` | POST | Exchange public token |
| `/soteria/plaid/get-accounts` | POST | Get user's accounts |
| `/soteria/plaid/get-balance` | POST | Get account balance |
| `/soteria/plaid/transfer` | POST | Initiate transfer |

## Request/Response Examples

### Create Link Token

**Request:**
```bash
curl -X POST http://localhost:8000/soteria/plaid/create-link-token \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_123",
    "client_name": "Soteria",
    "products": ["auth", "balance"],
    "country_codes": ["US"]
  }'
```

**Response:**
```json
{
  "link_token": "link-sandbox-xxx..."
}
```

### Exchange Public Token

**Request:**
```bash
curl -X POST http://localhost:8000/soteria/plaid/exchange-public-token \
  -H "Content-Type: application/json" \
  -d '{
    "public_token": "public-sandbox-xxx...",
    "user_id": "test_user_123"
  }'
```

**Response:**
```json
{
  "access_token": "access-sandbox-xxx...",
  "item_id": "item_xxx...",
  "accounts": [...]
}
```

## Differences from Production

### Storage
- **Local Dev**: Access tokens stored in memory (lost on server restart)
- **Production**: Access tokens stored in DynamoDB (persistent)

### Authentication
- **Local Dev**: Firebase Auth tokens accepted but not validated
- **Production**: Firebase Auth tokens validated by API Gateway

### Error Messages
- **Local Dev**: Detailed error messages with stack traces
- **Production**: Sanitized error messages for security

## Troubleshooting

### Server won't start

**Check:**
1. Port 8000 is available: `lsof -i :8000`
2. Node.js version: `node --version` (should be 20.x)
3. Dependencies installed: `npm install`

### iOS app can't connect

**For Simulator:**
- Make sure server is running: `curl http://localhost:8000/health`
- Check Xcode console for connection errors

**For Physical Device:**
- Use Mac's IP address instead of localhost
- Check firewall settings
- Verify device and Mac are on same network

### Plaid API errors

**Check:**
1. Credentials in `.env` file are correct
2. `PLAID_ENV=sandbox` for testing
3. Plaid dashboard shows sandbox credentials

### Access token lost

**Normal behavior:** Access tokens are stored in memory and lost on server restart.

**To persist:**
- Reconnect account (exchange token again)
- Or implement file-based storage for local dev

## Next Steps

1. **Test Plaid integration locally**
2. **Debug any issues**
3. **Deploy to AWS when ready:**
   ```bash
   ./deploy-soteria-lambdas.sh
   ```

## Additional Resources

- [Local Dev Server README](./local-dev-server/README.md)
- [Plaid Quickstart Guide](https://plaid.com/docs/quickstart/)
- [AWS Deployment Guide](./AWS_SETUP_INSTRUCTIONS.md)

