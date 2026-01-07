# Apple Wallet Setup - Resume Guide

**Status**: Backend infrastructure complete, waiting for organization transition approval  
**Date Prepared**: January 3, 2026  
**Next Step**: After organization approval, complete Apple Developer Portal setup

---

## ✅ What's Already Complete

### Backend Infrastructure (100% Complete)
- ✅ **Lambda Function**: `soteria-apple-wallet-pass` deployed and configured
- ✅ **API Gateway Endpoint**: `GET /soteria/apple-wallet/pass` configured and deployed
- ✅ **S3 Bucket**: `soteria-wallet-passes` created
- ✅ **Pass Assets**: Logo and icon uploaded to S3
- ✅ **Authentication**: JWT token validation implemented
- ✅ **CORS**: Configured for cross-origin requests

### iOS App Code (100% Complete)
- ✅ **AppleWalletService.swift**: Updated to download passes from backend
- ✅ **PremiumCardBack.swift**: Updated to call backend API
- ✅ **Error Handling**: Proper error messages implemented

### Pass Assets (100% Complete)
- ✅ **logo.png**: 180x180px (resized from `soteria_logo.png`)
- ✅ **icon.png**: 29x29px (resized from `soteria_logo.png`)
- ✅ **Location**: `s3://soteria-wallet-passes/assets/`

---

## 📋 What Needs to Be Done (After Organization Approval)

### Step 1: Verify New Team ID
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Membership** section
3. Note your **Team ID** (e.g., `4P5YXTJ7U7` or new ID after transition)
4. Save this for Step 5

### Step 2: Register Pass Type ID
1. Go to [Pass Type IDs](https://developer.apple.com/account/resources/identifiers/list/passTypeId)
2. Click **"+"** to create a new Pass Type ID
3. Enter identifier: `pass.com.soteria.member` (or your preferred identifier)
   - Must match your bundle ID structure: `pass.{reverse-domain}.{identifier}`
   - Example: If bundle ID is `io.montebay.soteria`, use `pass.com.montebay.soteria.member`
4. Click **"Continue"** and **"Register"**
5. Note the Pass Type ID for Step 5

### Step 3: Download Pass Type ID Certificate
1. Click on your newly created Pass Type ID
2. Click **"Create Certificate"**
3. Follow the steps:
   - Create a Certificate Signing Request (CSR) in Keychain Access
   - Upload the CSR
   - Download the certificate (.cer file)
4. Double-click the .cer file to install in Keychain
5. Export as .p12 file:
   - Open **Keychain Access**
   - Find your Pass Type ID certificate (search for "Pass Type ID" or your identifier)
   - Right-click → **Export**
   - Save as `cert.p12`
   - **Set a password** (you'll need this for Step 5)
   - Choose **Personal Information Exchange (.p12)** format

### Step 4: Download WWDR Certificate
1. Go to [Apple Certificates](https://developer.apple.com/certificates/)
2. Download **"Apple Worldwide Developer Relations Intermediate Certificate"**
3. Save as `wwdr.pem` or `wwdr.cer`
   - If downloaded as .cer, you can rename to .pem

### Step 5: Upload Certificates to S3
```bash
# Upload Pass Type ID certificate
aws s3 cp cert.p12 s3://soteria-wallet-passes/certificates/cert.p12 --region us-east-1

# Upload WWDR certificate
aws s3 cp wwdr.pem s3://soteria-wallet-passes/certificates/wwdr.pem --region us-east-1
```

### Step 6: Update Lambda Environment Variables
```bash
# Get your new Team ID from Step 1
TEAM_ID="YOUR_NEW_TEAM_ID"
PASS_TYPE_ID="pass.com.soteria.member"  # Or your Pass Type ID from Step 2
CERT_PASSWORD="your_certificate_password"  # Password from Step 3

aws lambda update-function-configuration \
  --function-name soteria-apple-wallet-pass \
  --environment "Variables={
    PASS_BUCKET=soteria-wallet-passes,
    PASS_TYPE_ID=${PASS_TYPE_ID},
    CERT_PASSWORD=${CERT_PASSWORD},
    USER_DATA_TABLE=soteria-user-data,
    TEAM_IDENTIFIER=${TEAM_ID}
  }" \
  --region us-east-1
```

**⚠️ Security Note**: For production, consider using AWS Secrets Manager instead of Lambda environment variables for the certificate password.

### Step 7: Test the Endpoint
```bash
# Get your ID token from the app (or use Cognito CLI)
ID_TOKEN="your_cognito_id_token"
USER_ID="your_user_id"

curl -X GET \
  "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/apple-wallet/pass?user_id=${USER_ID}&card_type=gold" \
  -H "Authorization: Bearer ${ID_TOKEN}" \
  -H "Accept: application/vnd.apple.pkpass" \
  --output test-pass.pkpass
```

If successful, you should get a `.pkpass` file that can be opened in Apple Wallet.

### Step 8: Test in iOS App
1. Open the Soteria app
2. Navigate to your premium card
3. Tap **"Add to Apple Wallet"**
4. The pass should download and open in Apple Wallet

---

## 📁 File Locations & References

### Backend Files
- **Lambda Function**: `lambda/soteria-apple-wallet-pass/index.js`
- **API Gateway Script**: `connect-apple-wallet-to-api-gateway.sh`
- **Setup Documentation**: `APPLE_WALLET_SETUP_STATUS.md`
- **Assets Guide**: `APPLE_WALLET_PASS_ASSETS.md`

### iOS Files
- **Service**: `soteria/Services/AppleWalletService.swift`
- **View**: `soteria/Views/PremiumCardBack.swift`

### S3 Locations
- **Certificates**: `s3://soteria-wallet-passes/certificates/`
- **Assets**: `s3://soteria-wallet-passes/assets/`

### API Endpoint
```
GET https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/apple-wallet/pass
Query Parameters:
  - user_id: (required) The authenticated user's ID
  - card_type: (optional) gold, platinum, or black (defaults to gold)
Headers:
  - Authorization: Bearer {idToken}
  - Accept: application/vnd.apple.pkpass
```

---

## 🔍 Verification Checklist

After completing all steps, verify:

- [ ] Pass Type ID registered in Apple Developer Portal
- [ ] Certificates downloaded (.p12 and WWDR)
- [ ] Certificates uploaded to S3
- [ ] Lambda environment variables updated with:
  - [ ] Team ID
  - [ ] Pass Type ID
  - [ ] Certificate password
- [ ] Test endpoint returns `.pkpass` file
- [ ] iOS app can download and add pass to Wallet
- [ ] Pass displays correctly in Apple Wallet with logo and icon

---

## 🐛 Troubleshooting

### Error: "Invalid pass data"
- Check that certificates are correctly uploaded to S3
- Verify certificate password is correct in Lambda environment
- Check Lambda logs: `aws logs tail /aws/lambda/soteria-apple-wallet-pass --follow`

### Error: "Pass Type ID not found"
- Verify Pass Type ID matches exactly in Lambda environment
- Check that Pass Type ID is registered under the correct organization account

### Error: "Certificate not found"
- Verify certificates are in S3: `aws s3 ls s3://soteria-wallet-passes/certificates/`
- Check file names match exactly: `cert.p12` and `wwdr.pem`

### Pass doesn't display logo/icon
- Verify assets are in S3: `aws s3 ls s3://soteria-wallet-passes/assets/`
- Check Lambda logs for asset loading errors

### 401 Unauthorized
- Verify JWT token is valid and not expired
- Check that user_id in query matches authenticated user

---

## 📚 Additional Resources

- [Apple Wallet Developer Guide](https://developer.apple.com/wallet/)
- [PassKit Framework Documentation](https://developer.apple.com/documentation/passkit)
- [Creating Passes](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/PassKit_PG/Creating.html)
- [Pass Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/wallet)

---

## 📝 Notes

- **Team ID**: Will change after organization transition - update in Lambda environment
- **Pass Type ID**: Must match bundle ID structure (reverse domain)
- **Certificate Expiration**: Pass Type ID certificates expire after 1 year - need renewal
- **Testing**: Can test passes without TestFlight - just need certificates

---

**Ready to resume**: Once organization transition is approved, follow Steps 1-8 above.

