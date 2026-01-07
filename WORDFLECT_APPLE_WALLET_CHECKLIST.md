# Wordflect Backend Status

## ✅ Confirmed: Wordflect Does NOT Need Apple Wallet

Wordflect does not require Apple Wallet integration.

## 📋 Wordflect Lambda Functions Status

### Existing Lambda Functions
Wordflect already has Lambda functions deployed:
- ✅ `wordflect-backend-dev-signin`
- ✅ `wordflect-backend-dev-signup`

These are separate from Soteria and use the `wordflect-` prefix for isolation.

### No Additional Setup Needed
Unless Wordflect needs new features or endpoints, no additional Lambda setup is required.

---

## Decision: Does Wordflect Need Apple Wallet? (Historical Reference)

### Consider These Factors:

1. **Premium Memberships?**
   - Does Wordflect have premium/subscription tiers?
   - Are there member cards or membership levels?
   - Would a Wallet pass add value?

2. **Partner/Loyalty Integration?**
   - Does Wordflect have partner discounts?
   - Would merchants need to scan/validate memberships?
   - Is there a QR code or barcode system?

3. **User Experience Benefits?**
   - Would users benefit from quick access via Wallet?
   - Is membership validation needed offline?
   - Would it enhance the premium experience?

## If YES - Setup Requirements

### Separate Resources Needed (Isolated from Soteria)

Wordflect would need its own complete setup:

1. **Apple Developer Portal**
   - Separate Pass Type ID: `pass.com.wordflect.member` (or your bundle ID structure)
   - Separate certificates (Pass Type ID + WWDR)
   - Same Team ID (if same organization)

2. **AWS Infrastructure**
   - Lambda Function: `wordflect-apple-wallet-pass`
   - API Gateway: Separate endpoint (or separate resource path)
   - S3 Bucket: `wordflect-wallet-passes` (or use existing Wordflect bucket)
   - Separate pass assets (logo.png, icon.png)

3. **iOS App Code**
   - `WordflectWalletService.swift` (similar to `AppleWalletService.swift`)
   - Update member card view to call backend

### Setup Process (Similar to Soteria)

1. **Backend Setup** (Can do now)
   - Create Lambda function
   - Configure API Gateway endpoint
   - Create S3 bucket
   - Prepare pass assets

2. **After Organization Approval**
   - Register Pass Type ID
   - Download certificates
   - Upload to S3
   - Update Lambda environment

### Resource Naming Convention

Following the existing pattern:
- **Lambda**: `wordflect-apple-wallet-pass`
- **S3 Bucket**: `wordflect-wallet-passes`
- **API Gateway**: Use existing Wordflect API Gateway or create separate resource path
- **Pass Type ID**: `pass.com.wordflect.member` (or match your bundle ID)

### Code Reuse

You can reuse the Soteria Lambda code as a template:
- Copy `lambda/soteria-apple-wallet-pass/` to `lambda/wordflect-apple-wallet-pass/`
- Update environment variables
- Update pass JSON structure for Wordflect branding
- Update iOS service code

## If NO - Skip This Feature

If Wordflect doesn't have:
- Premium memberships
- Member cards
- Partner/loyalty programs
- Need for offline validation

Then Apple Wallet may not be necessary.

## Recommendation

**Wait to decide** until:
1. Organization transition is complete
2. You've completed Soteria Apple Wallet setup
3. You can assess if Wordflect would benefit from the same feature

The setup process is identical, so once you've done it for Soteria, doing it for Wordflect would be straightforward.

---

## Quick Comparison

| Feature | Soteria | Wordflect |
|---------|---------|-----------|
| Premium Memberships | ✅ Yes | ❓ ? |
| Member Cards | ✅ Yes | ❓ ? |
| Partner Discounts | ✅ Yes | ❓ ? |
| Apple Wallet Needed | ✅ Yes | ❓ ? |

