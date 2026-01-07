#!/bin/bash

# Deploy Partner Dashboard to AWS S3
# This script creates an S3 bucket, uploads the dashboard, and enables static website hosting

BUCKET_NAME="soteria-partner-dashboard"
REGION="us-east-1"
DASHBOARD_DIR="partner-dashboard"

echo "🚀 Deploying Partner Dashboard to S3"
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
echo "📤 Uploading dashboard files..."
if [ -d "$DASHBOARD_DIR" ]; then
    aws s3 sync "${DASHBOARD_DIR}/" "s3://${BUCKET_NAME}/" \
        --region "${REGION}" \
        --exclude "*.DS_Store" \
        --exclude ".git/*" \
        --content-type "text/html" \
        --cache-control "no-cache"
    
    if [ $? -eq 0 ]; then
        echo "✅ Files uploaded successfully"
    else
        echo "❌ Failed to upload files"
        exit 1
    fi
else
    echo "❌ Dashboard directory not found: ${DASHBOARD_DIR}"
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
cat > /tmp/dashboard-policy.json <<EOF
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
    --policy file:///tmp/dashboard-policy.json \
    --region "${REGION}"

if [ $? -eq 0 ]; then
    echo "✅ Bucket policy set successfully"
    rm /tmp/dashboard-policy.json
else
    echo "❌ Failed to set bucket policy"
    exit 1
fi
echo ""

# Get website URL
WEBSITE_URL="http://${BUCKET_NAME}.s3-website-${REGION}.amazonaws.com"

echo "✅ Partner Dashboard deployed successfully!"
echo ""
echo "📋 Dashboard Details:"
echo "   Bucket: ${BUCKET_NAME}"
echo "   Region: ${REGION}"
echo "   Website URL: ${WEBSITE_URL}"
echo ""
echo "🌐 Access your dashboard at:"
echo "   ${WEBSITE_URL}"
echo ""
echo "💡 Next Steps:"
echo "   1. Share this URL with partners: ${WEBSITE_URL}"
echo "   2. Partners can login with Partner ID and API Key"
echo "   3. Dashboard shows real-time analytics from API"
echo ""

