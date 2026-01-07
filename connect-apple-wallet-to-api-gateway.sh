#!/bin/bash

# Connect Apple Wallet Lambda function to API Gateway

REGION="us-east-1"
API_GATEWAY_ID="${API_GATEWAY_ID:-ue1psw3mt3}"  # Main API Gateway ID
STAGE="prod"
FUNCTION_NAME="soteria-apple-wallet-pass"

echo "🔗 Connecting Apple Wallet Lambda to API Gateway..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get /soteria resource ID
echo "📡 Getting /soteria resource..."
SOTERIA_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_GATEWAY_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria'].id" \
    --output text 2>/dev/null)

if [ -z "$SOTERIA_RESOURCE_ID" ] || [ "$SOTERIA_RESOURCE_ID" == "None" ]; then
    echo -e "${RED}❌ /soteria resource not found${NC}"
    exit 1
fi

echo "   ✅ /soteria resource ID: $SOTERIA_RESOURCE_ID"

# Check if /soteria/apple-wallet resource exists
echo ""
echo "📡 Checking for /soteria/apple-wallet resource..."
APPLE_WALLET_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_GATEWAY_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/apple-wallet'].id" \
    --output text 2>/dev/null)

if [ -z "$APPLE_WALLET_RESOURCE_ID" ] || [ "$APPLE_WALLET_RESOURCE_ID" == "None" ]; then
    echo "   Creating /soteria/apple-wallet resource..."
    APPLE_WALLET_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_GATEWAY_ID" \
        --parent-id "$SOTERIA_RESOURCE_ID" \
        --path-part "apple-wallet" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}   ❌ Failed to create resource${NC}"
        exit 1
    fi
    echo -e "${GREEN}   ✅ Created resource: $APPLE_WALLET_RESOURCE_ID${NC}"
else
    echo -e "${GREEN}   ✅ Resource exists: $APPLE_WALLET_RESOURCE_ID${NC}"
fi

# Check if /soteria/apple-wallet/pass resource exists
echo ""
echo "📡 Checking for /soteria/apple-wallet/pass resource..."
PASS_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_GATEWAY_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/apple-wallet/pass'].id" \
    --output text 2>/dev/null)

if [ -z "$PASS_RESOURCE_ID" ] || [ "$PASS_RESOURCE_ID" == "None" ]; then
    echo "   Creating /soteria/apple-wallet/pass resource..."
    PASS_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_GATEWAY_ID" \
        --parent-id "$APPLE_WALLET_RESOURCE_ID" \
        --path-part "pass" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}   ❌ Failed to create resource${NC}"
        exit 1
    fi
    echo -e "${GREEN}   ✅ Created resource: $PASS_RESOURCE_ID${NC}"
else
    echo -e "${GREEN}   ✅ Resource exists: $PASS_RESOURCE_ID${NC}"
fi

# Get Lambda function ARN
echo ""
echo "📡 Getting Lambda function ARN..."
LAMBDA_ARN=$(aws lambda get-function \
    --function-name "$FUNCTION_NAME" \
    --region "$REGION" \
    --query 'Configuration.FunctionArn' \
    --output text)

if [ -z "$LAMBDA_ARN" ]; then
    echo -e "${RED}❌ Lambda function not found: $FUNCTION_NAME${NC}"
    exit 1
fi

echo "   ✅ Lambda ARN: $LAMBDA_ARN"

# Grant API Gateway permission to invoke Lambda
echo ""
echo "📡 Granting API Gateway permission..."
SOURCE_ARN="arn:aws:execute-api:${REGION}:*:${API_GATEWAY_ID}/*/GET/soteria/apple-wallet/pass"

aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "api-gateway-${API_GATEWAY_ID}-apple-wallet-pass-get" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "$SOURCE_ARN" \
    --region "$REGION" \
    2>/dev/null && echo -e "${GREEN}   ✅ Permission granted${NC}" || echo "   Permission may already exist"

# Create GET method
echo ""
echo "📡 Creating GET method..."
aws apigateway put-method \
    --rest-api-id "$API_GATEWAY_ID" \
    --resource-id "$PASS_RESOURCE_ID" \
    --http-method "GET" \
    --authorization-type "NONE" \
    --region "$REGION" \
    --query 'httpMethod' \
    --output text \
    2>/dev/null && echo -e "${GREEN}   ✅ Method created${NC}" || echo "   Method may already exist"

# Set up integration
echo ""
echo "📡 Setting up Lambda integration..."
aws apigateway put-integration \
    --rest-api-id "$API_GATEWAY_ID" \
    --resource-id "$PASS_RESOURCE_ID" \
    --http-method "GET" \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
    --region "$REGION" \
    --query 'type' \
    --output text

if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ Integration configured${NC}"
else
    echo -e "${RED}   ❌ Failed to configure integration${NC}"
    exit 1
fi

# Create OPTIONS method for CORS
echo ""
echo "📡 Creating OPTIONS method for CORS..."
aws apigateway put-method \
    --rest-api-id "$API_GATEWAY_ID" \
    --resource-id "$PASS_RESOURCE_ID" \
    --http-method "OPTIONS" \
    --authorization-type "NONE" \
    --region "$REGION" \
    --query 'httpMethod' \
    --output text \
    2>/dev/null && echo -e "${GREEN}   ✅ OPTIONS method created${NC}" || echo "   OPTIONS method may already exist"

# Set up mock integration for OPTIONS
aws apigateway put-integration \
    --rest-api-id "$API_GATEWAY_ID" \
    --resource-id "$PASS_RESOURCE_ID" \
    --http-method "OPTIONS" \
    --type MOCK \
    --integration-http-method OPTIONS \
    --request-templates '{"application/json":"{\"statusCode\":200}"}' \
    --region "$REGION" \
    --query 'type' \
    --output text \
    2>/dev/null && echo -e "${GREEN}   ✅ OPTIONS integration configured${NC}" || echo "   OPTIONS integration may already exist"

# Set up method response for OPTIONS
aws apigateway put-method-response \
    --rest-api-id "$API_GATEWAY_ID" \
    --resource-id "$PASS_RESOURCE_ID" \
    --http-method "OPTIONS" \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Origin":true,"method.response.header.Access-Control-Allow-Headers":true,"method.response.header.Access-Control-Allow-Methods":true}' \
    --region "$REGION" \
    2>/dev/null && echo -e "${GREEN}   ✅ OPTIONS method response configured${NC}" || echo "   OPTIONS method response may already exist"

# Set up integration response for OPTIONS
aws apigateway put-integration-response \
    --rest-api-id "$API_GATEWAY_ID" \
    --resource-id "$PASS_RESOURCE_ID" \
    --http-method "OPTIONS" \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'\''*'\''","method.response.header.Access-Control-Allow-Headers":"'\''Content-Type,Authorization'\''","method.response.header.Access-Control-Allow-Methods":"'\''GET,OPTIONS'\''"}' \
    --region "$REGION" \
    2>/dev/null && echo -e "${GREEN}   ✅ OPTIONS integration response configured${NC}" || echo "   OPTIONS integration response may already exist"

# Deploy to stage
echo ""
echo "📡 Deploying to $STAGE stage..."
aws apigateway create-deployment \
    --rest-api-id "$API_GATEWAY_ID" \
    --stage-name "$STAGE" \
    --region "$REGION" \
    --query 'id' \
    --output text \
    2>/dev/null && echo -e "${GREEN}   ✅ Deployed successfully${NC}" || echo "   Deployment may already exist"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Apple Wallet API Connected!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "API Endpoint:"
echo "  GET https://${API_GATEWAY_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}/soteria/apple-wallet/pass"
echo ""
echo -e "${YELLOW}⚠️  Note: You still need to:${NC}"
echo "  1. Register Pass Type ID in Apple Developer Portal"
echo "  2. Download Pass Type ID certificate (.p12)"
echo "  3. Download WWDR certificate"
echo "  4. Upload certificates to S3: s3://soteria-wallet-passes/certificates/"
echo "  5. Upload pass assets (logo.png, icon.png) to S3: s3://soteria-wallet-passes/assets/"
echo ""

