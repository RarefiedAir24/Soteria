#!/bin/bash

# Script to grant API Gateway permission to invoke Lambda function

FUNCTION_NAME="soteria-get-app-name"
REGION="us-east-1"

# Get API Gateway ID (you'll need to provide this)
echo "🔧 Granting API Gateway permission to invoke Lambda function"
echo ""
echo "Please provide your API Gateway ID:"
read -p "API Gateway ID: " API_ID

if [ -z "$API_ID" ]; then
    echo "❌ Error: API Gateway ID is required"
    exit 1
fi

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Grant permission
echo "🔐 Granting permission..."

aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id apigateway-invoke-$(date +%s) \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Permission granted successfully!"
else
    echo "⚠️  Permission may already exist (this is OK)"
fi

echo ""
echo "📝 Next steps:"
echo "1. Create API Gateway endpoint: POST /soteria/app-name"
echo "2. Connect endpoint to Lambda function"
echo "3. Deploy API Gateway"

