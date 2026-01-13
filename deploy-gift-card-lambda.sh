#!/bin/bash

# Script to deploy Gift Card Redemption Lambda
# Run this after creating the DynamoDB tables

set -e

echo "🎁 Deploying Gift Card Redemption Lambda..."

# Configuration
REGION="us-east-1"
FUNCTION_NAME="soteria-redeem-gift-card"
ROLE_NAME="soteria-lambda-role"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# Tremendous API key (sandbox for now)
TREMENDOUS_API_KEY="TEST_gIEksL8d0--nLz2T2VAZXIZs8mzqccp9yS3pDScswAv"
TREMENDOUS_ENV="sandbox"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  Prerequisites:${NC}"
echo -e "${YELLOW}   1. IAM role: ${ROLE_NAME} exists${NC}"
echo -e "${YELLOW}   2. DynamoDB tables created (run create-gift-card-tables.sh first)${NC}"
echo -e "${YELLOW}   3. Tremendous API key ready${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Navigate to lambda directory
cd "$(dirname "$0")/lambda/soteria-redeem-gift-card"

# Check if function exists
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" &>/dev/null; then
    echo "📦 Function exists, updating..."
    UPDATE_MODE=true
else
    echo "📦 Creating new function..."
    UPDATE_MODE=false
fi

# Install dependencies
echo "📥 Installing dependencies..."
if [ ! -d "node_modules" ]; then
    npm install --production
fi

# Create deployment package
echo "🎒 Creating deployment package..."
cd ..
zip -r "${FUNCTION_NAME}.zip" soteria-redeem-gift-card -x "*.git*" "*.DS_Store*" > /dev/null

if [ "$UPDATE_MODE" = true ]; then
    # Update function code
    echo "🔄 Updating function code..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file "fileb://${FUNCTION_NAME}.zip" \
        --region "$REGION" \
        --query 'FunctionName' \
        --output text
    
    # Update configuration
    echo "⚙️  Updating configuration..."
    aws lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --timeout 30 \
        --memory-size 512 \
        --environment "Variables={
            USER_DATA_TABLE=soteria-user-data,
            REDEMPTIONS_TABLE=soteria-gift-card-redemptions,
            MONTHLY_CAPS_TABLE=soteria-monthly-redemption-caps,
            TREMENDOUS_API_KEY=${TREMENDOUS_API_KEY},
            TREMENDOUS_ENV=${TREMENDOUS_ENV}
        }" \
        --region "$REGION" \
        --query 'FunctionName' \
        --output text
else
    # Create function
    echo "🆕 Creating new function..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime nodejs20.x \
        --role "$ROLE_ARN" \
        --handler "index.handler" \
        --zip-file "fileb://${FUNCTION_NAME}.zip" \
        --timeout 30 \
        --memory-size 512 \
        --environment "Variables={
            USER_DATA_TABLE=soteria-user-data,
            REDEMPTIONS_TABLE=soteria-gift-card-redemptions,
            MONTHLY_CAPS_TABLE=soteria-monthly-redemption-caps,
            TREMENDOUS_API_KEY=${TREMENDOUS_API_KEY},
            TREMENDOUS_ENV=${TREMENDOUS_ENV}
        }" \
        --region "$REGION" \
        --tags Project=Soteria,Environment=prod \
        --query 'FunctionName' \
        --output text
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ${FUNCTION_NAME} deployed successfully!${NC}"
else
    echo -e "${RED}❌ Failed to deploy ${FUNCTION_NAME}${NC}"
    exit 1
fi

# Clean up
rm -f "${FUNCTION_NAME}.zip"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Gift Card Lambda Deployed!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Function: ${FUNCTION_NAME}"
echo "Region: ${REGION}"
echo "Timeout: 30s"
echo "Memory: 512MB"
echo "Environment: ${TREMENDOUS_ENV}"
echo ""
echo "Environment Variables Set:"
echo "  - USER_DATA_TABLE: soteria-user-data"
echo "  - REDEMPTIONS_TABLE: soteria-gift-card-redemptions"
echo "  - MONTHLY_CAPS_TABLE: soteria-monthly-redemption-caps"
echo "  - TREMENDOUS_API_KEY: ****...$(echo $TREMENDOUS_API_KEY | tail -c 10)"
echo "  - TREMENDOUS_ENV: ${TREMENDOUS_ENV}"
echo ""
echo "Next steps:"
echo "  1. Test the Lambda function manually"
echo "  2. Connect to API Gateway endpoint"
echo "  3. Update iOS app with API Gateway URL"
echo ""
echo "To test manually:"
echo "  aws lambda invoke \\"
echo "    --function-name ${FUNCTION_NAME} \\"
echo "    --region ${REGION} \\"
echo "    --payload file://test-event.json \\"
echo "    response.json"
echo ""
