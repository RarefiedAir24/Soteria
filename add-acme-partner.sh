#!/bin/bash

# Add ACME demo partner to the Partner Loyalty system

REGION="us-east-1"
TABLE_NAME="soteria-partners"

echo "🎁 Adding ACME demo partner to Partner Loyalty system..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if table exists
echo "Checking if table exists..."
TABLE_EXISTS=$(aws dynamodb describe-table \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --query 'Table.TableStatus' \
    --output text 2>/dev/null)

if [ "$TABLE_EXISTS" != "ACTIVE" ]; then
    echo -e "${RED}❌ Table $TABLE_NAME does not exist or is not active${NC}"
    echo "Please create the table first using: ./create-partner-tables.sh"
    exit 1
fi

echo -e "${GREEN}✅ Table exists${NC}"
echo ""

# Valid until date: 2026-12-31T23:59:59Z
VALID_UNTIL="2026-12-31T23:59:59Z"

echo "Adding ACME partner..."

aws dynamodb put-item \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --item "{
        \"partner_id\": {\"S\": \"demo-acme-partner\"},
        \"name\": {\"S\": \"ACME\"},
        \"description\": {\"S\": \"Your trusted partner for quality products and exceptional service. Visit our Plantation location for in-store savings.\"},
        \"loyalty_percentage\": {\"N\": \"10\"},
        \"loyalty_amount\": {\"NULL\": true},
        \"loyalty_type\": {\"S\": \"percentage\"},
        \"is_active\": {\"BOOL\": true},
        \"category\": {\"S\": \"Retail\"},
        \"location\": {\"S\": \"Plantation, FL\"},
        \"terms\": {\"S\": \"10% discount applies to all in-store purchases. Cannot be combined with other offers. Valid until December 31, 2026. Maximum 3 redemptions per user. Must present Soteria member card at time of purchase. Discount applies to regular-priced items only. Excludes sale items and clearance merchandise.\"},
        \"max_redemptions_per_user\": {\"N\": \"3\"},
        \"valid_until\": {\"S\": \"$VALID_UNTIL\"},
        \"has_brick_and_mortar\": {\"BOOL\": true},
        \"created_at\": {\"N\": \"$(date +%s)000\"}
    }" \
    --return-consumed-capacity TOTAL

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ ACME partner added successfully!${NC}"
    echo ""
    echo "Partner Details:"
    echo "  - Name: ACME"
    echo "  - Loyalty: 10% off"
    echo "  - Expires: December 31, 2026"
    echo "  - Location: Plantation, FL"
    echo "  - Address: 8205 NW 9th Court Plantation FL, 33322"
    echo "  - Brick & Mortar: Yes"
    echo "  - Max Redemptions: 3 per user"
else
    echo ""
    echo -e "${RED}❌ Failed to add ACME partner${NC}"
    exit 1
fi

