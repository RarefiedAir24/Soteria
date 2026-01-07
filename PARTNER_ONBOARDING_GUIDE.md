# Partner Onboarding Guide

**For Soteria Team** - Step-by-step process for onboarding new partners

---

## Overview

This guide walks through the complete partner onboarding process, from initial contact to full integration.

---

## Pre-Onboarding Checklist

Before starting onboarding, ensure you have:

- [ ] Partner's business information (name, description, contact info)
- [ ] Discount details (percentage or fixed amount, terms)
- [ ] Partner's technical contact (for integration support)
- [ ] Partner's POS system information (if known)

---

## Step 1: Partner Registration

### Option A: Manual Registration (Admin)

1. **Collect Partner Information**
   - Business name
   - Description
   - Discount percentage or fixed amount
   - Category (Food & Beverage, Health & Fitness, etc.)
   - Location
   - Contact email and phone
   - Terms and conditions
   - Logo URL (optional)
   - Max redemptions per user (optional)
   - Valid until date (optional)

2. **Register via API**

```bash
curl -X POST \
  "https://g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod/soteria/partner/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ACME Coffee",
    "description": "Premium coffee and pastries",
    "discount_percentage": 10,
    "discount_type": "percentage",
    "category": "Food & Beverage",
    "location": "New York, NY",
    "contact_email": "partner@acme.com",
    "contact_phone": "+1-555-0123",
    "terms": "Valid on all items. Cannot be combined with other offers.",
    "max_redemptions_per_user": 5,
    "valid_until": "2026-12-31T23:59:59Z"
  }'
```

3. **Save Credentials**
   - Partner ID (e.g., `partner-acme-coffee-abc123`)
   - API Key (e.g., `sk_live_...`) - **Save this immediately, it's only shown once!**

### Option B: Self-Service Registration (Future)

Partners can register themselves via a web form (to be implemented).

---

## Step 2: Send Welcome Email

Send the partner a welcome email with:

1. **Partner Credentials**
   - Partner ID
   - API Key
   - API Base URL

2. **Integration Resources**
   - Link to Partner Integration Guide
   - Sample code in their preferred language
   - Test credentials

3. **Support Information**
   - Support email: partners@soteria.app
   - Integration support contact
   - Partner dashboard URL

**Email Template:**

```
Subject: Welcome to Soteria Partner Program!

Hi [Partner Name],

Welcome to the Soteria Partner Loyalty Program! We're excited to have you on board.

Your Partner Credentials:
- Partner ID: partner-acme-coffee-abc123
- API Key: sk_live_xxxxxxxxxxxxx (save this - it won't be shown again!)
- API Base URL: https://g3ksyd36e5.execute-api.us-east-1.amazonaws.com/prod

Next Steps:
1. Review the Integration Guide: [link to PARTNER_INTEGRATION_GUIDE.md]
2. Test the API with the provided test credentials
3. Integrate the API into your POS system
4. Access your dashboard: [link to partner dashboard]

Support:
- Email: partners@soteria.app
- Integration Guide: [link]
- Sample Code: [link]

We're here to help! Let us know if you have any questions.

Best,
The Soteria Team
```

---

## Step 3: Integration Support

### Initial Setup Call

Schedule a 30-minute call with the partner's technical contact:

1. **Review Integration Options**
   - Barcode/QR code scanning (recommended)
   - Member number entry (alternative)

2. **Walk Through API**
   - Show validation endpoint
   - Demonstrate with test credentials
   - Answer technical questions

3. **Provide Sample Code**
   - Share code in their preferred language
   - Help with initial integration

### Integration Checklist

- [ ] Partner has received credentials
- [ ] Partner has reviewed integration guide
- [ ] Partner has tested API with test credentials
- [ ] Partner has integrated API into POS system
- [ ] Partner has tested with real member (if available)
- [ ] Partner understands error handling
- [ ] Partner knows how to access dashboard

---

## Step 4: Testing & Validation

### Test Credentials

Provide partner with:
- Test member QR code data
- Test member number
- Expected validation results

### Test Scenarios

1. **Valid Premium Member**
   - Should return `valid: true`
   - Should show discount percentage

2. **Invalid/Expired Member**
   - Should return `valid: false`
   - Should show appropriate error

3. **Limit Reached**
   - Should return error after max redemptions

### Partner Testing

- [ ] Partner has tested validation endpoint
- [ ] Partner has tested redemption recording (optional)
- [ ] Partner has tested error scenarios
- [ ] Partner has verified discount calculation
- [ ] Partner has tested in production environment

---

## Step 5: Go Live

### Pre-Launch Checklist

- [ ] Partner integration is complete
- [ ] Partner has tested successfully
- [ ] Partner understands terms and conditions
- [ ] Partner has access to dashboard
- [ ] Partner knows how to contact support

### Launch Steps

1. **Activate Partner**
   - Ensure `is_active: true` in DynamoDB
   - Verify `valid_until` date (if set)

2. **Notify Partner**
   - Send "Go Live" email
   - Confirm they're ready
   - Provide support contact

3. **Monitor**
   - Check CloudWatch logs for errors
   - Monitor redemption activity
   - Check partner dashboard for issues

### Post-Launch

- [ ] Monitor first 24 hours for issues
- [ ] Check partner dashboard for activity
- [ ] Follow up with partner after 1 week
- [ ] Collect feedback for improvements

---

## Step 6: Ongoing Support

### Partner Dashboard

Partners can access their dashboard at:
- URL: `https://partners.soteria.app` (or hosted location)
- Login with Partner ID and API Key

**Dashboard Features:**
- Total redemptions
- Total discount amount
- Unique members
- Redemptions by day (chart)
- Top members
- Date range filtering

### Regular Check-ins

- **Week 1**: Check in to ensure everything is working
- **Month 1**: Review analytics and gather feedback
- **Quarterly**: Review partnership and discuss improvements

### Support Channels

- **Email**: partners@soteria.app
- **Dashboard**: In-app support (future)
- **Documentation**: Integration guide and FAQ

---

## Troubleshooting

### Common Issues

**Issue: Partner can't validate members**
- Check partner_id is correct
- Verify API endpoint URL
- Check network connectivity
- Review error logs

**Issue: Discount not applying**
- Verify discount_percentage is set correctly
- Check partner's discount calculation logic
- Ensure validation returns `valid: true`

**Issue: API key not working**
- Verify API key is correct
- Check if key was regenerated
- Contact support to reset key

**Issue: Redemption limit reached**
- Check `max_redemptions_per_user` setting
- Verify redemption count in dashboard
- Consider increasing limit if needed

---

## Partner Management

### Updating Partner Information

```bash
# Update partner via DynamoDB
aws dynamodb update-item \
  --table-name soteria-partners \
  --key '{"partner_id": {"S": "partner-acme"}}' \
  --update-expression "SET discount_percentage = :dp, updated_at = :now" \
  --expression-attribute-values '{
    ":dp": {"N": "15"},
    ":now": {"S": "2026-01-03T12:00:00Z"}
  }' \
  --region us-east-1
```

### Deactivating Partner

```bash
# Set is_active to false
aws dynamodb update-item \
  --table-name soteria-partners \
  --key '{"partner_id": {"S": "partner-acme"}}' \
  --update-expression "SET is_active = :ia, updated_at = :now" \
  --expression-attribute-values '{
    ":ia": {"BOOL": false},
    ":now": {"S": "2026-01-03T12:00:00Z"}
  }' \
  --region us-east-1
```

### Regenerating API Key

1. Generate new API key
2. Hash and store in `soteria-partner-api-keys` table
3. Send new key to partner securely
4. Partner updates their integration

---

## Resources

### Documentation
- **Integration Guide**: `PARTNER_INTEGRATION_GUIDE.md`
- **API Reference**: See integration guide
- **Architecture**: `PARTNER_INTEGRATION_OPTIONS.md`

### Tools
- **Partner Registration**: `deploy-partner-registration.sh`
- **Test Scripts**: `test-partner-apis.sh`
- **Dashboard**: `partner-dashboard/index.html`

### Support
- **Email**: partners@soteria.app
- **Dashboard**: https://partners.soteria.app (or hosted location)

---

## Quick Reference

### API Endpoints

- **Register Partner**: `POST /soteria/partner/register`
- **Validate Member**: `POST /soteria/partner/validate-member`
- **Record Redemption**: `POST /soteria/partner/redeem`
- **Get Analytics**: `GET /soteria/partner/analytics`
- **List Partners**: `GET /soteria/partner/list`

### DynamoDB Tables

- **soteria-partners**: Partner information
- **soteria-partner-redemptions**: Redemption history
- **soteria-partner-api-keys**: API key storage (hashed)
- **soteria-partner-scans**: Scan analytics

---

**Last Updated:** January 2026  
**Version:** 1.0

