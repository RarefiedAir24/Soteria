#!/bin/bash

# Script to connect authentication Lambda functions to API Gateway
# Run this script after deploying the Lambda functions

set -e  # Exit on error

echo "🚀 Connecting authentication Lambda functions to API Gateway..."

# Configuration
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "📝 Please provide your API Gateway ID:"
read -p "API Gateway ID: " API_ID

if [ -z "$API_ID" ]; then
    echo "❌ API Gateway ID is required"
    exit 1
fi

echo -e "${YELLOW}⚠️  This will create/update API Gateway endpoints${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Function to create or update API Gateway endpoint
create_endpoint() {
    local RESOURCE_PATH=$1
    local HTTP_METHOD=$2
    local LAMBDA_FUNCTION=$3
    
    echo ""
    echo "🔗 Creating endpoint: $HTTP_METHOD $RESOURCE_PATH..."
    
    # Get or create resource
    RESOURCE_ID=$(aws apigateway get-resources \
        --rest-api-id "$API_ID" \
        --region "$REGION" \
        --query "items[?path=='${RESOURCE_PATH}'].id" \
        --output text)
    
    if [ -z "$RESOURCE_ID" ] || [ "$RESOURCE_ID" == "None" ]; then
        # Get or create /soteria resource
        PARENT_ID=$(aws apigateway get-resources \
            --rest-api-id "$API_ID" \
            --region "$REGION" \
            --query "items[?path=='/soteria'].id" \
            --output text)
        
        if [ -z "$PARENT_ID" ] || [ "$PARENT_ID" == "None" ]; then
            # Create /soteria resource first
            ROOT_ID=$(aws apigateway get-resources \
                --rest-api-id "$API_ID" \
                --region "$REGION" \
                --query "items[?path=='/'].id" \
                --output text)
            
            PARENT_ID=$(aws apigateway create-resource \
                --rest-api-id "$API_ID" \
                --parent-id "$ROOT_ID" \
                --path-part "soteria" \
                --region "$REGION" \
                --query 'id' \
                --output text 2>/dev/null || \
            aws apigateway get-resources \
                --rest-api-id "$API_ID" \
                --region "$REGION" \
                --query "items[?path=='/soteria'].id" \
                --output text)
        fi
        
        # Get or create /auth resource
        AUTH_RESOURCE_ID=$(aws apigateway get-resources \
            --rest-api-id "$API_ID" \
            --region "$REGION" \
            --query "items[?path=='/soteria/auth'].id" \
            --output text)
        
        if [ -z "$AUTH_RESOURCE_ID" ] || [ "$AUTH_RESOURCE_ID" == "None" ]; then
            AUTH_RESOURCE_ID=$(aws apigateway create-resource \
                --rest-api-id "$API_ID" \
                --parent-id "$PARENT_ID" \
                --path-part "auth" \
                --region "$REGION" \
                --query 'id' \
                --output text 2>/dev/null || \
            aws apigateway get-resources \
                --rest-api-id "$API_ID" \
                --region "$REGION" \
                --query "items[?path=='/soteria/auth'].id" \
                --output text)
        fi
        
        # Create specific endpoint resource
        RESOURCE_NAME=$(basename "$RESOURCE_PATH")
        RESOURCE_ID=$(aws apigateway create-resource \
            --rest-api-id "$API_ID" \
            --parent-id "$AUTH_RESOURCE_ID" \
            --path-part "$RESOURCE_NAME" \
            --region "$REGION" \
            --query 'id' \
            --output text)
    fi
    
    # Create or update method
    if aws apigateway get-method \
        --rest-api-id "$API_ID" \
        --resource-id "$RESOURCE_ID" \
        --http-method "$HTTP_METHOD" \
        --region "$REGION" &>/dev/null; then
        echo "   Method exists, updating..."
    else
        echo "   Creating method..."
        aws apigateway put-method \
            --rest-api-id "$API_ID" \
            --resource-id "$RESOURCE_ID" \
            --http-method "$HTTP_METHOD" \
            --authorization-type NONE \
            --region "$REGION" > /dev/null
    fi
    
    # Set up integration
    LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_FUNCTION}"
    
    echo "   Setting up Lambda integration..."
    aws apigateway put-integration \
        --rest-api-id "$API_ID" \
        --resource-id "$RESOURCE_ID" \
        --http-method "$HTTP_METHOD" \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
        --region "$REGION" > /dev/null
    
    # Grant API Gateway permission to invoke Lambda
    echo "   Granting API Gateway permission..."
    aws lambda add-permission \
        --function-name "$LAMBDA_FUNCTION" \
        --statement-id "apigateway-${API_ID}-${RESOURCE_ID}-${HTTP_METHOD}" \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/${HTTP_METHOD}${RESOURCE_PATH}" \
        --region "$REGION" 2>/dev/null || echo "   Permission may already exist"
    
    # Enable CORS (skip if already exists)
    echo "   Enabling CORS..."
    aws apigateway put-method-response \
        --rest-api-id "$API_ID" \
        --resource-id "$RESOURCE_ID" \
        --http-method "$HTTP_METHOD" \
        --status-code 200 \
        --response-parameters "method.response.header.Access-Control-Allow-Origin=true" \
        --region "$REGION" > /dev/null 2>&1 || echo "   CORS already configured"
    
    echo -e "${GREEN}   ✅ Endpoint created/updated${NC}"
}

# Create all auth endpoints
create_endpoint "/soteria/auth/signup" "POST" "soteria-auth-signup"
create_endpoint "/soteria/auth/signin" "POST" "soteria-auth-signin"
create_endpoint "/soteria/auth/refresh" "POST" "soteria-auth-refresh"
create_endpoint "/soteria/auth/reset-password" "POST" "soteria-auth-reset-password"

# Deploy API Gateway
echo ""
echo "🚀 Deploying API Gateway..."
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name prod \
    --region "$REGION" \
    --query 'id' \
    --output text > /dev/null

# Get API Gateway URL
API_URL=$(aws apigateway get-stage \
    --rest-api-id "$API_ID" \
    --stage-name prod \
    --region "$REGION" \
    --query 'invokeUrl' \
    --output text)

# Output summary
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Authentication Endpoints Connected!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "API Gateway URL: $API_URL"
echo ""
echo "Endpoints created:"
echo "  POST $API_URL/soteria/auth/signup"
echo "  POST $API_URL/soteria/auth/signin"
echo "  POST $API_URL/soteria/auth/refresh"
echo "  POST $API_URL/soteria/auth/reset-password"
echo ""
echo "Next step: Update CognitoAuthService.swift with API Gateway URL"
echo ""

