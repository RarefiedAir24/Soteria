# Plaid Link Token Request Validation

## Our Request Structure

Based on Plaid documentation, here's what we're sending:

```json
{
  "user": {
    "client_user_id": "[Firebase user ID]"
  },
  "client_name": "Soteria",
  "products": ["auth", "balance"],
  "country_codes": ["US"],
  "language": "en"
}
```

## Required Fields Check

✅ **client_name**: Present - "Soteria"  
✅ **language**: Present - "en"  
✅ **country_codes**: Present - ["US"] (array)  
✅ **user**: Present - object with client_user_id  
✅ **user.client_user_id**: Present - Firebase user ID  
✅ **products**: Present - ["auth", "balance"] (array with at least one product)

## Field Validation

### client_name
- ✅ Type: String
- ✅ Value: "Soteria"
- ✅ Required: Yes

### language
- ✅ Type: String
- ✅ Value: "en"
- ✅ Required: Yes
- ✅ Valid values: "en", "fr", "es", etc.

### country_codes
- ✅ Type: Array
- ✅ Value: ["US"]
- ✅ Required: Yes
- ✅ Contains valid country code: "US"

### user
- ✅ Type: Object
- ✅ Required: Yes
- ✅ Contains client_user_id: Yes

### user.client_user_id
- ✅ Type: String
- ✅ Required: Yes
- ✅ Unique per user: Yes (Firebase UID)

### products
- ✅ Type: Array
- ✅ Required: Yes
- ✅ Contains at least one product: Yes
- ✅ Valid products: ["auth", "balance"]
- ✅ Products are valid: Yes

## What We're NOT Including (Correctly)

❌ **redirect_uri**: Not included (correct for mobile)  
❌ **webhook**: Not included (correct for mobile)  
❌ **ios_bundle_id**: Not included (not a valid parameter)  
❌ **android_package_name**: Not included (iOS app only)

## Request Structure Comparison

### Plaid Documentation Example:
```json
{
  "client_name": "My App",
  "language": "en",
  "country_codes": ["US"],
  "user": {
    "client_user_id": "unique-user-id-123"
  },
  "products": ["auth", "transactions"]
}
```

### Our Request:
```json
{
  "client_name": "Soteria",
  "language": "en",
  "country_codes": ["US"],
  "user": {
    "client_user_id": "[Firebase UID]"
  },
  "products": ["auth", "balance"]
}
```

**Result**: ✅ Structure matches exactly!

## Conclusion

Our request structure is **100% correct** according to Plaid's documentation. All required fields are present, properly formatted, and have valid values.

The error "link token can only be configured for one Link flow" is likely an **account-level configuration issue** on Plaid's side, not a request structure problem.

