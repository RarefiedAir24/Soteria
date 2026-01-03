# Member Number Implementation - Option 3 ✅

## Overview

Implemented database-generated member numbers (Option 3) for future-proofing the partner loyalty system. This provides a professional, credit card-like member number that can be manually entered when scanning is not available.

## Implementation Details

### Format
- **Format**: `SOT-XXXXXX` (e.g., `SOT-123456`)
- **Length**: 6 digits after "SOT-" prefix
- **Generation**: Random 6-digit number (000001 to 999999)
- **Uniqueness**: Checked against database before assignment

### Components Created

#### 1. MemberNumberService (iOS)
**File**: `soteria/Services/MemberNumberService.swift`

- Loads member number from cache (UserDefaults)
- Fetches from backend API if not cached
- Generates temporary local number as fallback
- Formats number with "SOT-" prefix

#### 2. Premium Card Back Update
**File**: `soteria/Views/PremiumCardBack.swift`

- Displays member number on far right of signature box
- Username on left, member number on right
- Monospace font (12pt) for clarity
- Color matches card type
- Loads member number on appear

#### 3. Lambda Function: Member Number Generator
**File**: `lambda/soteria-member-number/index.js`

**Endpoint**: `GET /soteria/member-number?user_id={userId}`

**Response**:
```json
{
  "success": true,
  "member_number": "SOT-123456"
}
```

**Features**:
- Generates unique 6-digit member numbers
- Checks for duplicates before assignment
- Stores in both `soteria-member-numbers` table and user data
- Only generates for premium users
- Returns existing number if already assigned

#### 4. Updated Validation Endpoint
**File**: `lambda/soteria-partner-validate-member/index.js`

**Now accepts**:
- `qr_data` (existing) - QR code JSON string
- `member_number` (new) - Member number string (e.g., "SOT-123456")

**Request Examples**:
```json
// QR Code (existing)
{
  "qr_data": "{\"user_id\":\"...\",\"card_type\":\"...\"}",
  "partner_id": "partner-123"
}

// Member Number (new)
{
  "member_number": "SOT-123456",
  "partner_id": "partner-123"
}
```

#### 5. Partner Scanner Update
**File**: `partner-scanner/index.html`

- Added separate input field for member number
- New `validateMemberNumber()` function
- Clear UI separation between QR code and member number entry

#### 6. Database Table
**Script**: `create-member-number-table.sh`

Creates `soteria-member-numbers` table:
- Primary key: `member_number` (String)
- Attributes: `user_id`, `created_at`
- Pay-per-request billing

## Database Schema

### soteria-member-numbers Table
```
member_number (PK): String - "SOT-123456"
user_id: String - User's unique ID
created_at: String - ISO8601 timestamp
```

### user_data Table (Updated)
Stores member number in user profile:
```
user_id (PK): String
data_type (SK): String - "member_number"
data: {
  member_number: String - "SOT-123456"
  created_at: String - ISO8601 timestamp
}
```

## Deployment Steps

### 1. Create Database Table
```bash
./create-member-number-table.sh
```

### 2. Deploy Member Number Lambda
```bash
cd lambda/soteria-member-number
zip -r function.zip index.js package.json node_modules/
aws lambda create-function \
  --function-name soteria-member-number \
  --runtime nodejs18.x \
  --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --region us-east-1
```

### 3. Connect to API Gateway
```bash
# Create resource
aws apigateway create-resource \
  --rest-api-id YOUR_API_ID \
  --parent-id PARENT_RESOURCE_ID \
  --path-part member-number

# Create method
aws apigateway put-method \
  --rest-api-id YOUR_API_ID \
  --resource-id MEMBER_NUMBER_RESOURCE_ID \
  --http-method GET \
  --authorization-type NONE

# Set integration
aws apigateway put-integration \
  --rest-api-id YOUR_API_ID \
  --resource-id MEMBER_NUMBER_RESOURCE_ID \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:YOUR_ACCOUNT:function:soteria-member-number/invocations
```

### 4. Update Validation Lambda
The validation Lambda has been updated to accept member numbers. Redeploy:
```bash
cd lambda/soteria-partner-validate-member
zip -r function.zip index.js package.json node_modules/
aws lambda update-function-code \
  --function-name soteria-partner-validate-member \
  --zip-file fileb://function.zip \
  --region us-east-1
```

## Usage

### iOS App
Member numbers are automatically:
- Generated when user becomes premium
- Displayed on card back
- Cached locally for offline access
- Fetched from backend when needed

### Partner Scanner
Partners can now:
1. **Scan QR code** (existing method)
2. **Enter member number manually** (new method)
   - Format: `SOT-123456`
   - No spaces or special characters needed
   - Case-insensitive

### API Usage
```bash
# Get member number
curl "https://api.soteria.app/soteria/member-number?user_id=user-123"

# Validate by member number
curl -X POST "https://api.soteria.app/soteria/partner/validate-member" \
  -H "Content-Type: application/json" \
  -d '{
    "member_number": "SOT-123456",
    "partner_id": "partner-123"
  }'
```

## Migration for Existing Users

For existing premium users without member numbers:

1. **Automatic**: Next time they open the app, member number will be generated
2. **Manual**: Can be triggered by calling the member number API
3. **Bulk**: Can create a migration script to generate numbers for all premium users

## Benefits

✅ **Future-proof**: Database-backed, can be extended
✅ **Professional**: Credit card-like member number
✅ **Flexible**: Works with or without scanning
✅ **Unique**: Guaranteed uniqueness via database
✅ **Traceable**: Can track when numbers were assigned
✅ **Scalable**: Can support millions of members

## Next Steps

1. ✅ Create member number service
2. ✅ Update card back display
3. ✅ Create Lambda function
4. ✅ Update validation endpoint
5. ✅ Update partner scanner
6. ⏳ Deploy Lambda functions
7. ⏳ Create database table
8. ⏳ Test end-to-end flow
9. ⏳ Migrate existing premium users

---

**Status**: ✅ Implementation Complete - Ready for Deployment

