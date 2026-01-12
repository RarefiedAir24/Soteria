#!/bin/bash

# ================================================================
# Tremendous Sandbox Testing Script
# Test the Tremendous API before Wednesday's call
# ================================================================

# INSTRUCTIONS:
# 1. Get your Tremendous Sandbox API key
# 2. Replace YOUR_SANDBOX_API_KEY below
# 3. Replace your-email@example.com with your actual email
# 4. Run: chmod +x test-tremendous-sandbox.sh
# 5. Run: ./test-tremendous-sandbox.sh

# ================================================================
# CONFIGURATION
# ================================================================

TREMENDOUS_API_KEY="YOUR_SANDBOX_API_KEY"  # ⬅️ REPLACE THIS
TREMENDOUS_BASE_URL="https://testflight.tremendous.com"
TEST_EMAIL="your-email@example.com"  # ⬅️ REPLACE THIS

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ================================================================
# TEST 1: Check API Connectivity
# ================================================================

echo ""
echo "${BLUE}========================================${NC}"
echo "${BLUE}TEST 1: API Connectivity Check${NC}"
echo "${BLUE}========================================${NC}"
echo ""

echo "Testing Tremendous sandbox API..."
echo "Base URL: $TREMENDOUS_BASE_URL"
echo ""

# Simple health check (list organizations)
echo "Fetching organizations..."
ORGS_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $TREMENDOUS_API_KEY" \
  "$TREMENDOUS_BASE_URL/api/v2/organizations")

HTTP_CODE=$(echo "$ORGS_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$ORGS_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
  echo "${GREEN}✅ API connection successful!${NC}"
  echo "Response:"
  echo "$RESPONSE_BODY" | jq '.'
else
  echo "${RED}❌ API connection failed (HTTP $HTTP_CODE)${NC}"
  echo "$RESPONSE_BODY"
  exit 1
fi

# ================================================================
# TEST 2: Create $5 Amazon Gift Card Order
# ================================================================

echo ""
echo "${BLUE}========================================${NC}"
echo "${BLUE}TEST 2: Create \$5 Amazon Gift Card${NC}"
echo "${BLUE}========================================${NC}"
echo ""

EXTERNAL_ID="soteria-test-$(date +%s)"

echo "Creating order with external ID: $EXTERNAL_ID"
echo "Sending to: $TEST_EMAIL"
echo ""

ORDER_PAYLOAD=$(cat <<EOF
{
  "external_id": "$EXTERNAL_ID",
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
      "name": "Soteria Test User",
      "email": "$TEST_EMAIL"
    },
    "products": [
      "AMAZON"
    ]
  }
}
EOF
)

echo "Payload:"
echo "$ORDER_PAYLOAD" | jq '.'
echo ""

ORDER_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $TREMENDOUS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$ORDER_PAYLOAD" \
  "$TREMENDOUS_BASE_URL/api/v2/orders")

HTTP_CODE=$(echo "$ORDER_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$ORDER_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
  echo "${GREEN}✅ Order created successfully!${NC}"
  echo ""
  echo "Full response:"
  echo "$RESPONSE_BODY" | jq '.'
  echo ""
  
  # Extract key info
  ORDER_ID=$(echo "$RESPONSE_BODY" | jq -r '.order.id')
  REWARD_ID=$(echo "$RESPONSE_BODY" | jq -r '.order.reward.id')
  REWARD_LINK=$(echo "$RESPONSE_BODY" | jq -r '.order.reward.delivery.link // "N/A"')
  
  echo "${GREEN}========================================${NC}"
  echo "${GREEN}📧 Check your email: $TEST_EMAIL${NC}"
  echo "${GREEN}========================================${NC}"
  echo ""
  echo "Order ID: $ORDER_ID"
  echo "Reward ID: $REWARD_ID"
  echo "Reward Link: $REWARD_LINK"
  echo ""
  echo "${YELLOW}⚠️  In sandbox mode, emails may not actually be sent.${NC}"
  echo "${YELLOW}    Use the reward link above to access the gift card.${NC}"
  
else
  echo "${RED}❌ Order creation failed (HTTP $HTTP_CODE)${NC}"
  echo "$RESPONSE_BODY" | jq '.'
  exit 1
fi

# ================================================================
# TEST 3: List Available Products
# ================================================================

echo ""
echo "${BLUE}========================================${NC}"
echo "${BLUE}TEST 3: List Available Products${NC}"
echo "${BLUE}========================================${NC}"
echo ""

echo "Fetching available gift card products..."
PRODUCTS_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $TREMENDOUS_API_KEY" \
  "$TREMENDOUS_BASE_URL/api/v2/products")

HTTP_CODE=$(echo "$PRODUCTS_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$PRODUCTS_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
  echo "${GREEN}✅ Products fetched successfully!${NC}"
  echo ""
  
  # Show just product names
  echo "Available products for Soteria integration:"
  echo "$RESPONSE_BODY" | jq -r '.products[] | "- \(.name) (ID: \(.id))"' | head -20
  echo ""
  echo "${YELLOW}💡 Use these product IDs in your PRODUCT_MAP${NC}"
  
else
  echo "${RED}❌ Failed to fetch products (HTTP $HTTP_CODE)${NC}"
  echo "$RESPONSE_BODY"
fi

# ================================================================
# TEST 4: Check Balance (Funding Source)
# ================================================================

echo ""
echo "${BLUE}========================================${NC}"
echo "${BLUE}TEST 4: Check Account Balance${NC}"
echo "${BLUE}========================================${NC}"
echo ""

echo "Fetching funding sources..."
FUNDING_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $TREMENDOUS_API_KEY" \
  "$TREMENDOUS_BASE_URL/api/v2/funding_sources")

HTTP_CODE=$(echo "$FUNDING_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$FUNDING_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
  echo "${GREEN}✅ Funding sources retrieved!${NC}"
  echo ""
  echo "$RESPONSE_BODY" | jq '.'
  
else
  echo "${RED}❌ Failed to fetch funding sources (HTTP $HTTP_CODE)${NC}"
  echo "$RESPONSE_BODY"
fi

# ================================================================
# SUMMARY
# ================================================================

echo ""
echo "${GREEN}========================================${NC}"
echo "${GREEN}✅ TESTING COMPLETE${NC}"
echo "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Check your email ($TEST_EMAIL) for the test gift card"
echo "2. Review the product IDs for your PRODUCT_MAP"
echo "3. Prepare questions for Wednesday's call"
echo "4. Share these results with the Tremendous team"
echo ""
echo "${BLUE}📝 Questions for Wednesday:${NC}"
echo "   - Confirm product ID format (AMAZON, VISA, etc.)"
echo "   - Ask about funding source setup for production"
echo "   - Clarify email delivery vs. link delivery"
echo "   - Discuss webhook integration for delivery status"
echo ""
