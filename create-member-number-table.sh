#!/bin/bash

# Create DynamoDB table for member number mappings
# This table stores the mapping between member numbers and user IDs

TABLE_NAME="soteria-member-numbers"
REGION="us-east-1"

echo "📊 Creating Member Numbers DynamoDB Table"
echo "=========================================="
echo ""

# Check if table already exists
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null | grep -q "TableName"; then
    echo "✅ Table already exists: $TABLE_NAME"
    exit 0
fi

echo "Creating table: $TABLE_NAME"

aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions \
        AttributeName=member_number,AttributeType=S \
    --key-schema \
        AttributeName=member_number,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ Table created successfully"
    echo ""
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"
    echo "✅ Table is now active"
else
    echo "❌ Failed to create table"
    exit 1
fi

echo ""
echo "📊 Creating GSI on user_data table for member number lookup"
echo "=========================================="
echo ""

# Note: This requires updating the user_data table schema
# For now, we'll use a scan-based lookup as fallback
echo "ℹ️  Note: The user_data table will need a GSI for efficient member number lookups"
echo "   For now, the Lambda function uses a scan-based fallback"
echo ""
echo "✅ Member number infrastructure ready!"

