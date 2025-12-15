#!/bin/bash

# Script to create DynamoDB table for app token mappings
# Table: soteria-app-token-mappings

echo "🔧 Creating DynamoDB table: soteria-app-token-mappings"

aws dynamodb create-table \
  --table-name soteria-app-token-mappings \
  --attribute-definitions \
    AttributeName=token_hash,AttributeType=S \
  --key-schema \
    AttributeName=token_hash,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1 \
  --tags \
    Key=Project,Value=Soteria \
    Key=Environment,Value=Production

echo "⏳ Waiting for table to be active..."

aws dynamodb wait table-exists \
  --table-name soteria-app-token-mappings \
  --region us-east-1

echo "✅ Table created successfully!"
echo ""
echo "📋 Table Details:"
aws dynamodb describe-table \
  --table-name soteria-app-token-mappings \
  --region us-east-1 \
  --query 'Table.[TableName,TableStatus,TableArn]' \
  --output table

echo ""
echo "📝 Next steps:"
echo "1. Deploy Lambda function: ./deploy-app-name-lambda.sh"
echo "2. Create API Gateway endpoint: See BACKEND_TOKEN_MAPPING_SETUP.md"
echo "3. Populate database with app mappings"

