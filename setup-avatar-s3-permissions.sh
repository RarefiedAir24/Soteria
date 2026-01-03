#!/bin/bash

# Set up IAM permissions for Lambda functions to access S3 bucket

ROLE_NAME="soteria-lambda-role"
BUCKET_NAME="soteria-avatars-516141816050"
REGION="us-east-1"

echo "🔐 Setting up IAM permissions for S3 avatar storage..."

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null)

if [ -z "$ROLE_ARN" ]; then
    echo "❌ Error: IAM role '$ROLE_NAME' not found"
    echo "Please create the role first or update the ROLE_NAME variable"
    exit 1
fi

echo "✅ Found IAM role: $ROLE_ARN"

# Create policy document for S3 access
cat > /tmp/s3-avatar-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/avatars/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}",
            "Condition": {
                "StringLike": {
                    "s3:prefix": "avatars/*"
                }
            }
        }
    ]
}
EOF

# Create policy
POLICY_NAME="S3AvatarAccessPolicy"
POLICY_ARN=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document file:///tmp/s3-avatar-policy.json \
    --query 'Policy.Arn' \
    --output text 2>/dev/null)

if [ -z "$POLICY_ARN" ]; then
    # Policy might already exist, try to get it
    POLICY_ARN=$(aws iam get-policy --policy-arn "arn:aws:iam::516141816050:policy/$POLICY_NAME" --query 'Policy.Arn' --output text 2>/dev/null)
    if [ -z "$POLICY_ARN" ]; then
        echo "❌ Failed to create or find policy"
        exit 1
    else
        echo "✅ Policy already exists: $POLICY_ARN"
    fi
else
    echo "✅ Created policy: $POLICY_ARN"
fi

# Attach policy to role
echo "🔗 Attaching policy to role..."
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN" 2>/dev/null || echo "⚠️ Policy may already be attached"

echo ""
echo "✅ IAM permissions set up successfully!"
echo ""
echo "Lambda functions can now:"
echo "  - Upload avatars to s3://${BUCKET_NAME}/avatars/"
echo "  - Download avatars from s3://${BUCKET_NAME}/avatars/"
echo "  - List avatars in the bucket"

