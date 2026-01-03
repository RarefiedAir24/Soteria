#!/bin/bash

# Connect Partner Discount Lambda functions to API Gateway

REGION="us-east-1"
API_GATEWAY_ID="${API_GATEWAY_ID:-ue1psw3mt3}"  # Default API Gateway ID
STAGE="prod"

echo "🔗 Connecting Partner Discount Lambda functions to API Gateway..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to connect Lambda to API Gateway
connect_lambda() {
    local RESOURCE_PATH=$1
    local HTTP_METHOD=$2
    local FUNCTION_NAME=$3
    
    echo ""
    echo "📡 Connecting: $RESOURCE_PATH ($HTTP_METHOD) -> $FUNCTION_NAME"
    
    # Get or create resource
    RESOURCE_ID=$(aws apigateway get-resources \
        --rest-api-id "$API_GATEWAY_ID" \
        --region "$REGION" \
        --query "items[?path=='$RESOURCE_PATH'].id" \
        --output text 2>/dev/null)
    
    if [ -z "$RESOURCE_ID" ] || [ "$RESOURCE_ID" == "None" ]; then
        echo "   Creating resource: $RESOURCE_PATH"
        # Get parent resource ID (assuming /soteria exists)
        PARENT_ID=$(aws apigateway get-resources \
            --rest-api-id "$API_GATEWAY_ID" \
            --region "$REGION" \
            --query "items[?path=='/soteria'].id" \
            --output text 2>/dev/null)
        
        if [ -z "$PARENT_ID" ] || [ "$PARENT_ID" == "None" ]; then
            echo -e "${RED}   ❌ Parent resource /soteria not found${NC}"
            return 1
        fi
        
        # Create resource
        RESOURCE_ID=$(aws apigateway create-resource \
            --rest-api-id "$API_GATEWAY_ID" \
            --parent-id "$PARENT_ID" \
            --path-part "$(basename $RESOURCE_PATH)" \
            --region "$REGION" \
            --query 'id' \
            --output text)
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}   ❌ Failed to create resource${NC}"
            return 1
        fi
    fi
    
    echo "   Resource ID: $RESOURCE_ID"
    
    # Get Lambda function ARN
    LAMBDA_ARN=$(aws lambda get-function \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION" \
        --query 'Configuration.FunctionArn' \
        --output text)
    
    if [ -z "$LAMBDA_ARN" ]; then
        echo -e "${RED}   ❌ Lambda function not found: $FUNCTION_NAME${NC}"
        return 1
    fi
    
    echo "   Lambda ARN: $LAMBDA_ARN"
    
    # Grant API Gateway permission to invoke Lambda
    SOURCE_ARN="arn:aws:execute-api:${REGION}:*:${API_GATEWAY_ID}/*/${HTTP_METHOD}${RESOURCE_PATH}"
    
    aws lambda add-permission \
        --function-name "$FUNCTION_NAME" \
        --statement-id "api-gateway-${API_GATEWAY_ID}-${RESOURCE_PATH//\//-}-${HTTP_METHOD}" \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "$SOURCE_ARN" \
        --region "$REGION" \
        2>/dev/null || echo "   Permission may already exist"
    
    # Create or update method
    aws apigateway put-method \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$RESOURCE_ID" \
        --http-method "$HTTP_METHOD" \
        --authorization-type "NONE" \
        --region "$REGION" \
        --query 'httpMethod' \
        --output text \
        2>/dev/null || echo "   Method may already exist"
    
    # Set up integration
    aws apigateway put-integration \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$RESOURCE_ID" \
        --http-method "$HTTP_METHOD" \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
        --region "$REGION" \
        --query 'type' \
        --output text
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ Connected successfully${NC}"
    else
        echo -e "${RED}   ❌ Failed to connect${NC}"
        return 1
    fi
}

# Connect all Lambda functions
connect_lambda "/soteria/partner/validate-member" "POST" "soteria-partner-validate-member"
connect_lambda "/soteria/partner/list" "GET" "soteria-partner-list"
connect_lambda "/soteria/partner/redeem" "POST" "soteria-partner-redeem"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All Partner Discount APIs Connected!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Deploy to stage:"
echo "  aws apigateway create-deployment --rest-api-id $API_GATEWAY_ID --stage-name $STAGE --region $REGION"
echo ""
echo "API Endpoints:"
echo "  POST https://${API_GATEWAY_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}/soteria/partner/validate-member"
echo "  GET  https://${API_GATEWAY_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}/soteria/partner/list"
echo "  POST https://${API_GATEWAY_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}/soteria/partner/redeem"
echo ""

