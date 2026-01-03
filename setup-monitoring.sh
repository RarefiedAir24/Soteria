#!/bin/bash

# Setup CloudWatch monitoring and alarms for Partner Loyalty system
# This script creates CloudWatch alarms for Lambda errors, API Gateway issues, and DynamoDB throttling

echo "📊 Setting up CloudWatch Monitoring for Partner Loyalty"
echo "========================================================"
echo ""

REGION="us-east-1"
SNS_TOPIC_ARN=""  # Optional: Add SNS topic ARN for notifications

# Lambda function names
LAMBDA_FUNCTIONS=(
    "soteria-partner-validate-member"
    "soteria-partner-list"
    "soteria-partner-redeem"
)

# DynamoDB table names
DYNAMODB_TABLES=(
    "soteria-partners"
    "soteria-partner-redemptions"
    "soteria-partner-scans"
)

# API Gateway stage
API_GATEWAY_STAGE="prod"

echo "🔔 Creating CloudWatch Alarms..."
echo ""

# 1. Lambda Function Error Alarms
for func in "${LAMBDA_FUNCTIONS[@]}"; do
    echo "Creating alarm for Lambda: $func"
    
    aws cloudwatch put-metric-alarm \
        --alarm-name "${func}-errors" \
        --alarm-description "Alert when ${func} has errors" \
        --metric-name Errors \
        --namespace AWS/Lambda \
        --statistic Sum \
        --period 300 \
        --threshold 1 \
        --comparison-operator GreaterThanOrEqualToThreshold \
        --evaluation-periods 1 \
        --dimensions Name=FunctionName,Value="${func}" \
        --region "${REGION}" \
        ${SNS_TOPIC_ARN:+--alarm-actions "${SNS_TOPIC_ARN}"} \
        --treat-missing-data notBreaching
    
    if [ $? -eq 0 ]; then
        echo "✅ Alarm created: ${func}-errors"
    else
        echo "❌ Failed to create alarm for ${func}"
    fi
    echo ""
done

# 2. Lambda Function Duration Alarms
for func in "${LAMBDA_FUNCTIONS[@]}"; do
    echo "Creating duration alarm for Lambda: $func"
    
    aws cloudwatch put-metric-alarm \
        --alarm-name "${func}-duration" \
        --alarm-description "Alert when ${func} takes too long" \
        --metric-name Duration \
        --namespace AWS/Lambda \
        --statistic Average \
        --period 300 \
        --threshold 5000 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 2 \
        --dimensions Name=FunctionName,Value="${func}" \
        --region "${REGION}" \
        ${SNS_TOPIC_ARN:+--alarm-actions "${SNS_TOPIC_ARN}"} \
        --treat-missing-data notBreaching
    
    if [ $? -eq 0 ]; then
        echo "✅ Alarm created: ${func}-duration"
    else
        echo "❌ Failed to create duration alarm for ${func}"
    fi
    echo ""
done

# 3. DynamoDB Throttling Alarms
for table in "${DYNAMODB_TABLES[@]}"; do
    echo "Creating throttling alarm for DynamoDB: $table"
    
    aws cloudwatch put-metric-alarm \
        --alarm-name "${table}-throttles" \
        --alarm-description "Alert when ${table} is being throttled" \
        --metric-name UserErrors \
        --namespace AWS/DynamoDB \
        --statistic Sum \
        --period 300 \
        --threshold 1 \
        --comparison-operator GreaterThanOrEqualToThreshold \
        --evaluation-periods 1 \
        --dimensions Name=TableName,Value="${table}" \
        --region "${REGION}" \
        ${SNS_TOPIC_ARN:+--alarm-actions "${SNS_TOPIC_ARN}"} \
        --treat-missing-data notBreaching
    
    if [ $? -eq 0 ]; then
        echo "✅ Alarm created: ${table}-throttles"
    else
        echo "❌ Failed to create throttling alarm for ${table}"
    fi
    echo ""
done

# 4. API Gateway 4xx Errors
echo "Creating API Gateway 4xx error alarm..."
aws cloudwatch put-metric-alarm \
    --alarm-name "soteria-partner-api-4xx-errors" \
    --alarm-description "Alert when API Gateway has 4xx errors" \
    --metric-name 4XXError \
    --namespace AWS/ApiGateway \
    --statistic Sum \
    --period 300 \
    --threshold 10 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --dimensions Name=ApiName,Value="soteria-api" \
    --region "${REGION}" \
    ${SNS_TOPIC_ARN:+--alarm-actions "${SNS_TOPIC_ARN}"} \
    --treat-missing-data notBreaching

if [ $? -eq 0 ]; then
    echo "✅ Alarm created: soteria-partner-api-4xx-errors"
else
    echo "⚠️  Failed to create API Gateway 4xx alarm (API name may need adjustment)"
fi
echo ""

# 5. API Gateway 5xx Errors
echo "Creating API Gateway 5xx error alarm..."
aws cloudwatch put-metric-alarm \
    --alarm-name "soteria-partner-api-5xx-errors" \
    --alarm-description "Alert when API Gateway has 5xx errors" \
    --metric-name 5XXError \
    --namespace AWS/ApiGateway \
    --statistic Sum \
    --period 300 \
    --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --dimensions Name=ApiName,Value="soteria-api" \
    --region "${REGION}" \
    ${SNS_TOPIC_ARN:+--alarm-actions "${SNS_TOPIC_ARN}"} \
    --treat-missing-data notBreaching

if [ $? -eq 0 ]; then
    echo "✅ Alarm created: soteria-partner-api-5xx-errors"
else
    echo "⚠️  Failed to create API Gateway 5xx alarm (API name may need adjustment)"
fi
echo ""

echo "========================================================"
echo "✅ CloudWatch Monitoring Setup Complete!"
echo ""
echo "📊 View alarms in CloudWatch Console:"
echo "   https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#alarmsV2:"
echo ""
echo "📈 View metrics:"
echo "   - Lambda: https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#metricsV2:graph=~();namespace=AWS/Lambda"
echo "   - DynamoDB: https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#metricsV2:graph=~();namespace=AWS/DynamoDB"
echo "   - API Gateway: https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#metricsV2:graph=~();namespace=AWS/ApiGateway"
echo ""
echo "💡 To receive email notifications, create an SNS topic and update SNS_TOPIC_ARN in this script"

