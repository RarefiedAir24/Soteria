# Local Development Quick Start

Get up and running with local Plaid development in 3 minutes!

## Step 1: Configure Environment

```bash
cd local-dev-server
cp .env.example .env
```

Edit `.env` and add your Plaid credentials:
```env
PLAID_CLIENT_ID=your_client_id_here
PLAID_SECRET=your_secret_here
PLAID_ENV=sandbox
```

## Step 2: Start Server

**Option A: Docker (Recommended)**
```bash
# From project root
docker-compose up
```

**Option B: Node.js**
```bash
cd local-dev-server
npm install
npm start
```

Server will run at: **http://localhost:8000**

## Step 3: Test iOS App

1. Open Xcode
2. Run app in **DEBUG** mode (default)
3. App will automatically connect to `http://localhost:8000`
4. Test Plaid integration!

## That's It! 🎉

The iOS app is already configured to use the local server in DEBUG mode.

**To switch back to production:**
- Just run the app in **RELEASE** mode
- Or change the scheme in Xcode

## Troubleshooting

**Server won't start?**
- Check port 8000 is free: `lsof -i :8000`
- Verify Node.js 20.x: `node --version`

**iOS can't connect?**
- Simulator: Should work automatically
- Physical device: Use Mac's IP address (see LOCAL_DEV_SETUP.md)

**Need help?**
- See [LOCAL_DEV_SETUP.md](./LOCAL_DEV_SETUP.md) for detailed guide
- See [local-dev-server/README.md](./local-dev-server/README.md) for server docs

