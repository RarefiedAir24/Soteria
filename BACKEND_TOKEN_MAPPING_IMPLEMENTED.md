# Backend Token Mapping Implementation ✅

## Overview

Automatic app naming is now implemented using backend token hash mapping. When users select apps, the system automatically looks up app names from a backend database, eliminating the need for manual naming.

## What Was Implemented

### 1. **Lambda Function** ✅
- **File:** `lambda/soteria-get-app-name/index.js`
- **Purpose:** Maps ApplicationToken hashes to app names
- **Endpoint:** `POST /soteria/app-name`
- **Features:**
  - Batch lookup (handles up to 100 hashes per request)
  - Returns mapping of hash → app name
  - Handles missing mappings gracefully

### 2. **AWSDataService Enhancement** ✅
- **New Method:** `getAppNamesFromTokens(tokenHashes: [String])`
- **Purpose:** Calls backend API to get app names
- **Returns:** Dictionary mapping token hash → app name
- **Error Handling:** Throws errors for network/parsing issues

### 3. **DeviceActivityService Auto-Naming** ✅
- **New Method:** `autoNameAppsFromBackend()`
- **Trigger:** Automatically called when apps are selected
- **Process:**
  1. Generates token hashes from ApplicationToken.hashValue
  2. Calls backend API with hashes
  3. Updates app names from backend response
  4. Falls back to generic names if backend fails
- **Timing:** Runs 6 seconds after app selection (non-blocking)

### 4. **Removed Mandatory Naming** ✅
- **AppNamingView:** Now optional (users can customize if they want)
- **SettingsView:** No longer forces naming screen
- **Fallback:** Generic names assigned automatically if backend fails

## How It Works

### Flow Diagram

```
User Selects Apps
    ↓
DeviceActivityService.selectedApps.didSet
    ↓
Wait 6 seconds (non-blocking)
    ↓
autoNameAppsFromBackend()
    ↓
Generate Token Hashes
    ↓
Call Backend API: getAppNamesFromTokens()
    ↓
Backend Looks Up in DynamoDB
    ↓
Return App Names
    ↓
Update appNames Dictionary
    ↓
Save to UserDefaults
    ↓
Done! Apps are automatically named
```

### Token Hash Generation

```swift
// ApplicationToken is Hashable
let hash = String(token.hashValue)
// Example: "1234567890"
```

### Backend Request

```json
POST /soteria/app-name
{
  "token_hashes": ["1234567890", "0987654321"]
}
```

### Backend Response

```json
{
  "success": true,
  "app_names": {
    "1234567890": "Amazon",
    "0987654321": "Uber Eats"
  },
  "found_count": 2,
  "total_requested": 2
}
```

### Fallback Behavior

If backend lookup fails:
- Uses generic names: "Shopping App" (single app) or "App 1", "App 2" (multiple)
- Saves generic names to UserDefaults
- Users can still customize names later

## Backend Setup Required

### 1. DynamoDB Table

**Table Name:** `soteria-app-token-mappings`

**Schema:**
- Partition Key: `token_hash` (String)
- Attributes: `app_name` (String), `bundle_id` (String, optional), `category` (String, optional)

### 2. Lambda Function

**Function Name:** `soteria-get-app-name`

**Deployment:**
```bash
cd lambda/soteria-get-app-name
npm install
zip -r function.zip index.js node_modules package.json
# Deploy to AWS Lambda
```

### 3. API Gateway

**Endpoint:** `POST /soteria/app-name`

**Integration:** Lambda function `soteria-get-app-name`

**CORS:** Enabled

### 4. Database Population

You'll need to populate the DynamoDB table with app mappings. Options:

1. **Manual Entry:** Add known apps manually
2. **Bulk Import:** Use AWS CLI or Lambda function
3. **User Feedback:** Allow users to correct names, send back to backend
4. **App Store API:** Use App Store Search API to identify apps

## iOS Code Changes

### DeviceActivityService.swift

**Added:**
- `autoNameAppsFromBackend()` method
- Automatic call in `selectedApps.didSet` (6-second delay)

**Modified:**
- App naming is now automatic (no user action required)

### AWSDataService.swift

**Added:**
- `getAppNamesFromTokens(tokenHashes:)` method
- Backend API call to `/soteria/app-name`

### AppNamingView.swift

**Modified:**
- Removed mandatory naming requirement
- Changed messaging to "Apps are automatically named"
- Added "Done" button (naming is optional)
- Shows "Auto-named" indicator for backend-provided names

### SettingsView.swift

**Modified:**
- Removed automatic naming screen prompt
- Users can still access naming via "Manage Apps"

## Testing

### Test Backend Lookup

1. **Populate database:**
   - Add test mappings to DynamoDB
   - Example: `token_hash: "1234567890" → app_name: "Amazon"`

2. **Select apps in iOS app:**
   - Select Amazon app
   - Wait 6+ seconds
   - Check console logs for:
     - `🔍 [DeviceActivityService] Starting auto-naming from backend...`
     - `✅ [DeviceActivityService] Backend returned 1 app name(s)`
     - `✅ [DeviceActivityService] Auto-named app 0: Amazon`

3. **Verify:**
   - App name should be "Amazon" (not "App 1")
   - Name persists across app restarts

### Test Fallback

1. **Select unknown app:**
   - Select an app not in database
   - Wait 6+ seconds
   - Check console logs for:
     - `⚠️ [DeviceActivityService] Failed to get app names from backend`
     - `💾 [DeviceActivityService] Saved generic fallback names`

2. **Verify:**
   - App name should be "Shopping App" or "App 1"
   - User can still customize name later

## Benefits

✅ **Zero User Burden:**
- Apps are automatically named
- No manual input required
- Works immediately after app selection

✅ **Scalable:**
- Backend database can grow over time
- New apps can be added to database
- Works for any number of apps

✅ **Graceful Fallback:**
- If backend fails, uses generic names
- App still works normally
- Users can customize if needed

✅ **Persistent:**
- Names saved to UserDefaults
- Persist across app restarts
- Can sync to AWS if enabled

## Next Steps

1. **Deploy Backend:**
   - Create DynamoDB table
   - Deploy Lambda function
   - Create API Gateway endpoint
   - Update API URL in `AWSDataService.swift`

2. **Populate Database:**
   - Add common apps (Amazon, Uber Eats, DoorDash, etc.)
   - Use token hashes from test devices
   - Build mapping over time

3. **Monitor:**
   - Check CloudWatch logs
   - Monitor Lambda invocations
   - Track DynamoDB reads

4. **Iterate:**
   - Add more apps to database
   - Improve fallback names
   - Consider user feedback loop

## Notes

- **Token Hash Stability:** `ApplicationToken.hashValue` is consistent for the same app on the same device, but may differ across devices (privacy feature)
- **Backend Dependency:** App naming now depends on backend availability. Fallback ensures app still works if backend is down.
- **Database Growth:** As more users use the app, the database will grow with more app mappings.
- **Privacy:** Token hashes don't reveal app identity directly - they're opaque identifiers that require database lookup.

## Files Created/Modified

**Created:**
- `lambda/soteria-get-app-name/index.js`
- `lambda/soteria-get-app-name/package.json`
- `BACKEND_TOKEN_MAPPING_SETUP.md`
- `BACKEND_TOKEN_MAPPING_IMPLEMENTED.md`

**Modified:**
- `soteria/Services/DeviceActivityService.swift`
- `soteria/Services/AWSDataService.swift`
- `soteria/Views/AppNamingView.swift`
- `soteria/Views/SettingsView.swift`

