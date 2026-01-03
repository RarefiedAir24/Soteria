#!/bin/bash

# Grant Lambda role permission to delete Cognito users

ROLE_NAME="soteria-lambda-role"
REGION="us-east-1"
USER_POOL_ID="us-east-1_099POP0Rf"

echo "🔐 Granting Cognito delete permission to Lambda role..."

# Create policy document for Cognito admin delete user
cat > /tmp/cognito-delete-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:AdminDeleteUser"
            ],
            "Resource": "arn:aws:cognito-idp:${REGION}:516141816050:userpool/${USER_POOL_ID}"
        }
    ]
}
EOF

# Create policy
POLICY_NAME="CognitoDeleteUserPolicy"
POLICY_ARN=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document file:///tmp/cognito-delete-policy.json \
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
echo "✅ Cognito delete permission granted!"
echo ""
echo "Lambda can now delete Cognito user accounts"

