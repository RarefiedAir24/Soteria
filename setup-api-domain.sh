#!/bin/bash

# Setup API Gateway Custom Domain for api.soteria.zone
# This script configures Route 53 and API Gateway custom domain

set -e

DOMAIN="soteria.zone"
SUBDOMAIN="api"
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
API_GATEWAY_ID="${API_GATEWAY_ID:-ue1psw3mt3}"
REGION="${AWS_REGION:-us-east-1}"
STAGE="prod"

echo "🌐 Setting up custom domain: ${FULL_DOMAIN}"

# Check if Route 53 hosted zone exists
echo "🔍 Checking Route 53 hosted zone for ${DOMAIN}..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name "${DOMAIN}" \
    --query "HostedZones[0].Id" \
    --output text 2>/dev/null | sed 's|/hostedzone/||')

if [ -z "$HOSTED_ZONE_ID" ] || [ "$HOSTED_ZONE_ID" == "None" ]; then
    echo "❌ Hosted zone not found for ${DOMAIN}"
    echo "   Please create a hosted zone in Route 53 first"
    exit 1
fi

echo "✅ Found hosted zone: ${HOSTED_ZONE_ID}"

# Create ACM certificate (if not exists)
echo "🔐 Checking SSL certificate..."
CERT_ARN=$(aws acm list-certificates \
    --region us-east-1 \
    --query "CertificateSummaryList[?DomainName=='${FULL_DOMAIN}'].CertificateArn" \
    --output text)

if [ -z "$CERT_ARN" ] || [ "$CERT_ARN" == "None" ]; then
    echo "📝 Creating SSL certificate..."
    CERT_ARN=$(aws acm request-certificate \
        --domain-name "${FULL_DOMAIN}" \
        --validation-method DNS \
        --region us-east-1 \
        --query 'CertificateArn' \
        --output text)
    
    echo "✅ Certificate requested: ${CERT_ARN}"
    echo "⚠️  You need to validate the certificate by adding DNS records to Route 53"
    echo "   Run: aws acm describe-certificate --certificate-arn ${CERT_ARN} --region us-east-1"
    echo "   Then add the CNAME records to Route 53"
    read -p "Press Enter after certificate is validated..."
else
    echo "✅ Certificate found: ${CERT_ARN}"
fi

# Verify certificate is issued
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn "${CERT_ARN}" \
    --region us-east-1 \
    --query 'Certificate.Status' \
    --output text)

if [ "$CERT_STATUS" != "ISSUED" ]; then
    echo "❌ Certificate is not issued yet. Status: ${CERT_STATUS}"
    echo "   Please validate the certificate first"
    exit 1
fi

# Create API Gateway custom domain
echo "🌐 Creating API Gateway custom domain..."
DOMAIN_NAME=$(aws apigatewayv2 get-domain-names \
    --region "${REGION}" \
    --query "Items[?DomainName=='${FULL_DOMAIN}'].DomainName" \
    --output text 2>/dev/null || echo "")

if [ -z "$DOMAIN_NAME" ]; then
    echo "📝 Creating new custom domain..."
    aws apigatewayv2 create-domain-name \
        --domain-name "${FULL_DOMAIN}" \
        --domain-name-configurations "CertificateArn=${CERT_ARN}" \
        --region "${REGION}" > /dev/null
    
    echo "⏳ Waiting for domain to be available..."
    aws apigatewayv2 wait domain-available \
        --domain-name "${FULL_DOMAIN}" \
        --region "${REGION}" || true
else
    echo "✅ Custom domain already exists"
fi

# Get domain target
echo "🔍 Getting domain target..."
DOMAIN_TARGET=$(aws apigatewayv2 get-domain-name \
    --domain-name "${FULL_DOMAIN}" \
    --region "${REGION}" \
    --query 'DomainNameConfigurations[0].TargetDomainName' \
    --output text)

echo "✅ Domain target: ${DOMAIN_TARGET}"

# Create API mapping
echo "🔗 Creating API mapping..."
MAPPING_ID=$(aws apigatewayv2 get-api-mappings \
    --domain-name "${FULL_DOMAIN}" \
    --region "${REGION}" \
    --query "Items[?ApiId=='${API_GATEWAY_ID}'].ApiMappingId" \
    --output text 2>/dev/null || echo "")

if [ -z "$MAPPING_ID" ]; then
    # Get API ID (REST API)
    API_ID=$(aws apigateway get-rest-api \
        --rest-api-id "${API_GATEWAY_ID}" \
        --region "${REGION}" \
        --query 'id' \
        --output text)
    
    # For REST APIs, we need to use API Gateway v1
    # Create base path mapping
    echo "📝 Creating base path mapping..."
    aws apigateway create-base-path-mapping \
        --domain-name "${FULL_DOMAIN}" \
        --rest-api-id "${API_GATEWAY_ID}" \
        --stage "${STAGE}" \
        --region "${REGION}" 2>/dev/null || echo "⚠️  Mapping may already exist"
else
    echo "✅ API mapping already exists"
fi

# Create/Update Route 53 record
echo "📝 Creating Route 53 A record..."
RECORD_EXISTS=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "${HOSTED_ZONE_ID}" \
    --query "ResourceRecordSets[?Name=='${FULL_DOMAIN}.']" \
    --output text)

if [ -z "$RECORD_EXISTS" ]; then
    # For API Gateway custom domain, use alias record
    CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "${FULL_DOMAIN}.",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z1D633PJN98FT9",
        "DNSName": "${DOMAIN_TARGET}",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
EOF
)
    
    CHANGE_ID=$(aws route53 change-resource-record-sets \
        --hosted-zone-id "${HOSTED_ZONE_ID}" \
        --change-batch "${CHANGE_BATCH}" \
        --query 'ChangeInfo.Id' \
        --output text)
    
    echo "✅ Route 53 record created. Change ID: ${CHANGE_ID}"
    echo "⏳ Waiting for DNS propagation (this may take a few minutes)..."
    aws route53 wait resource-record-sets-changed --id "${CHANGE_ID}"
else
    echo "✅ Route 53 record already exists"
fi

echo ""
echo "✅ Custom domain setup complete!"
echo ""
echo "📋 Summary:"
echo "   Domain: ${FULL_DOMAIN}"
echo "   Certificate: ${CERT_ARN}"
echo "   API Gateway: ${API_GATEWAY_ID}"
echo "   Stage: ${STAGE}"
echo ""
echo "🌐 Your API is now available at:"
echo "   https://${FULL_DOMAIN}/soteria/partner/*"
echo ""
echo "⏳ DNS propagation may take 5-10 minutes"
echo "   Test with: curl https://${FULL_DOMAIN}/soteria/partner/list"

