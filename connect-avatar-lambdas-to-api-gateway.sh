#!/bin/bash

# Connect avatar Lambda functions to API Gateway

API_GATEWAY_ID="ue1psw3mt3"
REGION="us-east-1"
UPLOAD_FUNCTION_NAME="soteria-avatar-upload"
DOWNLOAD_FUNCTION_NAME="soteria-avatar-download"

echo "🔗 Connecting avatar Lambda functions to API Gateway..."

# Use the hardcoded API Gateway ID (from existing setup)
API_ID="$API_GATEWAY_ID"

echo "✅ Using API Gateway: $API_ID"

# Get root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" --query "items[?path=='/'].id" --output text)

# Check if /soteria resource exists, create if not
SOTERIA_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" --query "items[?path=='/soteria'].id" --output text)

if [ -z "$SOTERIA_RESOURCE_ID" ]; then
    echo "📦 Creating /soteria resource..."
    SOTERIA_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$ROOT_RESOURCE_ID" \
        --path-part "soteria" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    echo "✅ Created /soteria resource: $SOTERIA_RESOURCE_ID"
fi

# Check if /soteria/avatar resource exists, create if not
AVATAR_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" --query "items[?path=='/soteria/avatar'].id" --output text)

if [ -z "$AVATAR_RESOURCE_ID" ]; then
    echo "📦 Creating /soteria/avatar resource..."
    AVATAR_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$SOTERIA_RESOURCE_ID" \
        --path-part "avatar" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    echo "✅ Created /soteria/avatar resource: $AVATAR_RESOURCE_ID"
fi

# Get Lambda function ARNs
UPLOAD_FUNCTION_ARN=$(aws lambda get-function --function-name "$UPLOAD_FUNCTION_NAME" --region "$REGION" --query 'Configuration.FunctionArn' --output text)
DOWNLOAD_FUNCTION_ARN=$(aws lambda get-function --function-name "$DOWNLOAD_FUNCTION_NAME" --region "$REGION" --query 'Configuration.FunctionArn' --output text)

if [ -z "$UPLOAD_FUNCTION_ARN" ] || [ -z "$DOWNLOAD_FUNCTION_ARN" ]; then
    echo "❌ Error: Lambda functions not found"
    exit 1
fi

# Grant API Gateway permission to invoke Lambda functions
echo ""
echo "🔐 Granting API Gateway permission to invoke Lambda functions..."

aws lambda add-permission \
    --function-name "$UPLOAD_FUNCTION_NAME" \
    --statement-id "api-gateway-invoke-upload" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "arn:aws:execute-api:$REGION:*:$API_ID/*/*" \
    --region "$REGION" 2>/dev/null || echo "⚠️ Permission may already exist"

aws lambda add-permission \
    --function-name "$DOWNLOAD_FUNCTION_NAME" \
    --statement-id "api-gateway-invoke-download" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "arn:aws:execute-api:$REGION:*:$API_ID/*/*" \
    --region "$REGION" 2>/dev/null || echo "⚠️ Permission may already exist"

# Create /upload resource
UPLOAD_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" --query "items[?path=='/soteria/avatar/upload'].id" --output text)

if [ -z "$UPLOAD_RESOURCE_ID" ]; then
    echo "📦 Creating /soteria/avatar/upload resource..."
    UPLOAD_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$AVATAR_RESOURCE_ID" \
        --path-part "upload" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    echo "✅ Created /soteria/avatar/upload resource: $UPLOAD_RESOURCE_ID"
fi

# Create POST method for upload
echo "📝 Creating POST method for /soteria/avatar/upload..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$UPLOAD_RESOURCE_ID" \
    --http-method POST \
    --authorization-type NONE \
    --region "$REGION" 2>/dev/null || echo "⚠️ Method may already exist"

# Create integration for upload
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$UPLOAD_RESOURCE_ID" \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$UPLOAD_FUNCTION_ARN/invocations" \
    --region "$REGION" 2>/dev/null || echo "⚠️ Integration may already exist"

# Create /download resource
DOWNLOAD_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" --query "items[?path=='/soteria/avatar/download'].id" --output text)

if [ -z "$DOWNLOAD_RESOURCE_ID" ]; then
    echo "📦 Creating /soteria/avatar/download resource..."
    DOWNLOAD_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$AVATAR_RESOURCE_ID" \
        --path-part "download" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    echo "✅ Created /soteria/avatar/download resource: $DOWNLOAD_RESOURCE_ID"
fi

# Create GET method for download
echo "📝 Creating GET method for /soteria/avatar/download..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$DOWNLOAD_RESOURCE_ID" \
    --http-method GET \
    --authorization-type NONE \
    --region "$REGION" 2>/dev/null || echo "⚠️ Method may already exist"

# Create integration for download
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$DOWNLOAD_RESOURCE_ID" \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$DOWNLOAD_FUNCTION_ARN/invocations" \
    --region "$REGION" 2>/dev/null || echo "⚠️ Integration may already exist"

# Deploy API
echo ""
echo "🚀 Deploying API Gateway..."
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name prod \
    --region "$REGION" 2>/dev/null || echo "⚠️ Deployment may already exist"

echo ""
echo "✅ Avatar Lambda functions connected to API Gateway!"
echo ""
echo "Endpoints:"
echo "  POST https://$API_ID.execute-api.$REGION.amazonaws.com/prod/soteria/avatar/upload"
echo "  GET  https://$API_ID.execute-api.$REGION.amazonaws.com/prod/soteria/avatar/download"

