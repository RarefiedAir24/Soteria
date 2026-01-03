#!/bin/bash

# Deploy Partner Scanner Web Portal to AWS S3
# This script creates an S3 bucket, uploads the scanner, and enables static website hosting

BUCKET_NAME="soteria-partner-scanner"
REGION="us-east-1"
SCANNER_DIR="partner-scanner"

echo "🚀 Deploying Partner Scanner to S3"
echo "===================================="
echo ""

# Check if bucket exists
if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "📦 Creating S3 bucket: ${BUCKET_NAME}"
    aws s3 mb "s3://${BUCKET_NAME}" --region "${REGION}"
    
    if [ $? -eq 0 ]; then
        echo "✅ Bucket created successfully"
    else
        echo "❌ Failed to create bucket"
        exit 1
    fi
else
    echo "✅ Bucket already exists: ${BUCKET_NAME}"
fi
echo ""

# Upload files
echo "📤 Uploading scanner files..."
if [ -d "$SCANNER_DIR" ]; then
    aws s3 sync "${SCANNER_DIR}/" "s3://${BUCKET_NAME}/" \
        --region "${REGION}" \
        --exclude "*.DS_Store" \
        --exclude ".git/*"
    
    if [ $? -eq 0 ]; then
        echo "✅ Files uploaded successfully"
    else
        echo "❌ Failed to upload files"
        exit 1
    fi
else
    echo "❌ Scanner directory not found: ${SCANNER_DIR}"
    exit 1
fi
echo ""

# Enable static website hosting
echo "🌐 Enabling static website hosting..."
aws s3 website "s3://${BUCKET_NAME}" \
    --index-document index.html \
    --error-document index.html \
    --region "${REGION}"

if [ $? -eq 0 ]; then
    echo "✅ Static website hosting enabled"
else
    echo "❌ Failed to enable static website hosting"
    exit 1
fi
echo ""

# Set bucket policy for public read access
echo "🔓 Setting bucket policy for public access..."
cat > /tmp/bucket-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket "${BUCKET_NAME}" \
    --policy file:///tmp/bucket-policy.json \
    --region "${REGION}"

if [ $? -eq 0 ]; then
    echo "✅ Bucket policy set for public read access"
else
    echo "⚠️  Failed to set bucket policy (you may need to set it manually)"
fi
echo ""

# Get website URL
WEBSITE_URL="http://${BUCKET_NAME}.s3-website-${REGION}.amazonaws.com"
echo "===================================="
echo "✅ Deployment Complete!"
echo ""
echo "📱 Partner Scanner URL:"
echo "   ${WEBSITE_URL}"
echo ""
echo "🌍 To use a custom domain:"
echo "   1. Set up CloudFront distribution pointing to this bucket"
echo "   2. Configure your domain's DNS to point to CloudFront"
echo ""
echo "📝 Note: The scanner requires camera permissions in the browser"
echo "   and CORS must be enabled on the API Gateway endpoints."

