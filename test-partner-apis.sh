#!/bin/bash

# Test script for Partner Loyalty API endpoints
# This script tests all three partner loyalty endpoints

API_BASE_URL="https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod"
API_ENDPOINT="${API_BASE_URL}/soteria/partner"

echo "🧪 Testing Partner Loyalty API Endpoints"
echo "=========================================="
echo ""

# Test 1: List Partners
echo "📋 Test 1: List Partners (GET /soteria/partner/list)"
echo "---------------------------------------------------"
response=$(curl -s -X GET "${API_ENDPOINT}/list")
echo "Response:"
echo "$response" | jq '.' 2>/dev/null || echo "$response"
echo ""

# Check if successful
if echo "$response" | grep -q '"success":true'; then
    echo "✅ Partner list endpoint working!"
    partner_count=$(echo "$response" | jq '.partners | length' 2>/dev/null || echo "0")
    echo "   Found $partner_count partners"
else
    echo "❌ Partner list endpoint failed"
fi
echo ""

# Test 2: Validate Member (with sample QR data)
echo "🔍 Test 2: Validate Member (POST /soteria/partner/validate-member)"
echo "-----------------------------------------------------------------"

# Sample QR code data (JSON string)
QR_DATA='{"user_id":"test-user-123","card_type":"gold","member_since":"2024-01-01T00:00:00Z","app":"soteria","version":"1.0"}'
PARTNER_ID="partner-artisan-coffee"  # Using one of the sample partners

echo "QR Data: $QR_DATA"
echo "Partner ID: $PARTNER_ID"
echo ""

response=$(curl -s -X POST "${API_ENDPOINT}/validate-member" \
  -H "Content-Type: application/json" \
  -d "{
    \"qr_data\": \"$QR_DATA\",
    \"partner_id\": \"$PARTNER_ID\"
  }")

echo "Response:"
echo "$response" | jq '.' 2>/dev/null || echo "$response"
echo ""

if echo "$response" | grep -q '"success":true'; then
    echo "✅ Validate member endpoint working!"
    if echo "$response" | grep -q '"valid":true'; then
        echo "   Member validation successful"
    else
        echo "   ⚠️  Member validation returned invalid (this may be expected for test data)"
    fi
else
    echo "❌ Validate member endpoint failed"
fi
echo ""

# Test 3: Redeem (with sample data)
echo "💳 Test 3: Record Redemption (POST /soteria/partner/redeem)"
echo "-----------------------------------------------------------"

USER_ID="test-user-123"
DISCOUNT_AMOUNT=5.00
TRANSACTION_ID="test-txn-$(date +%s)"

echo "User ID: $USER_ID"
echo "Partner ID: $PARTNER_ID"
echo "Discount Amount: \$$DISCOUNT_AMOUNT"
echo "Transaction ID: $TRANSACTION_ID"
echo ""

response=$(curl -s -X POST "${API_ENDPOINT}/redeem" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"$USER_ID\",
    \"partner_id\": \"$PARTNER_ID\",
    \"loyalty_amount\": $DISCOUNT_AMOUNT,
    \"transaction_id\": \"$TRANSACTION_ID\"
  }")

echo "Response:"
echo "$response" | jq '.' 2>/dev/null || echo "$response"
echo ""

if echo "$response" | grep -q '"success":true'; then
    echo "✅ Redeem endpoint working!"
    redemption_id=$(echo "$response" | jq -r '.redemption.redemption_id' 2>/dev/null || echo "N/A")
    echo "   Redemption ID: $redemption_id"
else
    echo "❌ Redeem endpoint failed"
    echo "   (This may fail if user doesn't exist or limits are exceeded)"
fi
echo ""

echo "=========================================="
echo "✅ API Testing Complete!"
echo ""
echo "Note: Some tests may fail with expected errors (e.g., invalid test user IDs)"
echo "The important thing is that the endpoints are responding correctly."

