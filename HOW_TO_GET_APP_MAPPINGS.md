# How to Get App Token Mappings

## Overview

The iOS app automatically logs token hashes when you select apps. Follow these steps to collect them and populate the database.

## Step-by-Step Process

### Step 1: Select Apps in iOS App

1. **Open the iOS app** (in Xcode or on device)
2. **Go to Settings** → **App Monitoring** → **Select Apps**
3. **Select apps** you want to map (e.g., Amazon, Uber Eats, DoorDash)
4. **Wait 6+ seconds** (the app needs time to generate hashes and call backend)

### Step 2: Check Xcode Console Logs

1. **Open Xcode Console** (View → Debug Area → Activate Console, or `Cmd+Shift+Y`)
2. **Look for these log messages:**
   ```
   🔍 [DeviceActivityService] Starting auto-naming from backend...
   🔍 [DeviceActivityService] Token 0 hash: 1234567890
   🔍 [DeviceActivityService] Token 1 hash: 0987654321
   🔍 [DeviceActivityService] Token 2 hash: 1122334455
   ✅ [DeviceActivityService] Backend returned X app name(s)
   ```

3. **Copy the hash values** (the numbers after "hash: ")

### Step 3: Identify Which App is Which

**Important:** The token hashes are logged in the **order** apps were selected, but you need to identify which app corresponds to which hash.

**Method 1: Select One App at a Time (Easiest)**
1. Select only **one app** (e.g., Amazon)
2. Check console: `Token 0 hash: 1234567890`
3. Note: "Amazon" → `1234567890`
4. Clear selection, select next app, repeat

**Method 2: Select Multiple Apps and Identify by Index**
1. Select apps in a specific order (e.g., Amazon, then Uber Eats, then DoorDash)
2. Note the order you selected them
3. Match hashes to apps by index:
   - Token 0 = First app selected
   - Token 1 = Second app selected
   - etc.

**Method 3: Use App Names from Backend Response**
- If backend returns names, you'll see:
  ```
  ✅ [DeviceActivityService] Auto-named app 0: Amazon (from backend)
  ✅ [DeviceActivityService] Auto-named app 1: Uber Eats (from backend)
  ```
- This tells you which hash maps to which app

### Step 4: Add Mappings to Database

**Option A: Using Script (Recommended)**

1. **Edit `populate-app-mappings.sh`:**
   ```bash
   declare -A APP_MAPPINGS=(
       ["1234567890"]="Amazon"           # Token 0 hash → App name
       ["0987654321"]="Uber Eats"        # Token 1 hash → App name
       ["1122334455"]="DoorDash"         # Token 2 hash → App name
       # Add more as you discover them
   )
   ```

2. **Run the script:**
   ```bash
   ./populate-app-mappings.sh
   ```

**Option B: Using AWS Console**

1. Go to [DynamoDB Console](https://console.aws.amazon.com/dynamodb)
2. Select table: `soteria-app-token-mappings`
3. Click **"Create item"**
4. Add:
   - `token_hash`: `1234567890` (your hash)
   - `app_name`: `Amazon`
   - `created_at`: Current timestamp (number)
   - `updated_at`: Current timestamp (number)
5. Click **"Create item"**

**Option C: Using AWS CLI**

```bash
aws dynamodb put-item \
  --table-name soteria-app-token-mappings \
  --item '{
    "token_hash": {"S": "1234567890"},
    "app_name": {"S": "Amazon"},
    "created_at": {"N": "1701234567890"},
    "updated_at": {"N": "1701234567890"}
  }' \
  --region us-east-1
```

## Example: Complete Workflow

### 1. Select Amazon App

**In iOS App:**
- Settings → App Monitoring → Select Apps
- Select "Amazon"
- Wait 6+ seconds

**In Xcode Console:**
```
🔍 [DeviceActivityService] Starting auto-naming from backend...
🔍 [DeviceActivityService] Token 0 hash: 1234567890
⚠️ [DeviceActivityService] Backend returned 0 app name(s)
```

**Result:** Amazon → hash `1234567890`

### 2. Add to Database

```bash
aws dynamodb put-item \
  --table-name soteria-app-token-mappings \
  --item '{
    "token_hash": {"S": "1234567890"},
    "app_name": {"S": "Amazon"},
    "created_at": {"N": "1701234567890"},
    "updated_at": {"N": "1701234567890"}
  }' \
  --region us-east-1
```

### 3. Test

**Select Amazon again in iOS app:**
- Wait 6+ seconds
- Check console:
  ```
  ✅ [DeviceActivityService] Backend returned 1 app name(s)
  ✅ [DeviceActivityService] Auto-named app 0: Amazon (from backend)
  ```

**Success!** The app is now automatically named.

## Tips for Efficient Collection

### 1. Batch Collection

Create a list of apps to map, then:
1. Select apps one at a time
2. Note hash for each
3. Add all to database at once

### 2. Use Script for Multiple Apps

Edit `populate-app-mappings.sh` with all your mappings:
```bash
declare -A APP_MAPPINGS=(
    ["1234567890"]="Amazon"
    ["0987654321"]="Uber Eats"
    ["1122334455"]="DoorDash"
    ["2233445566"]="Target"
    ["3344556677"]="Walmart"
    # ... add more
)
```

Then run: `./populate-app-mappings.sh`

### 3. Verify Hash Consistency

**Important:** Test that the same app produces the same hash:
1. Select Amazon on Device A → Note hash
2. Select Amazon on Device B → Note hash
3. If hashes match → Good! Hash is consistent
4. If hashes differ → May need different approach

### 4. Common Apps to Map First

Start with these popular apps:
- **Shopping:** Amazon, Target, Walmart, eBay
- **Food Delivery:** Uber Eats, DoorDash, Grubhub, Postmates
- **Ride-Sharing:** Uber, Lyft
- **Social:** Instagram, Facebook, TikTok, Twitter
- **Entertainment:** Netflix, Hulu, Disney+, YouTube
- **Gaming:** App Store games, etc.

## Troubleshooting

### Issue: No hash logs appearing

**Possible causes:**
- Didn't wait 6+ seconds after selecting apps
- Apps weren't actually selected
- Console not showing logs

**Fix:**
- Wait longer (10+ seconds)
- Re-select apps
- Check Xcode console filters

### Issue: Hash is different on different devices

**This is a problem!** Hash should be consistent.

**Possible causes:**
- Different iOS versions
- Different app builds
- ApplicationToken hashValue inconsistency

**Fix:**
- Test on same iOS version
- Use same app build
- If still inconsistent, may need different hashing method

### Issue: Backend returns 0 names

**This is normal** if the hash isn't in the database yet.

**Fix:**
- Add the hash to the database (see Step 4 above)
- Select the app again
- Should now return the name

## Quick Reference

**Console log format:**
```
🔍 [DeviceActivityService] Token {index} hash: {hash}
```

**Database table:** `soteria-app-token-mappings`

**Key field:** `token_hash` (String)

**Value field:** `app_name` (String)

**Endpoint:** `POST /soteria/app-name`

**Request:** `{"token_hashes": ["hash1", "hash2"]}`

**Response:** `{"app_names": {"hash1": "Amazon", "hash2": "Uber Eats"}}`

