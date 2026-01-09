# Apple Wallet Certificate Files - Retention Guide

## 📋 Current Certificate Files on Desktop

Found on your Desktop:
- `Certificates.p12` (3.2KB) - Pass Type ID certificate with private key
- `pass.cer` (1.5KB) - Pass Type ID certificate (without private key)
- `wwdr.pem` (1.1KB) - Apple Worldwide Developer Relations certificate

---

## 🔍 How Certificates Are Used

### Lambda Function Setup
The Lambda function (`soteria-apple-wallet-pass`) downloads certificates from **S3** at runtime:

1. **From S3**: `s3://soteria-wallet-passes/certificates/cert.p12`
2. **From S3**: `s3://soteria-wallet-passes/certificates/wwdr.pem`
3. **Password**: Retrieved from AWS Secrets Manager (`soteria/apple-wallet/cert-password`)

The Lambda function **does NOT** use local files - it downloads from S3 each time it runs.

---

## ✅ Can You Delete Local Files?

### **YES, you can delete local copies IF:**
1. ✅ Certificates are already uploaded to S3
2. ✅ Lambda function is working correctly
3. ✅ You have a backup somewhere safe

### **RECOMMENDED: Keep a Secure Backup**

**Why keep backups:**
- 🔒 **Security**: If S3 files are accidentally deleted or corrupted
- 🔄 **Recovery**: If you need to re-upload to S3
- 📝 **Documentation**: For future reference or team members
- 🔑 **Private Key**: The `.p12` file contains your private key - if lost, you'd need to regenerate everything

---

## 💾 Recommended Backup Strategy

### Option 1: Secure Cloud Storage (Recommended)
1. **Upload to secure location**:
   - Encrypted cloud storage (iCloud Keychain, 1Password, etc.)
   - Password-protected archive
   - Secure file sharing service

2. **Delete from Desktop** (after backup confirmed)

### Option 2: Keep Local Encrypted Copy
1. **Create encrypted archive**:
   ```bash
   cd ~/Desktop
   zip -e certificates-backup.zip Certificates.p12 pass.cer wwdr.pem
   # Enter a strong password when prompted
   ```

2. **Move to secure location**:
   - Move `certificates-backup.zip` to a secure folder
   - Delete original files from Desktop

### Option 3: Keychain Access (macOS)
1. **Import to Keychain** (already done for `.p12`)
2. **Export from Keychain** if needed later
3. **Delete Desktop files** (Keychain has the private key)

---

## ⚠️ Important Notes

### Files You Need:
- **`Certificates.p12`**: Contains BOTH certificate AND private key
  - ⚠️ **CRITICAL**: If lost, you cannot regenerate the private key
  - Must create new Pass Type ID certificate if lost

- **`wwdr.pem`**: Apple's WWDR certificate
  - ✅ Can be re-downloaded from Apple at any time
  - Not critical to keep locally

- **`pass.cer`**: Certificate without private key
  - ⚠️ Less useful - `.p12` is what you need
  - Can be deleted if `.p12` is safely backed up

### Files in S3:
- Lambda downloads these at runtime
- If S3 files are lost, you can re-upload from backup
- S3 is the **active** storage location

---

## 🔐 Security Best Practices

1. **Never commit to Git**: ✅ Already in `.gitignore`
2. **Encrypt backups**: Use password-protected archives
3. **Store separately**: Don't keep password and certificates together
4. **Limit access**: Only authorized team members should have access
5. **Rotate if compromised**: If exposed, regenerate certificates

---

## ✅ Action Plan

### Recommended Steps:

1. **Verify S3 has certificates**:
   ```bash
   aws s3 ls s3://soteria-wallet-passes/certificates/
   ```

2. **Test Lambda function** (if not already tested):
   - Generate a test pass
   - Verify it works

3. **Create encrypted backup**:
   ```bash
   cd ~/Desktop
   zip -e certificates-backup-$(date +%Y%m%d).zip Certificates.p12 pass.cer wwdr.pem
   ```

4. **Move backup to secure location**:
   - Move encrypted zip to secure folder
   - Or upload to encrypted cloud storage

5. **Delete from Desktop** (after backup confirmed):
   ```bash
   rm ~/Desktop/Certificates.p12
   rm ~/Desktop/pass.cer
   rm ~/Desktop/wwdr.pem
   ```

---

## 📝 Summary

**Answer**: You can delete local files **IF**:
- ✅ Certificates are in S3 (verified)
- ✅ Lambda is working (tested)
- ✅ You have a secure backup

**Recommendation**: 
1. Create encrypted backup first
2. Verify S3 has files
3. Then delete Desktop files

**Critical**: The `.p12` file contains your private key - **never lose it** without a backup!

---

**Status**: Ready to backup and clean up Desktop ✅

