#!/bin/bash

# Script to deploy Soteria Lambda functions
# Run this script after creating the IAM role and DynamoDB tables

set -e  # Exit on error

echo "🚀 Deploying Soteria Lambda functions..."

# Configuration
REGION="us-east-1"
ROLE_NAME="soteria-lambda-role"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  Make sure you have:${NC}"
echo -e "${YELLOW}   1. Created IAM role: ${ROLE_NAME}${NC}"
echo -e "${YELLOW}   2. Created DynamoDB tables${NC}"
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
    
    # Check if function exists
    if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" &>/dev/null; then
        echo "   Function exists, updating..."
        UPDATE_MODE=true
    else
        echo "   Creating new function..."
        UPDATE_MODE=false
    fi
    
    # Install dependencies
    echo "   Installing dependencies..."
    cd "$LAMBDA_DIR"
    if [ ! -d "node_modules" ]; then
        npm install --production
    fi
    
    # Create deployment package
    echo "   Creating deployment package..."
    zip -r "../${FUNCTION_NAME}.zip" . -x "*.git*" "*.DS_Store*" > /dev/null
    cd ..
    
    if [ "$UPDATE_MODE" = true ]; then
        # Update function code
        aws lambda update-function-code \
            --function-name "$FUNCTION_NAME" \
            --zip-file "fileb://${FUNCTION_NAME}.zip" \
            --region "$REGION" \
            --query 'FunctionName' \
            --output text
        
        # Update configuration
        aws lambda update-function-configuration \
            --function-name "$FUNCTION_NAME" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY" \
            --region "$REGION" \
            --query 'FunctionName' \
            --output text
    else
        # Create function
        aws lambda create-function \
            --function-name "$FUNCTION_NAME" \
            --runtime nodejs20.x \
            --role "$ROLE_ARN" \
            --handler "$HANDLER" \
            --zip-file "fileb://${FUNCTION_NAME}.zip" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY" \
            --region "$REGION" \
            --tags Project=Soteria,Environment=prod \
            --query 'FunctionName' \
            --output text
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ $FUNCTION_NAME deployed successfully${NC}"
    else
        echo -e "${RED}   ❌ Failed to deploy $FUNCTION_NAME${NC}"
        return 1
    fi
}

# Deploy Lambda functions
cd "$(dirname "$0")/lambda"

# 1. soteria-sync-user-data
deploy_lambda "soteria-sync-user-data" "soteria-sync-user-data" "index.handler" 30 256

# 2. soteria-get-user-data
deploy_lambda "soteria-get-user-data" "soteria-get-user-data" "index.handler" 30 256

# 3. soteria-get-dashboard (pre-computed dashboard data)
deploy_lambda "soteria-get-dashboard" "soteria-get-dashboard" "index.handler" 10 512

# 4. Plaid functions
deploy_lambda "soteria-plaid-create-link-token" "soteria-plaid-create-link-token" "index.handler" 30 256
deploy_lambda "soteria-plaid-exchange-token" "soteria-plaid-exchange-token" "index.handler" 30 256
deploy_lambda "soteria-plaid-get-balance" "soteria-plaid-get-balance" "index.handler" 30 256
deploy_lambda "soteria-plaid-transfer" "soteria-plaid-transfer" "index.handler" 60 512

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All Lambda Functions Deployed!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Functions deployed:"
echo "  Data Sync:"
echo "    - soteria-sync-user-data"
echo "    - soteria-get-user-data"
echo "  Dashboard:"
echo "    - soteria-get-dashboard (pre-computed metrics)"
echo "  Plaid:"
echo "    - soteria-plaid-create-link-token"
echo "    - soteria-plaid-exchange-token"
echo "    - soteria-plaid-get-balance"
echo "    - soteria-plaid-transfer"
echo ""
echo "Next steps:"
echo "  1. Connect Lambda functions to API Gateway"
echo "  2. Configure CORS on API Gateway"
echo "  3. Deploy API Gateway to prod stage"
echo "  4. Update iOS app with new API Gateway URL"
echo ""

