# Quick Fix: Physical Device Connection

## Problem
Getting "could not connect to server" error when testing on a physical iOS device.

## Solution

### Your Mac's IP Address: `10.0.0.52`

### Step 1: Update PlaidService.swift

Open `soteria/Services/PlaidService.swift` and change line 47:

**From:**
```swift
private let apiGatewayURL = "http://localhost:8000"
```

**To:**
```swift
private let apiGatewayURL = "http://10.0.0.52:8000"
```

### Step 2: Allow Firewall (if needed)

1. **System Settings** → **Network** → **Firewall**
2. Click **Options...**
3. Allow connections on port 8000
4. Or temporarily disable firewall for testing

### Step 3: Verify Same Network

- Mac and iOS device must be on the **same Wi-Fi network**
- Both should connect to the same router

### Step 4: Test

1. Restart the iOS app
2. Try connecting again
3. Should now connect successfully!

## Alternative: Use iOS Simulator

If you want to avoid IP configuration:

1. **Use iOS Simulator** instead of physical device
2. Simulator can access `localhost:8000` directly
3. No configuration needed

## Verify Server is Running

```bash
curl http://localhost:8000/health
```

Should return:
```json
{"status":"ok","message":"Soteria local dev server is running"}
```

