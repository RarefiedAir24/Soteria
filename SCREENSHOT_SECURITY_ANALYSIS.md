# Screenshot Security & Privacy Analysis

## ⚠️ Current Implementation (Security Gaps Identified)

### Where Screenshots Are Currently Stored:

1. **Local Device Storage** 📱
   - Location: App's Documents directory (`deposit_screenshots/`)
   - Format: JPEG files (resized to max 1200px)
   - **⚠️ ISSUE**: NOT ENCRYPTED
   - **⚠️ ISSUE**: Persists indefinitely (no auto-deletion)
   - **⚠️ ISSUE**: Backed up to iCloud (if enabled)

2. **S3 Cloud Storage** ☁️ (Optional)
   - Service: `DepositScreenshotAPIService`
   - **⚠️ ISSUE**: Not automatically called (needs integration)
   - **⚠️ ISSUE**: No encryption policy defined
   - **⚠️ ISSUE**: No lifecycle/expiration policy
   - **⚠️ ISSUE**: No bucket security audit

3. **Lambda Verification** 🔍
   - ✅ **GOOD**: Processes in-memory only
   - ✅ **GOOD**: NOT stored on Lambda
   - ✅ **GOOD**: Base64 transmitted over HTTPS
   - ✅ **GOOD**: Textract doesn't store images

---

## 🔒 Recommended Security Solution

### Option 1: Ephemeral-Only (Most Secure) ⭐ RECOMMENDED

**Flow:**
```
User selects screenshot 
  → Verify immediately
  → Award points
  → DELETE image (never stored)
```

**Pros:**
- ✅ Maximum privacy (no storage)
- ✅ No encryption needed
- ✅ No S3 costs
- ✅ GDPR/CCPA compliant by design
- ✅ No data breach risk

**Cons:**
- ❌ Can't re-verify later
- ❌ No dispute resolution evidence
- ❌ User can't view screenshot history

**Implementation:**
- Store verification result only (not image)
- Keep metadata: `verified: true/false, confidence: 0.92, date: ...`
- Delete image immediately after verification

---

### Option 2: Encrypted Local + Auto-Delete (Balanced)

**Flow:**
```
User uploads screenshot
  → Encrypt with device keychain
  → Store locally for 30 days
  → Auto-delete after expiration
  → Never upload to cloud
```

**Pros:**
- ✅ User can view recent screenshots
- ✅ No cloud storage needed
- ✅ Hardware-encrypted (iOS Keychain/Secure Enclave)
- ✅ Auto-cleanup

**Cons:**
- ❌ Lost if device is lost
- ❌ Not synced across devices
- ❌ Slightly more complex

**Implementation:**
- Use iOS Data Protection (encryption at rest)
- Set file attribute: `.completeFileProtection`
- Background task for cleanup
- Store expiration date with each image

---

### Option 3: Encrypted S3 + Lifecycle (Cloud Backup)

**Flow:**
```
User uploads screenshot
  → Encrypt locally
  → Upload to S3 (encrypted bucket)
  → S3 auto-deletes after 30 days
  → Cognito auth required for access
```

**Pros:**
- ✅ Synced across devices
- ✅ Survives device loss
- ✅ Server-side encryption (AES-256)
- ✅ Auto-cleanup with lifecycle policies
- ✅ IAM access controls

**Cons:**
- ❌ S3 storage costs (~$0.023/GB/month)
- ❌ More attack surface
- ❌ Requires S3 security hardening

**Implementation:**
- S3 bucket with SSE-S3 or SSE-KMS encryption
- Lifecycle policy: delete after 30 days
- IAM policy: user can only access their own files
- S3 bucket policy: deny non-HTTPS
- S3 logging enabled

---

## 🎯 My Recommendation: Option 1 (Ephemeral)

For a financial app with banking screenshots, **privacy should be paramount**.

### Why Ephemeral is Best:

1. **Zero Data Breach Risk**: Can't leak what you don't store
2. **Regulatory Compliance**: Easiest to defend in audit
3. **User Trust**: "We never store your banking screenshots"
4. **Cost**: $0 for storage
5. **Simplicity**: Fewer moving parts

### Verification Flow:
```swift
// User uploads screenshot
↓
// Immediate verification (2-5 seconds)
ScreenshotVerificationService.verify(image, amount)
↓
// Store result only
UserDefaults: {
  "deposit_123_verified": true,
  "deposit_123_confidence": 0.92,
  "deposit_123_verified_at": "2026-01-09T..."
}
↓
// Image discarded (never touches disk)
image = nil
```

---

## 🛡️ Implementation Plan

### Phase 1: Immediate Security Fixes (CRITICAL)

1. **Stop Storing Unencrypted Screenshots**
   - Modify `DepositScreenshotService.saveScreenshot()` to be ephemeral
   - Pass image directly to verification without saving

2. **Update Lambda to Never Log Images**
   - Add validation: no base64 data in CloudWatch logs
   - Truncate extracted text to 100 chars max

3. **Delete Existing Screenshots**
   - Add cleanup function for legacy screenshots
   - Run on app launch

### Phase 2: Enhanced Privacy (Optional)

4. **Add User Control**
   - Setting: "Delete screenshots after verification" (default: ON)
   - Setting: "Keep screenshots for X days" (if user wants history)

5. **Verification Receipt**
   - Show user: "✅ Screenshot verified (92% confidence)"
   - No need to show the actual image again

6. **Audit Trail**
   - Store verification metadata (date, confidence, result)
   - Never store the actual image

---

## 📋 Security Checklist

### iOS App
- [ ] Remove `DepositScreenshotService.saveScreenshot()` calls
- [ ] Pass images directly to verification (in-memory only)
- [ ] Add file protection attribute if storing temporarily: `.completeFileProtection`
- [ ] Exclude screenshot directory from iCloud backup
- [ ] Auto-delete screenshots on app termination
- [ ] Clear screenshots on logout
- [ ] Add "Screenshots are not stored" to privacy policy

### Lambda Function
- [ ] Verify images are NOT logged to CloudWatch
- [ ] Add max log size for extracted text (100 chars)
- [ ] Enable VPC for Lambda (optional, extra isolation)
- [ ] Rotate IAM credentials regularly

### S3 (If Used)
- [ ] Enable server-side encryption (SSE-S3 or SSE-KMS)
- [ ] Create lifecycle policy: delete after 30 days
- [ ] Set bucket policy: deny non-HTTPS requests
- [ ] Enable S3 access logging
- [ ] Restrict IAM: user can only access their own folder
- [ ] Enable S3 versioning (for accidental deletion recovery)
- [ ] Set up CloudTrail for audit logs
- [ ] Regular security audits with AWS Trusted Advisor

### API Gateway
- [ ] Enforce TLS 1.2+ only
- [ ] Enable request/response validation
- [ ] Set up WAF rules (block suspicious IPs)
- [ ] Enable CloudWatch logs (without image data)
- [ ] Rate limiting per user

---

## 💰 Cost Comparison

### Option 1: Ephemeral (Recommended)
- Storage: $0
- Verification: $0.0015 per screenshot
- **Total per 1,000 verifications**: $1.50

### Option 2: Local Encrypted
- Storage: $0 (uses device storage)
- Verification: $0.0015 per screenshot
- **Total per 1,000 verifications**: $1.50

### Option 3: S3 Encrypted
- Storage: $0.023/GB/month (~$0.001 per screenshot)
- Verification: $0.0015 per screenshot
- S3 operations: $0.005 per 1,000 requests
- **Total per 1,000 verifications**: $2.00/month + $0.005

---

## 🚨 Data Breach Scenarios

### If Ephemeral (Option 1):
- **Breach Impact**: None (no data to steal)
- **Compliance**: ✅ Easy to defend
- **User Impact**: None

### If Local Storage (Option 2):
- **Breach Impact**: One device compromised
- **Compliance**: ⚠️ Must prove encryption
- **User Impact**: 1 user affected

### If S3 Storage (Option 3):
- **Breach Impact**: Potentially all users
- **Compliance**: ❌ Major incident, reporting required
- **User Impact**: All users affected
- **Cost**: Legal fees, PR damage, fines

---

## 📜 Privacy Policy Language

### For Ephemeral Approach:
```
Screenshot Verification:
When you submit a screenshot to verify a manual deposit, we temporarily 
process the image using AI to confirm its authenticity. The screenshot 
is analyzed in real-time and immediately discarded. We do not store, 
save, or retain your banking screenshots on our servers or your device.

What we keep:
- Verification result (verified: yes/no)
- Confidence score (e.g., 92%)
- Timestamp of verification

What we DON'T keep:
- The actual screenshot image
- Banking account details
- Personal financial information from the image
```

### For Storage Approach:
```
⚠️ More complex legal language required:
- Data retention period
- Encryption methods
- Where data is stored
- User rights (access, deletion)
- Third-party processors (AWS)
- International data transfers
```

---

## 🎯 Final Recommendation

**Implement Option 1 (Ephemeral) immediately.**

This gives you:
1. ✅ Maximum privacy and security
2. ✅ Lowest compliance burden
3. ✅ Best user trust
4. ✅ Lowest cost
5. ✅ Simplest implementation

If users complain about not being able to view screenshot history, you can always add optional encrypted local storage later as an opt-in feature.

**The golden rule**: Don't store what you don't need.

