#!/bin/bash

# Deploy Lambda functions for avatar upload/download

REGION="us-east-1"
ROLE_NAME="soteria-lambda-role"
BUCKET_NAME="soteria-avatars-516141816050"

echo "🚀 Deploying avatar Lambda functions..."

# Function 1: Avatar Upload
echo ""
echo "📤 Deploying avatar upload Lambda..."
cd lambda/soteria-avatar-upload

# Install dependencies
npm install --production

# Create deployment package
zip -r function.zip index.js node_modules/ package.json

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null)

if [ -z "$ROLE_ARN" ]; then
    echo "❌ Error: IAM role '$ROLE_ARN' not found"
    echo "Please create the role first or update the ROLE_NAME variable"
    exit 1
fi

# Check if function exists
FUNCTION_NAME="soteria-avatar-upload"
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" 2>/dev/null; then
    echo "🔄 Updating existing function..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://function.zip \
        --region "$REGION"
    
    # Update environment variables
    aws lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --environment "Variables={AVATAR_BUCKET_NAME=$BUCKET_NAME}" \
        --region "$REGION"
else
    echo "📦 Creating new function..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime nodejs18.x \
        --role "$ROLE_ARN" \
        --handler index.handler \
        --zip-file fileb://function.zip \
        --timeout 30 \
        --memory-size 256 \
        --environment "Variables={AVATAR_BUCKET_NAME=$BUCKET_NAME}" \
        --region "$REGION" \
        --tags "Project=Soteria,Environment=prod,Function=avatar-upload"
fi

# Clean up
rm -f function.zip
cd ../..

# Function 2: Avatar Download
echo ""
echo "📥 Deploying avatar download Lambda..."
cd lambda/soteria-avatar-download

# Install dependencies
npm install --production

# Create deployment package
zip -r function.zip index.js node_modules/ package.json

# Check if function exists
FUNCTION_NAME="soteria-avatar-download"
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" 2>/dev/null; then
    echo "🔄 Updating existing function..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://function.zip \
        --region "$REGION"
    
    # Update environment variables
    aws lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --environment "Variables={AVATAR_BUCKET_NAME=$BUCKET_NAME}" \
        --region "$REGION"
else
    echo "📦 Creating new function..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime nodejs18.x \
        --role "$ROLE_ARN" \
        --handler index.handler \
        --zip-file fileb://function.zip \
        --timeout 30 \
        --memory-size 256 \
        --environment "Variables={AVATAR_BUCKET_NAME=$BUCKET_NAME}" \
        --region "$REGION" \
        --tags "Project=Soteria,Environment=prod,Function=avatar-download"
fi

# Clean up
rm -f function.zip
cd ../..

echo ""
echo "✅ Avatar Lambda functions deployed successfully!"
echo ""
echo "Next steps:"
echo "1. Create S3 bucket: ./create-s3-avatar-bucket.sh"
echo "2. Connect Lambda functions to API Gateway: ./connect-avatar-lambdas-to-api-gateway.sh"
echo "3. Update IAM role to allow S3 access"

