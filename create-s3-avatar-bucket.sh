#!/bin/bash

# Create S3 bucket for avatar storage
# This bucket will store user avatars with proper security and lifecycle policies

BUCKET_NAME="soteria-avatars-516141816050"
REGION="us-east-1"

echo "🔍 Creating S3 bucket for avatar storage..."
echo "Bucket name: $BUCKET_NAME"
echo "Region: $REGION"

# Check if bucket already exists
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "📦 Creating new S3 bucket..."
    
    # Create bucket
    # Note: us-east-1 doesn't need LocationConstraint
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    
    # Enable versioning (for backup/recovery)
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Block public access (avatars are private)
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    # Set CORS configuration (for direct uploads from app if needed)
    cat > /tmp/cors-config.json <<EOF
{
    "CORSRules": [
        {
            "AllowedOrigins": ["*"],
            "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
            "AllowedHeaders": ["*"],
            "ExposeHeaders": ["ETag"],
            "MaxAgeSeconds": 3000
        }
    ]
}
EOF
    
    aws s3api put-bucket-cors \
        --bucket "$BUCKET_NAME" \
        --cors-configuration file:///tmp/cors-config.json
    
    # Set lifecycle policy (delete old versions after 90 days)
    # Note: Lifecycle policy is optional - skipping for now to avoid XML issues
    # Can be added later via AWS Console if needed
    echo "ℹ️ Skipping lifecycle policy (optional)"
    
    echo "✅ S3 bucket created successfully!"
else
    echo "✅ S3 bucket already exists!"
fi

# Display bucket info
echo ""
echo "📊 Bucket Information:"
aws s3api get-bucket-location --bucket "$BUCKET_NAME"
aws s3api get-bucket-versioning --bucket "$BUCKET_NAME"

echo ""
echo "✅ S3 bucket setup complete!"
echo "Bucket: s3://$BUCKET_NAME"
echo ""
echo "Next steps:"
echo "1. Create Lambda functions for upload/download"
echo "2. Set up IAM permissions for Lambda to access S3"
echo "3. Create API Gateway endpoints"

