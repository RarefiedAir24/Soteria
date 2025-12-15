#!/bin/bash

# Script to populate DynamoDB table with initial app mappings
# Usage: ./populate-app-mappings.sh

TABLE_NAME="soteria-app-token-mappings"
REGION="us-east-1"

echo "📝 Populating app token mappings..."

# Example mappings (you'll need to replace with actual token hashes from your test devices)
# To get token hashes:
# 1. Select apps in iOS app
# 2. Check console logs for: "🔍 [DeviceActivityService] Token X hash: XXXXX"
# 3. Use those hashes here

declare -A APP_MAPPINGS=(
    # Format: ["token_hash"]="app_name"
    # Example: ["1234567890"]="Amazon"
    # ["0987654321"]="Uber Eats"
    # ["1122334455"]="DoorDash"
)

if [ ${#APP_MAPPINGS[@]} -eq 0 ]; then
    echo "⚠️  No app mappings defined in script"
    echo ""
    echo "📋 To add mappings:"
    echo "1. Select apps in iOS app"
    echo "2. Check console logs for token hashes"
    echo "3. Edit this script and add mappings to APP_MAPPINGS array"
    echo "4. Run this script again"
    exit 0
fi

echo "📦 Adding ${#APP_MAPPINGS[@]} app mapping(s)..."

for hash in "${!APP_MAPPINGS[@]}"; do
    app_name="${APP_MAPPINGS[$hash]}"
    
    echo "  ➕ Adding: $hash → $app_name"
    
    aws dynamodb put-item \
        --table-name $TABLE_NAME \
        --item "{
            \"token_hash\": {\"S\": \"$hash\"},
            \"app_name\": {\"S\": \"$app_name\"},
            \"created_at\": {\"N\": \"$(date +%s)000\"},
            \"updated_at\": {\"N\": \"$(date +%s)000\"}
        }" \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        echo "    ✅ Added successfully"
    else
        echo "    ❌ Failed to add"
    fi
done

echo ""
echo "✅ Population complete!"
echo ""
echo "📋 Verify mappings:"
aws dynamodb scan \
    --table-name $TABLE_NAME \
    --region $REGION \
    --query 'Items[*].[token_hash.S,app_name.S]' \
    --output table

