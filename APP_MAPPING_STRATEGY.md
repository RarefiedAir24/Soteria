# App Token Mapping Strategy

## Overview

The app token mapping system uses a **global, pre-populated database** to map `ApplicationToken` hashes to human-readable app names.

## How It Works

### 1. Token Hash Generation

When a user selects apps in the iOS app:
- Each app has an `ApplicationToken` (provided by Apple's FamilyControls framework)
- The app generates a **hash** from the token (consistent across all users for the same app)
- Example: Amazon's token always hashes to `1234567890` for all users

### 2. Global Mapping Table

The DynamoDB table `soteria-app-token-mappings` stores:
- **Key:** `token_hash` (String) - The hash of the ApplicationToken
- **Value:** `app_name` (String) - Human-readable app name (e.g., "Amazon", "Uber Eats")

**Important:** This is a **global** table, not user-specific. Once we map a token hash to "Amazon", all users who select Amazon will automatically get "Amazon" as the app name.

### 3. Lookup Process

1. User selects apps in iOS app
2. App generates token hashes for selected apps
3. App calls backend: `POST /soteria/app-name` with `{"token_hashes": ["hash1", "hash2"]}`
4. Backend looks up hashes in DynamoDB table
5. Returns mapping: `{"hash1": "Amazon", "hash2": "Uber Eats"}`
6. App automatically names the apps

## Database Population Strategy

### Option 1: Pre-Populate (Recommended)

**Pre-populate the database with common apps** before launch:

1. **Collect token hashes** from test devices:
   - Select common apps (Amazon, Uber Eats, DoorDash, etc.)
   - Check console logs for token hashes
   - Add mappings to database

2. **Benefits:**
   - Users get proper names immediately
   - No need to wait for backend lookup
   - Better user experience

3. **How to populate:**
   ```bash
   # Edit populate-app-mappings.sh with your mappings
   declare -A APP_MAPPINGS=(
       ["1234567890"]="Amazon"
       ["0987654321"]="Uber Eats"
       ["1122334455"]="DoorDash"
       # Add more as you discover them
   )
   
   ./populate-app-mappings.sh
   ```

### Option 2: On-Demand Population

**Populate as users select apps:**

1. When a user selects an app that's not in the database:
   - Backend returns empty result
   - App uses generic name (e.g., "App 0", "App 1")
   - Admin can later add the mapping manually

2. **Benefits:**
   - No upfront work
   - Database grows organically

3. **Drawbacks:**
   - Users see generic names initially
   - Requires manual intervention to add mappings

### Option 3: Hybrid Approach (Best)

**Pre-populate common apps, add others on-demand:**

1. **Pre-populate top 50-100 most common apps:**
   - Shopping: Amazon, Target, Walmart, eBay
   - Food: Uber Eats, DoorDash, Grubhub, Postmates
   - Ride-sharing: Uber, Lyft
   - Social: Instagram, Facebook, TikTok
   - Entertainment: Netflix, Hulu, Disney+
   - etc.

2. **For unknown apps:**
   - Use generic names initially
   - Collect token hashes from user logs
   - Add to database as discovered

3. **Benefits:**
   - Best user experience (most apps named immediately)
   - Database grows over time
   - Minimal manual work

## Implementation Details

### Token Hash Consistency

The hash is generated using:
```swift
let hash = token.hashValue  // Swift's built-in hash
```

**Important:** `hashValue` is consistent across app launches for the same token, but may vary between:
- Different iOS versions
- Different devices (potentially)
- Different app builds (potentially)

**Recommendation:** Test hash consistency across devices and iOS versions before relying on it for production.

### Fallback Strategy

If a token hash is not found in the database:
1. App uses generic name: "App 0", "App 1", etc.
2. App logs the token hash for later population
3. Admin can collect logs and add mappings

### User-Specific Mappings?

**Current design: NO user-specific mappings**

The mapping is global because:
- Same app = same token hash (for all users)
- More efficient (one lookup table)
- Easier to manage
- Better user experience (names appear immediately)

**If you need user-specific names:**
- You could add a `user_id` to the table
- But this would require significant changes to the design
- Not recommended unless there's a specific use case

## Next Steps

1. **Test hash consistency:**
   - Select same app on multiple devices
   - Verify hash is the same
   - If different, may need to use a different hashing method

2. **Pre-populate common apps:**
   - Start with top 20-50 apps
   - Add more as you discover them

3. **Monitor and grow:**
   - Check logs for unmapped token hashes
   - Add mappings as needed
   - Build comprehensive database over time

## Example: Adding a New App Mapping

```bash
# 1. User selects "Amazon" in iOS app
# 2. Check console logs:
#    🔍 [DeviceActivityService] Token 0 hash: 1234567890

# 3. Add to database:
aws dynamodb put-item \
  --table-name soteria-app-token-mappings \
  --item '{
    "token_hash": {"S": "1234567890"},
    "app_name": {"S": "Amazon"},
    "created_at": {"N": "1701234567890"},
    "updated_at": {"N": "1701234567890"}
  }' \
  --region us-east-1

# 4. All future users who select Amazon will get "Amazon" as the name
```

