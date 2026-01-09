# Plaid Production Access - Call Prep Guide

**Call Time:** 20 minutes  
**Status:** Production access granted ✅

---

## 🎯 **Critical Questions to Ask**

### **🚨 0. PRICING - $1,000/Month Support Fee (ASK FIRST!)**
- [ ] **Q:** "I see there's a $1,000/month fee for app support. Can you break down exactly what this covers?"
- [ ] **Q:** "Is this fee required for Production access, or is it optional?"
- [ ] **Q:** "Are there other pricing tiers or support plans for early-stage startups or lower volumes?"
- [ ] **Q:** "When does billing start? Is it from today, or from when we go live with users?"
- [ ] **Q:** "What's included in this support: response time SLAs, dedicated support contact, implementation help?"
- [ ] **Q:** "Are there any other fees beyond this: per-transaction fees, API call fees, or minimum usage requirements?"
- [ ] **Q:** "What happens if we don't purchase this support plan? Do we still get basic support for Production issues?"
- [ ] **Annual Impact:** $12,000/year - Need to factor into business model
- [ ] **Alternatives:** Ask about Launch, Scale, or other tier options

**CRITICAL:** This is a major ongoing cost. Need clarity on what you're paying for and if it's required.

### **🚨 1. OAuth Registration (Part of Onboarding - ✅ Will Complete Today!)**
- [ ] **Q:** "I understand OAuth registration is part of this onboarding call. Can we complete that today?"
- [ ] **Q:** "What's the timeline for bank approval after we submit OAuth registration?"
- [ ] **Q:** "Which banks will be available immediately vs which require the 2-4 week approval?"
- [ ] **Q:** "What materials do you need from us: app name, logo, privacy policy URL?"
- [ ] **Q:** "Can we test OAuth flow in Sandbox while waiting for Production approval?"
- [ ] **Expected Timeline:** OAuth submitted today, banks approve in 2-4 weeks
- [ ] **Action:** Provide app details during call for OAuth submission

**GOOD NEWS:** OAuth registration will be handled during this call as part of standard onboarding!

### **1. Dashboard Checklist (Ask First!)**
- [ ] **Q:** "The dashboard shows '0 of 4 complete' for basic setup. We've already completed our Sandbox integration with working iOS app and Lambda endpoints. Can we skip the Quickstart checklist and just verify our Production configuration?"
- [ ] **Expected Answer:** Yes, you can skip it if your Sandbox integration is working
- [ ] **Clarify:** "What from that checklist, if anything, do we need to complete for Production?"

### **1. Unit Integration**
- [ ] **Q:** "Is the Unit integration enabled for our Production environment?"
- [ ] **Q:** "Do we need to do anything special to activate Unit in Production, or is it automatic?"
- [ ] **Expected Answer:** Should be enabled automatically if requested during signup

### **2. Credentials & Access**
- [ ] **Q:** "Can you confirm our Production Client ID and Secret are active?"
- [ ] **Q:** "Where do we find our Production credentials?" (Should be in Dashboard → Keys)
- [ ] **Q:** "Is there a separate webhook URL we should configure for Production?"

### **3. Account Select Configuration**
- [ ] **Q:** "We need Account Select set to 'one account' for Unit integration - is this configured in Production?"
- [ ] **Confirm:** Dashboard → Link Customization → Account Select = "enabled for one account"

### **4. Application Profile**
- [ ] **Q:** "Is our Application Profile complete for Production? Are there any additional fields needed?"
- [ ] **Check:** Team Settings → Application Profile

### **5. Rate Limits & Volume**
- [ ] **Q:** "What are our Production rate limits?"
- [ ] **Q:** "Are there any usage quotas or limits we should be aware of?"
- [ ] **Q:** "Do we need to notify you before going live or hitting certain volume thresholds?"

### **6. Testing & Validation**
- [ ] **Q:** "Can we test Production credentials in Sandbox first, or do we need to test with real banks immediately?"
- [ ] **Q:** "Are there recommended test banks or accounts for initial Production testing?"
- [ ] **Q:** "What's the approval process for going live with users?"

### **7. Webhooks & Monitoring**
- [ ] **Q:** "Should we configure Production webhooks differently than Sandbox?"
- [ ] **Q:** "What webhook events should we monitor for Unit integration?"
- [ ] **Q:** "Do you have recommended CloudWatch/monitoring best practices?"

### **8. Support & Escalation**
- [ ] **Q:** "What's the support process for Production issues?"
- [ ] **Q:** "Do we have a dedicated Slack channel or support contact?"
- [ ] **Q:** "What's the typical response time for Production support tickets?"

---

## 📋 **Information to Collect**

### **💰 CRITICAL - Pricing:**
1. **Monthly Fee:** $`______________________________` (Is $1,000 required?)
2. **Pricing Tier:** ☐ Launch ☐ Scale ☐ Enterprise ☐ Custom
3. **Per-transaction fees:** $`______________________________`
4. **Other fees:** `______________________________`
5. **Billing start date:** `______________________________`
6. **Support included:** `______________________________`
7. **Annual commitment required:** ☐ Yes ☐ No
8. **Startup credits available:** ☐ Yes ☐ No → Amount: `______________________________`
9. **Can negotiate to Launch tier:** ☐ Yes ☐ No

### **🚨 CRITICAL - OAuth Status:**
10. **OAuth Registration Status:** ☐ Approved ☐ Pending ☐ Not Submitted
11. **OAuth Approval Timeline:** `______________________________`
12. **Available Banks (without OAuth):** `______________________________`
13. **OAuth Submission URL:** Dashboard → `______________________________`
14. **Required Materials:** `______________________________`

### **Write Down:**
15. **Production Client ID:** `______________________________`
16. **Production Secret:** `______________________________` (don't share this)
17. **Production Webhook URL:** `______________________________`
18. **Support Email/Slack:** `______________________________`
19. **Rate Limits:** `______________________________`
20. **Go-Live Checklist:** (ask if they have one)

---

## ✅ **Configuration Checklist (Ask Plaid to Verify)**

### **Dashboard Settings:**
- [ ] **Integrations → Unit** = Enabled
- [ ] **Link Customization → Account Select** = "enabled for one account"
- [ ] **Link Customization → Products** = Auth (confirm)
- [ ] **Team Settings → Application Profile** = Complete
- [ ] **Keys** = Production credentials visible

### **Environment Settings:**
- [ ] **Sandbox** = Working (we can test this)
- [ ] **Production** = Active and ready

---

## 🚀 **Post-Call Action Items**

### **🚨 MOST URGENT (Today - Same Day as Call):**
1. [ ] **Submit OAuth Registration** (if not already approved)
   - Go to Dashboard → Compliance Center
   - Fill out OAuth registration form
   - Upload: App logo, privacy policy, app description
   - Provide: App name, support email, redirect URI
   - Submit for review (2-4 week timeline)

### **Immediate (Today):**
2. [ ] Update Lambda environment variables with Production credentials
   ```bash
   PLAID_ENV=production
   PLAID_CLIENT_ID=<production_id>
   PLAID_SECRET=<production_secret>
   ```

3. [ ] Test Production credentials in Sandbox environment first (if possible)

4. [ ] Update iOS app configuration
   ```swift
   // Update PlaidService.swift
   let plaidEnvironment = .production // Change from .sandbox
   ```

### **This Week:**
4. [ ] Create Production webhook endpoint if needed
5. [ ] Test with real bank account (yours or test user)
6. [ ] Verify processor token creation works in Production
7. [ ] Verify Unit counterparty creation works with Production token
8. [ ] Set up CloudWatch alarms for Production Lambda errors

### **Before Public Launch:**
9. [ ] Complete full end-to-end test with real bank
10. [ ] Verify Unit Production credentials are active
11. [ ] Test error handling (wrong password, etc.)
12. [ ] Load test with multiple accounts
13. [ ] Review Plaid's go-live checklist (ask if they have one)

---

## 🔧 **Technical Details to Clarify**

### **Processor Token Creation:**
- [ ] **Confirm:** We're using `processor: 'unit'` in Production
- [ ] **Ask:** "Is there any difference in how processor tokens work in Production vs Sandbox?"
- [ ] **Ask:** "Do processor tokens expire? If so, what's the TTL?"

### **Unit Integration:**
- [ ] **Ask:** "Does Unit need to approve our Production integration on their end?"
- [ ] **Ask:** "Is there a separate Unit Production API URL we should use?"
- [ ] **Current Unit URLs:**
  - Sandbox: `https://api.s.unit.sh`
  - Production: `https://api.unit.sh`

---

## ⚠️ **Important Notes**

### **Security Reminders:**
- ✅ **Never** commit Production secrets to git
- ✅ **Always** use environment variables
- ✅ **Rotate** secrets if accidentally exposed
- ✅ **Use** separate AWS accounts for Production if possible

### **Testing Approach:**
1. **Phase 1:** Test with your own bank account
2. **Phase 2:** Test with 5-10 beta users
3. **Phase 3:** Soft launch to broader TestFlight
4. **Phase 4:** Full production launch

---

## 📊 **Quick Stats to Share (If Asked)**

**Current Status:**
- ✅ Sandbox integration complete
- ✅ Lambda functions deployed
- ✅ iOS app integrated
- ✅ Unit Sandbox account active
- 🚧 Awaiting Production credentials activation

**Expected Volume:**
- **Initial:** 10-20 users in first month
- **Growth:** 100-500 users in 6 months
- **Use Case:** Savings app with Unit deposit accounts

---

## 🎯 **Key Takeaway Questions**

At the end of the call, confirm:

1. ✅ "So we're clear to use Production credentials starting today?"
2. ✅ "Unit integration is fully enabled in Production?"
3. ✅ "We can test with real bank accounts without any approval needed?"
4. ✅ "If we have issues, we contact [support method] for help?"
5. ✅ "Is there anything else we need to do before going live?"

---

## 📝 **Call Notes Template**

```
Date: [DATE]
Attendees: 
- Plaid: [NAMES]
- Soteria: [YOUR NAME]

Key Points:
- 
- 
- 

Action Items:
- [ ] 
- [ ] 
- [ ] 

Blockers:
- 
- 

Next Steps:
- 
- 
```

---

## 🚀 **After Call - Quick Deploy**

If everything is approved, you can switch to Production in **~15 minutes**:

```bash
# 1. Update Lambda env vars (2 mins)
aws lambda update-function-configuration \
  --function-name soteria-plaid-create-link-token \
  --environment Variables="{PLAID_ENV=production,...}"

# 2. Update iOS constants (1 min)
# Change plaidEnvironment to .production

# 3. Test with real bank (5 mins)
# Connect your own bank account

# 4. Verify logs (2 mins)
# Check CloudWatch for success messages

# 5. Done! ✅
```

---

**Good luck on the call!** 🎉

**Quick Reference:**
- [ ] Unit integration enabled?
- [ ] Account Select = one account?
- [ ] Production credentials ready?
- [ ] Support contact info?
- [ ] Clear to go live?
