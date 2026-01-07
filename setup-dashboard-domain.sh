#!/bin/bash

# Setup dashboard.soteria.zone custom domain
# Similar to api.soteria.zone setup, but for the partner dashboard

DOMAIN="dashboard.soteria.zone"
HOSTED_ZONE_ID="Z04270822OU4CSQ32HC2P"
REGION="us-east-1"
BUCKET_NAME="soteria-partner-dashboard"

echo "🚀 Setting up dashboard.soteria.zone"
echo "===================================="
echo ""

# Step 1: Request SSL Certificate
echo "📜 Step 1: Requesting SSL Certificate..."
CERT_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN" \
    --validation-method DNS \
    --region "$REGION" \
    --query 'CertificateArn' \
    --output text 2>/dev/null)

if [ -z "$CERT_ARN" ] || [ "$CERT_ARN" == "None" ]; then
    echo "⚠️  Certificate may already exist, checking..."
    CERT_ARN=$(aws acm list-certificates \
        --region "$REGION" \
        --query "CertificateSummaryList[?DomainName=='$DOMAIN'].CertificateArn" \
        --output text | head -1)
fi

if [ -z "$CERT_ARN" ] || [ "$CERT_ARN" == "None" ]; then
    echo "❌ Failed to get certificate ARN"
    exit 1
fi

echo "✅ Certificate ARN: $CERT_ARN"
echo ""

# Step 2: Get certificate validation records
echo "📋 Step 2: Getting certificate validation records..."
sleep 3
VALIDATION_RECORDS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region "$REGION" \
    --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
    --output json)

if [ "$VALIDATION_RECORDS" == "null" ] || [ -z "$VALIDATION_RECORDS" ]; then
    echo "⏳ Waiting for validation records to be available..."
    sleep 5
    VALIDATION_RECORDS=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region "$REGION" \
        --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
        --output json)
fi

VALIDATION_NAME=$(echo "$VALIDATION_RECORDS" | jq -r '.Name')
VALIDATION_VALUE=$(echo "$VALIDATION_RECORDS" | jq -r '.Value')

echo "📝 Validation Record:"
echo "   Name: $VALIDATION_NAME"
echo "   Value: $VALIDATION_VALUE"
echo ""

# Step 3: Add validation record to Route 53
echo "🌐 Step 3: Adding validation record to Route 53..."
CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$VALIDATION_NAME",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$VALIDATION_VALUE"}]
    }
  }]
}
EOF
)

CHANGE_ID=$(aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch "$CHANGE_BATCH" \
    --query 'ChangeInfo.Id' \
    --output text)

echo "✅ Validation record added. Change ID: $CHANGE_ID"
echo "⏳ Waiting for certificate validation (this may take 5-10 minutes)..."
echo ""

# Step 4: Wait for certificate validation
echo "⏳ Waiting for certificate to be validated..."
MAX_WAIT=600  # 10 minutes
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region "$REGION" \
        --query 'Certificate.Status' \
        --output text)
    
    if [ "$STATUS" == "ISSUED" ]; then
        echo "✅ Certificate validated!"
        break
    fi
    
    echo "   Status: $STATUS (waiting...)"
    sleep 30
    ELAPSED=$((ELAPSED + 30))
done

if [ "$STATUS" != "ISSUED" ]; then
    echo "⚠️  Certificate not yet validated. You may need to wait and run this script again."
    echo "   Or manually check: aws acm describe-certificate --certificate-arn $CERT_ARN --region $REGION"
fi
echo ""

# Step 5: Create CloudFront distribution
echo "☁️  Step 5: Creating CloudFront distribution..."

# Create Origin Access Identity for S3
OAI_COMMENT="Soteria Partner Dashboard OAI"
OAI_ID=$(aws cloudfront create-cloud-front-origin-access-identity \
    --cloud-front-origin-access-identity-config "CallerReference=$(date +%s),Comment=$OAI_COMMENT" \
    --query 'CloudFrontOriginAccessIdentity.Id' \
    --output text 2>/dev/null || echo "")

if [ -z "$OAI_ID" ]; then
    echo "⚠️  OAI may already exist, checking..."
    OAI_ID=$(aws cloudfront list-cloud-front-origin-access-identities \
        --query "CloudFrontOriginAccessIdentityList.Items[?Comment=='$OAI_COMMENT'].Id" \
        --output text | head -1)
fi

if [ -z "$OAI_ID" ]; then
    echo "❌ Failed to create/get OAI"
    exit 1
fi

echo "✅ OAI ID: $OAI_ID"
echo ""

# Update S3 bucket policy to allow CloudFront
echo "🔓 Step 6: Updating S3 bucket policy..."
OAI_ARN="arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity $OAI_ID"
BUCKET_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "$OAI_ARN"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
    }
  ]
}
EOF
)

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "$BUCKET_POLICY"
echo "✅ Bucket policy updated"
echo ""

# Create CloudFront distribution config
echo "☁️  Step 7: Creating CloudFront distribution..."
DIST_CONFIG=$(cat <<EOF
{
  "CallerReference": "dashboard-$(date +%s)",
  "Comment": "Soteria Partner Dashboard",
  "Enabled": true,
  "Origins": {
    "Quantity": 1,
    "Items": [{
      "Id": "S3-${BUCKET_NAME}",
      "DomainName": "${BUCKET_NAME}.s3.${REGION}.amazonaws.com",
      "S3OriginConfig": {
        "OriginAccessIdentity": "origin-access-identity/cloudfront/${OAI_ID}"
      }
    }]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${BUCKET_NAME}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {"Forward": "none"}
    },
    "MinTTL": 0,
    "DefaultTTL": 3600,
    "MaxTTL": 86400,
    "Compress": true
  },
  "ViewerCertificate": {
    "ACMCertificateArn": "$CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "Aliases": {
    "Quantity": 1,
    "Items": ["$DOMAIN"]
  }
}
EOF
)

echo "$DIST_CONFIG" > /tmp/dist-config.json

DIST_ID=$(aws cloudfront create-distribution \
    --distribution-config file:///tmp/dist-config.json \
    --query 'Distribution.Id' \
    --output text)

if [ -z "$DIST_ID" ]; then
    echo "❌ Failed to create CloudFront distribution"
    exit 1
fi

echo "✅ CloudFront distribution created: $DIST_ID"
echo "⏳ Distribution is deploying (takes 15-20 minutes)..."
echo ""

# Step 8: Get CloudFront domain name
sleep 5
CF_DOMAIN=$(aws cloudfront get-distribution \
    --id "$DIST_ID" \
    --query 'Distribution.DomainName' \
    --output text)

echo "✅ CloudFront Domain: $CF_DOMAIN"
echo ""

# Step 9: Create Route 53 A record
echo "🌐 Step 9: Creating Route 53 A record..."
CF_HOSTED_ZONE_ID="Z2FDTNDATAQYW2"  # CloudFront hosted zone ID

CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$DOMAIN.",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "$CF_HOSTED_ZONE_ID",
        "DNSName": "$CF_DOMAIN.",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
EOF
)

CHANGE_ID=$(aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch "$CHANGE_BATCH" \
    --query 'ChangeInfo.Id' \
    --output text)

echo "✅ Route 53 record created. Change ID: $CHANGE_ID"
echo ""

echo "✅ Setup Complete!"
echo ""
echo "📋 Summary:"
echo "   Domain: $DOMAIN"
echo "   CloudFront Distribution: $DIST_ID"
echo "   Certificate: $CERT_ARN"
echo "   Status: Deploying (15-20 minutes)"
echo ""
echo "⏳ Next Steps:"
echo "   1. Wait 15-20 minutes for CloudFront to deploy"
echo "   2. Wait 5-10 minutes for DNS propagation"
echo "   3. Access dashboard at: https://$DOMAIN"
echo ""
echo "🧪 Check status:"
echo "   aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.Status'"
echo ""

