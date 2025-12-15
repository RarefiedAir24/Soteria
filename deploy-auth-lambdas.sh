#!/bin/bash

# Script to deploy Soteria authentication Lambda functions
# Run this script after creating the Cognito User Pool

set -e  # Exit on error

echo "🚀 Deploying Soteria authentication Lambda functions..."

# Configuration
REGION="us-east-1"
ROLE_NAME="soteria-lambda-role"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# Get Cognito User Pool ID and Client ID
echo ""
echo "📝 Please provide your Cognito configuration:"
read -p "User Pool ID: " USER_POOL_ID
read -p "Client ID: " CLIENT_ID
read -p "Client Secret (optional, press Enter if none): " CLIENT_SECRET

if [ -z "$USER_POOL_ID" ] || [ -z "$CLIENT_ID" ]; then
    echo "❌ User Pool ID and Client ID are required"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  Make sure you have:${NC}"
echo -e "${YELLOW}   1. Created IAM role: ${ROLE_NAME}${NC}"
echo -e "${YELLOW}   2. Created Cognito User Pool${NC}"
echo -e "${YELLOW}   3. Installed dependencies in lambda directories${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Function to deploy a Lambda function
deploy_lambda() {
    local FUNCTION_NAME=$1
    local LAMBDA_DIR=$2
    local HANDLER=$3
    local TIMEOUT=${4:-30}
    local MEMORY=${5:-256}
    
    echo ""
    echo "📦 Deploying: $FUNCTION_NAME..."
    
    # Install dependencies if node_modules doesn't exist
    if [ ! -d "$LAMBDA_DIR/node_modules" ]; then
        echo "   Installing dependencies..."
        cd "$LAMBDA_DIR"
        npm install --production
        cd - > /dev/null
    fi
    
    # Create deployment package
    echo "   Creating deployment package..."
    cd "$LAMBDA_DIR"
    zip -r "../${FUNCTION_NAME}.zip" . -x "*.git*" "*.DS_Store*" > /dev/null
    cd - > /dev/null
    
    # Check if function exists
    if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" &>/dev/null; then
        echo "   Function exists, updating code..."
        aws lambda update-function-code \
            --function-name "$FUNCTION_NAME" \
            --zip-file "fileb://lambda/${FUNCTION_NAME}.zip" \
            --region "$REGION" \
            --query 'FunctionName' \
            --output text
        
        echo "   Updating configuration..."
        aws lambda update-function-configuration \
            --function-name "$FUNCTION_NAME" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY" \
            --environment "Variables={USER_POOL_ID=${USER_POOL_ID},CLIENT_ID=${CLIENT_ID}${CLIENT_SECRET:+,CLIENT_SECRET=${CLIENT_SECRET}}}" \
            --region "$REGION" \
            --query 'FunctionName' \
            --output text
    else
        echo "   Creating new function..."
        # Create tags JSON
        TAGS_JSON='{"Project":"Soteria","Environment":"prod"}'
        
        aws lambda create-function \
            --function-name "$FUNCTION_NAME" \
            --runtime nodejs18.x \
            --role "$ROLE_ARN" \
            --handler "$HANDLER" \
            --zip-file "fileb://lambda/${FUNCTION_NAME}.zip" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY" \
            --environment "Variables={USER_POOL_ID=${USER_POOL_ID},CLIENT_ID=${CLIENT_ID}${CLIENT_SECRET:+,CLIENT_SECRET=${CLIENT_SECRET}}}" \
            --region "$REGION" \
            --tags "$TAGS_JSON" \
            --query 'FunctionName' \
            --output text
    fi
    
    echo -e "${GREEN}   ✅ $FUNCTION_NAME deployed${NC}"
}

# Deploy all auth Lambda functions
deploy_lambda "soteria-auth-signup" "lambda/soteria-auth-signup" "index.handler" 30 256
deploy_lambda "soteria-auth-signin" "lambda/soteria-auth-signin" "index.handler" 30 256
deploy_lambda "soteria-auth-refresh" "lambda/soteria-auth-refresh" "index.handler" 30 256
deploy_lambda "soteria-auth-reset-password" "lambda/soteria-auth-reset-password" "index.handler" 30 256

# Step 5: Output summary
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Authentication Lambda Functions Deployed!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Deployed functions:"
echo "  - soteria-auth-signup"
echo "  - soteria-auth-signin"
echo "  - soteria-auth-refresh"
echo "  - soteria-auth-reset-password"
echo ""
echo "Next step: Run connect-auth-lambdas-to-api-gateway.sh"
echo ""

