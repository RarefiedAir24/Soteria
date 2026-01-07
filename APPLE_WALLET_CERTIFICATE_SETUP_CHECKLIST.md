# Apple Wallet Certificate Setup Checklist

**Date Started**: [Current Date]  
**Status**: In Progress  
**Team ID**: `4P5YXTJ7U7` (Montebay Innovations LLC)

---

## ✅ Pre-Setup (Completed)

- [x] Organization account transitioned
- [x] Team ID verified: `4P5YXTJ7U7`
- [x] Lambda function configured with `TEAM_IDENTIFIER`
- [x] Secrets Manager secret created: `soteria/apple-wallet/cert-password`
- [x] Lambda IAM role has Secrets Manager permissions
- [x] Lambda code updated to support Secrets Manager

---

## 📋 Step-by-Step Checklist

### Step 1: Register Pass Type ID in Apple Developer Portal

- [ ] Go to [Apple Developer Portal - Pass Type IDs](https://developer.apple.com/account/resources/identifiers/list/passTypeId)
- [ ] Click **"+"** button to create new Pass Type ID
- [ ] Enter identifier: `pass.com.soteria.member`
  - **Note**: Must follow format `pass.{reverse-domain}.{identifier}`
  - Bundle ID is `io.montebay.soteria`, so use `pass.com.soteria.member`
- [ ] Click **"Continue"** and **"Register"**
- [ ] Verify Pass Type ID is listed and active

**Status**: ⏳ Pending

---

### Step 2: Create Pass Type ID Certificate

- [ ] Click on `pass.com.soteria.member` Pass Type ID
- [ ] Click **"Create Certificate"** button
- [ ] Follow certificate creation wizard:
  - [ ] Create Certificate Signing Request (CSR) in Keychain Access
  - [ ] Upload CSR to Apple Developer Portal
  - [ ] Download certificate (.cer file)
- [ ] Double-click `.cer` file to install in Keychain
- [ ] Verify certificate appears in Keychain Access

**Status**: ⏳ Pending

---

### Step 3: Export Certificate as .p12 File

- [ ] Open **Keychain Access** application
- [ ] Select **"My Certificates"** in left sidebar
- [ ] Find certificate named: `Pass Type ID: pass.com.soteria.member`
- [ ] Right-click certificate → **Export**
- [ ] Save as: `cert.p12`
- [ ] **Set password** when prompted (REQUIRED - Keychain enforces this)
- [ ] **Document password** in secure location (see password documentation below)
- [ ] Choose format: **Personal Information Exchange (.p12)**
- [ ] Click **"Save"**

**Status**: ⏳ Pending  
**Password Location**: See `APPLE_WALLET_CERTIFICATE_PASSWORD.md`

---

### Step 4: Download WWDR Certificate

- [ ] Go to [Apple Developer Portal - Certificates](https://developer.apple.com/certificates/)
- [ ] Download **"Apple Worldwide Developer Relations Intermediate Certificate"**
- [ ] Save as: `wwdr.pem`
  - If downloaded as `.cer`, rename to `.pem`
- [ ] Verify file exists locally

**Status**: ⏳ Pending

---

### Step 5: Upload Certificates to S3

- [ ] Upload Pass Type ID certificate:
  ```bash
  aws s3 cp cert.p12 s3://soteria-wallet-passes/certificates/cert.p12 --region us-east-1
  ```
- [ ] Upload WWDR certificate:
  ```bash
  aws s3 cp wwdr.pem s3://soteria-wallet-passes/certificates/wwdr.pem --region us-east-1
  ```
- [ ] Verify files uploaded:
  ```bash
  aws s3 ls s3://soteria-wallet-passes/certificates/ --region us-east-1
  ```

**Status**: ⏳ Pending

---

### Step 6: Store Certificate Password in Secrets Manager

- [ ] Retrieve password from secure documentation
- [ ] Store in AWS Secrets Manager:
  ```bash
  aws secretsmanager put-secret-value \
    --secret-id soteria/apple-wallet/cert-password \
    --secret-string "PASSWORD_HERE" \
    --region us-east-1
  ```
- [ ] Verify secret updated:
  ```bash
  aws secretsmanager get-secret-value \
    --secret-id soteria/apple-wallet/cert-password \
    --region us-east-1 \
    --query 'SecretString' \
    --output text
  ```

**Status**: ⏳ Pending

---

### Step 7: Verify Lambda Configuration

- [ ] Check Lambda environment variables:
  ```bash
  aws lambda get-function-configuration \
    --function-name soteria-apple-wallet-pass \
    --region us-east-1 \
    --query 'Environment.Variables' \
    --output json
  ```
- [ ] Verify all required variables are set:
  - [x] `TEAM_IDENTIFIER` = `4P5YXTJ7U7` ✅
  - [x] `PASS_TYPE_ID` = `pass.com.soteria.member` ✅
  - [x] `PASS_BUCKET` = `soteria-wallet-passes` ✅
  - [x] `USER_DATA_TABLE` = `soteria-user-data` ✅
  - [ ] `CERT_PASSWORD` (optional - using Secrets Manager instead)

**Status**: ✅ Mostly Complete (CERT_PASSWORD not needed - using Secrets Manager)

---

### Step 8: Test Certificate Access

- [ ] Test Lambda can download certificates from S3:
  ```bash
  # This will be tested when Lambda runs
  ```
- [ ] Test Lambda can access Secrets Manager:
  ```bash
  # Verify IAM role has permissions (already verified ✅)
  ```

**Status**: ⏳ Pending (will test after certificates uploaded)

---

### Step 9: Test Apple Wallet Pass Generation

- [ ] Make test API call to Lambda endpoint:
  ```bash
  curl -X GET \
    "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/apple-wallet/pass?user_id=TEST_USER_ID&card_type=gold" \
    -H "Authorization: Bearer VALID_ID_TOKEN"
  ```
- [ ] Verify response is valid `.pkpass` file
- [ ] Test in iOS app:
  - [ ] Open Soteria app
  - [ ] Navigate to premium card
  - [ ] Tap "Add to Apple Wallet"
  - [ ] Verify pass downloads and opens in Apple Wallet

**Status**: ⏳ Pending

---

## 📝 Notes

- **Certificate Expiration**: Pass Type ID certificates expire after 1 year
- **Password Security**: Password stored in AWS Secrets Manager (not in code or env vars)
- **Team ID**: `4P5YXTJ7U7` (unchanged after organization transition)
- **Pass Type ID**: `pass.com.soteria.member`

---

## 🔒 Security Checklist

- [x] Password will be stored in AWS Secrets Manager (not environment variables)
- [x] Lambda IAM role has Secrets Manager read permissions
- [x] Certificate files stored in private S3 bucket
- [ ] Password documented in secure internal documentation
- [ ] Access to password restricted to authorized personnel only

---

## ✅ Completion Status

**Overall Progress**: 30% Complete

- ✅ Infrastructure setup: 100%
- ⏳ Certificate creation: 0%
- ⏳ Certificate upload: 0%
- ⏳ Password storage: 0%
- ⏳ Testing: 0%

---

**Last Updated**: [Current Date]  
**Next Action**: Register Pass Type ID in Apple Developer Portal

