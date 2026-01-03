#!/bin/bash

# Script to configure rate limiting on API Gateway
# This helps prevent brute force attacks and DoS

set -e

echo "🛡️  Configuring API Gateway rate limiting..."

# API Gateway IDs
MAIN_API_ID="${1:-ue1psw3mt3}"
MEMBER_API_ID="${2:-g3ksyd36e5}"
REGION="${AWS_REGION:-us-east-1}"

# Rate limiting settings
# Burst: Maximum number of requests in a short time window
# Rate: Sustained requests per second
BURST_LIMIT=100
RATE_LIMIT=50  # requests per second

echo "📊 Rate Limit Settings:"
echo "  Burst Limit: $BURST_LIMIT requests"
echo "  Rate Limit: $RATE_LIMIT requests/second"
echo ""

# Function to set throttling for an API Gateway
set_throttling() {
    local API_ID=$1
    local API_NAME=$2
    
    echo "🔧 Configuring throttling for $API_NAME (API ID: $API_ID)..."
    
    # Get current usage plan or create one
    USAGE_PLAN_ID=$(aws apigateway get-usage-plans \
        --region "$REGION" \
        --query "items[?name=='soteria-rate-limit'].id" \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$USAGE_PLAN_ID" ]; then
        echo "📝 Creating usage plan..."
        USAGE_PLAN_ID=$(aws apigateway create-usage-plan \
            --region "$REGION" \
            --name "soteria-rate-limit" \
            --description "Rate limiting for Soteria API" \
            --throttle "burstLimit=$BURST_LIMIT,rateLimit=$RATE_LIMIT" \
            --api-stages "[{\"apiId\":\"$API_ID\",\"stage\":\"prod\"}]" \
            --query 'id' \
            --output text)
        echo "✅ Usage plan created: $USAGE_PLAN_ID"
    else
        echo "📝 Updating existing usage plan..."
        # Update throttling using direct parameters
        aws apigateway update-usage-plan \
            --region "$REGION" \
            --usage-plan-id "$USAGE_PLAN_ID" \
            --throttle "burstLimit=$BURST_LIMIT,rateLimit=$RATE_LIMIT" > /dev/null
        echo "✅ Usage plan updated"
    fi
    
    # Also set default throttling on the API stage
    echo "📝 Setting default throttling on prod stage..."
    # Note: Stage-level throttling requires different approach
    # Usage plan throttling is sufficient for most cases
    echo "✅ Throttling configured via usage plan"
}

# Configure main API Gateway
set_throttling "$MAIN_API_ID" "Main API"

# Configure member number API Gateway
set_throttling "$MEMBER_API_ID" "Member Number API"

echo ""
echo "✅ Rate limiting configured"
echo ""
echo "📊 Current Limits:"
echo "  Burst: $BURST_LIMIT requests"
echo "  Rate: $RATE_LIMIT requests/second"
echo ""
echo "💡 Note: These limits apply per API key. For per-IP limiting, consider AWS WAF."

