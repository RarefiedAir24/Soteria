#!/bin/bash

# Script to add Plaid credentials to Lambda functions
# Usage: ./add-plaid-credentials.sh YOUR_CLIENT_ID YOUR_SECRET

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

echo "🔐 Adding Plaid credentials to Lambda functions..."
echo "Environment: $PLAID_ENV"
echo ""

# Update all three functions
for func in rever-plaid-create-link-token rever-plaid-exchange-token rever-plaid-transfer; do
    echo "Updating $func..."
    aws lambda update-function-configuration \
        --function-name "$func" \
        --environment "Variables={PLAID_CLIENT_ID=$PLAID_CLIENT_ID,PLAID_SECRET=$PLAID_SECRET,PLAID_ENV=$PLAID_ENV,DYNAMODB_TABLE=rever-plaid-access-tokens}" \
        --region us-east-1 \
        --query 'FunctionName' \
        --output text > /dev/null
    echo "✅ $func updated"
done

echo ""
echo "✅ All Lambda functions updated with Plaid credentials!"
echo ""
echo "⚠️  Note: For production, use AWS Secrets Manager instead of environment variables"

