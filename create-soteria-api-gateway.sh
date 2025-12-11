#!/bin/bash

# Script to create AWS API Gateway for Soteria (renamed from Rever)
# Run this script after reviewing it to ensure it's correct

set -e  # Exit on error

echo "🚀 Creating AWS API Gateway for Soteria..."

# Configuration
API_NAME="soteria-api"
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
    --description "API Gateway for Soteria app - Data sync and Plaid integration" \
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

# Step 3: Create /soteria resource (for data sync endpoints)
echo "📁 Creating /soteria resource..."
SOTERIA_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$ROOT_RESOURCE_ID" \
    --path-part "soteria" \
    --region "$REGION" \
    --query 'id' \
    --output text)

echo "Soteria resource ID: $SOTERIA_RESOURCE_ID"

# Step 4: Create data sync sub-resources
echo "📁 Creating data sync sub-resources..."

# /soteria/sync (POST) - Save user data
SYNC_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$SOTERIA_RESOURCE_ID" \
    --path-part "sync" \
    --region "$REGION" \
    --query 'id' \
    --output text)

# /soteria/data (GET) - Get user data
DATA_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$SOTERIA_RESOURCE_ID" \
    --path-part "data" \
    --region "$REGION" \
    --query 'id' \
    --output text)

# Step 5: Create /soteria/plaid resource (for Plaid integration)
echo "📁 Creating /soteria/plaid resource..."
PLAID_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$SOTERIA_RESOURCE_ID" \
    --path-part "plaid" \
    --region "$REGION" \
    --query 'id' \
    --output text)

echo "Plaid resource ID: $PLAID_RESOURCE_ID"

# Step 6: Create Plaid sub-resources
echo "📁 Creating Plaid sub-resources..."

# /soteria/plaid/create-link-token
CREATE_TOKEN_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$PLAID_RESOURCE_ID" \
    --path-part "create-link-token" \
    --region "$REGION" \
    --query 'id' \
    --output text)

# /soteria/plaid/exchange-token
EXCHANGE_TOKEN_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$PLAID_RESOURCE_ID" \
    --path-part "exchange-token" \
    --region "$REGION" \
    --query 'id' \
    --output text)

# /soteria/plaid/balance
BALANCE_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$PLAID_RESOURCE_ID" \
    --path-part "balance" \
    --region "$REGION" \
    --query 'id' \
    --output text)

# /soteria/plaid/transfer
TRANSFER_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$PLAID_RESOURCE_ID" \
    --path-part "transfer" \
    --region "$REGION" \
    --query 'id' \
    --output text)

echo -e "${GREEN}✅ Resources created${NC}"

# Step 7: Output summary
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
echo "  Data Sync:"
echo "    - /soteria/sync (ID: $SYNC_RESOURCE_ID)"
echo "    - /soteria/data (ID: $DATA_RESOURCE_ID)"
echo "  Plaid:"
echo "    - /soteria/plaid/create-link-token (ID: $CREATE_TOKEN_RESOURCE_ID)"
echo "    - /soteria/plaid/exchange-token (ID: $EXCHANGE_TOKEN_RESOURCE_ID)"
echo "    - /soteria/plaid/balance (ID: $BALANCE_RESOURCE_ID)"
echo "    - /soteria/plaid/transfer (ID: $TRANSFER_RESOURCE_ID)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Create Lambda functions with soteria- prefix (see AWS_SOTERIA_SETUP.md)"
echo "2. Connect Lambda functions to these resources"
echo "3. Configure CORS"
echo "4. Deploy API to stage: $STAGE_NAME"
echo "5. Get the Invoke URL and update iOS app"
echo ""
echo "To get the Invoke URL after deployment:"
echo "  aws apigateway get-stage --rest-api-id $API_ID --stage-name $STAGE_NAME --region $REGION --query 'invokeUrl' --output text"
echo ""
echo "Save this API ID for later: $API_ID"
echo ""

