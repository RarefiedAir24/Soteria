# Code Redemption Implementation - Backend Requirements

## ✅ Frontend Complete

The iOS app now has:
- ✅ Code entry field on partner card back
- ✅ Validation and redemption UI
- ✅ Success/error messaging
- ✅ Integration with `PartnerLoyaltyService`

---

## 🔧 Backend Requirements

### 1. **DynamoDB Tables**

#### **Table: `soteria-partner-codes`**
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

**GSI (Global Secondary Index):**
- `partner_id-created_at-index`: Query codes by partner

#### **Table: `soteria-code-redemptions`**
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

**GSI (Global Secondary Indexes):**
- `code-redeemed_at-index`: Query redemptions by code
- `user_id-redeemed_at-index`: Query user's code redemptions
- `partner_id-redeemed_at-index`: Query partner's code redemptions

---

### 2. **Lambda Functions**

#### **`soteria-partner-validate-code`**
- **Endpoint**: `POST /soteria/partner/validate-code`
- **Purpose**: Validate a code before redemption
- **Request**:
  ```json
  {
    "code": "ACME2024",
    "user_id": "user-456",
    "partner_id": "demo-acme-partner"
  }
  ```
- **Response**:
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
    "message": null,
    "error": null
  }
  ```
- **Validation Checks**:
  1. Code exists in `soteria-partner-codes`
  2. Code is active (`is_active === true`)
  3. Current date between `valid_from` and `valid_until`
  4. User's redemption count < `max_uses_per_user`
  5. Total redemptions < `max_uses`
  6. User is premium (check subscription status)
  7. Code belongs to specified partner

#### **`soteria-partner-redeem-code`**
- **Endpoint**: `POST /soteria/partner/redeem-code`
- **Purpose**: Record code redemption
- **Request**:
  ```json
  {
    "code": "ACME2024",
    "user_id": "user-456",
    "partner_id": "demo-acme-partner"
  }
  ```
- **Response**:
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
    },
    "error": null
  }
  ```
- **Process**:
  1. Re-validate code (same checks as validate-code)
  2. If valid, create redemption record
  3. Return redemption confirmation

---

### 3. **API Gateway Configuration**

Add new endpoints:
- `POST /soteria/partner/validate-code` → `soteria-partner-validate-code` Lambda
- `POST /soteria/partner/redeem-code` → `soteria-partner-redeem-code` Lambda

Both should:
- Use `AWS_PROXY` integration
- Require authentication (JWT token)
- Include CORS headers
- Handle errors gracefully

---

### 4. **Partner Dashboard Updates**

Add code management to partner dashboard:
- **Create Code**: Form to generate new codes
- **List Codes**: View all codes for partner
- **Code Analytics**: Usage stats per code
- **Edit/Deactivate**: Manage existing codes

---

## 📋 Implementation Checklist

### Backend
- [ ] Create `soteria-partner-codes` DynamoDB table
- [ ] Create `soteria-code-redemptions` DynamoDB table
- [ ] Create `soteria-partner-validate-code` Lambda function
- [ ] Create `soteria-partner-redeem-code` Lambda function
- [ ] Configure API Gateway endpoints
- [ ] Add authentication to Lambda functions
- [ ] Test validation logic
- [ ] Test redemption flow

### Partner Dashboard
- [ ] Add code management section
- [ ] Create code form
- [ ] List codes view
- [ ] Code analytics
- [ ] Edit/deactivate functionality

### Testing
- [ ] Test code validation
- [ ] Test code redemption
- [ ] Test error cases (invalid code, expired, max uses, etc.)
- [ ] Test premium user requirement
- [ ] Test partner matching

---

## 🔄 Current Status

### ✅ Completed
- iOS UI for code entry (on card back)
- `PartnerLoyaltyService` method: `validateAndRedeemCode`
- Response models (`CodeValidationResponse`, `CodeInfo`, `CodeRedemptionResult`)

### ⏳ Pending
- Backend Lambda functions
- DynamoDB tables
- API Gateway endpoints
- Partner dashboard code management

---

## 🚀 Next Steps

1. **Create DynamoDB tables** (using AWS CLI or console)
2. **Build Lambda functions** (validate-code and redeem-code)
3. **Configure API Gateway** (add endpoints)
4. **Test end-to-end** (iOS app → API → DynamoDB)
5. **Add partner dashboard** (code management UI)

---

**Last Updated**: January 2026

