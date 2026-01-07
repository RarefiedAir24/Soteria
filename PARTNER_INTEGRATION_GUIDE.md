# Soteria Partner Integration Guide

**Version:** 1.0  
**Last Updated:** January 2026  
**API Base URL:** `https://api.soteria.zone`

---

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [API Authentication](#api-authentication)
4. [API Endpoints](#api-endpoints)
5. [Integration Examples](#integration-examples)
6. [Error Handling](#error-handling)
7. [Testing](#testing)
8. [Support](#support)

---

## Overview

Soteria's Partner Loyalty API allows businesses to validate Soteria premium members and apply loyalty benefits in real-time. The API uses a **real-time validation** approach - no user lists are shared, ensuring privacy and accuracy.

### Key Features

- ✅ **Real-time validation** - Always checks current subscription status
- ✅ **Privacy-friendly** - No user data sharing required
- ✅ **Simple integration** - RESTful API with JSON responses
- ✅ **Flexible** - Works with barcode scanning or manual member number entry

---

## Getting Started

### Step 1: Partner Registration

Contact Soteria to register as a partner. You'll receive:

- **Partner ID** - Your unique identifier (e.g., `partner-acme`)
- **API Key** (optional) - For rate limiting and analytics
- **Test Credentials** - For development and testing

### Step 2: Choose Integration Method

**Option A: Barcode/QR Code Scanning** (Recommended)
- Member shows card on phone
- Partner scans barcode/QR code
- Extract JSON data from scan
- Validate via API

**Option B: Member Number Entry**
- Member provides member number (e.g., `SOT-123456`)
- Partner enters number manually
- Validate via API

### Step 3: Integrate API

Add API calls to your POS system or checkout flow. See [Integration Examples](#integration-examples) below.

---

## API Authentication

Currently, the API uses **partner_id** for identification. API keys are optional and can be added for enhanced security and rate limiting.

### Request Headers

```http
Content-Type: application/json
X-Partner-ID: partner-acme          # Optional, can also be in request body
X-API-Key: your-api-key-here        # Optional, for future use
```

---

## API Endpoints

### 1. Validate Member

Validates a Soteria premium member and returns their eligibility for loyalty benefits.

**Endpoint:** `POST /soteria/partner/validate-member`

**Request Body:**

```json
{
  "qr_data": "{\"user_id\":\"user-123\",\"card_type\":\"gold\",\"member_since\":\"2024-01-01T00:00:00Z\"}",
  "partner_id": "partner-acme"
}
```

**OR (using member number):**

```json
{
  "member_number": "SOT-123456",
  "partner_id": "partner-acme"
}
```

**Success Response (200):**

```json
{
  "success": true,
  "valid": true,
  "member": {
    "user_id": "user-123",
    "card_type": "gold",
    "member_since": "2024-01-01T00:00:00Z",
    "is_premium": true,
    "subscription_status": "active",
    "subscription_type": "monthly"
  },
  "partner": {
    "partner_id": "partner-acme",
    "name": "ACME Coffee",
    "description": "Premium coffee and pastries",
    "discount_percentage": 10,
    "discount_amount": null,
    "discount_type": "percentage",
    "logo_url": "https://...",
    "terms": "Valid on all items. Cannot be combined with other offers."
  }
}
```

**Error Response (403) - Not Premium:**

```json
{
  "success": true,
  "valid": false,
  "error": "User does not have an active premium subscription",
  "member": {
    "user_id": "user-123",
    "is_premium": false,
    "subscription_status": "expired"
  }
}
```

**Error Response (400) - Invalid Request:**

```json
{
  "success": false,
  "error": "Either qr_data or member_number is required"
}
```

---

### 2. Record Redemption

Records a loyalty benefit redemption for analytics and tracking.

**Endpoint:** `POST /soteria/partner/redeem`

**Request Body:**

```json
{
  "user_id": "user-123",
  "partner_id": "partner-acme",
  "loyalty_amount": 5.00,
  "transaction_id": "txn-456"
}
```

**Success Response (200):**

```json
{
  "success": true,
  "redemption": {
    "redemption_id": "redemption-789",
    "user_id": "user-123",
    "partner_id": "partner-acme",
    "partner_name": "ACME Coffee",
    "loyalty_amount": 5.00,
    "transaction_id": "txn-456",
    "redeemed_at": "2024-01-15T10:30:00Z"
  }
}
```

**Error Response (403) - Limit Reached:**

```json
{
  "success": false,
  "error": "Maximum redemptions (5) reached"
}
```

---

### 3. List Partners

Returns all active partners (for reference, not typically needed for integration).

**Endpoint:** `GET /soteria/partner/list`

**Query Parameters:**
- `category` (optional) - Filter by category
- `location` (optional) - Filter by location

**Success Response (200):**

```json
{
  "success": true,
  "partners": [
    {
      "partner_id": "partner-acme",
      "name": "ACME Coffee",
      "description": "Premium coffee and pastries",
      "discount_percentage": 10,
      "discount_type": "percentage",
      "category": "Food & Beverage",
      "location": "New York, NY",
      "is_active": true,
      "valid_until": "2026-12-31T23:59:59Z"
    }
  ]
}
```

---

## Integration Examples

### JavaScript (Node.js / Browser)

```javascript
/**
 * Validate a member's QR code
 */
async function validateMember(qrData, partnerId) {
  const response = await fetch(
    'https://api.soteria.zone/soteria/partner/validate-member',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        qr_data: qrData,
        partner_id: partnerId
      })
    }
  );

  const result = await response.json();

  if (result.valid && result.member.is_premium) {
    // Member is valid - apply discount
    const discountPercent = result.partner.discount_percentage;
    return {
      valid: true,
      discountPercent: discountPercent,
      member: result.member
    };
  } else {
    // Member is not valid
    return {
      valid: false,
      error: result.error || 'Member is not eligible'
    };
  }
}

/**
 * Record a redemption
 */
async function recordRedemption(userId, partnerId, loyaltyAmount, transactionId) {
  const response = await fetch(
    'https://api.soteria.zone/soteria/partner/redeem',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        user_id: userId,
        partner_id: partnerId,
        loyalty_amount: loyaltyAmount,
        transaction_id: transactionId
      })
    }
  );

  const result = await response.json();
  return result;
}

// Example usage in checkout flow
async function processCheckout(scannedQRCode, partnerId, transactionId, totalAmount) {
  // 1. Validate member
  const validation = await validateMember(scannedQRCode, partnerId);
  
  if (!validation.valid) {
    alert('Sorry, this member is not eligible for the loyalty benefit.');
    return;
  }

  // 2. Calculate discount
  const discountAmount = (totalAmount * validation.discountPercent) / 100;
  const finalAmount = totalAmount - discountAmount;

  // 3. Apply discount to order
  applyDiscountToOrder(discountAmount);

  // 4. Record redemption (optional, for analytics)
  try {
    await recordRedemption(
      validation.member.user_id,
      partnerId,
      discountAmount,
      transactionId
    );
  } catch (error) {
    console.error('Failed to record redemption:', error);
    // Don't block checkout if redemption recording fails
  }

  // 5. Complete checkout
  completeCheckout(finalAmount);
}
```

---

### Python

```python
import requests
import json

API_BASE_URL = "https://api.soteria.zone"

def validate_member(qr_data, partner_id):
    """
    Validate a member's QR code
    """
    url = f"https://api.soteria.zone/soteria/partner/validate-member"
    
    payload = {
        "qr_data": qr_data,
        "partner_id": partner_id
    }
    
    response = requests.post(url, json=payload)
    result = response.json()
    
    if result.get("valid") and result.get("member", {}).get("is_premium"):
        discount_percent = result.get("partner", {}).get("discount_percentage", 0)
        return {
            "valid": True,
            "discount_percent": discount_percent,
            "member": result.get("member")
        }
    else:
        return {
            "valid": False,
            "error": result.get("error", "Member is not eligible")
        }

def record_redemption(user_id, partner_id, loyalty_amount, transaction_id=None):
    """
    Record a redemption
    """
    url = f"https://api.soteria.zone/soteria/partner/redeem"
    
    payload = {
        "user_id": user_id,
        "partner_id": partner_id,
        "loyalty_amount": loyalty_amount
    }
    
    if transaction_id:
        payload["transaction_id"] = transaction_id
    
    response = requests.post(url, json=payload)
    return response.json()

# Example usage
def process_checkout(scanned_qr_code, partner_id, transaction_id, total_amount):
    # 1. Validate member
    validation = validate_member(scanned_qr_code, partner_id)
    
    if not validation["valid"]:
        print("Sorry, this member is not eligible for the loyalty benefit.")
        return
    
    # 2. Calculate discount
    discount_amount = (total_amount * validation["discount_percent"]) / 100
    final_amount = total_amount - discount_amount
    
    # 3. Apply discount
    apply_discount_to_order(discount_amount)
    
    # 4. Record redemption (optional)
    try:
        record_redemption(
            validation["member"]["user_id"],
            partner_id,
            discount_amount,
            transaction_id
        )
    except Exception as e:
        print(f"Failed to record redemption: {e}")
        # Don't block checkout if redemption recording fails
    
    # 5. Complete checkout
    complete_checkout(final_amount)
```

---

### PHP

```php
<?php

$API_BASE_URL = "https://api.soteria.zone";

function validateMember($qrData, $partnerId) {
    $url = $API_BASE_URL . "/soteria/partner/validate-member";
    
    $payload = [
        "qr_data" => $qrData,
        "partner_id" => $partnerId
    ];
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Content-Type: application/json"
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    $result = json_decode($response, true);
    
    if ($result["valid"] && $result["member"]["is_premium"]) {
        $discountPercent = $result["partner"]["discount_percentage"];
        return [
            "valid" => true,
            "discount_percent" => $discountPercent,
            "member" => $result["member"]
        ];
    } else {
        return [
            "valid" => false,
            "error" => $result["error"] ?? "Member is not eligible"
        ];
    }
}

function recordRedemption($userId, $partnerId, $loyaltyAmount, $transactionId = null) {
    $url = $API_BASE_URL . "/soteria/partner/redeem";
    
    $payload = [
        "user_id" => $userId,
        "partner_id" => $partnerId,
        "loyalty_amount" => $loyaltyAmount
    ];
    
    if ($transactionId) {
        $payload["transaction_id"] = $transactionId;
    }
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Content-Type: application/json"
    ]);
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    return json_decode($response, true);
}

// Example usage
function processCheckout($scannedQRCode, $partnerId, $transactionId, $totalAmount) {
    // 1. Validate member
    $validation = validateMember($scannedQRCode, $partnerId);
    
    if (!$validation["valid"]) {
        echo "Sorry, this member is not eligible for the loyalty benefit.";
        return;
    }
    
    // 2. Calculate discount
    $discountAmount = ($totalAmount * $validation["discount_percent"]) / 100;
    $finalAmount = $totalAmount - $discountAmount;
    
    // 3. Apply discount
    applyDiscountToOrder($discountAmount);
    
    // 4. Record redemption (optional)
    try {
        recordRedemption(
            $validation["member"]["user_id"],
            $partnerId,
            $discountAmount,
            $transactionId
        );
    } catch (Exception $e) {
        error_log("Failed to record redemption: " . $e->getMessage());
        // Don't block checkout if redemption recording fails
    }
    
    // 5. Complete checkout
    completeCheckout($finalAmount);
}
?>
```

---

### cURL Examples

```bash
# Validate member with QR code
curl -X POST \
  "https://api.soteria.zone/soteria/partner/validate-member" \
  -H "Content-Type: application/json" \
  -d '{
    "qr_data": "{\"user_id\":\"user-123\",\"card_type\":\"gold\",\"member_since\":\"2024-01-01T00:00:00Z\"}",
    "partner_id": "partner-acme"
  }'

# Validate member with member number
curl -X POST \
  "https://api.soteria.zone/soteria/partner/validate-member" \
  -H "Content-Type: application/json" \
  -d '{
    "member_number": "SOT-123456",
    "partner_id": "partner-acme"
  }'

# Record redemption
curl -X POST \
  "https://api.soteria.zone/soteria/partner/redeem" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user-123",
    "partner_id": "partner-acme",
    "loyalty_amount": 5.00,
    "transaction_id": "txn-456"
  }'
```

---

## Error Handling

### HTTP Status Codes

- **200** - Success
- **400** - Bad Request (invalid parameters)
- **403** - Forbidden (member not eligible, limit reached)
- **404** - Not Found (partner not found)
- **500** - Internal Server Error

### Error Response Format

```json
{
  "success": false,
  "error": "Error message describing what went wrong"
}
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Either qr_data or member_number is required` | Missing required field | Include either `qr_data` or `member_number` in request |
| `partner_id is required` | Missing partner ID | Include `partner_id` in request |
| `Invalid QR code format` | Malformed QR data | Ensure QR code is valid JSON string |
| `User does not have an active premium subscription` | Member is not premium | Member must have active Soteria Plus subscription |
| `Maximum redemptions (5) reached` | User hit redemption limit | Check partner's `max_redemptions_per_user` setting |
| `Partner discount is not active` | Partner benefit expired | Check partner's `is_active` and `valid_until` fields |

### Best Practices

1. **Always handle errors gracefully** - Don't block checkout if validation fails
2. **Log errors for debugging** - Include request/response in logs
3. **Retry on network errors** - Implement retry logic for transient failures
4. **Cache partner info** - Store partner discount info locally to reduce API calls
5. **Validate before checkout** - Check member eligibility before finalizing order

---

## Testing

### Test Credentials

Contact Soteria support to receive:
- Test partner ID
- Test member QR codes
- Test member numbers

### Test Flow

1. **Validate test member** - Should return `valid: true`
2. **Apply discount** - Calculate and apply discount
3. **Record redemption** - Should succeed
4. **Test invalid member** - Should return `valid: false`
5. **Test limit reached** - Should return error after max redemptions

### Test QR Code Data

```json
{
  "user_id": "test-user-premium",
  "card_type": "gold",
  "member_since": "2024-01-01T00:00:00Z"
}
```

---

## Support

### Documentation
- **Integration Guide**: This document
- **API Reference**: See [API Endpoints](#api-endpoints) section
- **Sample Code**: See [Integration Examples](#integration-examples) section

### Contact
- **Email**: partners@soteria.app
- **Support Hours**: Monday-Friday, 9 AM - 5 PM EST
- **Emergency**: For production issues, contact support immediately

### Resources
- **Partner Portal**: https://partners.soteria.app (coming soon)
- **Status Page**: https://status.soteria.app (coming soon)
- **Changelog**: https://changelog.soteria.app (coming soon)

---

## FAQ

**Q: Do I need to share user lists with Soteria?**  
A: No. The API uses real-time validation - no user data sharing required.

**Q: What if the API is down?**  
A: You can choose to allow discounts anyway (at your risk) or deny all discounts until API is restored.

**Q: Can I use member numbers instead of QR codes?**  
A: Yes! Use the `member_number` field instead of `qr_data` in the validation request.

**Q: How often should I validate?**  
A: Validate once per transaction. Don't cache validation results.

**Q: Is redemption recording required?**  
A: No, it's optional but recommended for analytics and tracking.

**Q: What happens if a member's subscription expires?**  
A: The API will return `valid: false` immediately after expiration.

---

**Last Updated:** January 2026  
**Version:** 1.0

