#!/bin/bash

# Interactive script to collect and add app mappings
# This script helps you collect token hashes from Xcode console and add them to the database

TABLE_NAME="soteria-app-token-mappings"
REGION="us-east-1"

echo "📝 App Token Mapping Collector"
echo "════════════════════════════════════════"
echo ""
echo "This script helps you add app token mappings to the database."
echo ""
echo "Steps:"
echo "1. Select apps in iOS app (Settings → App Monitoring → Select Apps)"
echo "2. Wait 6+ seconds"
echo "3. Check Xcode console for: '🔍 [DeviceActivityService] Token X hash: XXXXX'"
echo "4. Enter the hash and app name below"
echo ""
echo "Press Ctrl+C to exit"
echo ""

while true; do
    echo "────────────────────────────────────"
    echo "Enter app mapping (or 'done' to finish):"
    
    read -p "Token hash: " TOKEN_HASH
    
    if [ "$TOKEN_HASH" == "done" ] || [ -z "$TOKEN_HASH" ]; then
        echo ""
        echo "✅ Finished collecting mappings!"
        break
    fi
    
    read -p "App name: " APP_NAME
    
    if [ -z "$APP_NAME" ]; then
        echo "⚠️  App name is required. Skipping..."
        continue
    fi
    
    echo ""
    echo "Adding: $TOKEN_HASH → $APP_NAME"
    
    # Add to database
    aws dynamodb put-item \
        --table-name $TABLE_NAME \
        --item "{
            \"token_hash\": {\"S\": \"$TOKEN_HASH\"},
            \"app_name\": {\"S\": \"$APP_NAME\"},
            \"created_at\": {\"N\": \"$(date +%s)000\"},
            \"updated_at\": {\"N\": \"$(date +%s)000\"}
        }" \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        echo "✅ Added successfully!"
    else
        echo "❌ Failed to add. Check your AWS credentials and table name."
    fi
    
    echo ""
done

echo ""
echo "📋 Current mappings in database:"
aws dynamodb scan \
    --table-name $TABLE_NAME \
    --region $REGION \
    --query 'Items[*].[token_hash.S,app_name.S]' \
    --output table

echo ""
echo "✅ Done!"

