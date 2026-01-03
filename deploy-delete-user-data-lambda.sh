#!/bin/bash

# Deploy Lambda function for deleting user data

REGION="us-east-1"
ROLE_NAME="soteria-lambda-role"
FUNCTION_NAME="soteria-delete-user-data"

echo "🚀 Deploying delete user data Lambda function..."

cd lambda/soteria-delete-user-data

# Install dependencies
npm install --production

# Create deployment package
zip -r function.zip index.js node_modules/ package.json

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --region "$REGION" --query 'Role.Arn' --output text 2>/dev/null)

if [ -z "$ROLE_ARN" ]; then
    echo "❌ Error: IAM role '$ROLE_NAME' not found"
    exit 1
fi

# Get Cognito User Pool ID (from environment or prompt)
if [ -z "$COGNITO_USER_POOL_ID" ]; then
    echo "Please enter Cognito User Pool ID:"
    read COGNITO_USER_POOL_ID
fi

# Check if function exists
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" 2>/dev/null; then
    echo "🔄 Updating existing function..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://function.zip \
        --region "$REGION"
    
    # Update environment variables
    aws lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --environment "Variables={COGNITO_USER_POOL_ID=$COGNITO_USER_POOL_ID}" \
        --region "$REGION"
else
    echo "📦 Creating new function..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime nodejs18.x \
        --role "$ROLE_ARN" \
        --handler index.handler \
        --zip-file fileb://function.zip \
        --timeout 60 \
        --memory-size 512 \
        --environment "Variables={COGNITO_USER_POOL_ID=$COGNITO_USER_POOL_ID}" \
        --region "$REGION" \
        --tags "Project=Soteria,Environment=prod,Function=delete-user-data"
fi

# Clean up
rm -f function.zip
cd ../..

echo ""
echo "✅ Delete user data Lambda function deployed successfully!"
echo ""
echo "Next steps:"
echo "1. Connect Lambda to API Gateway: ./connect-delete-user-data-to-api-gateway.sh"
echo "2. Grant Lambda permission to delete Cognito users"

