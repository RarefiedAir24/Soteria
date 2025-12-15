#!/bin/bash

# Script to deploy Lambda function: soteria-get-app-name

echo "🔧 Deploying Lambda function: soteria-get-app-name"

# Navigate to Lambda directory
cd "$(dirname "$0")/lambda/soteria-get-app-name"

# Check if node_modules exists, if not install dependencies
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Create deployment package
echo "📦 Creating deployment package..."
zip -r function.zip index.js node_modules package.json -x "*.DS_Store" "*/.*"

# Check if function exists
FUNCTION_NAME="soteria-get-app-name"
REGION="us-east-1"

if aws lambda get-function --function-name $FUNCTION_NAME --region $REGION &>/dev/null; then
    echo "🔄 Function exists, updating..."
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://function.zip \
        --region $REGION
    
    echo "⏳ Waiting for update to complete..."
    aws lambda wait function-updated \
        --function-name $FUNCTION_NAME \
        --region $REGION
    
    echo "✅ Function updated successfully!"
else
    echo "🆕 Function doesn't exist, creating..."
    
    # Get IAM role ARN (you may need to adjust this)
    ROLE_ARN=$(aws iam list-roles --query 'Roles[?RoleName==`soteria-lambda-role`].Arn' --output text --region $REGION)
    
    if [ -z "$ROLE_ARN" ]; then
        echo "❌ Error: IAM role 'soteria-lambda-role' not found"
        echo "💡 Create the role first or update the script with the correct role ARN"
        exit 1
    fi
    
    aws lambda create-function \
        --function-name $FUNCTION_NAME \
        --runtime nodejs18.x \
        --role $ROLE_ARN \
        --handler index.handler \
        --zip-file fileb://function.zip \
        --timeout 30 \
        --memory-size 256 \
        --environment Variables="{APP_TOKEN_MAPPINGS_TABLE=soteria-app-token-mappings}" \
        --region $REGION \
        --tags Project=Soteria,Environment=Production
    
    echo "⏳ Waiting for function to be active..."
    aws lambda wait function-active \
        --function-name $FUNCTION_NAME \
        --region $REGION
    
    echo "✅ Function created successfully!"
fi

# Clean up
rm -f function.zip

echo ""
echo "📋 Function Details:"
aws lambda get-function \
    --function-name $FUNCTION_NAME \
    --region $REGION \
    --query 'Configuration.[FunctionName,Runtime,LastModified,State]' \
    --output table

echo ""
echo "📝 Next steps:"
echo "1. Grant API Gateway permission (if needed)"
echo "2. Create API Gateway endpoint: POST /soteria/app-name"
echo "3. Populate database with app mappings"

cd - > /dev/null

