#!/bin/bash

# Script to create /soteria/app-name endpoint in existing API Gateway
# This script will check both existing APIs and add the endpoint to the appropriate one

set -e

REGION="us-east-1"
FUNCTION_NAME="soteria-get-app-name"
STAGE_NAME="prod"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🔍 Checking existing API Gateways..."

# Check both APIs
API_IDS=("g3ksyd36e5" "ue1psw3mt3")
API_ID=""
SOTERIA_RESOURCE_ID=""

for api in "${API_IDS[@]}"; do
    echo "Checking API: $api"
    
    # Get resources
    RESOURCES=$(aws apigateway get-resources --rest-api-id "$api" --region "$REGION" --query 'items[*].path' --output text)
    
    if echo "$RESOURCES" | grep -q "/soteria"; then
        echo -e "${GREEN}✅ Found /soteria resource in API: $api${NC}"
        API_ID="$api"
        
        # Get /soteria resource ID
        SOTERIA_RESOURCE_ID=$(aws apigateway get-resources \
            --rest-api-id "$api" \
            --region "$REGION" \
            --query 'items[?path==`/soteria`].id' \
            --output text)
        break
    fi
done

if [ -z "$API_ID" ]; then
    echo -e "${RED}❌ No API Gateway with /soteria resource found${NC}"
    echo "Please create /soteria resource first or specify API ID manually"
    exit 1
fi

echo ""
echo -e "${GREEN}Using API Gateway: $API_ID${NC}"
echo -e "${GREEN}Soteria resource ID: $SOTERIA_RESOURCE_ID${NC}"
echo ""

# Check if /soteria/app-name already exists
APP_NAME_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query 'items[?path==`/soteria/app-name`].id' \
    --output text 2>/dev/null || echo "")

if [ -n "$APP_NAME_RESOURCE_ID" ]; then
    echo -e "${YELLOW}⚠️  /soteria/app-name resource already exists (ID: $APP_NAME_RESOURCE_ID)${NC}"
    echo "Checking if POST method exists..."
    
    # Check if POST method exists
    METHOD_EXISTS=$(aws apigateway get-method \
        --rest-api-id "$API_ID" \
        --resource-id "$APP_NAME_RESOURCE_ID" \
        --http-method POST \
        --region "$REGION" \
        --query 'httpMethod' \
        --output text 2>/dev/null || echo "")
    
    if [ "$METHOD_EXISTS" == "POST" ]; then
        echo -e "${GREEN}✅ POST method already exists${NC}"
        echo "Endpoint is ready!"
        exit 0
    fi
else
    # Create /soteria/app-name resource
    echo "📁 Creating /soteria/app-name resource..."
    APP_NAME_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$SOTERIA_RESOURCE_ID" \
        --path-part "app-name" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    
    echo -e "${GREEN}✅ Resource created: $APP_NAME_RESOURCE_ID${NC}"
fi

# Get Lambda function ARN
echo "🔍 Getting Lambda function ARN..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}"

# Check if Lambda function exists
if ! aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" &>/dev/null; then
    echo -e "${RED}❌ Lambda function '$FUNCTION_NAME' not found${NC}"
    echo "Please deploy the Lambda function first: ./deploy-app-name-lambda.sh"
    exit 1
fi

# Create POST method
echo "📝 Creating POST method..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$APP_NAME_RESOURCE_ID" \
    --http-method POST \
    --authorization-type NONE \
    --region "$REGION" \
    --no-api-key-required

echo -e "${GREEN}✅ POST method created${NC}"

# Set up Lambda integration
echo "🔗 Setting up Lambda integration..."
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$APP_NAME_RESOURCE_ID" \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
    --region "$REGION"

echo -e "${GREEN}✅ Lambda integration configured${NC}"

# Grant API Gateway permission to invoke Lambda
echo "🔐 Granting API Gateway permission..."
aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "apigateway-post-$(date +%s)" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/soteria/app-name" \
    --region "$REGION" 2>/dev/null || echo "  Permission may already exist"

echo -e "${GREEN}✅ Permission granted${NC}"

# Enable CORS
echo "🌐 Enabling CORS..."
aws apigateway put-method-response \
    --rest-api-id "$API_ID" \
    --resource-id "$APP_NAME_RESOURCE_ID" \
    --http-method POST \
    --status-code 200 \
    --response-parameters "method.response.header.Access-Control-Allow-Origin=false" \
    --region "$REGION" 2>/dev/null || echo "  Method response may already exist"

# Add CORS headers to integration response
aws apigateway put-integration-response \
    --rest-api-id "$API_ID" \
    --resource-id "$APP_NAME_RESOURCE_ID" \
    --http-method POST \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'","method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,Authorization'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'POST,OPTIONS'"'"'"}' \
    --region "$REGION" 2>/dev/null || echo "  Integration response may already exist"

# Create OPTIONS method for CORS preflight
echo "📝 Creating OPTIONS method for CORS..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$APP_NAME_RESOURCE_ID" \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region "$REGION" \
    --no-api-key-required 2>/dev/null || echo "  OPTIONS method may already exist"

# Mock integration for OPTIONS
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$APP_NAME_RESOURCE_ID" \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\":200}"}' \
    --region "$REGION" 2>/dev/null || echo "  OPTIONS integration may already exist"

# OPTIONS method response
aws apigateway put-method-response \
    --rest-api-id "$API_ID" \
    --resource-id "$APP_NAME_RESOURCE_ID" \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Origin":false,"method.response.header.Access-Control-Allow-Headers":false,"method.response.header.Access-Control-Allow-Methods":false}' \
    --region "$REGION" 2>/dev/null || echo "  OPTIONS method response may already exist"

# OPTIONS integration response
aws apigateway put-integration-response \
    --rest-api-id "$API_ID" \
    --resource-id "$APP_NAME_RESOURCE_ID" \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'","method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,Authorization'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'POST,OPTIONS'"'"'"}' \
    --response-templates '{"application/json":""}' \
    --region "$REGION" 2>/dev/null || echo "  OPTIONS integration response may already exist"

echo -e "${GREEN}✅ CORS enabled${NC}"

# Deploy API
echo "🚀 Deploying API to $STAGE_NAME stage..."
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name "$STAGE_NAME" \
    --region "$REGION" 2>/dev/null || \
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name "$STAGE_NAME" \
    --description "Added /soteria/app-name endpoint" \
    --region "$REGION"

echo -e "${GREEN}✅ API deployed${NC}"

# Get endpoint URL
ENDPOINT_URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE_NAME}/soteria/app-name"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Endpoint Created Successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "API Gateway ID: $API_ID"
echo "Endpoint URL: $ENDPOINT_URL"
echo ""
echo "📝 Next steps:"
echo "1. Update iOS app:"
echo "   Edit: soteria/Services/AWSDataService.swift"
echo "   Update: apiGatewayURL = \"https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE_NAME}\""
echo ""
echo "2. Test endpoint:"
echo "   curl -X POST $ENDPOINT_URL \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"token_hashes\": [\"YOUR_HASH\"]}'"
echo ""
echo "3. Populate database with app mappings"
echo ""

