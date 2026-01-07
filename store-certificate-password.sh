#!/bin/bash

# Apple Wallet Certificate Password Storage Script
# This script stores the certificate password in AWS Secrets Manager

set -e  # Exit on error

echo "🔐 Apple Wallet Certificate Password Storage"
echo "============================================="
echo ""

# Configuration
SECRET_NAME="soteria/apple-wallet/cert-password"
REGION="us-east-1"

# Prompt for password (secure input)
echo "Enter the certificate password (input will be hidden):"
read -s CERT_PASSWORD

if [ -z "$CERT_PASSWORD" ]; then
    echo "❌ Error: Password cannot be empty"
    exit 1
fi

echo ""
echo "📤 Storing password in AWS Secrets Manager..."

# Store password in Secrets Manager
aws secretsmanager put-secret-value \
    --secret-id "$SECRET_NAME" \
    --secret-string "$CERT_PASSWORD" \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ Password stored successfully in Secrets Manager"
    echo ""
    echo "🔍 Verifying secret..."
    aws secretsmanager get-secret-value \
        --secret-id "$SECRET_NAME" \
        --region "$REGION" \
        --query 'SecretString' \
        --output text > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Secret verified - password is accessible"
    else
        echo "⚠️  Warning: Could not verify secret access"
    fi
else
    echo "❌ Failed to store password in Secrets Manager"
    exit 1
fi

echo ""
echo "✅ Password storage complete!"
echo ""
echo "📝 Remember to:"
echo "   1. Document password in APPLE_WALLET_CERTIFICATE_PASSWORD.md"
echo "   2. Test pass generation via API endpoint"

