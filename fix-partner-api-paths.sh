#!/bin/bash

# Fix Partner API paths - create proper nested structure under /soteria/partner

API_GATEWAY_ID="ue1psw3mt3"
REGION="us-east-1"

echo "🔧 Fixing Partner API Gateway paths..."

# Get /soteria resource ID
SOTERIA_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_GATEWAY_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria'].id" \
    --output text)

if [ -z "$SOTERIA_ID" ]; then
    echo "❌ /soteria resource not found"
    exit 1
fi

echo "✅ Found /soteria resource: $SOTERIA_ID"

# Check if /soteria/partner exists, create if not
PARTNER_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_GATEWAY_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/partner'].id" \
    --output text)

if [ -z "$PARTNER_ID" ] || [ "$PARTNER_ID" == "None" ]; then
    echo "📦 Creating /soteria/partner resource..."
    PARTNER_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_GATEWAY_ID" \
        --parent-id "$SOTERIA_ID" \
        --path-part "partner" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    echo "✅ Created /soteria/partner: $PARTNER_ID"
else
    echo "✅ /soteria/partner already exists: $PARTNER_ID"
fi

# Function to create or move endpoint
create_endpoint() {
    local ENDPOINT_NAME=$1
    local HTTP_METHOD=$2
    local LAMBDA_FUNCTION=$3
    
    echo ""
    echo "📡 Setting up: $HTTP_METHOD /soteria/partner/$ENDPOINT_NAME -> $LAMBDA_FUNCTION"
    
    # Check if resource exists
    RESOURCE_ID=$(aws apigateway get-resources \
        --rest-api-id "$API_GATEWAY_ID" \
        --region "$REGION" \
        --query "items[?path=='/soteria/partner/$ENDPOINT_NAME'].id" \
        --output text)
    
    if [ -z "$RESOURCE_ID" ] || [ "$RESOURCE_ID" == "None" ]; then
        echo "   Creating resource: /soteria/partner/$ENDPOINT_NAME"
        RESOURCE_ID=$(aws apigateway create-resource \
            --rest-api-id "$API_GATEWAY_ID" \
            --parent-id "$PARTNER_ID" \
            --path-part "$ENDPOINT_NAME" \
            --region "$REGION" \
            --query 'id' \
            --output text)
    fi
    
    echo "   Resource ID: $RESOURCE_ID"
    
    # Get Lambda ARN
    LAMBDA_ARN=$(aws lambda get-function \
        --function-name "$LAMBDA_FUNCTION" \
        --region "$REGION" \
        --query 'Configuration.FunctionArn' \
        --output text)
    
    echo "   Lambda ARN: $LAMBDA_ARN"
    
    # Grant permission
    SOURCE_ARN="arn:aws:execute-api:${REGION}:*:${API_GATEWAY_ID}/*/${HTTP_METHOD}/soteria/partner/${ENDPOINT_NAME}"
    aws lambda add-permission \
        --function-name "$LAMBDA_FUNCTION" \
        --statement-id "api-gateway-${API_GATEWAY_ID}-partner-${ENDPOINT_NAME}-${HTTP_METHOD}" \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "$SOURCE_ARN" \
        --region "$REGION" \
        2>/dev/null || echo "   Permission may already exist"
    
    # Create/update method
    aws apigateway put-method \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$RESOURCE_ID" \
        --http-method "$HTTP_METHOD" \
        --authorization-type "NONE" \
        --region "$REGION" \
        --query 'httpMethod' \
        --output text \
        2>/dev/null || echo "   Method may already exist"
    
    # Set up integration
    aws apigateway put-integration \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$RESOURCE_ID" \
        --http-method "$HTTP_METHOD" \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
        --region "$REGION" \
        --query 'type' \
        --output text
    
    echo "   ✅ Connected"
}

# Create endpoints
create_endpoint "validate-member" "POST" "soteria-partner-validate-member"
create_endpoint "list" "GET" "soteria-partner-list"
create_endpoint "redeem" "POST" "soteria-partner-redeem"

echo ""
echo "✅ All Partner API endpoints configured!"
echo ""
echo "Deploying to prod stage..."
aws apigateway create-deployment \
    --rest-api-id "$API_GATEWAY_ID" \
    --stage-name prod \
    --region "$REGION" \
    --query 'id' \
    --output text

echo ""
echo "✅ Deployment complete!"
echo ""
echo "API Endpoints:"
echo "  POST https://${API_GATEWAY_ID}.execute-api.${REGION}.amazonaws.com/prod/soteria/partner/validate-member"
echo "  GET  https://${API_GATEWAY_ID}.execute-api.${REGION}.amazonaws.com/prod/soteria/partner/list"
echo "  POST https://${API_GATEWAY_ID}.execute-api.${REGION}.amazonaws.com/prod/soteria/partner/redeem"
echo ""

