#!/bin/bash

# Script to add gift card redemption endpoint to existing API Gateway
# Run this after deploying the gift card Lambda

set -e

echo "🎁 Adding Gift Card Redemption Endpoint to API Gateway..."

# Configuration
API_NAME="soteria-api"
REGION="us-east-1"
STAGE_NAME="prod"
FUNCTION_NAME="soteria-redeem-gift-card"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  Prerequisites:${NC}"
echo -e "${YELLOW}   1. API Gateway '${API_NAME}' exists${NC}"
echo -e "${YELLOW}   2. Lambda '${FUNCTION_NAME}' is deployed${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Get API Gateway ID
echo "🔍 Finding API Gateway..."
API_ID=$(aws apigateway get-rest-apis \
    --region "$REGION" \
    --query "items[?name=='${API_NAME}'].id" \
    --output text)

if [ -z "$API_ID" ]; then
    echo -e "${RED}❌ API Gateway '${API_NAME}' not found!${NC}"
    echo ""
    echo "Run this first:"
    echo "  ./create-soteria-api-gateway.sh"
    exit 1
fi

echo -e "${GREEN}✅ Found API Gateway: $API_ID${NC}"

# Get root resource ID
echo "🔍 Getting root resource..."
ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query 'items[?path==`/`].id' \
    --output text)

# Get /soteria resource ID (or create it)
echo "🔍 Checking for /soteria resource..."
SOTERIA_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria'].id" \
    --output text)

if [ -z "$SOTERIA_RESOURCE_ID" ]; then
    echo "📁 Creating /soteria resource..."
    SOTERIA_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$ROOT_RESOURCE_ID" \
        --path-part "soteria" \
        --region "$REGION" \
        --query 'id' \
        --output text)
fi

echo "Soteria resource ID: $SOTERIA_RESOURCE_ID"

# Create /soteria/redeem-gift-card resource
echo "📁 Creating /soteria/redeem-gift-card resource..."
REDEEM_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$SOTERIA_RESOURCE_ID" \
    --path-part "redeem-gift-card" \
    --region "$REGION" \
    --query 'id' \
    --output text 2>/dev/null || aws apigateway get-resources \
        --rest-api-id "$API_ID" \
        --region "$REGION" \
        --query "items[?path=='/soteria/redeem-gift-card'].id" \
        --output text)

echo "Redeem gift card resource ID: $REDEEM_RESOURCE_ID"

# Create POST method
echo "🔧 Creating POST method..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$REDEEM_RESOURCE_ID" \
    --http-method POST \
    --authorization-type AWS_IAM \
    --region "$REGION" \
    --no-api-key-required \
    > /dev/null 2>&1 || echo "   Method already exists"

# Set up integration with Lambda
echo "🔗 Linking to Lambda function..."
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}"

aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$REDEEM_RESOURCE_ID" \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
    --region "$REGION" \
    > /dev/null 2>&1 || echo "   Integration already configured"

# Grant API Gateway permission to invoke Lambda
echo "🔐 Granting API Gateway permissions..."
aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "apigateway-gift-card-invoke" \
    --action "lambda:InvokeFunction" \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*/*" \
    --region "$REGION" \
    > /dev/null 2>&1 || echo "   Permission already granted"

# Create OPTIONS method for CORS
echo "🌐 Setting up CORS (OPTIONS method)..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$REDEEM_RESOURCE_ID" \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region "$REGION" \
    > /dev/null 2>&1 || echo "   OPTIONS method already exists"

# Set up mock integration for OPTIONS
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$REDEEM_RESOURCE_ID" \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
    --region "$REGION" \
    > /dev/null 2>&1 || echo "   OPTIONS integration already configured"

# Set up OPTIONS method response
aws apigateway put-method-response \
    --rest-api-id "$API_ID" \
    --resource-id "$REDEEM_RESOURCE_ID" \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": false, "method.response.header.Access-Control-Allow-Methods": false, "method.response.header.Access-Control-Allow-Origin": false}' \
    --region "$REGION" \
    > /dev/null 2>&1 || echo "   OPTIONS response already configured"

# Set up OPTIONS integration response
aws apigateway put-integration-response \
    --rest-api-id "$API_ID" \
    --resource-id "$REDEEM_RESOURCE_ID" \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,Authorization'"'"'", "method.response.header.Access-Control-Allow-Methods": "'"'"'POST,OPTIONS'"'"'", "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'"}' \
    --region "$REGION" \
    > /dev/null 2>&1 || echo "   OPTIONS integration response already configured"

# Deploy API
echo "🚀 Deploying API to ${STAGE_NAME} stage..."
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name "$STAGE_NAME" \
    --region "$REGION" \
    > /dev/null

# Get API Gateway URL
API_URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE_NAME}"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Gift Card Endpoint Added!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "API Gateway ID: $API_ID"
echo "Endpoint: POST /soteria/redeem-gift-card"
echo ""
echo -e "${YELLOW}📱 Update iOS app with this URL:${NC}"
echo ""
echo "   ${API_URL}/soteria/redeem-gift-card"
echo ""
echo "File to update:"
echo "   soteria/Services/LoyaltyPointsService.swift"
echo "   Line ~376"
echo ""
echo "Change:"
echo "   let endpoint = \"https://YOUR_API_GATEWAY_URL/redeem-gift-card\""
echo ""
echo "To:"
echo "   let endpoint = \"${API_URL}/soteria/redeem-gift-card\""
echo ""
echo "Test the endpoint:"
echo "   curl -X POST \\"
echo "     ${API_URL}/soteria/redeem-gift-card \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"userId\": \"test\", \"giftCardId\": \"amazon_5\", \"pointsToSpend\": 2500, \"email\": \"test@example.com\", \"brand\": \"Amazon\", \"amount\": 5}'"
echo ""
