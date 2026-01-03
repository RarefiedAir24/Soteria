#!/bin/bash

# Script to create DynamoDB tables for Partner Discount system
# Run this script to set up partner and redemption tracking

set -e  # Exit on error

echo "🚀 Creating DynamoDB tables for Partner Discount system..."

# Configuration
REGION="us-east-1"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  Make sure you have AWS credentials configured${NC}"
echo -e "${YELLOW}⚠️  This will create resources in AWS - review commands before running${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Function to create a table
create_table() {
    local TABLE_NAME=$1
    local PARTITION_KEY=$2
    local SORT_KEY=$3
    
    echo "📊 Creating table: $TABLE_NAME..."
    
    if [ -z "$SORT_KEY" ]; then
        # Table with only partition key
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions \
                AttributeName="$PARTITION_KEY",AttributeType=S \
            --key-schema \
                AttributeName="$PARTITION_KEY",KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION" \
            --tags \
                Key=Project,Value=Soteria \
                Key=Environment,Value=prod \
                Key=Feature,Value=PartnerDiscounts \
            --query 'TableDescription.TableName' \
            --output text
    else
        # Table with partition key and sort key
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions \
                AttributeName="$PARTITION_KEY",AttributeType=S \
                AttributeName="$SORT_KEY",AttributeType=S \
            --key-schema \
                AttributeName="$PARTITION_KEY",KeyType=HASH \
                AttributeName="$SORT_KEY",KeyType=RANGE \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION" \
            --tags \
                Key=Project,Value=Soteria \
                Key=Environment,Value=prod \
                Key=Feature,Value=PartnerDiscounts \
            --query 'TableDescription.TableName' \
            --output text
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Table $TABLE_NAME created successfully${NC}"
    else
        echo -e "${RED}❌ Failed to create table $TABLE_NAME${NC}"
        return 1
    fi
}

# Create all tables
echo ""
echo "Creating DynamoDB tables for Partner Discount system..."

# 1. soteria-partners - Partner businesses offering discounts
# Partition: partner_id, Sort: (none)
create_table "soteria-partners" "partner_id"

# 2. soteria-partner-redemptions - User redemptions of partner discounts
# Partition: user_id, Sort: redemption_id
create_table "soteria-partner-redemptions" "user_id" "redemption_id"

# 3. soteria-partner-scans - QR code scan events (for analytics)
# Partition: partner_id, Sort: scan_timestamp
create_table "soteria-partner-scans" "partner_id" "scan_timestamp"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All Partner Discount Tables Created!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Tables created:"
echo "  - soteria-partners (partner businesses)"
echo "  - soteria-partner-redemptions (user redemptions)"
echo "  - soteria-partner-scans (scan analytics)"
echo ""
echo "To verify tables:"
echo "  aws dynamodb list-tables --region $REGION --query 'TableNames[?contains(@, `partner`)]'"
echo ""

