# Plaid Call - Quick Reference (Print/Screen Share)

---

## ✅ **MUST CONFIRM**

| Item | Status | Notes |
|------|--------|-------|
| ☐ Unit integration enabled in Production | | |
| ☐ Account Select = "one account" | | |
| ☐ Production Client ID active | | `_______________` |
| ☐ Production Secret active | | `_______________` |
| ☐ Application Profile complete | | |
| ☐ Clear to test with real banks today | | |
| ☐ Support contact for Production issues | | `_______________` |

---

## 🚨 **TOP PRIORITY QUESTION**

### **1. PRICING: $1,000/month Support Fee**
**"I see there's a $1,000/month fee for app support. Can you clarify what this covers and if it's required for Production? Are there Launch or Startup tier options for early-stage companies?"**

- **What it covers:** `_______________________________`
- **Required or optional:** `_______________________________`
- **Alternative tiers (Launch/Startup):** `_______________________________`
- **When billing starts:** `_______________________________`
- **Startup credits available:** `_______________________________`
- **Annual cost:** $12,000+ ← Need to factor into business plan!
- **Can we negotiate lower:** `_______________________________`

---

## ✅ **OAuth - Will Complete During Call**

**"I understand OAuth registration will be completed during this onboarding call. What's the timeline for approval after submission?"**

- **Timeline after submission:** `_______________________________`
- **Which banks available immediately:** `_______________________________`
- **Chase/Wells/BofA approval ETA:** `_______________________________`
- **Materials needed from us:** `_______________________________`

---

## 🎯 **TOP 4 QUESTIONS**

1. **"Dashboard shows '0 of 4 complete' but we've already built Sandbox integration. Can we skip the Quickstart checklist?"**
   - Need: YES confirmation
   - Explain: We have working iOS app + Lambda endpoints

2. **"Is Unit integration fully enabled in Production?"**
   - Need: YES confirmation
   - Check: Dashboard → Integrations → Unit

3. **"Is Account Select configured to 'one account' for Production?"**
   - Need: YES confirmation  
   - Check: Dashboard → Link Customization

4. **"Are we clear to start testing with real bank accounts today?"**
   - Need: YES confirmation
   - Ask: Any approval process needed?

---

## 📋 **INFO TO COLLECT**

**Production Credentials:**
- Client ID: `_______________________________`
- Secret: `_______________________________`
- Webhook URL: `_______________________________`

**Support:**
- Email: `_______________________________`
- Slack: `_______________________________`
- Emergency contact: `_______________________________`

**Limits:**
- Rate limit: `_______________________________`
- Usage quota: `_______________________________`
- Volume restrictions: `_______________________________`

---

## 🚀 **OUR STATUS**

**Completed:**
✅ Sandbox integration working  
✅ Processor token Lambda ready  
✅ Unit counterparty Lambda ready  
✅ iOS app integrated  
✅ Unit Sandbox account active  

**Need from Plaid:**
🔲 Production credentials confirmation  
🔲 Unit integration verification  
🔲 Go-live approval  

---

## ⚡ **CRITICAL CONFIG**

**Must be set in Dashboard:**
```
Integrations → Unit → [ENABLED]
Link Customization → Account Select → [ONE ACCOUNT]
Link Customization → Products → [Auth]
Team Settings → Application Profile → [COMPLETE]
```

---

## 📞 **POST-CALL**

**Immediate:**
- [ ] Update Lambda: `PLAID_ENV=production`
- [ ] Update iOS: `plaidEnvironment = .production`
- [ ] Test with real bank
- [ ] Verify in CloudWatch

**Ready to deploy:** ~15 minutes after call

---

## 🆘 **IF ANYTHING ISN'T READY**

**Ask:** "What's blocking us and how do we resolve it?"  
**Ask:** "How long until we can go live?"  
**Ask:** "Is there a checklist we need to complete?"

---

**Use Case:** Savings app + Unit deposit accounts  
**Expected Volume:** 10-20 users initially, 100-500 in 6mo  
**Integration:** Plaid → Unit processor tokens → ACH funding
