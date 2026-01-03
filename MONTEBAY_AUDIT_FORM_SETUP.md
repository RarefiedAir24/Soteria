# Montebay Silent AWS Audit Form - Setup Guide

## Overview

This Lambda function handles form submissions from the Montebay website's Silent AWS Audit request form. It validates the submission and sends a formatted email via AWS SES.

## Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI configured
3. SES email domain verified (or email address verified for testing)

## Step 1: Create IAM Role

Create an IAM role for the Lambda function with the following permissions:

### Trust Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Permissions Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      "Resource": "*"
    }
  ]
}
```

**Or use AWS CLI:**
```bash
# Create role
aws iam create-role \
  --role-name montebay-lambda-role \
  --assume-role-policy-document file://trust-policy.json

# Attach basic execution role
aws iam attach-role-policy \
  --role-name montebay-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Create and attach SES policy
aws iam put-role-policy \
  --role-name montebay-lambda-role \
  --policy-name SESSendEmailPolicy \
  --policy-document file://ses-policy.json
```

## Step 2: Verify SES Email

### Option A: Verify Email Address (Quick for Testing)
1. Go to AWS SES Console → Verified identities
2. Click "Create identity"
3. Select "Email address"
4. Enter: `noreply@montebay.io` (or your sending email)
5. Enter: `contact@montebay.io` (or your receiving email)
6. Verify both email addresses by clicking links in confirmation emails

### Option B: Verify Domain (Production)
1. Go to AWS SES Console → Verified identities
2. Click "Create identity"
3. Select "Domain"
4. Enter: `montebay.io`
5. Add the DNS records provided to your domain's DNS settings
6. Wait for verification (can take up to 72 hours)

**Note:** If you're in SES Sandbox mode, you can only send to verified email addresses. Request production access to send to any email.

## Step 3: Deploy Lambda Function

```bash
cd /Users/frankschioppa/soteria
chmod +x deploy-montebay-audit-form-lambda.sh
./deploy-montebay-audit-form-lambda.sh
```

## Step 4: Create API Gateway Endpoint

### Option A: Using AWS Console
1. Go to API Gateway Console
2. Create new REST API (or use existing)
3. Create resource: `/montebay`
4. Create resource: `/silent-aws-audit`
5. Create POST method
6. Integration type: Lambda Function
7. Select: `montebay-silent-aws-audit-form`
8. Enable CORS
9. Deploy API to a stage (e.g., `prod`)
10. Note the API endpoint URL

### Option B: Using AWS CLI
```bash
# Create API (if it doesn't exist)
API_ID=$(aws apigateway create-rest-api \
  --name montebay-api \
  --description "Montebay website API" \
  --query 'id' \
  --output text)

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --query 'items[?path==`/`].id' \
  --output text)

# Create /montebay resource
MONTEBAY_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part montebay \
  --query 'id' \
  --output text)

# Create /silent-aws-audit resource
AUDIT_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $MONTEBAY_ID \
  --path-part silent-aws-audit \
  --query 'id' \
  --output text)

# Create POST method
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $AUDIT_ID \
  --http-method POST \
  --authorization-type NONE

# Set Lambda integration
LAMBDA_ARN=$(aws lambda get-function \
  --function-name montebay-silent-aws-audit-form \
  --query 'Configuration.FunctionArn' \
  --output text)

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $AUDIT_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
  --function-name montebay-silent-aws-audit-form \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:$(aws sts get-caller-identity --query Account --output text):${API_ID}/*/*"

# Enable CORS
aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $AUDIT_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters method.response.header.Access-Control-Allow-Headers=true,method.response.header.Access-Control-Allow-Methods=true,method.response.header.Access-Control-Allow-Origin=true

# Deploy API
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod

# Get endpoint URL
echo "API Endpoint: https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod/montebay/silent-aws-audit"
```

## Step 5: Update Website JavaScript

Update the form submission in `/Users/frankschioppa/montebay-website/script.js`:

Replace the mailto implementation with:

```javascript
// Replace the mailto section with:
const API_ENDPOINT = 'https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/montebay/silent-aws-audit';

// In the form submit handler, replace the mailto code with:
fetch(API_ENDPOINT, {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    body: JSON.stringify(formObject)
})
.then(response => response.json())
.then(data => {
    if (data.success) {
        showAuditFormMessage(data.message, 'success');
        auditForm.reset();
    } else {
        showAuditFormMessage(data.error || 'Sorry, there was an error submitting your request. Please try again.', 'error');
    }
})
.catch(error => {
    console.error('Error:', error);
    showAuditFormMessage('Sorry, there was an error submitting your request. Please try again or email contact@montebay.io directly.', 'error');
})
.finally(() => {
    submitBtn.textContent = originalText;
    submitBtn.disabled = false;
});
```

## Testing

1. Test the Lambda function directly:
```bash
aws lambda invoke \
  --function-name montebay-silent-aws-audit-form \
  --payload '{"httpMethod":"POST","body":"{\"full-name\":\"Test User\",\"work-email\":\"test@example.com\",\"company-name\":\"Test Co\",\"role-title\":\"CTO\",\"aws-environment-type\":\"Early-stage\",\"monthly-aws-spend\":\"Under $1,000\",\"audit-tier\":\"Essential Audit — $1,250\",\"audit-concerns\":[\"Security\"],\"audit-confirmations\":[\"Confirmation 1\",\"Confirmation 2\",\"Confirmation 3\"],\"delivery-acknowledgment\":\"Acknowledged\"}"}' \
  response.json

cat response.json
```

2. Test via API Gateway using curl:
```bash
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/montebay/silent-aws-audit \
  -H "Content-Type: application/json" \
  -d '{
    "full-name": "Test User",
    "work-email": "test@example.com",
    "company-name": "Test Company",
    "role-title": "CTO",
    "aws-environment-type": "Early-stage / small production environment",
    "monthly-aws-spend": "Under $1,000",
    "audit-concerns": ["Security or access risk"],
    "audit-tier": "Essential Audit — $1,250",
    "audit-confirmations": [
      "I understand this is a read-only, no-meeting AWS audit",
      "I am not requesting CI/CD, DevOps pipelines, or ongoing infrastructure management",
      "I understand implementation support is optional and separate"
    ],
    "delivery-acknowledgment": "I understand this audit is performed asynchronously and delivered within 5–7 business days after access is granted"
  }'
```

## Environment Variables

The Lambda function uses these environment variables:
- `TO_EMAIL`: Email address to receive submissions (default: contact@montebay.io)
- `FROM_EMAIL`: Email address to send from (default: noreply@montebay.io)
- `AWS_REGION`: AWS region (default: us-east-1)

Update them via:
```bash
aws lambda update-function-configuration \
  --function-name montebay-silent-aws-audit-form \
  --environment "Variables={TO_EMAIL=contact@montebay.io,FROM_EMAIL=noreply@montebay.io,AWS_REGION=us-east-1}"
```

## Optional: Store Submissions in DynamoDB

If you want to track submissions, uncomment the DynamoDB code in `index.js` and create a table:

```bash
aws dynamodb create-table \
  --table-name montebay-audit-submissions \
  --attribute-definitions AttributeName=submission_id,AttributeType=S \
  --key-schema AttributeName=submission_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Then add DynamoDB permissions to the Lambda role.

## Troubleshooting

1. **Email not sending**: Check SES verification status and sandbox mode
2. **CORS errors**: Ensure CORS is enabled in API Gateway
3. **Lambda timeout**: Increase timeout in function configuration
4. **Permission errors**: Verify IAM role has SES permissions

## Cost Estimate

- Lambda: Free tier includes 1M requests/month
- API Gateway: $3.50 per million requests
- SES: $0.10 per 1,000 emails

Total for ~100 submissions/month: ~$0.04/month

