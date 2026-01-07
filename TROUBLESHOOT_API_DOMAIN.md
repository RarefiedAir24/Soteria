# Troubleshooting api.soteria.zone

## Current Status

✅ **Infrastructure is correctly configured:**
- CloudFront Distribution: Deployed (E2208NPSBT76U6)
- Portal: Available and serving content
- Route 53: Points to CloudFront
- SSL Certificate: Configured
- S3 Bucket Policy: Fixed

## If You See "Not Available" or No Content

### Quick Test

**Test CloudFront directly (bypasses DNS):**
```
https://d156yc2pgirgp4.cloudfront.net/
```

If this works, the infrastructure is correct and it's a DNS/cache issue.

### Solutions

#### 1. Clear Browser Cache
- **Chrome**: Cmd+Shift+Delete (Mac) or Ctrl+Shift+Delete (Windows)
- **Safari**: Cmd+Option+E
- **Firefox**: Cmd+Shift+Delete
- Or use **Incognito/Private window**

#### 2. Hard Refresh
- **Mac**: Cmd+Shift+R
- **Windows**: Ctrl+Shift+R
- **Mobile**: Clear browser cache in settings

#### 3. Clear Local DNS Cache (Mac)
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

#### 4. Wait for Propagation
- DNS propagation: 5-15 minutes
- SSL certificate propagation: 15-30 minutes
- CloudFront edge cache: 5-10 minutes

**Total wait time: 15-30 minutes after setup**

### Verify Setup

```bash
# Check CloudFront status
./check-cloudfront-status.sh

# Test CloudFront directly
curl https://d156yc2pgirgp4.cloudfront.net/

# Check DNS
dig api.soteria.zone @8.8.8.8
```

### Expected Behavior

**Once fully propagated:**
- `https://api.soteria.zone/` → Developer Portal
- `https://api.soteria.zone/soteria/partner/list` → API endpoint

### If Still Not Working After 30 Minutes

1. **Check browser console** (F12) for errors
2. **Test from different network** (mobile data, different WiFi)
3. **Verify Route 53 record**:
   ```bash
   aws route53 list-resource-record-sets \
     --hosted-zone-id Z04270822OU4CSQ32HC2P \
     --query "ResourceRecordSets[?Name=='api.soteria.zone.']"
   ```
4. **Check CloudFront status**:
   ```bash
   aws cloudfront get-distribution --id E2208NPSBT76U6 \
     --query 'Distribution.Status'
   ```

### Working URLs (Use These for Now)

- **Portal (CloudFront direct)**: https://d156yc2pgirgp4.cloudfront.net/
- **API (Direct Gateway)**: https://ue1psw3mt3.execute-api.us-east-1.amazonaws.com/prod/soteria/partner/list

---

**Last Updated**: January 2026

