#!/bin/bash

# Create DynamoDB table for screenshot hash storage (Phase 2)

echo "📦 Creating DynamoDB table: ScreenshotHashes"

aws dynamodb create-table \
  --table-name ScreenshotHashes \
  --attribute-definitions \
    AttributeName=userId,AttributeType=S \
    AttributeName=timestamp,AttributeType=N \
  --key-schema \
    AttributeName=userId,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --time-to-live-specification \
    Enabled=true,AttributeName=expiresAt \
  --region us-east-1

echo "✅ Table creation initiated. Waiting for table to become active..."

aws dynamodb wait table-exists --table-name ScreenshotHashes --region us-east-1

echo "✅ ScreenshotHashes table is now active!"
echo ""
echo "Table Details:"
aws dynamodb describe-table --table-name ScreenshotHashes --region us-east-1 --query 'Table.{Name:TableName,Status:TableStatus,ItemCount:ItemCount}'
