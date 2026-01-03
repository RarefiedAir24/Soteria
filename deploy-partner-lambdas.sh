#!/bin/bash

# Deploy Lambda functions for Partner Discount system

REGION="us-east-1"
ROLE_NAME="soteria-lambda-role"

echo "🚀 Deploying Partner Discount Lambda functions..."

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null)

if [ -z "$ROLE_ARN" ]; then
    echo "❌ Error: IAM role '$ROLE_NAME' not found"
    echo "Please create the role first: ./create-soteria-lambda-role.sh"
    exit 1
fi

echo "✅ Using IAM role: $ROLE_ARN"
echo ""

# Function to deploy a Lambda function
deploy_lambda() {
    local FUNCTION_NAME=$1
    local LAMBDA_DIR=$2
    local HANDLER=$3
    local TIMEOUT=${4:-30}
    local MEMORY=${5:-256}
    
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
            --environment "Variables={PARTNERS_TABLE=soteria-partners,REDEMPTIONS_TABLE=soteria-partner-redemptions,SCANS_TABLE=soteria-partner-scans,USER_DATA_TABLE=soteria-user-data,USER_POOL_ID=${USER_POOL_ID:-us-east-1_XXXXXXXXX}}" \
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
            --environment "Variables={PARTNERS_TABLE=soteria-partners,REDEMPTIONS_TABLE=soteria-partner-redemptions,SCANS_TABLE=soteria-partner-scans,USER_DATA_TABLE=soteria-user-data,USER_POOL_ID=${USER_POOL_ID:-us-east-1_XXXXXXXXX}}" \
            --tags Project=Soteria,Environment=prod,Feature=PartnerDiscounts \
            --query 'FunctionName' \
            --output text
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "   ✅ $FUNCTION_NAME deployed successfully"
    else
        echo -e "   ❌ Failed to deploy $FUNCTION_NAME"
        return 1
    fi
}

# Deploy Lambda functions
cd "$(dirname "$0")/lambda"

# 1. Partner Validate Member
deploy_lambda "soteria-partner-validate-member" "soteria-partner-validate-member" "index.handler" 30 256

# 2. Partner List
deploy_lambda "soteria-partner-list" "soteria-partner-list" "index.handler" 30 256

# 3. Partner Redeem
deploy_lambda "soteria-partner-redeem" "soteria-partner-redeem" "index.handler" 30 256

echo ""
echo "✅ All Partner Discount Lambda Functions Deployed!"
echo ""
echo "Next steps:"
echo "  1. Create DynamoDB tables: ./create-partner-tables.sh"
echo "  2. Connect Lambda functions to API Gateway: ./connect-partner-lambdas-to-api-gateway.sh"
echo "  3. Configure CORS on API Gateway"
echo "  4. Deploy API Gateway to prod stage"
echo ""

