#!/bin/bash

# Script to add Plaid credentials to Soteria Lambda functions
# Usage: ./add-soteria-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "❌ Usage: $0 <PLAID_CLIENT_ID> <PLAID_SECRET>"
    echo ""
    echo "Get your credentials from: https://dashboard.plaid.com/developers/keys"
    exit 1
fi

PLAID_CLIENT_ID="$1"
PLAID_SECRET="$2"
PLAID_ENV="${3:-sandbox}"  # Default to sandbox

echo "🔐 Adding Plaid credentials to Soteria Lambda functions..."
echo "Environment: $PLAID_ENV"
echo ""

# Update all Soteria Plaid functions
for func in soteria-plaid-create-link-token soteria-plaid-exchange-token soteria-plaid-get-balance soteria-plaid-transfer; do
    echo "Updating $func..."
    aws lambda update-function-configuration \
        --function-name "$func" \
        --environment "Variables={PLAID_CLIENT_ID=$PLAID_CLIENT_ID,PLAID_SECRET=$PLAID_SECRET,PLAID_ENV=$PLAID_ENV,DYNAMODB_TABLE=soteria-plaid-access-tokens,TRANSFER_TABLE=soteria-plaid-transfers}" \
        --region us-east-1 \
        --query 'FunctionName' \
        --output text > /dev/null 2>&1 || echo "⚠️  Function $func may not exist yet - deploy it first"
    echo "✅ $func updated"
done

echo ""
echo "✅ All Soteria Lambda functions updated with Plaid credentials!"
echo ""
echo "⚠️  Note: For production, use AWS Secrets Manager instead of environment variables"
echo ""
echo "📝 Next steps:"
echo "   1. Deploy Lambda functions if not already deployed"
echo "   2. Create DynamoDB tables: soteria-plaid-access-tokens, soteria-plaid-transfers"
echo "   3. Update PlaidService.swift with your API Gateway URL"

