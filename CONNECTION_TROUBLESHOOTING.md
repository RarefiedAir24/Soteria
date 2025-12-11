# Connection Troubleshooting Guide

## Error: "Could not connect to server"

This error means the iOS app cannot reach the local development server.

## Quick Checks

### 1. Is the server running?

```bash
curl http://localhost:8000/health
```

Should return:
```json
{"status":"ok","message":"Soteria local dev server is running"}
```

### 2. Are you using iOS Simulator or Physical Device?

**iOS Simulator:**
- ✅ Can access `localhost:8000` directly
- ✅ Should work automatically

**Physical Device:**
- ❌ Cannot access `localhost` (that's the device itself!)
- ✅ Need to use your Mac's IP address

## Solution for Physical Device

### Step 1: Find Your Mac's IP Address

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Example output:
```
inet 192.168.1.100 netmask 0xffffff00 broadcast 192.168.1.255
```

Your IP is: `192.168.1.100`

### Step 2: Update PlaidService.swift

Change:
```swift
#if DEBUG
private let apiGatewayURL = "http://localhost:8000"
#endif
```

To:
```swift
#if DEBUG
private let apiGatewayURL = "http://192.168.1.100:8000"  // Your Mac's IP
#endif
```

### Step 3: Allow Firewall Connections

1. **System Settings** → **Network** → **Firewall**
2. Click **Options...**
3. Allow connections on port 8000
4. Or temporarily disable firewall for testing

### Step 4: Verify Same Network

- Mac and iOS device must be on the **same Wi-Fi network**
- Check both devices are connected to the same router

## Testing Connection

### From Mac Terminal

```bash
# Test server is accessible
curl http://localhost:8000/health

# Test from device's perspective (if you know device IP)
# This won't work, but shows the concept
```

### From iOS App

1. Run app in DEBUG mode
2. Try to connect
3. Check Xcode console for detailed error messages

## Common Issues

### Issue: "Connection refused"

**Cause:** Server not running or wrong port

**Fix:**
```bash
cd local-dev-server
npm start
```

### Issue: "Network unreachable"

**Cause:** Wrong IP address or different network

**Fix:**
- Verify Mac's IP address
- Ensure device and Mac on same network
- Check firewall settings

### Issue: "Timeout"

**Cause:** Firewall blocking connection

**Fix:**
- Allow port 8000 in firewall
- Or disable firewall temporarily

## Alternative: Use iOS Simulator

If testing on physical device is problematic:

1. **Use iOS Simulator instead**
2. Simulator can access `localhost:8000` directly
3. No IP address configuration needed

## Quick Test

```bash
# 1. Start server
cd local-dev-server && npm start

# 2. Test from Mac
curl http://localhost:8000/health

# 3. If using physical device, test from device's network
# (You'll need to know device's IP or use a network tool)
```

## Still Having Issues?

1. Check server logs: `tail -f local-dev-server/server.log`
2. Check Xcode console for detailed error messages
3. Verify server is listening: `lsof -i :8000`
4. Try restarting the server: `./STOP_LOCAL_SERVER.sh && ./START_LOCAL_SERVER.sh`

