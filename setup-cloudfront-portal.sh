#!/bin/bash

# Setup CloudFront to serve developer portal at api.soteria.zone root
# Routes:
#   - /* → S3 (Developer Portal)
#   - /soteria/* → API Gateway (API endpoints)

set -e

BUCKET_NAME="api.soteria.zone"
DOMAIN="api.soteria.zone"
API_GATEWAY_ID="ue1psw3mt3"
API_GATEWAY_DOMAIN="d-vw5bhbqss6.execute-api.us-east-1.amazonaws.com"
REGION="us-east-1"

echo "🌐 Setting up CloudFront for api.soteria.zone..."
echo "   Portal: https://${DOMAIN}/"
echo "   API: https://${DOMAIN}/soteria/partner/*"
echo ""

# Ensure bucket exists and has portal
echo "📦 Checking S3 bucket..."
if ! aws s3 ls "s3://${BUCKET_NAME}" &>/dev/null; then
    echo "❌ Bucket ${BUCKET_NAME} not found. Please deploy portal first."
    exit 1
fi

# Get bucket region
BUCKET_REGION=$(aws s3api get-bucket-location --bucket "$BUCKET_NAME" --query 'LocationConstraint' --output text)
if [ "$BUCKET_REGION" == "None" ]; then
    BUCKET_REGION="us-east-1"
fi

# Create CloudFront Origin Access Identity (OAI) for S3
echo "🔐 Creating Origin Access Identity..."
OAI_ID=$(aws cloudfront create-cloud-front-origin-access-identity \
    --cloud-front-origin-access-identity-config "CallerReference=api-portal-$(date +%s),Comment=API Portal OAI" \
    --query 'CloudFrontOriginAccessIdentity.Id' \
    --output text 2>/dev/null || \
    aws cloudfront list-cloud-front-origin-access-identities \
    --query 'CloudFrontOriginAccessIdentityList.Items[0].Id' \
    --output text)

echo "✅ OAI ID: ${OAI_ID}"

# Update S3 bucket policy to allow CloudFront OAI
echo "📝 Updating S3 bucket policy..."
BUCKET_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${OAI_ID}"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
    }
  ]
}
EOF
)

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "$BUCKET_POLICY" 2>/dev/null || echo "⚠️  Bucket policy may already exist"
echo "✅ S3 bucket policy updated"

# Get ACM certificate ARN for the domain
echo "🔍 Getting SSL certificate..."
CERT_ARN=$(aws acm list-certificates \
    --region us-east-1 \
    --query "CertificateSummaryList[?DomainName=='${DOMAIN}'].CertificateArn" \
    --output text)

if [ -z "$CERT_ARN" ] || [ "$CERT_ARN" == "None" ]; then
    echo "❌ SSL certificate not found for ${DOMAIN}"
    exit 1
fi

echo "✅ Certificate: ${CERT_ARN}"

# Check if distribution already exists
echo "🔍 Checking for existing CloudFront distribution..."
EXISTING_DIST=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Aliases.Items[?@=='${DOMAIN}']].Id" \
    --output text)

if [ -n "$EXISTING_DIST" ] && [ "$EXISTING_DIST" != "None" ]; then
    echo "✅ CloudFront distribution already exists: ${EXISTING_DIST}"
    DIST_ID="$EXISTING_DIST"
    echo "⚠️  If you want to recreate, delete the existing distribution first"
else
    echo "📝 Creating CloudFront distribution..."
    
    # Create distribution config with multiple origins and behaviors
    DIST_CONFIG=$(cat <<EOF
{
  "CallerReference": "api-portal-$(date +%s)",
  "Comment": "Soteria API Developer Portal and API Gateway",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 2,
    "Items": [
      {
        "Id": "S3-${BUCKET_NAME}",
        "DomainName": "${BUCKET_NAME}.s3.${BUCKET_REGION}.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/${OAI_ID}"
        }
      },
      {
        "Id": "API-Gateway",
        "DomainName": "${API_GATEWAY_DOMAIN}",
        "CustomOriginConfig": {
          "HTTPPort": 443,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "https-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          }
        }
      }
    ]
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
      "Cookies": {
        "Forward": "none"
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 3600,
    "MaxTTL": 86400,
    "Compress": true
  },
  "CacheBehaviors": {
    "Quantity": 1,
    "Items": [
      {
        "PathPattern": "/soteria/*",
        "TargetOriginId": "API-Gateway",
        "ViewerProtocolPolicy": "https-only",
        "AllowedMethods": {
          "Quantity": 7,
          "Items": ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"],
          "CachedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"]
          }
        },
        "ForwardedValues": {
          "QueryString": true,
          "Headers": {
            "Quantity": 3,
            "Items": ["Host", "Authorization", "Content-Type"]
          },
          "Cookies": {
            "Forward": "none"
          }
        },
        "MinTTL": 0,
        "DefaultTTL": 0,
        "MaxTTL": 0,
        "Compress": true
      }
    ]
  },
  "Aliases": {
    "Quantity": 1,
    "Items": ["${DOMAIN}"]
  },
  "ViewerCertificate": {
    "ACMCertificateArn": "${CERT_ARN}",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF
)

    DIST_ID=$(aws cloudfront create-distribution \
        --distribution-config "$DIST_CONFIG" \
        --query 'Distribution.Id' \
        --output text)
    
    echo "✅ CloudFront distribution created: ${DIST_ID}"
fi

# Get CloudFront domain name
CF_DOMAIN=$(aws cloudfront get-distribution \
    --id "$DIST_ID" \
    --query 'Distribution.DomainName' \
    --output text)

echo ""
echo "📝 Updating Route 53 to point to CloudFront..."
HOSTED_ZONE_ID="Z04270822OU4CSQ32HC2P"

CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "${DOMAIN}.",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z2FDTNDATAQYW2",
        "DNSName": "${CF_DOMAIN}",
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

echo "✅ Route 53 updated. Change ID: ${CHANGE_ID}"

# Check distribution status
STATUS=$(aws cloudfront get-distribution \
    --id "$DIST_ID" \
    --query 'Distribution.Status' \
    --output text)

echo ""
echo "✅ CloudFront setup complete!"
echo ""
echo "📊 Distribution Status: ${STATUS}"
echo "   Distribution ID: ${DIST_ID}"
echo "   CloudFront Domain: ${CF_DOMAIN}"
echo ""
if [ "$STATUS" != "Deployed" ]; then
    echo "⏳ CloudFront is deploying..."
    echo "   This typically takes 15-20 minutes"
    echo "   Status will change from 'InProgress' to 'Deployed'"
    echo ""
    echo "📊 Check status with:"
    echo "   aws cloudfront get-distribution --id ${DIST_ID} --query 'Distribution.Status'"
    echo ""
fi

echo "🌐 Once deployed (15-20 minutes):"
echo "   - Portal: https://${DOMAIN}/"
echo "   - API: https://${DOMAIN}/soteria/partner/list"
echo ""
echo "💡 Note: DNS propagation may take an additional 5-10 minutes after CloudFront deploys"
