#!/bin/bash

# Deploy Lambda function for Montebay Silent AWS Audit form

REGION="us-east-1"
ROLE_NAME="montebay-lambda-role"
FUNCTION_NAME="montebay-silent-aws-audit-form"

echo "🚀 Deploying Montebay Silent AWS Audit form Lambda..."

# Navigate to Lambda directory
cd "$(dirname "$0")/lambda/montebay-silent-aws-audit-form"

# Install dependencies
echo "📦 Installing dependencies..."
npm install --production

# Create deployment package
echo "📦 Creating deployment package..."
zip -r function.zip index.js node_modules/ package.json -x "*.DS_Store" "*/.*"

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null)

if [ -z "$ROLE_ARN" ]; then
    echo "⚠️  IAM role '$ROLE_NAME' not found. Creating it..."
    
    # Create role (you'll need to create the trust policy and attach SES permissions)
    echo "Please create the IAM role manually with:"
    echo "1. Trust policy allowing Lambda service"
    echo "2. Permissions for SES (SendEmail, SendRawEmail)"
    echo "3. CloudWatch Logs permissions"
    echo ""
    echo "Or use an existing Lambda role and update ROLE_NAME in this script"
    exit 1
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
        --environment "Variables={TO_EMAIL=contact@montebay.io,FROM_EMAIL=noreply@montebay.io,AWS_REGION=$REGION}" \
        --region "$REGION"
    
    echo "✅ Function updated successfully!"
else
    echo "📦 Creating new function..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime nodejs20.x \
        --role "$ROLE_ARN" \
        --handler index.handler \
        --zip-file fileb://function.zip \
        --timeout 30 \
        --memory-size 256 \
        --environment "Variables={TO_EMAIL=contact@montebay.io,FROM_EMAIL=noreply@montebay.io,AWS_REGION=$REGION}" \
        --region "$REGION" \
        --tags "Project=Montebay,Environment=prod,Function=audit-form"
    
    echo "✅ Function created successfully!"
fi

# Clean up
rm -f function.zip
cd ../..

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Set up API Gateway endpoint (see MONTEBAY_AUDIT_FORM_SETUP.md)"
echo "2. Verify SES email domain/address in AWS Console"
echo "3. Update website JavaScript with API endpoint URL"

