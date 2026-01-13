#!/bin/bash

# 🎁 MASTER SCRIPT: Deploy Complete Gift Card Redemption System
# This script runs all deployment steps in sequence

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🎁 GIFT CARD REDEMPTION - COMPLETE DEPLOYMENT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo "This script will:"
echo "  1️⃣  Create DynamoDB tables"
echo "  2️⃣  Deploy Lambda function"
echo "  3️⃣  Add API Gateway endpoint"
echo "  4️⃣  Display iOS app update instructions"
echo ""
echo -e "${YELLOW}⚠️  Prerequisites:${NC}"
echo -e "${YELLOW}   • AWS CLI configured with credentials${NC}"
echo -e "${YELLOW}   • IAM role 'soteria-lambda-role' exists${NC}"
echo -e "${YELLOW}   • API Gateway 'soteria-api' exists${NC}"
echo ""
read -p "Ready to deploy? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Track progress
STEP=1

# Step 1: Create DynamoDB Tables
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE} Step ${STEP}/3: Creating DynamoDB Tables${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
((STEP++))
./create-gift-card-tables.sh

# Step 2: Deploy Lambda Function
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE} Step ${STEP}/3: Deploying Lambda Function${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
((STEP++))
./deploy-gift-card-lambda.sh

# Step 3: Add API Gateway Endpoint
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE} Step ${STEP}/3: Adding API Gateway Endpoint${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
((STEP++))
./add-gift-card-endpoint.sh

# Success!
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ DEPLOYMENT COMPLETE! 🎉${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "🎯 What's been deployed:"
echo "  ✅ DynamoDB tables created"
echo "  ✅ Lambda function deployed"
echo "  ✅ API Gateway endpoint configured"
echo ""
echo -e "${YELLOW}📱 NEXT STEP: Update iOS App${NC}"
echo ""
echo "Get your API Gateway URL:"
API_ID=$(aws apigateway get-rest-apis --region us-east-1 --query "items[?name=='soteria-api'].id" --output text)
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"
echo ""
echo -e "${GREEN}   ${API_URL}/soteria/redeem-gift-card${NC}"
echo ""
echo "Update this file:"
echo "   soteria/Services/LoyaltyPointsService.swift"
echo ""
echo "Find line ~376 and change:"
echo "   let endpoint = \"https://YOUR_API_GATEWAY_URL/redeem-gift-card\""
echo ""
echo "To:"
echo "   let endpoint = \"${API_URL}/soteria/redeem-gift-card\""
echo ""
echo -e "${YELLOW}🧪 Test the deployment:${NC}"
echo ""
echo "Run this command to test:"
echo "   curl -X POST \\"
echo "     ${API_URL}/soteria/redeem-gift-card \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{
  \"userId\": \"test-user\",
  \"giftCardId\": \"amazon_5\",
  \"pointsToSpend\": 2500,
  \"email\": \"supergeek@me.com\",
  \"brand\": \"Amazon\",
  \"amount\": 5
}'"
echo ""
echo -e "${BLUE}📊 View logs:${NC}"
echo "   aws logs tail /aws/lambda/soteria-redeem-gift-card --follow"
echo ""
echo -e "${GREEN}You're ready to redeem gift cards! 🎁${NC}"
echo ""
