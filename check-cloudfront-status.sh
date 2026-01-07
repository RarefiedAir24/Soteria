#!/bin/bash

# Quick script to check CloudFront deployment status

DIST_ID="E2208NPSBT76U6"

echo "📊 Checking CloudFront Distribution Status..."
echo ""

STATUS=$(aws cloudfront get-distribution --id "$DIST_ID" --query 'Distribution.Status' --output text 2>/dev/null)
DOMAIN=$(aws cloudfront get-distribution --id "$DIST_ID" --query 'Distribution.DomainName' --output text 2>/dev/null)
ENABLED=$(aws cloudfront get-distribution --id "$DIST_ID" --query 'Distribution.DistributionConfig.Enabled' --output text 2>/dev/null)

echo "Distribution ID: $DIST_ID"
echo "Status: $STATUS"
echo "Enabled: $ENABLED"
echo "CloudFront Domain: $DOMAIN"
echo ""

if [ "$STATUS" = "Deployed" ]; then
    echo "✅ CloudFront is fully deployed!"
    echo ""
    echo "🌐 Test URLs:"
    echo "   Portal: https://api.soteria.zone/"
    echo "   API: https://api.soteria.zone/soteria/partner/list"
    echo ""
    echo "💡 If URLs don't work yet, wait 5-10 minutes for DNS propagation"
elif [ "$STATUS" = "InProgress" ]; then
    echo "⏳ CloudFront is still deploying..."
    echo "   This typically takes 15-20 minutes"
    echo "   Check again in a few minutes"
else
    echo "⚠️  Status: $STATUS"
fi

