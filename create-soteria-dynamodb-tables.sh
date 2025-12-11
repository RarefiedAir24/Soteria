#!/bin/bash

# Script to create DynamoDB tables for Soteria
# Run this script after reviewing it to ensure it's correct

set -e  # Exit on error

echo "🚀 Creating DynamoDB tables for Soteria..."

# Configuration
REGION="us-east-1"  # Change if you prefer a different region

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  Make sure you have AWS credentials configured${NC}"
echo -e "${YELLOW}⚠️  This will create resources in AWS - review commands before running${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Function to create a table
create_table() {
    local TABLE_NAME=$1
    local PARTITION_KEY=$2
    local SORT_KEY=$3
    
    echo "📊 Creating table: $TABLE_NAME..."
    
    if [ -z "$SORT_KEY" ]; then
        # Table with only partition key
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions \
                AttributeName="$PARTITION_KEY",AttributeType=S \
            --key-schema \
                AttributeName="$PARTITION_KEY",KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION" \
            --tags \
                Key=Project,Value=Soteria \
                Key=Environment,Value=prod \
            --query 'TableDescription.TableName' \
            --output text
    else
        # Table with partition key and sort key
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions \
                AttributeName="$PARTITION_KEY",AttributeType=S \
                AttributeName="$SORT_KEY",AttributeType=S \
            --key-schema \
                AttributeName="$PARTITION_KEY",KeyType=HASH \
                AttributeName="$SORT_KEY",KeyType=RANGE \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION" \
            --tags \
                Key=Project,Value=Soteria \
                Key=Environment,Value=prod \
            --query 'TableDescription.TableName' \
            --output text
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Table $TABLE_NAME created successfully${NC}"
    else
        echo -e "${RED}❌ Failed to create table $TABLE_NAME${NC}"
        return 1
    fi
}

# Create all tables
echo ""
echo "Creating DynamoDB tables..."

# 1. soteria-user-data - Main user data table
# Partition: user_id, Sort: data_type
create_table "soteria-user-data" "user_id" "data_type"

# 2. soteria-app-usage - App usage sessions
# Partition: user_id, Sort: session_id
create_table "soteria-app-usage" "user_id" "session_id"

# 3. soteria-unblock-events - Unblock event metrics
# Partition: user_id, Sort: timestamp
create_table "soteria-unblock-events" "user_id" "timestamp"

# 4. soteria-goals - Savings goals
# Partition: user_id, Sort: goal_id
create_table "soteria-goals" "user_id" "goal_id"

# 5. soteria-regrets - Regret entries
# Partition: user_id, Sort: regret_id
create_table "soteria-regrets" "user_id" "regret_id"

# 6. soteria-moods - Mood tracking data
# Partition: user_id, Sort: entry_id
create_table "soteria-moods" "user_id" "entry_id"

# 7. soteria-quiet-hours - Quiet hours schedules
# Partition: user_id, Sort: schedule_id
create_table "soteria-quiet-hours" "user_id" "schedule_id"

# 8. soteria-purchase-intents - Purchase intent records
# Partition: user_id, Sort: intent_id
create_table "soteria-purchase-intents" "user_id" "intent_id"

# 9. soteria-plaid-access-tokens - Plaid access tokens
# Partition: user_id, Sort: account_id
create_table "soteria-plaid-access-tokens" "user_id" "account_id"

# 10. soteria-plaid-transfers - Transfer records (optional)
# Partition: user_id, Sort: transfer_id
create_table "soteria-plaid-transfers" "user_id" "transfer_id"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All DynamoDB Tables Created!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Tables created:"
echo "  - soteria-user-data"
echo "  - soteria-app-usage"
echo "  - soteria-unblock-events"
echo "  - soteria-goals"
echo "  - soteria-regrets"
echo "  - soteria-moods"
echo "  - soteria-quiet-hours"
echo "  - soteria-purchase-intents"
echo "  - soteria-plaid-access-tokens"
echo "  - soteria-plaid-transfers"
echo ""
echo "To verify tables:"
echo "  aws dynamodb list-tables --region $REGION --query 'TableNames[?starts_with(@, `soteria-`)]'"
echo ""

