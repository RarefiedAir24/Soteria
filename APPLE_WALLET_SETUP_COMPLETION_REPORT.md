# Apple Wallet Certificate Setup - Completion Report

**Date**: January 7, 2026  
**Status**: Infrastructure Complete - Manual Steps Pending

---

## ✅ Completed Steps (Automated)

### 1. Infrastructure Setup ✅
- [x] Secrets Manager secret created: `soteria/apple-wallet/cert-password`
- [x] Lambda IAM role has Secrets Manager permissions
- [x] Lambda function updated to support Secrets Manager
- [x] Lambda `TEAM_IDENTIFIER` configured: `4P5YXTJ7U7`
- [x] S3 bucket verified: `soteria-wallet-passes` exists
- [x] Pass assets verified: `assets/` folder exists

### 2. Documentation ✅
- [x] Setup checklist created: `APPLE_WALLET_CERTIFICATE_SETUP_CHECKLIST.md`
- [x] Password documentation template created: `APPLE_WALLET_CERTIFICATE_PASSWORD.md`
- [x] Password file added to `.gitignore` (security)

### 3. Lambda Configuration ✅
**Current Environment Variables**:
```json
{
    "USER_DATA_TABLE": "soteria-user-data",
    "TEAM_IDENTIFIER": "4P5YXTJ7U7",
    "PASS_BUCKET": "soteria-wallet-passes",
    "PASS_TYPE_ID": "pass.com.soteria.member"
}
```

**Status**: ✅ All required variables set (CERT_PASSWORD will use Secrets Manager)

---

## ⏳ Pending Steps (Manual - Require Apple Developer Portal Access)

### Step 1: Register Pass Type ID
**Location**: [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list/passTypeId)  
**Action**: Create Pass Type ID `pass.com.soteria.member`  
**Estimated Time**: 5 minutes

### Step 2: Create Certificate
**Location**: Apple Developer Portal → Pass Type ID → Create Certificate  
**Action**: Create and download certificate, install in Keychain  
**Estimated Time**: 10 minutes

### Step 3: Export .p12 File
**Location**: Keychain Access → Export certificate  
**Action**: Export as `cert.p12` with password  
**Estimated Time**: 5 minutes  
**⚠️ IMPORTANT**: Document password in `APPLE_WALLET_CERTIFICATE_PASSWORD.md`

### Step 4: Download WWDR Certificate
**Location**: [Apple Developer Portal - Certificates](https://developer.apple.com/certificates/)  
**Action**: Download WWDR certificate as `wwdr.pem`  
**Estimated Time**: 2 minutes

### Step 5: Upload to S3
**Commands** (run after certificates are ready):
```bash
# Upload Pass Type ID certificate
aws s3 cp cert.p12 s3://soteria-wallet-passes/certificates/cert.p12 --region us-east-1

# Upload WWDR certificate
aws s3 cp wwdr.pem s3://soteria-wallet-passes/certificates/wwdr.pem --region us-east-1

# Verify upload
aws s3 ls s3://soteria-wallet-passes/certificates/ --region us-east-1
```

### Step 6: Store Password in Secrets Manager
**Command** (run after password is documented):
```bash
aws secretsmanager put-secret-value \
  --secret-id soteria/apple-wallet/cert-password \
  --secret-string "YOUR_PASSWORD_HERE" \
  --region us-east-1
```

---

## 📋 Quick Reference

### Secrets Manager
- **Secret Name**: `soteria/apple-wallet/cert-password`
- **ARN**: `arn:aws:secretsmanager:us-east-1:516141816050:secret:soteria/apple-wallet/cert-password-383YZb`
- **Status**: Created, waiting for password value

### S3 Bucket
- **Bucket**: `soteria-wallet-passes`
- **Region**: `us-east-1`
- **Certificates Path**: `certificates/`
- **Assets Path**: `assets/` (already has logo.png and icon.png)

### Lambda Function
- **Function Name**: `soteria-apple-wallet-pass`
- **Region**: `us-east-1`
- **Runtime**: `nodejs20.x`
- **IAM Role**: `soteria-lambda-role` (has Secrets Manager access)

### Team Information
- **Team ID**: `4P5YXTJ7U7`
- **Organization**: Montebay Innovations LLC
- **Pass Type ID**: `pass.com.soteria.member` (to be created)

---

## 🔒 Security Notes

1. **Password Storage**: Password will be stored in AWS Secrets Manager (not in code or env vars)
2. **Password Documentation**: Template created at `APPLE_WALLET_CERTIFICATE_PASSWORD.md`
3. **Git Ignore**: Password file and certificate files added to `.gitignore`
4. **Access Control**: Only Lambda function and authorized team members have access

---

## 📝 Next Actions

1. **Complete manual steps** (Steps 1-4 above)
2. **Document password** in `APPLE_WALLET_CERTIFICATE_PASSWORD.md`
3. **Upload certificates** to S3 (Step 5)
4. **Store password** in Secrets Manager (Step 6)
5. **Test pass generation** via API endpoint

---

## ✅ Verification Checklist

After completing manual steps, verify:

- [ ] Pass Type ID registered in Apple Developer Portal
- [ ] Certificate exported as `cert.p12` with password
- [ ] WWDR certificate downloaded as `wwdr.pem`
- [ ] Both certificates uploaded to S3
- [ ] Password documented in secure file
- [ ] Password stored in Secrets Manager
- [ ] Lambda can generate test pass

---

**Report Generated**: January 7, 2026  
**Infrastructure Status**: ✅ Complete  
**Manual Steps Status**: ⏳ Pending

