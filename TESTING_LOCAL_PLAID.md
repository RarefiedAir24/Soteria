# Testing Plaid Integration Locally

## ✅ Server Status

**Local development server is running!**

- **URL:** http://localhost:8000
- **Status:** ✅ Running
- **Health Check:** http://localhost:8000/health

## Quick Test

### 1. Verify Server is Running

```bash
curl http://localhost:8000/health
```

Should return:
```json
{"status":"ok","message":"Soteria local dev server is running"}
```

### 2. Test Create Link Token

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

Should return a `link_token` if Plaid credentials are configured correctly.

## Testing with iOS App

### Step 1: Verify iOS App Configuration

The iOS app is already configured to use the local server in **DEBUG** mode:

```swift
#if DEBUG
private let apiGatewayURL = "http://localhost:8000"
#else
private let apiGatewayURL = "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
#endif
```

### Step 2: Run iOS App in DEBUG Mode

1. **Open Xcode**
2. **Select "Debug" scheme** (default)
3. **Run on iOS Simulator** (recommended for localhost)
4. **Or run on physical device** (see note below)

### Step 3: Test Plaid Connection

1. **Navigate to Settings** in the app
2. **Tap "Account"** → **"Profile"**
3. **Tap "Bank Connection"**
4. **Tap "Connect Accounts"**
5. **Watch server logs** for requests

### Step 4: Monitor Server Logs

The server logs all requests. Watch for:

```
🔗 [Local Dev] Creating Plaid link token...
✅ [Local Dev] Link token created successfully
```

## Testing on Physical Device

If testing on a **physical iOS device**, you need to use your Mac's IP address instead of `localhost`:

### Find Your Mac's IP Address

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
# Example output: inet 192.168.1.100
```

### Update PlaidService.swift

Temporarily change:
```swift
#if DEBUG
private let apiGatewayURL = "http://192.168.1.100:8000"  // Your Mac's IP
#endif
```

### Allow Firewall Connections

1. **System Settings** → **Network** → **Firewall**
2. Allow connections on port 8000
3. Or temporarily disable firewall for testing

## Server Management

### Start Server

```bash
# Option 1: Use the helper script
./START_LOCAL_SERVER.sh

# Option 2: Manual start
cd local-dev-server
npm start

# Option 3: Background process (already running)
cd local-dev-server
nohup node server.js > server.log 2>&1 &
```

### Stop Server

```bash
# Find and kill the process
pkill -f "node server.js"

# Or if using the PID file
kill $(cat local-dev-server/server.pid)
```

### View Server Logs

```bash
# If running in background
tail -f local-dev-server/server.log

# Or check Docker logs (if using Docker)
docker-compose logs -f plaid-backend
```

## Troubleshooting

### Server Won't Start

**Check:**
1. Port 8000 is available: `lsof -i :8000`
2. Node.js is installed: `node --version` (should be 20.x)
3. Dependencies installed: `cd local-dev-server && npm install`

### iOS App Can't Connect

**For Simulator:**
- Should work automatically with `localhost:8000`
- Check server is running: `curl http://localhost:8000/health`

**For Physical Device:**
- Use Mac's IP address instead of localhost
- Check firewall settings
- Verify device and Mac are on same network

### Plaid API Errors

**Check:**
1. `.env` file has correct credentials
2. `PLAID_ENV=sandbox` for testing
3. Credentials are valid at: https://dashboard.plaid.com/team/keys

### Access Token Lost

**Normal behavior:** Access tokens are stored in memory and lost on server restart.

**To reconnect:**
- Just reconnect your account in the app
- Or implement file-based storage for local dev

## Next Steps

1. ✅ Server is running
2. ✅ iOS app configured for local dev
3. ⏳ Test Plaid connection in app
4. ⏳ Verify all endpoints work
5. ⏳ Deploy to AWS when ready

## Production Deployment

When ready to deploy:

1. **Build for Release** in Xcode
2. **Deploy Lambda functions:**
   ```bash
   ./deploy-soteria-lambdas.sh
   ```
3. **App automatically uses production API** in Release mode

