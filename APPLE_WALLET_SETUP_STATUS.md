# Apple Wallet Setup Status

## ⚠️ IMPORTANT: Wait for Organization Transition

**Current Status**: Organization account pending approval (Team ID: `4P5YXTJ7U7`)

**Recommendation**: **WAIT** to register Pass Type ID until after organization transition is complete.

### Why Wait?
1. **Team Identifier Changes**: Pass Type IDs are tied to your Apple Developer Team ID
2. **Certificate Binding**: Certificates are tied to the team/account
3. **Avoid Re-work**: If team ID changes, you'd need to:
   - Re-register the Pass Type ID
   - Re-download certificates
   - Re-upload everything to S3
   - Update Lambda environment variables

### What You CAN Do Now
- ✅ Backend infrastructure (Lambda, API Gateway, S3) - **DONE**
- ✅ iOS app code - **DONE**
- ✅ Prepare pass assets (logo.png, icon.png) - **Can design now**
- ⏳ Register Pass Type ID - **Wait for org transition**
- ⏳ Download certificates - **Wait for org transition**

## ✅ What's Been Set Up (No TestFlight Required)

### 1. Backend Infrastructure ✅
- **S3 Bucket**: `soteria-wallet-passes` created for storing certificates and assets
- **Lambda Function**: `soteria-apple-wallet-pass` deployed and configured
- **API Gateway Endpoint**: `GET /soteria/apple-wallet/pass` configured and deployed
- **Authentication**: Lambda function validates JWT tokens from Cognito
- **CORS**: Configured for cross-origin requests

### 2. iOS App Code ✅
- **AppleWalletService.swift**: Updated to download passes from backend
- **PremiumCardBack.swift**: Updated to call the backend API
- **Error Handling**: Proper error messages for missing backend setup

### 3. API Endpoint
```
GET https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/apple-wallet/pass?user_id={userId}&card_type={cardType}
```

**Headers Required:**
- `Authorization: Bearer {idToken}` (from Cognito)

**Query Parameters:**
- `user_id`: The authenticated user's ID
- `card_type`: `gold`, `platinum`, or `black` (optional, defaults to `gold`)

## ⚠️ What Still Needs to Be Done (Apple Developer Portal)

### 1. Register Pass Type ID
1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list/passTypeId)
2. Click **"+"** to create a new Pass Type ID
3. Enter identifier: `pass.com.soteria.member` (or your preferred identifier)
4. Click **"Continue"** and **"Register"**

### 2. Download Pass Type ID Certificate
1. Click on your Pass Type ID
2. Click **"Create Certificate"**
3. Follow the steps to create a certificate signing request (CSR)
4. Download the certificate (.cer file)
5. Double-click to install in Keychain
6. Export as .p12 file:
   - Open Keychain Access
   - Find your Pass Type ID certificate
   - Right-click → Export
   - Save as `cert.p12` (set a password)

### 3. Download WWDR Certificate
1. Go to [Apple Developer Portal - Certificates](https://developer.apple.com/certificates/)
2. Download **"Apple Worldwide Developer Relations Intermediate Certificate"**
3. Save as `wwdr.pem` or `wwdr.cer`

### 4. Upload Certificates to S3
```bash
# Upload Pass Type ID certificate
aws s3 cp cert.p12 s3://soteria-wallet-passes/certificates/cert.p12 --region us-east-1

# Upload WWDR certificate
aws s3 cp wwdr.pem s3://soteria-wallet-passes/certificates/wwdr.pem --region us-east-1
```

### 5. Set Certificate Password in Lambda Environment
```bash
# Store certificate password in AWS Secrets Manager or Lambda environment
aws lambda update-function-configuration \
  --function-name soteria-apple-wallet-pass \
  --environment "Variables={
    PASS_BUCKET=soteria-wallet-passes,
    PASS_TYPE_ID=pass.com.soteria.member,
    CERT_PASSWORD=your_certificate_password_here,
    USER_DATA_TABLE=soteria-user-data,
    TEAM_IDENTIFIER=YOUR_TEAM_ID
  }" \
  --region us-east-1
```

**⚠️ Security Note**: For production, use AWS Secrets Manager instead of Lambda environment variables for the certificate password.

### 6. Upload Pass Assets ✅ **DONE**
✅ **Assets have been prepared and uploaded from existing logo:**
- **Logo**: 180x180px PNG (resized from `soteria_logo.png`)
- **Icon**: 29x29px PNG (resized from `soteria_logo.png`)
- **Location**: `s3://soteria-wallet-passes/assets/logo.png` and `icon.png`

**Source**: Used existing `soteria_logo.png` (1268x1282px) from `soteria/Assets.xcassets/soteria_logo.imageset/`

**Asset Requirements:**
- **Logo**: 180x180px PNG, displayed on the front of the pass ✅
- **Icon**: 29x29px PNG (iPhone) or 40x40px PNG (iPad), displayed in notifications ✅

## 🧪 Testing

### Test the Endpoint (Before Certificates)
```bash
# This will fail with certificate errors, but confirms the endpoint works
curl -X GET \
  "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/apple-wallet/pass?user_id=test&card_type=gold" \
  -H "Authorization: Bearer YOUR_ID_TOKEN"
```

### Test After Certificates Are Uploaded
1. Open the Soteria app
2. Navigate to your premium card
3. Tap **"Add to Apple Wallet"**
4. The pass should download and open in Apple Wallet

## 📝 Notes

- **No TestFlight Required**: Apple Wallet passes can be set up and tested without TestFlight
- **Pass Type ID**: Must match your app's bundle ID structure (e.g., `pass.com.soteria.member`)
- **Team Identifier**: Get from Apple Developer Portal (Account → Membership → Team ID)
- **Certificate Expiration**: Pass Type ID certificates expire after 1 year, need to be renewed

## 🔒 Security

- ✅ JWT token validation ensures only authenticated users can request passes
- ✅ Users can only request their own passes (userId validation)
- ⚠️ Certificate password should be stored in AWS Secrets Manager for production
- ⚠️ Consider adding rate limiting to prevent abuse

## 📚 Resources

- [Apple Wallet Developer Guide](https://developer.apple.com/wallet/)
- [PassKit Framework Documentation](https://developer.apple.com/documentation/passkit)
- [Creating Passes](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/PassKit_PG/Creating.html)

