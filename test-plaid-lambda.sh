#!/bin/bash

# Test Plaid Lambda function and fix API Gateway integration

set -e

API_ID="ue1psw3mt3"
REGION="us-east-1"
ACCOUNT_ID="516141816050"
FUNCTION_NAME="soteria-plaid-create-link-token"

echo "🧪 Testing Plaid Lambda function..."

# Create test payload file
cat > /tmp/test-payload.json <<EOF
{
  "httpMethod": "POST",
  "body": "{\"user_id\":\"test123\",\"client_name\":\"Soteria\",\"products\":[\"auth\",\"balance\"],\"country_codes\":[\"US\"],\"language\":\"en\"}"
}
EOF

# Test Lambda function
echo "Testing Lambda function directly..."
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload file:///tmp/test-payload.json \
  --region $REGION \
  /tmp/lambda-response.json

echo ""
echo "Lambda response:"
cat /tmp/lambda-response.json | jq '.' 2>/dev/null || cat /tmp/lambda-response.json
echo ""

# Check if Lambda has permission for API Gateway
echo "Checking Lambda permissions..."
aws lambda get-policy \
  --function-name $FUNCTION_NAME \
  --region $REGION 2>&1 | grep -q "apigateway" && echo "✅ API Gateway has permission" || echo "⚠️  API Gateway permission might be missing"

echo ""
echo "🔍 Next steps:"
echo "1. Check CloudWatch logs: aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
echo "2. Test API Gateway endpoint: curl -X POST https://$API_ID.execute-api.$REGION.amazonaws.com/prod/soteria/plaid/create-link-token -H 'Content-Type: application/json' -d '{\"user_id\":\"test\"}'"

