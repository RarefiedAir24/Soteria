# Soteria Screenshot Verification Lambda

AWS Lambda function that uses Textract to verify deposit screenshots and prevent fraud.

## Quick Deploy

```bash
cd lambda/soteria-verify-screenshot
npm install
npm run deploy
```

The deployment script will automatically:
1. ✅ Create deployment package (function.zip)
2. ✅ Create/update IAM role with Textract permissions
3. ✅ Deploy Lambda function
4. ✅ Configure API Gateway endpoint
5. ✅ Set up Lambda invoke permissions

## Manual Setup (if auto-deploy fails)

### 1. Install Dependencies
```bash
npm install
```

### 2. Create Deployment Package
```bash
zip -r function.zip index.js node_modules/
```

### 3. Create IAM Role

**Trust Policy** (lambda-trust-policy.json):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "lambda.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

**Permissions Policy** (lambda-permissions.json):
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
        "textract:DetectDocumentText",
        "textract:AnalyzeDocument"
      ],
      "Resource": "*"
    }
  ]
}
```

**Create Role:**
```bash
aws iam create-role \
  --role-name soteria-verify-screenshot-role \
  --assume-role-policy-document file://lambda-trust-policy.json

aws iam put-role-policy \
  --role-name soteria-verify-screenshot-role \
  --policy-name soteria-textract-policy \
  --policy-document file://lambda-permissions.json
```

### 4. Deploy Lambda Function
```bash
aws lambda create-function \
  --function-name soteria-verify-screenshot \
  --runtime nodejs20.x \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/soteria-verify-screenshot-role \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --memory-size 512 \
  --region us-east-1
```

### 5. Update Existing Function
```bash
aws lambda update-function-code \
  --function-name soteria-verify-screenshot \
  --zip-file fileb://function.zip \
  --region us-east-1
```

### 6. API Gateway Setup

#### Option A: Using AWS Console
1. Go to API Gateway console
2. Select your `soteria-api`
3. Create resource: `/soteria/verify-screenshot`
4. Create method: `POST`
5. Integration type: Lambda Function
6. Lambda function: `soteria-verify-screenshot`
7. Enable CORS
8. Deploy to `prod` stage

#### Option B: Using AWS CLI
```bash
# Get API ID
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='soteria-api'].id" --output text)

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query "items[?path=='/'].id" --output text)

# Create /soteria resource (if not exists)
SOTERIA_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part soteria \
  --query 'id' --output text)

# Create /verify-screenshot resource
VERIFY_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $SOTERIA_ID \
  --path-part verify-screenshot \
  --query 'id' --output text)

# Create POST method
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $VERIFY_ID \
  --http-method POST \
  --authorization-type NONE

# Set up Lambda integration
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_ARN="arn:aws:lambda:us-east-1:$ACCOUNT_ID:function:soteria-verify-screenshot"

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $VERIFY_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"

# Add Lambda permission for API Gateway
aws lambda add-permission \
  --function-name soteria-verify-screenshot \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:$ACCOUNT_ID:$API_ID/*/*"

# Deploy API
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod
```

## Testing

### Test Lambda Directly
```bash
aws lambda invoke \
  --function-name soteria-verify-screenshot \
  --payload file://test-payload.json \
  response.json

cat response.json
```

### Test via API Gateway
```bash
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/soteria/verify-screenshot \
  -H "Content-Type: application/json" \
  -d '{"image":"BASE64_IMAGE_HERE","claimed_amount":100.50}'
```

## Configuration

- **Timeout**: 30 seconds (Textract can be slow)
- **Memory**: 512 MB (sufficient for image processing)
- **Runtime**: Node.js 20.x
- **Region**: us-east-1

## Monitoring

View logs:
```bash
aws logs tail /aws/lambda/soteria-verify-screenshot --follow
```

## Cost Estimation

- **Lambda**: ~$0.20 per 1M requests + compute time
- **Textract**: $1.50 per 1,000 pages analyzed
- **Typical cost**: ~$0.002 per screenshot verification

For 1,000 verifications/month: ~$2.00/month

## Security

- Function requires Textract permissions
- Add Cognito authorization to API Gateway for production
- Images are processed in-memory (not stored)
- Results include limited extracted text (500 chars max)

