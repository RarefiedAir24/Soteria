# Screenshot Verification System - Deployment Complete ✅

## Overview
AI-powered screenshot verification system using AWS Textract to prevent fraud in manual deposit submissions. Users can earn **reduced loyalty points** (30-50% of normal rate) for verified manual deposits with screenshots.

---

## 🚀 Deployment Status

### ✅ Lambda Function
- **Name**: `soteria-verify-screenshot`
- **Runtime**: Node.js 20.x
- **Region**: us-east-1
- **Memory**: 512 MB
- **Timeout**: 30 seconds
- **ARN**: `arn:aws:lambda:us-east-1:516141816050:function:soteria-verify-screenshot`

### ✅ IAM Role
- **Name**: `soteria-verify-screenshot-role`
- **Permissions**:
  - CloudWatch Logs (create log groups, streams, put events)
  - AWS Textract (DetectDocumentText, AnalyzeDocument)

### ✅ API Gateway
- **API ID**: `g3ksyd36e5`
- **Endpoint**: `https://g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod/soteria/verify-screenshot`
- **Method**: POST
- **Stage**: prod
- **Integration**: Lambda Proxy

---

## 🔒 How It Works

### 1. User Flow
```
User records manual deposit → Uploads screenshot → System verifies → Awards points
```

### 2. Verification Process

#### **Local Pre-Screening** (iOS App)
Fast checks before sending to AWS:
- ✅ Image aspect ratio (0.4-0.7 for phone screenshots)
- ✅ Minimum resolution (300x400)
- ✅ Amount range ($0.01 - $100,000)

#### **AWS Textract Analysis** (Backend)
1. Extract all text from image using OCR
2. Search for banking keywords:
   - `deposit`, `transfer`, `transaction`, `bank`, `checking`, `savings`
   - Bank names: `chase`, `wells fargo`, `bank of america`, etc.
   - Payment apps: `venmo`, `zelle`, `paypal`, `cash app`
3. Find dollar amounts in extracted text
4. Verify claimed amount matches extracted amount (±10% tolerance)
5. Look for date patterns (legitimate transactions have timestamps)
6. Calculate confidence score (0-100%)

#### **Fraud Detection**
Flags suspicious patterns:
- ❌ No banking keywords found
- ❌ Claimed amount not in screenshot
- ❌ No date found
- ❌ Insufficient text (<50 characters)
- ❌ Too many round numbers (>3)

### 3. Point Awards

| Confidence | Points Awarded | Example |
|------------|---------------|---------|
| 90%+ | 50% of deposit | $100 deposit = 50 points |
| 70-89% | 30% of deposit | $100 deposit = 30 points |
| <70% | 0% (rejected) | $100 deposit = 0 points |

**Compare to automatic deposits:**
- Plaid-verified deposits: 100% points ($100 = 100 points)
- Manual with screenshot: 30-50% points ($100 = 30-50 points)
- Manual without screenshot: 0% points

---

## 📊 Example Verification Results

### ✅ Legitimate Screenshot
```json
{
  "is_valid": true,
  "confidence": 0.92,
  "extracted_amount": 247.50,
  "found_keywords": ["chase", "bank", "deposit", "checking"],
  "fraud_indicators": [],
  "reason": "Screenshot verified with 92% confidence"
}
```
**Result**: User earns 123 points (50% of $247.50)

### ❌ Fake Screenshot
```json
{
  "is_valid": false,
  "confidence": 0.10,
  "extracted_amount": null,
  "found_keywords": [],
  "fraud_indicators": [
    "No banking keywords found",
    "Claimed amount not found in screenshot",
    "No date found"
  ],
  "reason": "Verification failed"
}
```
**Result**: User earns 0 points

---

## 🧪 Testing

### Test Lambda Directly
```bash
cd lambda/soteria-verify-screenshot

aws lambda invoke \
  --function-name soteria-verify-screenshot \
  --region us-east-1 \
  --cli-binary-format raw-in-base64-out \
  --payload file://test-event.json \
  response.json

cat response.json
```

### Test via API Gateway
```bash
curl -X POST https://g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod/soteria/verify-screenshot \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_COGNITO_TOKEN" \
  -d '{
    "image": "BASE64_ENCODED_IMAGE",
    "claimed_amount": 100.50
  }'
```

### Test from iOS App
1. Record a manual deposit
2. Upload a screenshot
3. Check console logs for verification result
4. Verify loyalty points awarded (if successful)

---

## 💰 Cost Estimation

### Per Verification
- **Lambda**: ~$0.0000002 (compute time)
- **Textract**: ~$0.0015 (per page analyzed)
- **API Gateway**: ~$0.0000035 (per request)
- **Total**: ~$0.0015 per screenshot

### Monthly Estimates
| Verifications/Month | Cost |
|---------------------|------|
| 100 | $0.15 |
| 1,000 | $1.50 |
| 10,000 | $15.00 |
| 100,000 | $150.00 |

**Note**: Textract is the primary cost driver at $1.50 per 1,000 pages.

---

## 🔐 Security Features

### 1. Reduced Rewards
- Max 50% points limits appeal of fraud
- Not worth the effort to fake screenshots

### 2. Multi-Factor Verification
- Must pass multiple validation layers
- Single failure = rejection

### 3. Amount Matching
- Can't claim $1,000 with a $10 screenshot
- ±10% tolerance for rounding/fees

### 4. Keyword Detection
- Must contain banking terminology
- Generic images rejected

### 5. Pattern Detection
- Flags suspicious patterns
- Too many round numbers = red flag

### 6. Asynchronous Processing
- Doesn't block user flow
- Points awarded after verification

### 7. No Storage
- Images processed in-memory
- Not stored on servers

---

## 📱 iOS Integration

### Files Modified
1. **`ScreenshotVerificationService.swift`** (NEW)
   - Handles screenshot verification API calls
   - Local pre-screening
   - Result parsing

2. **`PlaidService.swift`**
   - Integrated verification into `recordManualDeposit()`
   - Asynchronous point awards
   - Logging for debugging

3. **`LoyaltyPointsService.swift`**
   - Added `addPointsManual()` for verified screenshots
   - Syncs to AWS after point awards

### Code Flow
```swift
// User records manual deposit with screenshot
PlaidService.recordManualDeposit(amount: 100, screenshot: image)
  ↓
// Load screenshot from storage
DepositScreenshotService.loadScreenshot(for: depositId)
  ↓
// Verify screenshot
ScreenshotVerificationService.verifyScreenshot(image: screenshot, claimedAmount: 100)
  ↓
// Award points if verified
if verification.shouldAwardPoints {
    let points = Int(amount * verification.pointsMultiplier)
    LoyaltyPointsService.shared.addPointsManual(points)
}
```

---

## 🛠️ Maintenance

### View Logs
```bash
aws logs tail /aws/lambda/soteria-verify-screenshot --follow --region us-east-1
```

### Update Lambda Code
```bash
cd lambda/soteria-verify-screenshot
npm run deploy
```

### Monitor Performance
- CloudWatch Metrics: Duration, Errors, Throttles
- CloudWatch Logs: Verification results, fraud indicators
- API Gateway: Request count, latency, errors

### Adjust Verification Rules
Edit `lambda/soteria-verify-screenshot/index.js`:
- Add/remove banking keywords
- Adjust confidence thresholds
- Modify fraud detection logic

### Adjust Point Rewards
Edit `soteria/Services/ScreenshotVerificationService.swift`:
```swift
var pointsMultiplier: Double {
    if confidence >= 0.9 { return 0.5 }      // 50% points
    else if confidence >= 0.7 { return 0.3 } // 30% points
    else { return 0.0 }                      // No points
}
```

---

## 🚨 Known Limitations

1. **Textract Accuracy**: OCR may fail on poor quality images
2. **Cost**: $1.50 per 1,000 verifications (Textract pricing)
3. **Latency**: 2-5 seconds per verification (Textract processing time)
4. **Language**: Currently English only
5. **Image Size**: Large images (>5MB) may timeout

---

## 🎯 Future Enhancements

### Phase 2 (Optional)
- [ ] Add machine learning model for better fraud detection
- [ ] Support multiple languages (Spanish, Chinese, etc.)
- [ ] Cache verification results to prevent re-verification
- [ ] Add user reputation scoring (frequent fraud = lower trust)
- [ ] Implement image quality checks (blur detection, resolution)
- [ ] Add support for video verification (screen recordings)

### Phase 3 (Optional)
- [ ] Train custom ML model on legitimate bank screenshots
- [ ] Implement bank-specific verification rules
- [ ] Add OCR confidence scoring
- [ ] Support receipt verification (not just bank screenshots)

---

## 📞 Support

### Debugging
1. Check CloudWatch logs for verification details
2. Look for fraud indicators in response
3. Verify image quality and content
4. Test with known good screenshots

### Common Issues

**Issue**: "No banking keywords found"
- **Solution**: Screenshot must contain banking terminology

**Issue**: "Claimed amount not found in screenshot"
- **Solution**: Dollar amount must be visible in image

**Issue**: "Insufficient text in image"
- **Solution**: Screenshot too small or cropped

**Issue**: "Verification timeout"
- **Solution**: Image too large, reduce size/quality

---

## ✅ Deployment Checklist

- [x] Lambda function created
- [x] IAM role with Textract permissions
- [x] API Gateway endpoint configured
- [x] Lambda invoke permissions set
- [x] iOS app integrated
- [x] Test verification successful
- [x] Point awards working
- [x] Logging enabled
- [x] Documentation complete

---

## 🎉 Summary

The screenshot verification system is **fully deployed and operational**! 

Users can now:
- ✅ Upload screenshots with manual deposits
- ✅ Earn loyalty points for verified deposits (30-50% rate)
- ✅ See verification results in real-time

The system:
- ✅ Prevents fraud with AI-powered verification
- ✅ Awards reduced points to limit abuse
- ✅ Processes asynchronously for smooth UX
- ✅ Costs ~$0.0015 per verification

**Next**: Monitor CloudWatch logs for verification patterns and adjust rules as needed.

