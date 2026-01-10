# Gift Card Redemption Lambda

## Overview
This Lambda function handles gift card redemptions by:
1. Verifying user has enough loyalty points
2. Calling Tremendous API to send gift card
3. Deducting points from user's balance
4. Logging redemption for history

## Environment Variables
- `USER_DATA_TABLE`: DynamoDB table for user data (default: `soteria-user-data`)
- `REDEMPTIONS_TABLE`: DynamoDB table for gift card redemptions (default: `soteria-gift-card-redemptions`)
- `TREMENDOUS_API_KEY`: API key for Tremendous (required)

## Deployment

### 1. Install dependencies:
```bash
cd lambda/soteria-redeem-gift-card
npm install
```

### 2. Create deployment package:
```bash
zip -r function.zip index.js node_modules/
```

### 3. Deploy to AWS Lambda:
```bash
aws lambda create-function \
  --function-name soteria-redeem-gift-card \
  --runtime nodejs18.x \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --memory-size 256 \
  --environment Variables="{TREMENDOUS_API_KEY=your_key_here}"
```

### 4. Create DynamoDB table for redemptions:
```bash
aws dynamodb create-table \
  --table-name soteria-gift-card-redemptions \
  --attribute-definitions \
    AttributeName=redemptionId,AttributeType=S \
    AttributeName=userId,AttributeType=S \
  --key-schema \
    AttributeName=redemptionId,KeyType=HASH \
  --global-secondary-indexes \
    "[{\"IndexName\":\"UserIdIndex\",\"KeySchema\":[{\"AttributeName\":\"userId\",\"KeyType\":\"HASH\"}],\"Projection\":{\"ProjectionType\":\"ALL\"},\"ProvisionedThroughput\":{\"ReadCapacityUnits\":5,\"WriteCapacityUnits\":5}}]" \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### 5. Create API Gateway endpoint:
```bash
# Create REST API
aws apigateway create-rest-api --name soteria-api

# Add POST /redeem-gift-card resource
# Configure Cognito authorizer
# Deploy to stage
```

## Testing

### Test payload:
```json
{
  "body": "{\"userId\":\"test-user-123\",\"giftCardId\":\"amazon_5\",\"pointsToSpend\":2500,\"email\":\"user@example.com\",\"brand\":\"Amazon\",\"amount\":5.0}"
}
```

### Test locally:
```bash
node -e "const handler = require('./index').handler; handler({body: JSON.stringify({userId:'test',giftCardId:'amazon_5',pointsToSpend:2500,email:'test@test.com',brand:'Amazon',amount:5.0})}).then(console.log)"
```

## Tremendous API Setup

1. Sign up at https://www.tremendous.com/
2. Get API key from dashboard
3. Set up campaigns for each gift card type:
   - AMAZON5 ($5 Amazon)
   - TARGET10 ($10 Target)
   - STARBUCKS15 ($15 Starbucks)
   - VISA25 ($25 Visa)
4. Add API key to Lambda environment variables

## Permissions Required

Lambda execution role needs:
- `dynamodb:GetItem` on `soteria-user-data`
- `dynamodb:UpdateItem` on `soteria-user-data`
- `dynamodb:PutItem` on `soteria-gift-card-redemptions`
- `logs:CreateLogGroup`
- `logs:CreateLogStream`
- `logs:PutLogEvents`
