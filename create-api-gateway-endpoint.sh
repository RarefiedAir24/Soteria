#!/bin/bash

# Script to create API Gateway endpoint for app name lookup
# This script provides instructions and can create the endpoint if API Gateway CLI is available

echo "🔧 Creating API Gateway endpoint: POST /soteria/app-name"
echo ""

# Check if API Gateway ID is provided
if [ -z "$1" ]; then
    echo "Usage: ./create-api-gateway-endpoint.sh <API_GATEWAY_ID>"
    echo ""
    echo "To find your API Gateway ID:"
    echo "1. Go to AWS Console → API Gateway"
    echo "2. Find your API (e.g., 'soteria-api')"
    echo "3. Copy the API ID from the URL or details page"
    exit 1
fi

API_ID=$1
REGION="us-east-1"
FUNCTION_NAME="soteria-get-app-name"
FUNCTION_ARN=$(aws lambda get-function --function-name $FUNCTION_NAME --region $REGION --query 'Configuration.FunctionArn' --output text)

if [ -z "$FUNCTION_ARN" ]; then
    echo "❌ Error: Lambda function '$FUNCTION_NAME' not found"
    exit 1
fi

echo "📋 API Gateway ID: $API_ID"
echo "📋 Lambda Function: $FUNCTION_NAME"
echo "📋 Function ARN: $FUNCTION_ARN"
echo ""

# Note: API Gateway CLI operations are complex
# It's easier to do this via AWS Console or use AWS CDK/CloudFormation
echo "⚠️  Note: Creating API Gateway resources via CLI is complex"
echo "💡 Recommended: Use AWS Console or AWS CDK/CloudFormation"
echo ""
echo "📝 Manual Steps (AWS Console):"
echo ""
echo "1. Go to API Gateway Console → Your API ($API_ID)"
echo "2. Create Resource:"
echo "   - Click on '/soteria' resource (or create it if it doesn't exist)"
echo "   - Actions → Create Resource"
echo "   - Resource Name: app-name"
echo "   - Resource Path: app-name"
echo "   - Enable CORS: Yes"
echo "   - Create"
echo ""
echo "3. Create Method:"
echo "   - Click on '/soteria/app-name' resource"
echo "   - Actions → Create Method → POST"
echo "   - Integration type: Lambda Function"
echo "   - Lambda Function: $FUNCTION_NAME"
echo "   - Use Lambda Proxy Integration: Yes"
echo "   - Save"
echo ""
echo "4. Enable CORS:"
echo "   - Click on '/soteria/app-name' resource"
echo "   - Actions → Enable CORS"
echo "   - Access-Control-Allow-Origin: *"
echo "   - Access-Control-Allow-Headers: Content-Type,Authorization"
echo "   - Access-Control-Allow-Methods: POST,OPTIONS"
echo "   - Save"
echo ""
echo "5. Deploy API:"
echo "   - Actions → Deploy API"
echo "   - Deployment stage: prod (or create new)"
echo "   - Deploy"
echo ""
echo "6. Get Endpoint URL:"
echo "   https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/soteria/app-name"
echo ""
echo "7. Update iOS App:"
echo "   - Edit: soteria/Services/AWSDataService.swift"
echo "   - Update: apiGatewayURL = \"https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod\""
echo ""

# Try to create via CLI (basic attempt)
echo "🔄 Attempting to create via CLI..."
echo "⚠️  This may fail if resources don't exist - use manual steps above if needed"
echo ""

# Check if /soteria resource exists
SOTERIA_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --region $REGION \
    --query "items[?path=='/soteria'].id" \
    --output text 2>/dev/null)

if [ -z "$SOTERIA_RESOURCE_ID" ]; then
    echo "⚠️  /soteria resource not found - creating..."
    # This would require more complex CLI commands
    echo "💡 Please create /soteria resource manually in AWS Console first"
    exit 1
fi

echo "✅ /soteria resource found: $SOTERIA_RESOURCE_ID"
echo "💡 Continue with manual steps above to create /soteria/app-name endpoint"

