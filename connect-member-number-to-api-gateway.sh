#!/bin/bash

# Connect member number Lambda to API Gateway

API_ID=$(aws apigateway get-rest-apis --region us-east-1 --query 'items[0].id' --output text)

if [ -z "$API_ID" ]; then
    echo "❌ Could not find API Gateway"
    exit 1
fi

echo "📡 API Gateway ID: $API_ID"

# Get /soteria resource ID
SOTERIA_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region us-east-1 --query 'items[?path==`/soteria`].id' --output text)

if [ -z "$SOTERIA_RESOURCE_ID" ]; then
    echo "❌ Could not find /soteria resource"
    exit 1
fi

echo "✅ Found /soteria resource: $SOTERIA_RESOURCE_ID"

# Check if member-number resource already exists
MEMBER_NUMBER_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --region us-east-1 --query "items[?path==\`/soteria/member-number\`].id" --output text)

if [ -z "$MEMBER_NUMBER_RESOURCE_ID" ]; then
    echo "📦 Creating /soteria/member-number resource..."
    MEMBER_NUMBER_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_ID" \
        --parent-id "$SOTERIA_RESOURCE_ID" \
        --path-part "member-number" \
        --region us-east-1 \
        --query 'id' \
        --output text)
    
    if [ $? -eq 0 ]; then
        echo "✅ Created resource: $MEMBER_NUMBER_RESOURCE_ID"
    else
        echo "❌ Failed to create resource"
        exit 1
    fi
else
    echo "✅ Resource already exists: $MEMBER_NUMBER_RESOURCE_ID"
fi

# Get Lambda function ARN
LAMBDA_ARN=$(aws lambda get-function --function-name soteria-member-number --region us-east-1 --query 'Configuration.FunctionArn' --output text 2>/dev/null)

if [ -z "$LAMBDA_ARN" ]; then
    echo "❌ Could not find Lambda function"
    exit 1
fi

echo "✅ Lambda ARN: $LAMBDA_ARN"

# Get AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"

# Grant API Gateway permission to invoke Lambda
echo "🔐 Granting API Gateway permission to invoke Lambda..."
aws lambda add-permission \
    --function-name soteria-member-number \
    --statement-id "api-gateway-invoke-$(date +%s)" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" \
    --region "$REGION" 2>&1 | grep -v "already exists" || echo "✅ Permission already exists"

# Create GET method
echo "📡 Creating GET method..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$MEMBER_NUMBER_RESOURCE_ID" \
    --http-method GET \
    --authorization-type NONE \
    --region us-east-1 2>&1 | grep -E "(httpMethod|authorizationType)" || echo "✅ Method already exists"

# Set up Lambda integration
echo "🔗 Setting up Lambda integration..."
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$MEMBER_NUMBER_RESOURCE_ID" \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
    --region us-east-1 2>&1 | grep -E "(type|uri)" || echo "✅ Integration already exists"

# Deploy to prod stage
echo "🚀 Deploying to prod stage..."
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name prod \
    --region us-east-1 2>&1 | grep -E "(id|createdDate)" || echo "✅ Deployment created"

echo ""
echo "=========================================="
echo "✅ Member Number API Connected!"
echo ""
echo "Endpoint: https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod/soteria/member-number"
echo ""

