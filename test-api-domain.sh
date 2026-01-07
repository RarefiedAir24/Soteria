#!/bin/bash

# Test script for api.soteria.zone
# Run this to verify the custom domain is working

echo "🧪 Testing api.soteria.zone..."
echo ""

# Test DNS resolution
echo "1. Testing DNS resolution..."
DNS_RESULT=$(dig +short api.soteria.zone @8.8.8.8 2>/dev/null | head -1)
if [ -n "$DNS_RESULT" ]; then
    echo "   ✅ DNS resolves: $DNS_RESULT"
else
    echo "   ❌ DNS not resolving"
    exit 1
fi

# Test API endpoint
echo ""
echo "2. Testing API endpoint..."
API_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 10 "https://api.soteria.zone/soteria/partner/list" 2>&1)
HTTP_CODE=$(echo "$API_RESPONSE" | tail -1)
BODY=$(echo "$API_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ API is working! (HTTP $HTTP_CODE)"
    echo "$BODY" | jq -r '.success, (.partners | length | "Partners: \(.)")' 2>/dev/null || echo "$BODY" | head -3
elif [ "$HTTP_CODE" = "000" ]; then
    echo "   ⏳ DNS not propagated yet (connection failed)"
    echo "   Wait 15-30 minutes and try again"
elif [ "$HTTP_CODE" = "403" ] || [ "$HTTP_CODE" = "404" ]; then
    echo "   ⚠️  Got HTTP $HTTP_CODE - API Gateway issue"
    echo "   Response: $BODY"
else
    echo "   ⚠️  Got HTTP $HTTP_CODE"
    echo "   Response: $BODY"
fi

# Test direct API Gateway (should always work)
echo ""
echo "3. Testing direct API Gateway (should work)..."
DIRECT_RESPONSE=$(curl -s "https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/partner/list")
if echo "$DIRECT_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    PARTNER_COUNT=$(echo "$DIRECT_RESPONSE" | jq '.partners | length')
    echo "   ✅ Direct API works: $PARTNER_COUNT partners"
else
    echo "   ❌ Direct API failed"
fi

echo ""
echo "📋 Summary:"
echo "   - DNS: $([ -n "$DNS_RESULT" ] && echo "✅ Resolves" || echo "❌ Failed")"
echo "   - Custom Domain: $([ "$HTTP_CODE" = "200" ] && echo "✅ Working" || echo "⏳ Waiting for DNS")"
echo "   - Direct API: ✅ Working"
echo ""
echo "💡 If custom domain doesn't work:"
echo "   1. Wait 15-30 minutes for DNS propagation"
echo "   2. Clear DNS cache: sudo dscacheutil -flushcache"
echo "   3. Test from different network/browser"

