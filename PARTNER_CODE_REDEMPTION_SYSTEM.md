# Partner Code Redemption System

## Overview

This document outlines how a **partner-provided code redemption system** would work alongside the existing barcode-based validation system.

---

## Current System vs. Code System

### Current System (Barcode-Based)
```
Member shows card → Partner scans barcode → Partner validates via API → Discount applied
```

### Proposed System (Code-Based)
```
Partner provides code → Member enters code in app → App validates code → Redemption recorded
```

---

## How It Would Work

### 1. **Partner Code Management**

Partners would generate codes through their dashboard or API:

**Code Properties:**
- `code`: Unique redemption code (e.g., "ACME2024", "COFFEE15")
- `partner_id`: Which partner owns this code
- `discount_percentage` or `discount_amount`: Benefit value
- `valid_from`: Start date
- `valid_until`: Expiration date
- `max_uses`: Total times code can be used (across all users)
- `max_uses_per_user`: Times a single user can use it
- `is_active`: Whether code is currently active

**Example:**
```json
{
  "code": "ACME2024",
  "partner_id": "demo-acme-partner",
  "discount_percentage": 10,
  "valid_from": "2024-01-01",
  "valid_until": "2024-12-31",
  "max_uses": 1000,
  "max_uses_per_user": 3,
  "is_active": true
}
```

---

### 2. **Database Schema**

**New DynamoDB Table: `soteria-partner-codes`**

```javascript
{
  code: "ACME2024",                    // Partition key
  partner_id: "demo-acme-partner",
  discount_percentage: 10,
  discount_amount: null,
  valid_from: "2024-01-01T00:00:00Z",
  valid_until: "2024-12-31T23:59:59Z",
  max_uses: 1000,
  max_uses_per_user: 3,
  is_active: true,
  created_at: "2024-01-01T00:00:00Z",
  created_by: "partner_id or admin"
}
```

**New DynamoDB Table: `soteria-code-redemptions`**

```javascript
{
  redemption_id: "redemption-123",     // Partition key
  code: "ACME2024",
  user_id: "user-456",
  partner_id: "demo-acme-partner",
  discount_amount: 5.00,
  redeemed_at: "2024-01-15T10:30:00Z"
}
```

**GSI (Global Secondary Index):**
- `code-redeemed_at-index`: Query redemptions by code
- `user_id-redeemed_at-index`: Query user's code redemptions

---

### 3. **API Endpoints**

#### **Validate Code**
```
POST /soteria/partner/validate-code
```

**Request:**
```json
{
  "code": "ACME2024",
  "user_id": "user-456"
}
```

**Response:**
```json
{
  "success": true,
  "valid": true,
  "code_info": {
    "code": "ACME2024",
    "partner_id": "demo-acme-partner",
    "partner_name": "ACME",
    "discount_percentage": 10,
    "discount_amount": null,
    "valid_until": "2024-12-31T23:59:59Z",
    "max_uses_per_user": 3,
    "user_uses_remaining": 2
  },
  "error": null
}
```

#### **Redeem Code**
```
POST /soteria/partner/redeem-code
```

**Request:**
```json
{
  "code": "ACME2024",
  "user_id": "user-456"
}
```

**Response:**
```json
{
  "success": true,
  "redemption": {
    "redemption_id": "redemption-123",
    "code": "ACME2024",
    "user_id": "user-456",
    "partner_id": "demo-acme-partner",
    "discount_amount": 5.00,
    "redeemed_at": "2024-01-15T10:30:00Z"
  }
}
```

---

### 4. **App UI/UX**

#### **Option A: Code Entry on Partner Card** ✅ Recommended

Add a "Redeem Code" section to the partner card:

```
┌─────────────────────────────┐
│  ACME                       │
│  10% Discount               │
│  Valid until 12/31/2026     │
│                             │
│  [Redeem Code]              │ ← New button
│                             │
│  [View Details]             │
└─────────────────────────────┘
```

**When tapped:**
- Shows text field to enter code
- Validates code in real-time
- Shows success/error message
- Records redemption

#### **Option B: Dedicated Code Redemption View**

Add a new section in Partner Benefits:
- "Redeem Partner Code" button
- Code entry field
- List of available codes (if partner provides multiple)

#### **Option C: Settings/Profile Section**

Add "Partner Codes" section where members can:
- Enter codes
- View redeemed codes
- See code history

---

### 5. **Implementation Flow**

#### **Step 1: Partner Creates Code**
1. Partner logs into dashboard
2. Navigates to "Manage Codes"
3. Creates new code with properties
4. Code is stored in `soteria-partner-codes` table

#### **Step 2: Member Enters Code**
1. Member opens Partner Benefits in app
2. Taps on partner card
3. Taps "Redeem Code" button
4. Enters code (e.g., "ACME2024")
5. App calls `/soteria/partner/validate-code`

#### **Step 3: Validation**
1. Lambda checks:
   - Code exists
   - Code is active
   - Code not expired
   - User hasn't exceeded `max_uses_per_user`
   - Code hasn't exceeded `max_uses` (total)
2. Returns validation result

#### **Step 4: Redemption**
1. If valid, member confirms redemption
2. App calls `/soteria/partner/redeem-code`
3. Lambda:
   - Records redemption in `soteria-code-redemptions`
   - Increments usage counters
   - Returns redemption confirmation
4. Member sees success message

---

## Benefits of Code System

### For Partners
- ✅ **Marketing Control**: Partners can distribute codes via email, social media, etc.
- ✅ **Campaign Tracking**: Track which codes are most effective
- ✅ **Flexible Distribution**: Codes can be time-limited, location-specific, etc.
- ✅ **No Hardware Required**: No need for barcode scanners

### For Members
- ✅ **Easy to Use**: Just enter code in app
- ✅ **No Physical Presence**: Can redeem codes online/remotely
- ✅ **Multiple Codes**: Can use different codes from same partner
- ✅ **Clear Value**: See discount before redeeming

### For Soteria
- ✅ **Additional Revenue Stream**: Could charge partners for code generation
- ✅ **Better Analytics**: Track code performance
- ✅ **Marketing Tool**: Partners can run targeted campaigns

---

## Technical Requirements

### Backend
1. **New Lambda Functions:**
   - `soteria-partner-validate-code`: Validate code before redemption
   - `soteria-partner-redeem-code`: Record code redemption
   - `soteria-partner-create-code`: Partner creates codes (admin/partner dashboard)
   - `soteria-partner-list-codes`: List codes for a partner

2. **New DynamoDB Tables:**
   - `soteria-partner-codes`: Store code definitions
   - `soteria-code-redemptions`: Store code redemption records

3. **API Gateway Endpoints:**
   - `POST /soteria/partner/validate-code`
   - `POST /soteria/partner/redeem-code`
   - `POST /soteria/partner/codes` (create/list)
   - `GET /soteria/partner/codes/{partner_id}`

### Frontend (iOS App)
1. **UI Components:**
   - Code entry text field
   - Code validation feedback
   - Redemption confirmation
   - Code history view

2. **Service Updates:**
   - `PartnerLoyaltyService`: Add code validation/redemption methods
   - `PartnerLoyaltyView`: Add "Redeem Code" button to partner cards

3. **New Views:**
   - `CodeRedemptionView`: Dedicated code entry view
   - `CodeRedemptionHistoryView`: Show user's code redemptions

---

## Code Display Options

### Where to Show Codes on Partner Card

**Option 1: Button on Card Front**
```
┌─────────────────────────────┐
│  ACME                       │
│  10% Discount               │
│                             │
│  [Redeem Code]              │ ← Prominent button
│                             │
│  Tap for details →          │
└─────────────────────────────┘
```

**Option 2: Code Field on Card Back**
```
┌─────────────────────────────┐
│  Partner Details            │
│                             │
│  Enter Code:                │
│  [___________]              │
│  [Redeem]                   │
│                             │
│  Terms & Conditions...      │
└─────────────────────────────┘
```

**Option 3: Separate Code Section**
```
┌─────────────────────────────┐
│  Partner Benefits            │
│                             │
│  [Browse Partners]          │
│  [Redeem Code]  ← New tab    │
└─────────────────────────────┘
```

---

## Validation Logic

### Code Validation Checks

1. **Code Exists**: Code is in database
2. **Is Active**: `is_active === true`
3. **Not Expired**: Current date between `valid_from` and `valid_until`
4. **User Limit**: User's redemption count < `max_uses_per_user`
5. **Total Limit**: Total redemptions < `max_uses`
6. **User is Premium**: User has active premium subscription

### Error Messages

- `"Code not found"`: Code doesn't exist
- `"Code is inactive"`: Code has been deactivated
- `"Code has expired"`: Past `valid_until` date
- `"Code not yet valid"`: Before `valid_from` date
- `"Maximum uses reached"`: Total uses exceeded
- `"You've used this code too many times"`: User limit exceeded
- `"Premium membership required"`: User not premium

---

## Example User Flow

1. **Partner creates code:**
   - Partner: "ACME"
   - Code: "SAVE10"
   - Discount: 10%
   - Valid: 1/1/2024 - 12/31/2024
   - Max uses: 1000
   - Max per user: 3

2. **Partner distributes code:**
   - Email campaign: "Use code SAVE10 for 10% off!"
   - Social media: "New members get 10% off with SAVE10"

3. **Member sees code:**
   - Member receives email/social post
   - Opens Soteria app
   - Goes to Partner Benefits
   - Finds ACME partner card

4. **Member redeems:**
   - Taps "Redeem Code" on ACME card
   - Enters "SAVE10"
   - App validates code
   - Shows: "Code valid! 10% discount applied"
   - Member confirms
   - Redemption recorded

5. **Member uses benefit:**
   - Member visits ACME store
   - Shows redemption confirmation
   - Gets 10% discount

---

## Integration with Existing System

### Coexistence

Both systems can work together:

- **Barcode System**: For in-store, real-time validation
- **Code System**: For online, promotional, or remote redemptions

### Unified Redemption History

Both redemption types appear in:
- Member's redemption history
- Partner's analytics dashboard
- Same redemption tracking system

---

## Next Steps

1. **Design Database Schema**: Finalize DynamoDB table structures
2. **Create Lambda Functions**: Build validation and redemption endpoints
3. **Update API Gateway**: Add new endpoints
4. **Build iOS UI**: Add code entry to partner cards
5. **Partner Dashboard**: Add code management interface
6. **Testing**: Test end-to-end flow
7. **Documentation**: Update partner integration guide

---

## Questions to Consider

1. **Code Format**: 
   - Alphanumeric? (e.g., "ACME2024")
   - Numeric only? (e.g., "123456")
   - Custom format per partner?

2. **Code Distribution**:
   - Partners create codes themselves?
   - Soteria generates codes for partners?
   - Both options available?

3. **Code Visibility**:
   - Show codes on partner cards?
   - Hide codes until partner distributes?
   - Public code list vs. private codes?

4. **Redemption Location**:
   - Can codes be used online?
   - In-store only?
   - Both?

5. **Code Expiration**:
   - Auto-expire after date?
   - Manual deactivation?
   - Extend expiration?

---

**Last Updated**: January 2026

