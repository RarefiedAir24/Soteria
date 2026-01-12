# 🎁 Tremendous API Integration Plan for Soteria

**Prepared for:** Wednesday, Jan 14, 2026 Call  
**Date:** Sunday, Jan 12, 2026

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [Finding Your API Key](#finding-your-api-key)
3. [Current Soteria Architecture](#current-soteria-architecture)
4. [Tremendous Integration Architecture](#tremendous-integration-architecture)
5. [Technical Implementation Plan](#technical-implementation-plan)
6. [Cost & Economics](#cost--economics)
7. [Questions for Wednesday Call](#questions-for-wednesday-call)
8. [Next Steps](#next-steps)

---

## 🎯 Executive Summary

### What We're Building

**Soteria** is a savings app that rewards users with **loyalty points** for achieving their savings goals. Users can redeem these points for **real gift cards** via the **Tremendous API**.

### Current State

- ✅ **Loyalty points system fully built** - users earn points per dollar saved (10 pts/$1)
- ✅ **Gift card UI fully designed** - beautiful, conversion-optimized UX
- ✅ **Premium subscription gating** - gift cards only for Premium users
- ✅ **Monthly redemption caps** - $250/month for Premium, $500/month for Tier 2
- ⏳ **Backend integration needed** - connect to Tremendous API

### Integration Goal

Connect Soteria's loyalty system to Tremendous's 2,000+ payout methods to deliver **real gift cards** (Amazon, Visa, Target, Starbucks, Walmart) when users redeem points.

---

## 🔍 Finding Your API Key

### Step 1: Navigate to API Keys Section

You mentioned you can't find the API section. Try these:

1. **Primary Path:** 
   - Go to: `https://app.tremendous.com/teams/YOUR_TEAM_ID/settings`
   - Look for: **"API Keys"** or **"Developers"** tab

2. **Alternative Paths:**
   - Top navigation → **Settings** → **API Keys**
   - Left sidebar → **Integrations** → **API Access**
   - Search bar (top right) → type **"API"**

3. **Sandbox Environment:**
   - Sandbox might be separate: `https://testflight.tremendous.com`
   - Check your email for sandbox invitation link

### Step 2: Create Sandbox API Key

According to [Tremendous docs](https://developers.tremendous.com/docs/introduction):
- Sandbox is **free and open**
- You should see a button: **"Create API Key"** or **"Generate Key"**
- Name it: `Soteria Sandbox Key`

### Step 3: Store Securely

```bash
# Add to .env or secrets manager
TREMENDOUS_API_KEY=YOUR_SANDBOX_KEY_HERE
TREMENDOUS_ENVIRONMENT=sandbox
```

### 📧 If You Can't Find It

**Contact Tremendous support before Wednesday:**
- Email: support@tremendous.com
- Mention: "Preparing for Jan 14 call, need sandbox API access"
- Reference: Your team ID from the URL

---

## 🏗️ Current Soteria Architecture

### Loyalty Points System

**File:** `soteria/Services/LoyaltyPointsService.swift`

#### Key Features

1. **Point Earning:**
   - $1 saved = 10 points
   - Goal completion bonus: 5,000 points
   - Streak bonus: 1.5x multiplier

2. **Point Economics:**
   - **500 points = $1 gift card value**
   - Example: $5 gift card costs 2,500 points
   - Example: $10 gift card costs 5,000 points

3. **Premium Gating:**
   - Only Premium users can earn & redeem
   - Free users see "frozen" points (preserved but locked)

4. **Gift Cards Available:**
   ```swift
   GiftCard.availableCards:
   - Visa: $5, $10, $25, $50, $100
   - Amazon: $5, $10, $25, $50, $100
   - Target: $5, $10, $25, $50, $100
   - Walmart: $5, $10, $25, $50, $100
   - Starbucks: $5, $10, $25
   ```

### Current Redemption Flow

**File:** `soteria/Services/LoyaltyPointsService.swift:333-437`

```swift
func redeemGiftCard(
    giftCard: GiftCard, 
    userId: String, 
    email: String
) async throws -> GiftCardRedemption {
    // 1. Check Premium status
    guard isLoyaltyEnabled else {
        throw GiftCardRedemptionError.premiumRequired
    }
    
    // 2. Check points balance
    guard totalPoints >= giftCard.pointsCost else {
        throw GiftCardRedemptionError.insufficientPoints
    }
    
    // 3. Call backend Lambda ⬅️ THIS NEEDS TO CALL TREMENDOUS
    let redemption = try await callRedemptionAPI(...)
    
    // 4. Deduct points locally
    addPoints(-giftCard.pointsCost, ...)
    
    return redemption
}
```

**Current Issue:** Line 376 shows placeholder:
```swift
let endpoint = "https://YOUR_API_GATEWAY_URL/redeem-gift-card"
```

---

## 🔌 Tremendous Integration Architecture

### High-Level Flow

```
┌─────────────┐
│  Soteria    │
│  iOS App    │
└──────┬──────┘
       │ 1. User redeems 2,500 points for $5 Amazon
       ▼
┌─────────────────────┐
│  AWS API Gateway    │ ← Authenticated with Cognito JWT
└──────┬──────────────┘
       │ 2. Verify user, points, Premium status
       ▼
┌─────────────────────┐
│  AWS Lambda         │
│  (Node.js)          │
│                     │
│  - Validate request │
│  - Call Tremendous  │
│  - Log transaction  │
└──────┬──────────────┘
       │ 3. POST /orders (Tremendous API)
       ▼
┌─────────────────────┐
│  Tremendous API     │
│  https://api.        │
│  tremendous.com     │
└──────┬──────────────┘
       │ 4. Returns reward link
       ▼
┌─────────────────────┐
│  User's Email       │
│  Gift Card Link     │
└─────────────────────┘
```

### Why AWS Lambda?

1. **Security:** Never expose Tremendous API key in iOS app
2. **Validation:** Server-side verification of points balance
3. **Fraud Prevention:** Rate limiting, duplicate detection
4. **Logging:** Audit trail for all redemptions
5. **Webhooks:** Handle Tremendous callbacks

---

## 🛠️ Technical Implementation Plan

### Phase 1: Sandbox Testing (This Week)

#### 1.1 Get Tremendous Sandbox Access ✅

- [x] Access granted (you have it!)
- [ ] Find API key (see above)
- [ ] Test API key with curl

#### 1.2 Test Tremendous API Manually

**Test 1: Create an order**

```bash
curl https://testflight.tremendous.com/api/v2/orders \
  -X POST \
  -H "Authorization: Bearer YOUR_SANDBOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "external_id": "test-order-001",
    "payment": {
      "funding_source_id": "BALANCE"
    },
    "reward": {
      "value": {
        "denomination": 5,
        "currency_code": "USD"
      },
      "delivery": {
        "method": "EMAIL"
      },
      "recipient": {
        "name": "Test User",
        "email": "your-email@example.com"
      },
      "products": [
        "AMAZON"
      ]
    }
  }'
```

**Expected Response:**

```json
{
  "order": {
    "id": "ORD123456",
    "external_id": "test-order-001",
    "status": "PENDING",
    "reward": {
      "id": "RWD789012",
      "value": {
        "denomination": 5,
        "currency_code": "USD"
      },
      "delivery": {
        "method": "EMAIL",
        "status": "SCHEDULED",
        "link": "https://tremendous.com/rewards/ABC123"
      }
    }
  }
}
```

#### 1.3 Understand Tremendous Concepts

From [Tremendous docs](https://developers.tremendous.com/docs/introduction):

1. **Products:** Gift card brands (e.g., "AMAZON", "VISA", "TARGET")
2. **Orders:** A single redemption request
3. **Rewards:** The actual gift card sent to user
4. **Funding Sources:** How you pay (Balance, Invoice, Credit Card)
5. **Campaigns:** Optional templates for branding/styling

**Key Question for Wednesday:** How do we map our `tremendousCampaignId` to actual Tremendous product IDs?

---

### Phase 2: AWS Lambda Backend (Week of Jan 13-17)

#### 2.1 Create Lambda Function

**File:** `lambda/redeem-gift-card/index.js`

```javascript
const https = require('https');

// Tremendous API configuration
const TREMENDOUS_API_KEY = process.env.TREMENDOUS_API_KEY;
const TREMENDOUS_BASE_URL = process.env.TREMENDOUS_ENV === 'production' 
  ? 'https://api.tremendous.com'
  : 'https://testflight.tremendous.com';

// Product mapping
const PRODUCT_MAP = {
  'AMAZON_5': 'AMAZON',
  'AMAZON_10': 'AMAZON',
  'AMAZON_25': 'AMAZON',
  'VISA_5': 'VISA',
  'VISA_10': 'VISA',
  'TARGET_5': 'TARGET',
  // ... etc
};

exports.handler = async (event) => {
  try {
    // 1. Parse request
    const body = JSON.parse(event.body);
    const { userId, giftCardId, pointsToSpend, email, brand, amount } = body;
    
    // 2. Validate user (check JWT token)
    const userIdFromToken = event.requestContext.authorizer.claims.sub;
    if (userId !== userIdFromToken) {
      return errorResponse(403, 'Unauthorized');
    }
    
    // 3. Verify Premium status (query DynamoDB or Cognito)
    const isPremium = await checkPremiumStatus(userId);
    if (!isPremium) {
      return errorResponse(403, 'Premium subscription required');
    }
    
    // 4. Verify points balance (query DynamoDB)
    const userPoints = await getUserPoints(userId);
    if (userPoints < pointsToSpend) {
      return errorResponse(400, 'Insufficient points');
    }
    
    // 5. Check monthly cap
    const remainingCap = await getMonthlyRemainingCap(userId);
    if (amount > remainingCap) {
      return errorResponse(400, `Monthly cap exceeded. $${remainingCap} remaining.`);
    }
    
    // 6. Call Tremendous API
    const tremendousOrder = await createTremendousOrder({
      externalId: `soteria-${userId}-${Date.now()}`,
      amount: amount,
      currency: 'USD',
      product: PRODUCT_MAP[giftCardId] || brand.toUpperCase(),
      recipientEmail: email,
      recipientName: 'Soteria User'
    });
    
    // 7. Log redemption to DynamoDB
    await logRedemption({
      redemptionId: tremendousOrder.reward.id,
      userId,
      giftCardId,
      brand,
      amount,
      pointsSpent: pointsToSpend,
      tremendousOrderId: tremendousOrder.id,
      rewardLink: tremendousOrder.reward.delivery.link,
      status: 'delivered',
      timestamp: new Date().toISOString()
    });
    
    // 8. Update monthly cap usage
    await incrementMonthlyCapUsage(userId, amount);
    
    // 9. Return success
    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        redemptionId: tremendousOrder.reward.id,
        tremendousOrderId: tremendousOrder.id,
        rewardLink: tremendousOrder.reward.delivery.link,
        message: 'Gift card sent to your email!'
      })
    };
    
  } catch (error) {
    console.error('Redemption error:', error);
    return errorResponse(500, error.message);
  }
};

// Helper: Call Tremendous API
async function createTremendousOrder({ externalId, amount, currency, product, recipientEmail, recipientName }) {
  const payload = {
    external_id: externalId,
    payment: {
      funding_source_id: 'BALANCE' // TODO: Confirm with Tremendous on Wednesday
    },
    reward: {
      value: {
        denomination: amount,
        currency_code: currency
      },
      delivery: {
        method: 'EMAIL'
      },
      recipient: {
        name: recipientName,
        email: recipientEmail
      },
      products: [product]
    }
  };
  
  return new Promise((resolve, reject) => {
    const options = {
      hostname: TREMENDOUS_BASE_URL.replace('https://', ''),
      path: '/api/v2/orders',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${TREMENDOUS_API_KEY}`,
        'Content-Type': 'application/json'
      }
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200 || res.statusCode === 201) {
          resolve(JSON.parse(data).order);
        } else {
          reject(new Error(`Tremendous API error: ${res.statusCode} ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(JSON.stringify(payload));
    req.end();
  });
}

function errorResponse(statusCode, message) {
  return {
    statusCode,
    body: JSON.stringify({ error: message })
  };
}
```

#### 2.2 DynamoDB Tables Needed

**Table 1: Redemptions Log**
```
Table: soteria-gift-card-redemptions
Partition Key: redemptionId (String)
Sort Key: timestamp (String)

Attributes:
- userId
- giftCardId
- brand
- amount
- pointsSpent
- tremendousOrderId
- rewardLink
- status (delivered, pending, failed)
- recipientEmail
```

**Table 2: Monthly Cap Tracking**
```
Table: soteria-monthly-redemption-caps
Partition Key: userId (String)
Sort Key: month (String) e.g., "2026-01"

Attributes:
- totalRedeemed (Number)
- redemptionCount (Number)
- lastUpdated (String)
```

#### 2.3 API Gateway Setup

**Endpoint:** `POST /redeem-gift-card`

**Authorization:** AWS Cognito JWT (already implemented in Soteria)

**CORS:** Allow soteria app origins

---

### Phase 3: Update iOS App (Week of Jan 20-24)

#### 3.1 Update `callRedemptionAPI` Function

**File:** `soteria/Services/LoyaltyPointsService.swift:374`

Replace placeholder with real endpoint:

```swift
private func callRedemptionAPI(giftCard: GiftCard, userId: String, email: String) async throws -> GiftCardRedemption {
    // PRODUCTION ENDPOINT (update after Lambda deployment)
    let endpoint = "https://YOUR_API_GATEWAY_ID.execute-api.us-east-1.amazonaws.com/prod/redeem-gift-card"
    
    guard let url = URL(string: endpoint) else {
        throw GiftCardRedemptionError.invalidEndpoint
    }
    
    let payload: [String: Any] = [
        "userId": userId,
        "giftCardId": giftCard.id,
        "pointsToSpend": giftCard.pointsCost,
        "email": email,
        "brand": giftCard.brand,
        "amount": giftCard.amount
    ]
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    
    // Add Cognito JWT token
    if let authService = try? AuthService(),
       let idToken = await authService.getCurrentUserIdToken() {
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
    }
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw GiftCardRedemptionError.invalidResponse
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
        // Parse error message from backend
        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorMessage = errorJson["error"] as? String {
            throw GiftCardRedemptionError.serverError(code: httpResponse.statusCode, message: errorMessage)
        }
        throw GiftCardRedemptionError.serverError(code: httpResponse.statusCode, message: nil)
    }
    
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw GiftCardRedemptionError.invalidResponse
    }
    
    // Parse successful response
    let redemptionId = json["redemptionId"] as? String ?? UUID().uuidString
    let redemptionLink = json["rewardLink"] as? String
    let tremendousOrderId = json["tremendousOrderId"] as? String
    
    let redemption = GiftCardRedemption(
        id: redemptionId,
        userId: userId,
        giftCardId: giftCard.id,
        brand: giftCard.brand,
        amount: giftCard.amount,
        pointsSpent: giftCard.pointsCost,
        redemptionDate: Date(),
        redemptionCode: nil,
        redemptionLink: redemptionLink,
        status: .delivered,
        tremendousOrderId: tremendousOrderId
    )
    
    return redemption
}
```

#### 3.2 Add AuthService Token Method

**File:** `soteria/Services/AuthService.swift`

Add this method if not already present:

```swift
func getCurrentUserIdToken() async throws -> String? {
    guard let user = currentUser else {
        throw AuthError.notAuthenticated
    }
    
    // Get fresh ID token from Cognito
    return try await withCheckedThrowingContinuation { continuation in
        user.getSession { (session, error) in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let idToken = session?.idToken?.tokenString {
                continuation.resume(returning: idToken)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
```

#### 3.3 Update Error Handling

**File:** `soteria/Services/LoyaltyPointsService.swift:439`

Update error enum:

```swift
enum GiftCardRedemptionError: Error, LocalizedError {
    case premiumRequired
    case insufficientPoints(needed: Int, available: Int)
    case invalidEndpoint
    case invalidResponse
    case serverError(code: Int, message: String?)
    case monthlyCapExceeded(remaining: Double)
    
    var errorDescription: String? {
        switch self {
        case .premiumRequired:
            return "Premium subscription required to redeem gift cards"
        case .insufficientPoints(let needed, let available):
            return "Insufficient points. Need \(needed), have \(available)"
        case .invalidEndpoint:
            return "Invalid API endpoint"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            if let msg = message {
                return "Server error: \(msg)"
            }
            return "Server error (code: \(code))"
        case .monthlyCapExceeded(let remaining):
            return "Monthly redemption cap exceeded. $\(String(format: "%.2f", remaining)) remaining."
        }
    }
}
```

---

## 💰 Cost & Economics

### Soteria's Point Economics

**Current Setup:**
- User saves $1 → Earns 10 points
- 500 points = $1 gift card value
- Therefore: User must save **$50 to earn a $1 gift card**

**Example:**
- User saves $250 → Earns 2,500 points
- Redeems: $5 Amazon gift card (costs 2,500 points)
- **User saved $250, got $5 reward = 2% reward rate**

### Tremendous Pricing

According to [Tremendous](https://developers.tremendous.com/docs/introduction):
- **No markup on face value**
- **No transaction fees**
- **You pay exactly what you give** (e.g., $5 gift card costs you $5)

**Example:**
- User redeems $5 Amazon → Tremendous charges Soteria $5
- User redeems $25 Visa → Tremendous charges Soteria $25

### Monthly Economics for Soteria

Assuming 1,000 Premium users with average $10/month redemption:

**Monthly Cost:**
- 1,000 users × $10 = **$10,000/month** to Tremendous

**Monthly Revenue (from Premium):**
- 1,000 users × $7.99/month = **$7,990/month**

⚠️ **Important:** If average redemption > $7.99/user, you lose money!

### Risk Mitigation

1. **Monthly caps** - already implemented ✅
   - Premium: $250/month max
   - Tier 2: $500/month max

2. **Point earning rate** - already conservative ✅
   - 2% reward rate (user saves $50 to earn $1)

3. **Gamification focus** - not just rewards
   - Money tree decorations (points, not cash)
   - Achievements
   - Social features

### Questions for Tremendous on Wednesday

1. **Pricing:** Confirm no hidden fees, just face value?
2. **Volume discounts:** Any discounts for high volume?
3. **Funding:** How does funding source work? Pre-fund account or invoice?
4. **Limits:** Any transaction limits or velocity limits?

---

## ❓ Questions for Wednesday Call

### Technical Questions

1. **Product IDs:**
   - How do we get a list of all available product IDs?
   - Is it "AMAZON" or "AMAZON_GIFT_CARD" or something else?
   - Can we programmatically query available products by denomination?

2. **Funding Sources:**
   - What's the best funding method for startups?
   - Pre-funded balance vs. invoice vs. credit card?
   - Minimum balance requirements?

3. **Webhooks:**
   - What webhook events do you send?
   - Do we need webhooks for delivery confirmation?
   - What happens if email delivery fails?

4. **Error Handling:**
   - What error codes should we handle?
   - Retry logic recommendations?
   - Duplicate order prevention?

5. **Rate Limiting:**
   - What are the rate limits?
   - Best practices for high-volume apps?

6. **Testing:**
   - Can we reset sandbox data?
   - Test credit cards for funding?
   - How do we test refunds/cancellations?

### Business Questions

7. **Pricing & Fees:**
   - Confirm: Face value only, no markup?
   - Any setup fees or monthly minimums?
   - Volume discounts available?

8. **Production Access:**
   - What's required for production approval?
   - KYC/compliance requirements?
   - Timeline for production access?

9. **Support:**
   - What support do we get during integration?
   - SLA for API uptime?
   - Who to contact for urgent issues?

10. **Best Practices:**
    - Any fraud prevention recommendations?
    - Common mistakes to avoid?
    - Success stories from similar apps?

---

## 📅 Next Steps

### Before Wednesday Call (Jan 14)

- [ ] Find Tremendous sandbox API key
- [ ] Test Tremendous API with curl (see Phase 1.2 above)
- [ ] Review [Tremendous API docs](https://developers.tremendous.com/docs/introduction)
- [ ] Prepare questions from above list

### After Wednesday Call (Jan 15-17)

- [ ] Map Tremendous product IDs to Soteria gift cards
- [ ] Start AWS Lambda development
- [ ] Set up DynamoDB tables
- [ ] Deploy Lambda to dev environment

### Week of Jan 20-24

- [ ] Update iOS app with real API endpoint
- [ ] End-to-end testing in sandbox
- [ ] Security audit
- [ ] Load testing

### Week of Jan 27-31

- [ ] Request production access from Tremendous
- [ ] Production deployment
- [ ] Launch! 🚀

---

## 🎯 Summary

**You're in great shape!** Your loyalty system is fully built and ready. The integration is straightforward:

1. ✅ **iOS app UI:** Complete and beautiful
2. ✅ **Points system:** Working and tested
3. ✅ **Business logic:** Premium gating, caps, all set
4. ⏳ **Only missing:** Lambda backend to call Tremendous

**Focus for Wednesday:**
- Get product ID mappings
- Understand funding/billing
- Clarify production access timeline

Let me know if you find the API key or need help with anything else! 🚀
