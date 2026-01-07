# API Domain Setup Guide

**Setting up api.soteria.zone for Soteria API**

---

## Overview

This guide walks through setting up the `api.soteria.zone` custom domain for the Soteria API Gateway, making it easy for partners and developers to access the API.

---

## Prerequisites

1. ✅ Domain `soteria.zone` registered in Route 53
2. ✅ API Gateway REST API created (`ue1psw3mt3`)
3. ✅ AWS CLI configured with appropriate permissions
4. ✅ Permissions for:
   - Route 53 (create/update records)
   - API Gateway (create custom domain)
   - ACM (request/manage certificates)

---

## Step 1: Run Setup Script

```bash
./setup-api-domain.sh
```

This script will:
1. ✅ Check Route 53 hosted zone
2. ✅ Request/verify SSL certificate
3. ✅ Create API Gateway custom domain
4. ✅ Create API mapping
5. ✅ Create Route 53 A record (alias)

---

## Step 2: Manual Steps (if needed)

### A. Request SSL Certificate

If the script doesn't automatically request a certificate:

```bash
aws acm request-certificate \
  --domain-name api.soteria.zone \
  --validation-method DNS \
  --region us-east-1
```

### B. Validate Certificate

1. Get certificate validation records:
```bash
aws acm describe-certificate \
  --certificate-arn <CERT_ARN> \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions'
```

2. Add CNAME records to Route 53 for validation

3. Wait for certificate to be issued (usually 5-10 minutes)

### C. Create Custom Domain

```bash
aws apigatewayv2 create-domain-name \
  --domain-name api.soteria.zone \
  --domain-name-configurations "CertificateArn=<CERT_ARN>" \
  --region us-east-1
```

### D. Create Base Path Mapping

```bash
aws apigateway create-base-path-mapping \
  --domain-name api.soteria.zone \
  --rest-api-id ue1psw3mt3 \
  --stage prod \
  --region us-east-1
```

### E. Create Route 53 Record

Get the domain target:
```bash
aws apigatewayv2 get-domain-name \
  --domain-name api.soteria.zone \
  --region us-east-1 \
  --query 'DomainNameConfigurations[0].TargetDomainName'
```

Create A record (alias) pointing to the target.

---

## Step 3: Deploy Developer Portal

### Option A: S3 + CloudFront

```bash
# Create S3 bucket
aws s3 mb s3://api.soteria.zone --region us-east-1

# Upload portal
aws s3 cp api-portal/index.html s3://api.soteria.zone/index.html

# Enable static website hosting
aws s3 website s3://api.soteria.zone \
  --index-document index.html

# Create CloudFront distribution
aws cloudfront create-distribution \
  --origin-domain-name api.soteria.zone.s3-website-us-east-1.amazonaws.com \
  --default-root-object index.html
```

### Option B: Route 53 + S3

Point `api.soteria.zone` to S3 bucket via Route 53.

---

## Step 4: Update API Documentation

Update all references from:
- `https://g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod`

To:
- `https://api.soteria.zone`

---

## Verification

### Test API Endpoint

```bash
curl https://api.soteria.zone/soteria/partner/list
```

### Test Developer Portal

Open in browser:
```
https://api.soteria.zone
```

---

## API Endpoints

After setup, all endpoints will be available at:

| Endpoint | URL |
|----------|-----|
| Validate Member | `https://api.soteria.zone/soteria/partner/validate-member` |
| Record Redemption | `https://api.soteria.zone/soteria/partner/redeem` |
| Get Analytics | `https://api.soteria.zone/soteria/partner/analytics` |
| List Partners | `https://api.soteria.zone/soteria/partner/list` |
| Register Partner | `https://api.soteria.zone/soteria/partner/register` |

---

## Troubleshooting

### Certificate Not Issued

- Check DNS validation records are in Route 53
- Wait 5-10 minutes for validation
- Verify domain ownership

### DNS Not Resolving

- Check Route 53 record is created
- Wait for DNS propagation (5-10 minutes)
- Verify alias target is correct

### API Gateway 403 Error

- Check base path mapping is created
- Verify stage name matches (`prod`)
- Check API Gateway permissions

### CORS Issues

- Ensure CORS is configured on API Gateway
- Check `Access-Control-Allow-Origin` headers
- Verify preflight (OPTIONS) requests work

---

## Cost Estimates

- **Route 53**: $0.50/month per hosted zone + $0.40 per million queries
- **ACM Certificate**: Free
- **API Gateway Custom Domain**: Free
- **S3 + CloudFront**: ~$0.50/month for portal hosting

**Total: ~$1-2/month**

---

## Next Steps

1. ✅ Run setup script
2. ✅ Verify certificate is issued
3. ✅ Test API endpoints
4. ✅ Deploy developer portal
5. ✅ Update documentation
6. ✅ Share with partners

---

**Last Updated:** January 2026

