#!/bin/bash

# Script to create AWS Cognito User Pool for Soteria
# Run this script to set up authentication

set -e  # Exit on error

echo "🚀 Creating AWS Cognito User Pool for Soteria..."

# Configuration
POOL_NAME="soteria-users"
CLIENT_NAME="soteria-ios"
REGION="us-east-1"

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

# Step 1: Create User Pool
echo ""
echo "📝 Creating Cognito User Pool: $POOL_NAME..."

USER_POOL_OUTPUT=$(aws cognito-idp create-user-pool \
    --pool-name "$POOL_NAME" \
    --policies "PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true}" \
    --auto-verified-attributes email \
    --username-attributes email \
    --region "$REGION" \
    --query 'UserPool.{Id:Id,Name:Name}' \
    --output json)

USER_POOL_ID=$(echo "$USER_POOL_OUTPUT" | grep -o '"Id": "[^"]*"' | cut -d'"' -f4)

if [ -z "$USER_POOL_ID" ]; then
    echo -e "${RED}❌ Failed to create User Pool${NC}"
    exit 1
fi

echo -e "${GREEN}✅ User Pool created: $USER_POOL_ID${NC}"

# Step 2: Create User Pool Client
echo ""
echo "📝 Creating User Pool Client: $CLIENT_NAME..."

CLIENT_OUTPUT=$(aws cognito-idp create-user-pool-client \
    --user-pool-id "$USER_POOL_ID" \
    --client-name "$CLIENT_NAME" \
    --generate-secret \
    --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
    --region "$REGION" \
    --query 'UserPoolClient.{ClientId:ClientId,ClientName:ClientName}' \
    --output json)

CLIENT_ID=$(echo "$CLIENT_OUTPUT" | grep -o '"ClientId": "[^"]*"' | cut -d'"' -f4)

if [ -z "$CLIENT_ID" ]; then
    echo -e "${RED}❌ Failed to create User Pool Client${NC}"
    exit 1
fi

echo -e "${GREEN}✅ User Pool Client created: $CLIENT_ID${NC}"

# Step 3: Get Client Secret (if generated)
echo ""
echo "📝 Retrieving Client Secret..."
CLIENT_SECRET=$(aws cognito-idp describe-user-pool-client \
    --user-pool-id "$USER_POOL_ID" \
    --client-id "$CLIENT_ID" \
    --region "$REGION" \
    --query 'UserPoolClient.ClientSecret' \
    --output text)

# Step 4: Output summary
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Cognito User Pool Created!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "User Pool ID: $USER_POOL_ID"
echo "Client ID: $CLIENT_ID"
if [ -n "$CLIENT_SECRET" ] && [ "$CLIENT_SECRET" != "None" ]; then
    echo "Client Secret: $CLIENT_SECRET"
fi
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Save these values!${NC}"
echo ""
echo "Next steps:"
echo "1. Update CognitoAuthService.swift with these values"
echo "2. Set environment variables in Lambda functions:"
echo "   - USER_POOL_ID=$USER_POOL_ID"
echo "   - CLIENT_ID=$CLIENT_ID"
if [ -n "$CLIENT_SECRET" ] && [ "$CLIENT_SECRET" != "None" ]; then
    echo "   - CLIENT_SECRET=$CLIENT_SECRET"
fi
echo "3. Run deploy-auth-lambdas.sh to deploy Lambda functions"
echo "4. Run connect-auth-lambdas-to-api-gateway.sh to connect to API Gateway"
echo ""

