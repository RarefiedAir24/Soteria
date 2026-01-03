#!/bin/bash

# Script to set environment variables for Lambda functions that use auth-utils.js
# This sets Cognito configuration needed for JWT token validation

set -e

echo "🔧 Setting environment variables for Lambda functions..."

# Cognito configuration
COGNITO_USER_POOL_ID="${COGNITO_USER_POOL_ID:-us-east-1_099POP0Rf}"
COGNITO_CLIENT_ID="${COGNITO_CLIENT_ID:-3kammtce8eqracrm721d939jo}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Functions that need auth environment variables
FUNCTIONS=(
    "soteria-get-user-data"
    "soteria-sync-user-data"
    "soteria-delete-user-data"
    "soteria-get-dashboard"
    "soteria-member-number"
    "soteria-avatar-upload"
    "soteria-avatar-download"
    "soteria-goal-photo-upload"
    "soteria-goal-photo-download"
    "soteria-goal-photo-delete"
)

# Environment variables to set (AWS_REGION is reserved, don't set it)
ENV_VARS="{
    \"COGNITO_USER_POOL_ID\": \"$COGNITO_USER_POOL_ID\",
    \"COGNITO_CLIENT_ID\": \"$COGNITO_CLIENT_ID\"
}"

# Merge with existing environment variables
for func in "${FUNCTIONS[@]}"; do
    echo "📝 Updating $func..."
    
    # Get existing environment variables
    EXISTING_ENV=$(aws lambda get-function-configuration \
        --function-name "$func" \
        --region "$AWS_REGION" \
        --query 'Environment.Variables' \
        --output json 2>/dev/null || echo "{}")
    
    # Merge with new variables (new vars take precedence)
    if [ "$EXISTING_ENV" != "{}" ] && [ "$EXISTING_ENV" != "null" ]; then
        # Use jq to merge if available, otherwise use Python
        if command -v jq &> /dev/null; then
            MERGED_ENV=$(echo "$EXISTING_ENV" | jq ". + $ENV_VARS")
        else
            MERGED_ENV=$(python3 -c "
import json, sys
existing = json.loads('$EXISTING_ENV')
new_vars = json.loads('$ENV_VARS')
existing.update(new_vars)
print(json.dumps(existing))
")
        fi
    else
        MERGED_ENV="$ENV_VARS"
    fi
    
    # Update function configuration
    aws lambda update-function-configuration \
        --function-name "$func" \
        --region "$AWS_REGION" \
        --environment "Variables=$MERGED_ENV" \
        --query 'Environment.Variables' \
        --output json > /dev/null 2>&1 && echo "✅ $func updated" || echo "⚠️  $func not found (will be set on deployment)"
done

echo ""
echo "✅ Environment variables configured"
echo ""
echo "Variables set:"
echo "  COGNITO_USER_POOL_ID: $COGNITO_USER_POOL_ID"
echo "  COGNITO_CLIENT_ID: $COGNITO_CLIENT_ID"
echo "  (AWS_REGION is automatically set by Lambda)"

