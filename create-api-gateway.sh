#!/bin/bash

# Script to create AWS API Gateway for Rever Plaid integration
# Run this script after reviewing it to ensure it's correct

set -e  # Exit on error

echo "🚀 Creating AWS API Gateway for Rever..."

# Configuration
API_NAME="rever-plaid-api"
REGION="us-east-1"  # Change if you prefer a different region
STAGE_NAME="prod"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Step 1: Create REST API
echo "📡 Creating REST API: $API_NAME..."
API_ID=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --description "API Gateway for Rever app - Plaid integration" \
    --endpoint-configuration types=REGIONAL \
    --region "$REGION" \
    --query 'id' \
    --output text)

if [ -z "$API_ID" ]; then
    echo "❌ Failed to create API Gateway"
    exit 1
fi

echo -e "${GREEN}✅ API Gateway created! ID: $API_ID${NC}"

# Step 2: Get root resource ID
echo "🔍 Getting root resource ID..."
ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query 'items[?path==`/`].id' \
    --output text)

echo "Root resource ID: $ROOT_RESOURCE_ID"

# Step 3: Create /plaid resource
echo "📁 Creating /plaid resource..."
PLAID_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$ROOT_RESOURCE_ID" \
    --path-part "plaid" \
    --region "$REGION" \
    --query 'id' \
    --output text)

echo "Plaid resource ID: $PLAID_RESOURCE_ID"

# Step 4: Create sub-resources
echo "📁 Creating sub-resources..."

# /plaid/create-link-token
CREATE_TOKEN_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$PLAID_RESOURCE_ID" \
    --path-part "create-link-token" \
    --region "$REGION" \
    --query 'id' \
    --output text)

# /plaid/exchange-public-token
EXCHANGE_TOKEN_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$PLAID_RESOURCE_ID" \
    --path-part "exchange-public-token" \
    --region "$REGION" \
    --query 'id' \
    --output text)

# /plaid/transfer
TRANSFER_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$PLAID_RESOURCE_ID" \
    --path-part "transfer" \
    --region "$REGION" \
    --query 'id' \
    --output text)

echo -e "${GREEN}✅ Resources created${NC}"

# Step 5: Create methods (POST) for each resource
echo "🔧 Creating POST methods..."

# Note: These will fail if Lambda functions don't exist yet
# That's okay - we'll connect them later

echo "⚠️  Methods will be created when Lambda functions are ready"
echo "   You'll need to:"
echo "   1. Create Lambda functions first"
echo "   2. Connect them to these resources"
echo "   3. Deploy the API"

# Step 6: Enable CORS (we'll do this after methods are created)
echo "🌐 CORS will be configured after methods are created"

# Output summary
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ API Gateway Created Successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "API Gateway ID: $API_ID"
echo "API Name: $API_NAME"
echo "Region: $REGION"
echo ""
echo "Resources created:"
echo "  - /plaid/create-link-token (ID: $CREATE_TOKEN_RESOURCE_ID)"
echo "  - /plaid/exchange-public-token (ID: $EXCHANGE_TOKEN_RESOURCE_ID)"
echo "  - /plaid/transfer (ID: $TRANSFER_RESOURCE_ID)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Create Lambda functions (see AWS_BACKEND_SETUP.md)"
echo "2. Connect Lambda functions to these resources"
echo "3. Configure CORS"
echo "4. Deploy API to stage: $STAGE_NAME"
echo "5. Get the Invoke URL and update PlaidService.swift"
echo ""
echo "To get the Invoke URL after deployment:"
echo "  aws apigateway get-stage --rest-api-id $API_ID --stage-name $STAGE_NAME --region $REGION --query 'invokeUrl' --output text"
echo ""

