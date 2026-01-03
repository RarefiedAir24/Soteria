#!/bin/bash

# Connect delete user data Lambda function to API Gateway

API_GATEWAY_ID="ue1psw3mt3"
REGION="us-east-1"
FUNCTION_NAME="soteria-delete-user-data"

echo "🔗 Connecting delete user data Lambda to API Gateway..."

# Use the hardcoded API Gateway ID
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

# Check if /soteria/user resource exists, create if not
USER_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" --query "items[?path=='/soteria/user'].id" --output text)

if [ -z "$USER_RESOURCE_ID" ]; then
    echo "📦 Creating /soteria/user resource..."
    USER_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$SOTERIA_RESOURCE_ID" \
        --path-part "user" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    echo "✅ Created /soteria/user resource: $USER_RESOURCE_ID"
fi

# Check if /soteria/user/delete resource exists, create if not
DELETE_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region "$REGION" --query "items[?path=='/soteria/user/delete'].id" --output text)

if [ -z "$DELETE_RESOURCE_ID" ]; then
    echo "📦 Creating /soteria/user/delete resource..."
    DELETE_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$USER_RESOURCE_ID" \
        --path-part "delete" \
        --region "$REGION" \
        --query 'id' \
        --output text)
    echo "✅ Created /soteria/user/delete resource: $DELETE_RESOURCE_ID"
fi

# Get Lambda function ARN
FUNCTION_ARN=$(aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" --query 'Configuration.FunctionArn' --output text)

if [ -z "$FUNCTION_ARN" ]; then
    echo "❌ Error: Lambda function not found"
    exit 1
fi

# Grant API Gateway permission to invoke Lambda function
echo ""
echo "🔐 Granting API Gateway permission to invoke Lambda function..."

aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "api-gateway-invoke-delete" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "arn:aws:execute-api:$REGION:*:$API_ID/*/*" \
    --region "$REGION" 2>/dev/null || echo "⚠️ Permission may already exist"

# Create POST method for delete
echo "📝 Creating POST method for /soteria/user/delete..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$DELETE_RESOURCE_ID" \
    --http-method POST \
    --authorization-type NONE \
    --region "$REGION" 2>/dev/null || echo "⚠️ Method may already exist"

# Create integration for delete
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$DELETE_RESOURCE_ID" \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FUNCTION_ARN/invocations" \
    --region "$REGION" 2>/dev/null || echo "⚠️ Integration may already exist"

# Deploy API
echo ""
echo "🚀 Deploying API Gateway..."
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name prod \
    --region "$REGION" 2>/dev/null || echo "⚠️ Deployment may already exist"

echo ""
echo "✅ Delete user data Lambda connected to API Gateway!"
echo ""
echo "Endpoint:"
echo "  POST https://$API_ID.execute-api.$REGION.amazonaws.com/prod/soteria/user/delete"

