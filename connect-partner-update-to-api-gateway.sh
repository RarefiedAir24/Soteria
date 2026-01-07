#!/bin/bash

# Connect partner update Lambda function to API Gateway

API_GATEWAY_ID="ue1psw3mt3"
REGION="us-east-1"
FUNCTION_NAME="soteria-partner-update"

echo "🔗 Connecting partner update Lambda to API Gateway..."

# Get /soteria resource ID
SOTERIA_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_GATEWAY_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria'].id" \
    --output text)

if [ -z "$SOTERIA_RESOURCE_ID" ]; then
    echo "❌ Error: /soteria resource not found"
    exit 1
fi

# Get /soteria/partner resource ID
PARTNER_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_GATEWAY_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/partner'].id" \
    --output text)

if [ -z "$PARTNER_RESOURCE_ID" ]; then
    echo "❌ Error: /soteria/partner resource not found"
    exit 1
fi

# Check if /soteria/partner/{partner_id} resource exists (path parameter)
PARTNER_ID_RESOURCE=$(aws apigateway get-resources \
    --rest-api-id "$API_GATEWAY_ID" \
    --region "$REGION" \
    --query "items[?path=='/soteria/partner/{partner_id}'].id" \
    --output text)

if [ -z "$PARTNER_ID_RESOURCE" ]; then
    echo "📦 Creating /soteria/partner/{partner_id} resource..."
    PARTNER_ID_RESOURCE=$(aws apigateway create-resource \
        --rest-api-id "$API_GATEWAY_ID" \
        --parent-id "$PARTNER_RESOURCE_ID" \
        --path-part "{partner_id}" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    echo "✅ Created /soteria/partner/{partner_id} resource: $PARTNER_ID_RESOURCE"
else
    echo "✅ Found existing /soteria/partner/{partner_id} resource: $PARTNER_ID_RESOURCE"
fi

# Get Lambda function ARN
FUNCTION_ARN=$(aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" --query 'Configuration.FunctionArn' --output text)

if [ -z "$FUNCTION_ARN" ]; then
    echo "❌ Error: Lambda function not found"
    exit 1
fi

echo "✅ Lambda ARN: $FUNCTION_ARN"

# Grant API Gateway permission to invoke Lambda function
echo ""
echo "🔐 Granting API Gateway permission to invoke Lambda function..."

aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "api-gateway-invoke-update-$(date +%s)" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "arn:aws:execute-api:$REGION:*:$API_GATEWAY_ID/*/PUT/soteria/partner/*" \
    --region "$REGION" 2>/dev/null || echo "⚠️ Permission may already exist"

# Create PUT method
echo ""
echo "📝 Creating PUT method for /soteria/partner/{partner_id}..."
aws apigateway put-method \
    --rest-api-id "$API_GATEWAY_ID" \
    --resource-id "$PARTNER_ID_RESOURCE" \
    --http-method PUT \
    --authorization-type NONE \
    --region "$REGION" 2>/dev/null || echo "⚠️ Method may already exist"

# Create integration
echo "🔗 Creating Lambda integration..."
aws apigateway put-integration \
    --rest-api-id "$API_GATEWAY_ID" \
    --resource-id "$PARTNER_ID_RESOURCE" \
    --http-method PUT \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FUNCTION_ARN/invocations" \
    --region "$REGION" 2>/dev/null || echo "⚠️ Integration may already exist"

# Deploy API
echo ""
echo "🚀 Deploying API Gateway to prod stage..."
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id "$API_GATEWAY_ID" \
    --stage-name prod \
    --region "$REGION" \
    --query 'id' \
    --output text)

echo "✅ Deployment ID: $DEPLOYMENT_ID"
echo ""
echo "✅ Partner update endpoint configured!"
echo ""
echo "Endpoint: PUT https://${API_GATEWAY_ID}.execute-api.${REGION}.amazonaws.com/prod/soteria/partner/{partner_id}"
echo ""

