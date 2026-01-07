#!/bin/bash

# Apple Wallet Certificate Upload Script
# This script uploads the Pass Type ID certificate and WWDR certificate to S3

set -e  # Exit on error

echo "🔐 Apple Wallet Certificate Upload Script"
echo "=========================================="
echo ""

# Configuration
BUCKET="soteria-wallet-passes"
REGION="us-east-1"
CERT_PATH="cert.p12"
WWDR_PATH="wwdr.pem"

# Check if certificates exist
if [ ! -f "$CERT_PATH" ]; then
    echo "❌ Error: $CERT_PATH not found in current directory"
    echo "   Please export the certificate from Keychain Access first"
    exit 1
fi

if [ ! -f "$WWDR_PATH" ]; then
    echo "❌ Error: $WWDR_PATH not found in current directory"
    echo "   Please download the WWDR certificate from Apple Developer Portal first"
    exit 1
fi

echo "✅ Found certificate files:"
echo "   - $CERT_PATH"
echo "   - $WWDR_PATH"
echo ""

# Upload Pass Type ID certificate
echo "📤 Uploading Pass Type ID certificate to S3..."
aws s3 cp "$CERT_PATH" "s3://$BUCKET/certificates/cert.p12" --region "$REGION"
if [ $? -eq 0 ]; then
    echo "✅ Pass Type ID certificate uploaded successfully"
else
    echo "❌ Failed to upload Pass Type ID certificate"
    exit 1
fi

echo ""

# Upload WWDR certificate
echo "📤 Uploading WWDR certificate to S3..."
aws s3 cp "$WWDR_PATH" "s3://$BUCKET/certificates/wwdr.pem" --region "$REGION"
if [ $? -eq 0 ]; then
    echo "✅ WWDR certificate uploaded successfully"
else
    echo "❌ Failed to upload WWDR certificate"
    exit 1
fi

echo ""

# Verify upload
echo "🔍 Verifying uploaded files..."
aws s3 ls "s3://$BUCKET/certificates/" --region "$REGION"

echo ""
echo "✅ Certificate upload complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Store certificate password in Secrets Manager:"
echo "      aws secretsmanager put-secret-value \\"
echo "        --secret-id soteria/apple-wallet/cert-password \\"
echo "        --secret-string \"YOUR_PASSWORD\" \\"
echo "        --region us-east-1"
echo ""
echo "   2. Test pass generation via API endpoint"

