#!/bin/bash

# Add sample partners to the Partner Loyalty system

REGION="us-east-1"
TABLE_NAME="soteria-partners"

echo "🎁 Adding sample partners to Partner Loyalty system..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to add a partner
add_partner() {
    local PARTNER_ID=$1
    local NAME=$2
    local DESCRIPTION=$3
    local DISCOUNT_PERCENTAGE=$4
    local CATEGORY=$5
    local LOCATION=$6
    local TERMS=$7
    local MAX_REDEMPTIONS=${8:-10}
    
    echo "   Adding: $NAME..."
    
    aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --item "{
            \"partner_id\": {\"S\": \"$PARTNER_ID\"},
            \"name\": {\"S\": \"$NAME\"},
            \"description\": {\"S\": \"$DESCRIPTION\"},
            \"discount_percentage\": {\"N\": \"$DISCOUNT_PERCENTAGE\"},
            \"discount_type\": {\"S\": \"percentage\"},
            \"is_active\": {\"BOOL\": true},
            \"category\": {\"S\": \"$CATEGORY\"},
            \"location\": {\"S\": \"$LOCATION\"},
            \"terms\": {\"S\": \"$TERMS\"},
            \"max_redemptions_per_user\": {\"N\": \"$MAX_REDEMPTIONS\"},
            \"created_at\": {\"N\": \"$(date +%s)000\"}
        }" \
        --return-consumed-capacity TOTAL \
        --output text > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ $NAME added${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Failed to add $NAME${NC}"
    fi
}

# Add sample partners
echo ""
echo "Adding sample partners..."

# 1. Coffee Shop
add_partner \
    "partner-coffee-shop" \
    "Artisan Coffee Co." \
    "Premium coffee, pastries, and light meals" \
    "15" \
    "Food & Beverage" \
    "New York, NY" \
    "Valid on all items. Cannot be combined with other offers. Excludes gift cards." \
    "10"

# 2. Fitness Studio
add_partner \
    "partner-fitness-studio" \
    "Elite Fitness Studio" \
    "Premium fitness classes and personal training" \
    "20" \
    "Health & Fitness" \
    "Los Angeles, CA" \
    "Valid on monthly memberships and class packages. First-time members only." \
    "1"

# 3. Restaurant
add_partner \
    "partner-restaurant" \
    "The Gourmet Table" \
    "Fine dining restaurant with seasonal menu" \
    "10" \
    "Food & Beverage" \
    "San Francisco, CA" \
    "Valid on food and non-alcoholic beverages. Not valid on alcohol or special events." \
    "5"

# 4. Bookstore
add_partner \
    "partner-bookstore" \
    "Literary Haven Books" \
    "Independent bookstore with curated selection" \
    "15" \
    "Retail" \
    "Portland, OR" \
    "Valid on all books and merchandise. Excludes gift cards and special orders." \
    "20"

# 5. Spa & Wellness
add_partner \
    "partner-spa" \
    "Serenity Spa & Wellness" \
    "Full-service spa with massage, facials, and wellness treatments" \
    "25" \
    "Health & Wellness" \
    "Miami, FL" \
    "Valid on all services. Cannot be combined with other promotions. Advance booking required." \
    "3"

# 6. Tech Store
add_partner \
    "partner-tech-store" \
    "TechHub Electronics" \
    "Premium electronics and tech accessories" \
    "10" \
    "Retail" \
    "Seattle, WA" \
    "Valid on all products. Excludes sale items and extended warranties." \
    "5"

# 7. Yoga Studio
add_partner \
    "partner-yoga" \
    "Zen Yoga Studio" \
    "Yoga classes for all levels" \
    "20" \
    "Health & Fitness" \
    "Austin, TX" \
    "Valid on class packages and workshops. First-time students get additional 10% off." \
    "2"

# 8. Local Market
add_partner \
    "partner-market" \
    "Farmers Market Co-op" \
    "Organic produce and local goods" \
    "10" \
    "Food & Beverage" \
    "Boulder, CO" \
    "Valid on all purchases. Supports local farmers and artisans." \
    "30"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sample Partners Added!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Partners added:"
echo "  ☕ Artisan Coffee Co. - 15% off"
echo "  💪 Elite Fitness Studio - 20% off"
echo "  🍽️  The Gourmet Table - 10% off"
echo "  📚 Literary Haven Books - 15% off"
echo "  🧘 Serenity Spa & Wellness - 25% off"
echo "  💻 TechHub Electronics - 10% off"
echo "  🧘 Zen Yoga Studio - 20% off"
echo "  🥬 Farmers Market Co-op - 10% off"
echo ""
echo "To verify:"
echo "  aws dynamodb scan --table-name $TABLE_NAME --region $REGION --query 'Items[*].name.S'"
echo ""

