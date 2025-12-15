#!/bin/bash

# Quick setup script for Dashboard API endpoint
# This script creates the API Gateway resource and connects the Lambda function

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

echo "🚀 Setting up Dashboard API endpoint..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get /soteria resource ID
echo "📋 Getting resource IDs..."
SOTERIA_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria'].id" \
    --output text)

if [ -z "$SOTERIA_RESOURCE_ID" ] || [ "$SOTERIA_RESOURCE_ID" == "None" ]; then
    echo -e "${RED}❌ /soteria resource not found. Please create it first.${NC}"
    exit 1
fi

# Check if dashboard resource exists
DASHBOARD_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/dashboard'].id" \
    --output text)

# Create dashboard resource if it doesn't exist
if [ -z "$DASHBOARD_RESOURCE_ID" ] || [ "$DASHBOARD_RESOURCE_ID" == "None" ]; then
    echo "📝 Creating /soteria/dashboard resource..."
    DASHBOARD_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$SOTERIA_RESOURCE_ID" \
        --path-part "dashboard" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    echo -e "${GREEN}✅ Resource created: $DASHBOARD_RESOURCE_ID${NC}"
else
    echo -e "${GREEN}✅ Resource already exists: $DASHBOARD_RESOURCE_ID${NC}"
fi

# Create GET method
echo "📝 Creating GET method..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method GET \
    --authorization-type NONE \
    --region "$REGION" > /dev/null 2>&1 || echo "  Method may already exist"

# Connect to Lambda
echo "🔗 Connecting to Lambda function..."
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:soteria-get-dashboard"

aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
    --region "$REGION" > /dev/null

# Grant permission
echo "🔐 Granting API Gateway permission..."
aws lambda add-permission \
    --function-name soteria-get-dashboard \
    --statement-id "apigateway-get-dashboard-$(date +%s)" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/soteria/dashboard" \
    --region "$REGION" > /dev/null 2>&1 || echo "  Permission may already exist"

# Enable CORS
echo "🌐 Enabling CORS..."

# OPTIONS method
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region "$REGION" > /dev/null 2>&1 || echo "  OPTIONS method may already exist"

# Mock integration for OPTIONS
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method OPTIONS \
    --type MOCK \
    --integration-http-method OPTIONS \
    --request-templates '{"application/json":"{\"statusCode\":200}"}' \
    --region "$REGION" > /dev/null 2>&1 || echo "  OPTIONS integration may already exist"

# Method response for OPTIONS
aws apigateway put-method-response \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers":true,"method.response.header.Access-Control-Allow-Methods":true,"method.response.header.Access-Control-Allow-Origin":true}' \
    --region "$REGION" > /dev/null 2>&1 || echo "  OPTIONS method response may already exist"

# Integration response for OPTIONS
aws apigateway put-integration-response \
    --rest-api-id "$API_ID" \
    --resource-id "$DASHBOARD_RESOURCE_ID" \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,Authorization'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'"}' \
    --region "$REGION" > /dev/null 2>&1 || echo "  OPTIONS integration response may already exist"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Dashboard API Setup Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "1. Deploy API Gateway to prod stage:"
echo "   aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --region $REGION"
echo ""
echo "2. Test the endpoint:"
echo "   curl -X GET \"https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod/soteria/dashboard?user_id=YOUR_USER_ID\""
echo ""
echo "3. The iOS app will automatically use this endpoint once deployed!"
echo ""

