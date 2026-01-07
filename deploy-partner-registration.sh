#!/bin/bash

# Deploy Partner Registration Lambda Function
# This script deploys the partner registration Lambda and connects it to API Gateway

set -e

LAMBDA_FUNCTION_NAME="soteria-partner-register"
LAMBDA_DIR="lambda/soteria-partner-register"
API_GATEWAY_ID="${API_GATEWAY_ID:-ue1psw3mt3}"
REGION="${AWS_REGION:-us-east-1}"
ROLE_ARN="${LAMBDA_ROLE_ARN:-arn:aws:iam::516141816050:role/soteria-lambda-role}"

echo "🚀 Deploying Partner Registration Lambda..."

# Navigate to Lambda directory
cd "$LAMBDA_DIR" || exit 1

# Install dependencies
echo "📦 Installing dependencies..."
npm install --production

# Create deployment package
echo "📦 Creating deployment package..."
zip -r function.zip . -x "*.git*" "*.zip" "node_modules/.cache/*"

# Get or create Lambda function
echo "🔍 Checking if Lambda function exists..."
if aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" --region "$REGION" &>/dev/null; then
    echo "✅ Lambda function exists, updating..."
    aws lambda update-function-code \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --zip-file fileb://function.zip \
        --region "$REGION"
else
    echo "📝 Creating new Lambda function..."
    aws lambda create-function \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --runtime nodejs18.x \
        --role "$ROLE_ARN" \
        --handler index.handler \
        --zip-file fileb://function.zip \
        --timeout 30 \
        --memory-size 256 \
        --environment "Variables={PARTNERS_TABLE=soteria-partners,API_KEYS_TABLE=soteria-partner-api-keys}" \
        --region "$REGION"
fi

# Wait for function to be ready
echo "⏳ Waiting for Lambda function to be ready..."
aws lambda wait function-updated --function-name "$LAMBDA_FUNCTION_NAME" --region "$REGION"

# Get Lambda ARN
LAMBDA_ARN=$(aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" --region "$REGION" --query 'Configuration.FunctionArn' --output text)
echo "✅ Lambda ARN: $LAMBDA_ARN"

# Grant API Gateway permission to invoke Lambda
echo "🔐 Granting API Gateway permission..."
aws lambda add-permission \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --statement-id "api-gateway-invoke-$(date +%s)" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:516141816050:$API_GATEWAY_ID/*/*" \
    --region "$REGION" 2>/dev/null || echo "⚠️  Permission may already exist"

# Get /soteria resource ID
echo "🔍 Getting API Gateway resource IDs..."
ROOT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_GATEWAY_ID" --region "$REGION" --query "items[?path=='/soteria'].id" --output text)

if [ -z "$ROOT_RESOURCE_ID" ]; then
    echo "❌ /soteria resource not found. Please create it first."
    exit 1
fi

# Get or create /soteria/partner resource
PARTNER_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_GATEWAY_ID" --region "$REGION" --query "items[?path=='/soteria/partner'].id" --output text)

if [ -z "$PARTNER_RESOURCE_ID" ]; then
    echo "📝 Creating /soteria/partner resource..."
    PARTNER_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_GATEWAY_ID" \
        --parent-id "$ROOT_RESOURCE_ID" \
        --path-part "partner" \
        --region "$REGION" \
        --query 'id' --output text)
fi

# Get or create /soteria/partner/register resource
REGISTER_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_GATEWAY_ID" --region "$REGION" --query "items[?path=='/soteria/partner/register'].id" --output text)

if [ -z "$REGISTER_RESOURCE_ID" ]; then
    echo "📝 Creating /soteria/partner/register resource..."
    REGISTER_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id "$API_GATEWAY_ID" \
        --parent-id "$PARTNER_RESOURCE_ID" \
        --path-part "register" \
        --region "$REGION" \
        --query 'id' --output text)
fi

# Create or update POST method
echo "📝 Setting up POST method..."
if aws apigateway get-method --rest-api-id "$API_GATEWAY_ID" --resource-id "$REGISTER_RESOURCE_ID" --http-method POST --region "$REGION" &>/dev/null; then
    echo "✅ POST method exists, updating..."
    aws apigateway update-method \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$REGISTER_RESOURCE_ID" \
        --http-method POST \
        --authorization-type NONE \
        --region "$REGION"
else
    echo "📝 Creating POST method..."
    aws apigateway put-method \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$REGISTER_RESOURCE_ID" \
        --http-method POST \
        --authorization-type NONE \
        --region "$REGION"
fi

# Set up Lambda integration
echo "🔗 Setting up Lambda integration..."
aws apigateway put-integration \
    --rest-api-id "$API_GATEWAY_ID" \
    --resource-id "$REGISTER_RESOURCE_ID" \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations" \
    --region "$REGION"

# Create OPTIONS method for CORS
echo "📝 Setting up OPTIONS method for CORS..."
if ! aws apigateway get-method --rest-api-id "$API_GATEWAY_ID" --resource-id "$REGISTER_RESOURCE_ID" --http-method OPTIONS --region "$REGION" &>/dev/null; then
    aws apigateway put-method \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$REGISTER_RESOURCE_ID" \
        --http-method OPTIONS \
        --authorization-type NONE \
        --region "$REGION"
    
    aws apigateway put-integration \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$REGISTER_RESOURCE_ID" \
        --http-method OPTIONS \
        --type MOCK \
        --request-templates '{"application/json":"{\"statusCode\":200}"}' \
        --region "$REGION"
    
    aws apigateway put-method-response \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$REGISTER_RESOURCE_ID" \
        --http-method OPTIONS \
        --status-code 200 \
        --response-parameters '{"method.response.header.Access-Control-Allow-Headers":true,"method.response.header.Access-Control-Allow-Methods":true,"method.response.header.Access-Control-Allow-Origin":true}' \
        --region "$REGION"
    
    aws apigateway put-integration-response \
        --rest-api-id "$API_GATEWAY_ID" \
        --resource-id "$REGISTER_RESOURCE_ID" \
        --http-method OPTIONS \
        --status-code 200 \
        --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,Authorization'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'POST,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'"}' \
        --region "$REGION"
fi

# Deploy API
echo "🚀 Deploying API Gateway..."
aws apigateway create-deployment \
    --rest-api-id "$API_GATEWAY_ID" \
    --stage-name prod \
    --region "$REGION"

echo ""
echo "✅ Partner Registration Lambda deployed successfully!"
echo ""
echo "📋 Endpoint:"
echo "   POST https://$API_GATEWAY_ID.execute-api.$REGION.amazonaws.com/prod/soteria/partner/register"
echo ""
echo "📝 Next Steps:"
echo "   1. Create DynamoDB table: soteria-partner-api-keys"
echo "   2. Test the registration endpoint"
echo "   3. Update partner onboarding documentation"

cd - || exit 1

