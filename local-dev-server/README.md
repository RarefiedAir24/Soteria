# Soteria Local Development Server

Local development server for testing Plaid integration without deploying to AWS.

## Quick Start

### Option 1: Using Docker (Recommended)

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit .env and add your Plaid credentials
# PLAID_CLIENT_ID=your_client_id
# PLAID_SECRET=your_secret

# 3. Start server
docker-compose up

# Server will be running at http://localhost:8000
```

### Option 2: Using Node.js Directly

```bash
# 1. Install dependencies
npm install

# 2. Copy environment file
cp .env.example .env

# 3. Edit .env and add your Plaid credentials
# PLAID_CLIENT_ID=your_client_id
# PLAID_SECRET=your_secret

# 4. Start server
npm start

# Or with auto-reload (requires nodemon)
npm run dev
```

## Configuration

### Environment Variables

Create a `.env` file with:

```env
PLAID_CLIENT_ID=your_client_id_here
PLAID_SECRET=your_secret_here
PLAID_ENV=sandbox
PORT=8000
```

Get your Plaid credentials from: https://dashboard.plaid.com/team/keys

## Endpoints

All endpoints match the AWS Lambda function paths:

- `POST /soteria/plaid/create-link-token` - Create Plaid Link token
- `POST /soteria/plaid/exchange-public-token` - Exchange public token for access token
- `POST /soteria/plaid/get-accounts` - Get user's accounts
- `POST /soteria/plaid/get-balance` - Get account balance
- `POST /soteria/plaid/transfer` - Initiate transfer (requires Transfer API setup)
- `GET /health` - Health check

## iOS App Configuration

The iOS app automatically uses the local server when running in **DEBUG** mode:

```swift
#if DEBUG
private let apiGatewayURL = "http://localhost:8000"
#else
private let apiGatewayURL = "https://your-api-gateway.execute-api.us-east-1.amazonaws.com/prod"
#endif
```

### Testing with iOS Simulator

The iOS Simulator can access `localhost:8000` directly.

### Testing with Physical Device

If testing on a physical device, you need to:

1. Find your Mac's IP address:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. Update `PlaidService.swift`:
   ```swift
   #if DEBUG
   private let apiGatewayURL = "http://YOUR_MAC_IP:8000"
   #endif
   ```

3. Make sure your Mac's firewall allows connections on port 8000

## Development Workflow

1. **Start local server:**
   ```bash
   docker-compose up
   # or
   npm start
   ```

2. **Run iOS app in DEBUG mode:**
   - Open Xcode
   - Select "Debug" scheme
   - Run on simulator or device

3. **Test Plaid integration:**
   - App will connect to `http://localhost:8000`
   - All requests logged in server console
   - No AWS costs!

## Differences from Production

### Storage
- **Local Dev**: Access tokens stored in memory (lost on restart)
- **Production**: Access tokens stored in DynamoDB (persistent)

### Authentication
- **Local Dev**: Firebase Auth tokens accepted but not validated
- **Production**: Firebase Auth tokens validated by API Gateway

### Error Handling
- **Local Dev**: Detailed error messages and stack traces
- **Production**: Sanitized error messages for security

## Troubleshooting

### "Connection refused" error

**Problem:** iOS app can't connect to server

**Solutions:**
1. Make sure server is running: `curl http://localhost:8000/health`
2. Check if port 8000 is in use: `lsof -i :8000`
3. For physical device, use Mac's IP address instead of localhost

### "Plaid credentials not configured" error

**Problem:** Missing or invalid Plaid credentials

**Solutions:**
1. Check `.env` file exists and has correct values
2. Verify credentials at: https://dashboard.plaid.com/team/keys
3. Make sure `PLAID_ENV=sandbox` for testing

### "No access token found" error

**Problem:** Access token not stored (server restarted)

**Solutions:**
1. Reconnect your account (exchange token again)
2. In production, tokens are stored in DynamoDB and persist

## Production Deployment

When ready to deploy:

1. **Build for production:**
   ```bash
   # In Xcode, select "Release" scheme
   ```

2. **Deploy Lambda functions:**
   ```bash
   ./deploy-soteria-lambdas.sh
   ```

3. **Verify API Gateway URL:**
   - Update `apiGatewayURL` in `PlaidService.swift` if needed
   - Production uses AWS API Gateway automatically

## Additional Resources

- [Plaid Quickstart Guide](https://plaid.com/docs/quickstart/)
- [Plaid API Reference](https://plaid.com/docs/api/)
- [AWS Lambda Deployment Guide](../AWS_SETUP_INSTRUCTIONS.md)

