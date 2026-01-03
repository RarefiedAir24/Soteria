# Partner Discount System - Deployment Guide

This guide walks you through deploying the complete Partner Discount system, including backend APIs, partner scanner, and Apple Wallet integration.

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Node.js 20.x installed
3. AWS IAM role `soteria-lambda-role` exists
4. API Gateway ID (default: `ue1psw3mt3`)
5. DynamoDB tables created (or run the creation script)

## Step 1: Create DynamoDB Tables

```bash
./create-partner-tables.sh
```

This creates:
- `soteria-partners` - Partner businesses
- `soteria-partner-redemptions` - User redemptions
- `soteria-partner-scans` - Scan analytics

## Step 2: Deploy Lambda Functions

```bash
./deploy-partner-lambdas.sh
```

This deploys:
- `soteria-partner-validate-member` - Validates QR code scans
- `soteria-partner-list` - Lists available partners
- `soteria-partner-redeem` - Records redemptions

## Step 3: Connect to API Gateway

```bash
./connect-partner-lambdas-to-api-gateway.sh
```

This connects the Lambda functions to your API Gateway at:
- `POST /soteria/partner/validate-member`
- `GET /soteria/partner/list`
- `POST /soteria/partner/redeem`

## Step 4: Deploy API Gateway

```bash
aws apigateway create-deployment \
  --rest-api-id ue1psw3mt3 \
  --stage-name prod \
  --region us-east-1
```

## Step 5: Add Sample Partners

Use the AWS Console or CLI to add partner records:

```bash
aws dynamodb put-item \
  --table-name soteria-partners \
  --item '{
    "partner_id": {"S": "partner-coffee-shop"},
    "name": {"S": "Coffee Shop"},
    "description": {"S": "Premium coffee and pastries"},
    "discount_percentage": {"N": "10"},
    "discount_type": {"S": "percentage"},
    "is_active": {"BOOL": true},
    "category": {"S": "Food & Beverage"},
    "location": {"S": "New York, NY"},
    "terms": {"S": "Valid on all items. Cannot be combined with other offers."},
    "max_redemptions_per_user": {"N": "5"}
  }' \
  --region us-east-1
```

## Step 6: Deploy Partner Scanner

The partner scanner is a static HTML file that can be hosted on:
- AWS S3 + CloudFront
- Any web hosting service
- Local development server

To test locally:
```bash
cd partner-scanner
python3 -m http.server 8000
# Open http://localhost:8000
```

To deploy to S3:
```bash
aws s3 sync partner-scanner/ s3://your-bucket-name/partner-scanner/ \
  --region us-east-1

# Enable static website hosting
aws s3 website s3://your-bucket-name \
  --index-document index.html \
  --error-document index.html
```

## Step 7: Apple Wallet Pass Setup (Optional)

### 7.1 Register Pass Type ID

1. Go to Apple Developer Portal
2. Register a Pass Type ID (e.g., `pass.com.soteria.member`)
3. Download the certificate (.p12 file)
4. Download WWDR certificate

### 7.2 Upload Certificates to S3

```bash
# Create S3 bucket for pass assets
aws s3 mb s3://soteria-wallet-passes --region us-east-1

# Upload certificates
aws s3 cp cert.p12 s3://soteria-wallet-passes/certificates/cert.p12
aws s3 cp wwdr.pem s3://soteria-wallet-passes/certificates/wwdr.pem

# Upload pass assets
aws s3 cp logo.png s3://soteria-wallet-passes/assets/logo.png
aws s3 cp icon.png s3://soteria-wallet-passes/assets/icon.png
```

### 7.3 Deploy Apple Wallet Lambda

```bash
cd lambda/soteria-apple-wallet-pass
npm install --production
zip -r function.zip . -x "*.git*" "*.DS_Store*"

aws lambda create-function \
  --function-name soteria-apple-wallet-pass \
  --runtime nodejs20.x \
  --role arn:aws:iam::YOUR_ACCOUNT:role/soteria-lambda-role \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 60 \
  --memory-size 512 \
  --region us-east-1 \
  --environment "Variables={
    PASS_BUCKET=soteria-wallet-passes,
    PASS_TYPE_ID=pass.com.soteria.member,
    TEAM_IDENTIFIER=YOUR_TEAM_ID,
    USER_DATA_TABLE=soteria-user-data
  }"
```

### 7.4 Connect to API Gateway

```bash
# Add to connect-partner-lambdas-to-api-gateway.sh or run manually:
aws apigateway put-method \
  --rest-api-id ue1psw3mt3 \
  --resource-id RESOURCE_ID \
  --http-method GET \
  --authorization-type NONE \
  --region us-east-1

aws apigateway put-integration \
  --rest-api-id ue1psw3mt3 \
  --resource-id RESOURCE_ID \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCOUNT:function:soteria-apple-wallet-pass/invocations \
  --region us-east-1
```

## Testing

### Test Partner List API
```bash
curl "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/partner/list"
```

### Test QR Validation
```bash
curl -X POST "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/partner/validate-member" \
  -H "Content-Type: application/json" \
  -d '{
    "qr_data": "{\"user_id\":\"test-user\",\"card_type\":\"gold\",\"member_since\":\"2024-01-01T00:00:00Z\"}",
    "partner_id": "partner-coffee-shop"
  }'
```

### Test Partner Scanner
1. Open `partner-scanner/index.html` in a browser
2. Select a partner from the dropdown
3. Click "Start QR Scanner" or paste QR code data
4. Verify member validation works

## Environment Variables

Update Lambda environment variables as needed:
- `PARTNERS_TABLE` - DynamoDB table for partners
- `REDEMPTIONS_TABLE` - DynamoDB table for redemptions
- `SCANS_TABLE` - DynamoDB table for scan analytics
- `USER_DATA_TABLE` - DynamoDB table for user data
- `USER_POOL_ID` - Cognito User Pool ID (for premium validation)

## Security Considerations

1. **API Authentication**: Consider adding API keys or Cognito authentication for partner endpoints
2. **Rate Limiting**: Implement rate limiting to prevent abuse
3. **QR Code Expiration**: Consider adding expiration timestamps to QR codes
4. **Certificate Security**: Store certificates securely in S3 with encryption
5. **CORS**: Configure CORS appropriately for production

## Monitoring

Set up CloudWatch alarms for:
- Lambda function errors
- API Gateway 4xx/5xx responses
- DynamoDB throttling
- Scan validation failures

## Next Steps

1. **Partner Onboarding**: Create admin interface for adding partners
2. **Analytics Dashboard**: Build dashboard for redemption analytics
3. **Push Notifications**: Implement push notifications for new partner discounts
4. **Mobile App Integration**: Add partner list and redemption history to iOS app
5. **Partner Portal**: Create self-service portal for partners to manage discounts

## Troubleshooting

### Lambda function not found
- Verify function names match exactly
- Check region is correct (us-east-1)

### API Gateway 502 errors
- Check Lambda function logs in CloudWatch
- Verify IAM permissions for API Gateway to invoke Lambda

### QR code validation fails
- Verify user has active premium subscription in DynamoDB
- Check partner is active in `soteria-partners` table
- Review CloudWatch logs for detailed error messages

### Apple Wallet pass generation fails
- Verify certificates are uploaded to S3
- Check Pass Type ID matches Apple Developer registration
- Ensure OpenSSL is available in Lambda environment (may need Lambda layer)

