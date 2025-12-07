#!/bin/bash
# Create IAM role for Rever Lambda functions

ROLE_NAME="rever-plaid-lambda-role"
POLICY_NAME="rever-plaid-lambda-policy"

echo "🔐 Creating IAM role for Lambda functions..."

# Create trust policy for Lambda
cat > /tmp/trust-policy.json << 'TRUST'
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
TRUST

# Create the role
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file:///tmp/trust-policy.json \
  --description "IAM role for Rever Plaid Lambda functions" \
  --query 'Role.Arn' \
  --output text

# Attach basic Lambda execution policy
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Create policy for DynamoDB access
cat > /tmp/dynamodb-policy.json << 'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/rever-plaid-access-tokens"
    }
  ]
}
POLICY

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document file:///tmp/dynamodb-policy.json

# Create policy for Secrets Manager access
cat > /tmp/secrets-policy.json << 'SECRETS'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:rever/plaid/*"
    }
  ]
}
SECRETS

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "rever-plaid-secrets-policy" \
  --policy-document file:///tmp/secrets-policy.json

echo "✅ IAM role created: $ROLE_NAME"
aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text
