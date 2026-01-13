#!/bin/bash

# Script to create DynamoDB tables for gift card redemptions
# Run this before deploying the gift card Lambda

set -e

REGION="us-east-1"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🗄️  Creating DynamoDB tables for gift card redemptions..."
echo ""

# Function to create table if it doesn't exist
create_table_if_not_exists() {
    local TABLE_NAME=$1
    local KEY_SCHEMA=$2
    local ATTRIBUTE_DEFINITIONS=$3
    
    echo "Checking if table ${TABLE_NAME} exists..."
    
    if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" &>/dev/null; then
        echo -e "${YELLOW}   ⚠️  Table ${TABLE_NAME} already exists, skipping${NC}"
    else
        echo "   Creating table ${TABLE_NAME}..."
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions $ATTRIBUTE_DEFINITIONS \
            --key-schema $KEY_SCHEMA \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION" \
            --tags Key=Project,Value=Soteria Key=Environment,Value=prod \
            > /dev/null
        
        echo -e "${GREEN}   ✅ Table ${TABLE_NAME} created${NC}"
    fi
}

# 1. Gift Card Redemptions Table
echo ""
echo "1️⃣  Creating soteria-gift-card-redemptions table..."
create_table_if_not_exists \
    "soteria-gift-card-redemptions" \
    "AttributeName=redemptionId,KeyType=HASH AttributeName=timestamp,KeyType=RANGE" \
    "AttributeName=redemptionId,AttributeType=S AttributeName=timestamp,AttributeType=S"

# 2. Monthly Redemption Caps Table
echo ""
echo "2️⃣  Creating soteria-monthly-redemption-caps table..."
create_table_if_not_exists \
    "soteria-monthly-redemption-caps" \
    "AttributeName=userId,KeyType=HASH AttributeName=month,KeyType=RANGE" \
    "AttributeName=userId,AttributeType=S AttributeName=month,AttributeType=S"

# Wait for tables to be active
echo ""
echo "⏳ Waiting for tables to become active..."

aws dynamodb wait table-exists --table-name soteria-gift-card-redemptions --region "$REGION" 2>/dev/null || true
aws dynamodb wait table-exists --table-name soteria-monthly-redemption-caps --region "$REGION" 2>/dev/null || true

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All Tables Created Successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Tables created:"
echo "  1. soteria-gift-card-redemptions"
echo "     - Stores all gift card redemption records"
echo "     - Keys: redemptionId (HASH), timestamp (RANGE)"
echo ""
echo "  2. soteria-monthly-redemption-caps"
echo "     - Tracks monthly redemption usage per user"
echo "     - Keys: userId (HASH), month (RANGE)"
echo ""
echo "Next steps:"
echo "  1. Deploy gift card Lambda: ./deploy-gift-card-lambda.sh"
echo "  2. Set Tremendous API key in Lambda environment variables"
echo "  3. Connect Lambda to API Gateway"
echo ""
