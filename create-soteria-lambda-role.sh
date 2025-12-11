#!/bin/bash

# Script to create IAM role and policies for Soteria Lambda functions
# Run this script after reviewing it to ensure it's correct

set -e  # Exit on error

echo "🚀 Creating IAM role and policies for Soteria Lambda functions..."

# Configuration
ROLE_NAME="soteria-lambda-role"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  Make sure you have AWS credentials configured${NC}"
echo -e "${YELLOW}⚠️  This will create resources in AWS - review commands before running${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Step 1: Create trust policy for Lambda
echo "📝 Creating trust policy..."
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)

# Step 2: Create IAM role
echo "👤 Creating IAM role: $ROLE_NAME..."
aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" \
    --description "IAM role for Soteria Lambda functions" \
    --tags Key=Project,Value=Soteria Key=Environment,Value=prod \
    --query 'Role.RoleName' \
    --output text

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to create IAM role (may already exist)${NC}"
    echo "Continuing with policy attachment..."
fi

# Step 3: Attach basic execution role (for CloudWatch Logs)
echo "📋 Attaching AWSLambdaBasicExecutionRole..."
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Step 4: Create DynamoDB policy
echo "📋 Creating DynamoDB policy..."
DYNAMODB_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/soteria-*"
      ]
    }
  ]
}
EOF
)

POLICY_NAME="soteria-dynamodb-policy"
echo "📋 Creating policy: $POLICY_NAME..."
aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document "$DYNAMODB_POLICY" \
    --description "Policy for Soteria Lambda functions to access DynamoDB" \
    --query 'Policy.Arn' \
    --output text

POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

# Attach policy to role
echo "📋 Attaching DynamoDB policy to role..."
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"

# Step 5: Output summary
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ IAM Role and Policies Created!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Role Name: $ROLE_NAME"
echo "Role ARN: arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo ""
echo "Policies attached:"
echo "  - AWSLambdaBasicExecutionRole (CloudWatch Logs)"
echo "  - $POLICY_NAME (DynamoDB access)"
echo ""
echo "Use this role ARN when creating Lambda functions:"
echo "  arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo ""

