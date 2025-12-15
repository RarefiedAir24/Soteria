#!/bin/bash

# Script to connect Lambda functions to API Gateway
# Run this AFTER creating the API Gateway and deploying Lambda functions
# Usage: ./connect-api-gateway-lambdas.sh API_GATEWAY_ID

set -e

if [ -z "$1" ]; then
    echo "❌ Usage: $0 <API_GATEWAY_ID>"
    echo ""
    echo "Get your API Gateway ID from:"
    echo "  aws apigateway get-rest-apis --query \"items[?name=='soteria-api'].id\" --output text --region us-east-1"
    exit 1
fi

API_ID="$1"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "🔗 Connecting Lambda functions to API Gateway: $API_ID"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get resource IDs
echo "📋 Getting resource IDs..."
SOTERIA_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria'].id" \
    --output text)

PLAID_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/plaid'].id" \
    --output text)

CREATE_TOKEN_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/plaid/create-link-token'].id" \
    --output text)

EXCHANGE_TOKEN_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/plaid/exchange-token'].id" \
    --output text)

BALANCE_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/plaid/balance'].id" \
    --output text)

TRANSFER_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/plaid/transfer'].id" \
    --output text)

DASHBOARD_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/dashboard'].id" \
    --output text)

echo "✅ Resource IDs retrieved"
echo ""

# Function to create method and connect Lambda
connect_lambda() {
    local RESOURCE_ID=$1
    local HTTP_METHOD=$2
    local LAMBDA_NAME=$3
    local PATH_NAME=$4
    
    echo "🔗 Connecting $PATH_NAME ($HTTP_METHOD) to $LAMBDA_NAME..."
    
    # Create method
    aws apigateway put-method \
        --rest-api-id "$API_ID" \
        --resource-id "$RESOURCE_ID" \
        --http-method "$HTTP_METHOD" \
        --authorization-type NONE \
        --region "$REGION" > /dev/null 2>&1 || echo "  Method may already exist"
    
    # Set up Lambda integration
    LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_NAME}"
    
    aws apigateway put-integration \
        --rest-api-id "$API_ID" \
        --resource-id "$RESOURCE_ID" \
        --http-method "$HTTP_METHOD" \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
        --region "$REGION" > /dev/null
    
    # Grant API Gateway permission to invoke Lambda
    aws lambda add-permission \
        --function-name "$LAMBDA_NAME" \
        --statement-id "apigateway-${HTTP_METHOD}-${RESOURCE_ID}" \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/${HTTP_METHOD}${PATH_NAME}" \
        --region "$REGION" > /dev/null 2>&1 || echo "  Permission may already exist"
    
    echo -e "${GREEN}  ✅ Connected${NC}"
}

# Connect all endpoints
connect_lambda "$CREATE_TOKEN_RESOURCE_ID" "POST" "soteria-plaid-create-link-token" "/soteria/plaid/create-link-token"
connect_lambda "$EXCHANGE_TOKEN_RESOURCE_ID" "POST" "soteria-plaid-exchange-token" "/soteria/plaid/exchange-token"
connect_lambda "$BALANCE_RESOURCE_ID" "GET" "soteria-plaid-get-balance" "/soteria/plaid/balance"
connect_lambda "$TRANSFER_RESOURCE_ID" "POST" "soteria-plaid-transfer" "/soteria/plaid/transfer"

# Dashboard endpoint
if [ -n "$DASHBOARD_RESOURCE_ID" ] && [ "$DASHBOARD_RESOURCE_ID" != "None" ]; then
    connect_lambda "$DASHBOARD_RESOURCE_ID" "GET" "soteria-get-dashboard" "/soteria/dashboard"
else
    echo -e "${YELLOW}⚠️  Dashboard resource not found. Creating it...${NC}"
    # Create dashboard resource if it doesn't exist
    DASHBOARD_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$SOTERIA_RESOURCE_ID" \
        --path-part "dashboard" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    connect_lambda "$DASHBOARD_RESOURCE_ID" "GET" "soteria-get-dashboard" "/soteria/dashboard"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All Lambda Functions Connected!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Enable CORS on all endpoints (use AWS Console or CLI)"
echo "2. Deploy API Gateway to 'prod' stage"
echo "3. Update PlaidService.swift with the API Gateway URL"
echo ""
echo "To deploy:"
echo "  aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --region $REGION"
echo ""
echo "To get the URL:"
echo "  aws apigateway get-stage --rest-api-id $API_ID --stage-name prod --region $REGION --query 'invokeUrl' --output text"

