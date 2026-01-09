# Plaid Call - Updated Focus (Final)

**Call in ~5 minutes**  
**Status:** OAuth handled during call ✅ | Pricing is main concern 💰

---

## 🎯 **TOP 3 PRIORITIES**

### **#1 - PRICING ($1,000/month)**
> "What does the $1,000/month cover, and do you have a Launch tier for startups?"

**Why critical:** $12,000/year is a major cost for early stage  
**Goal:** Negotiate to $200-500/month Launch tier or get startup credits  
**Write down:** Full pricing breakdown, what's included, when billing starts

---

### **#2 - OAUTH (Will complete today ✅)**
> "I understand OAuth is part of onboarding. What's the timeline after submission?"

**Why important:** Determines when Chase, Wells Fargo, BofA are available  
**Good news:** They'll handle submission during this call  
**Write down:** Approval timeline (2-4 weeks), which banks available immediately  
**Materials needed:** App name, logo, privacy policy URL

---

### **#3 - PRODUCTION CREDENTIALS**
> "Can we get Production credentials today and start testing?"

**Why important:** Need these to deploy  
**Goal:** Walk out with Client ID and Secret  
**Write down:** Copy Production Client ID and Secret from Dashboard

---

## 📝 **QUICK INFO TO HAVE READY**

**For OAuth Registration:**
- **App Name:** Soteria
- **App Description:** "Soteria helps users achieve savings goals through automated saving. Users connect bank accounts to track deposits and monitor progress."
- **Company Name:** Your LLC name
- **Privacy Policy URL:** Your URL (or say "in progress")
- **Support Email:** support@yourapp.com (or your email)
- **Redirect URI:** Ask them format - probably `soteria://oauth-callback`

---

## 💰 **PRICING NEGOTIATION SCRIPT**

> "I'm excited to work with Plaid, but I need to be transparent: we're an early-stage startup, and $1,000/month is significant before we have revenue. 
>
> Do you have a Launch tier or startup program that scales with our growth? 
>
> We're committed to growing with Plaid long-term - we just need pricing that aligns with our stage."

**Key phrases:**
- "Early-stage startup" 
- "Committed long-term"
- "Scales with growth"
- "What options do you have?"

---

## ✅ **WHAT TO EXPECT ON THE CALL**

### **Plaid will probably:**
1. ✅ Walk through dashboard setup
2. ✅ Enable Unit integration
3. ✅ Submit OAuth registration for you
4. ✅ Provide Production credentials
5. ✅ Explain pricing options
6. ✅ Answer your questions

### **You should:**
1. ✅ Ask about Launch tier pricing first
2. ✅ Provide OAuth materials (app name, etc.)
3. ✅ Copy Production Client ID and Secret
4. ✅ Confirm Unit integration enabled
5. ✅ Ask about timeline for major banks
6. ✅ Get support contact info

---

## 📋 **CHECKLIST TO COMPLETE DURING CALL**

- [ ] **Pricing:** Clarified pricing tier and monthly cost
- [ ] **OAuth:** Submitted with your app details
- [ ] **Production Keys:** Copied Client ID and Secret
- [ ] **Unit Integration:** Confirmed enabled in Dashboard
- [ ] **Support:** Got support email/Slack contact
- [ ] **Timeline:** Know when major banks will be available
- [ ] **Billing:** Know when charges start

---

## 🚀 **AFTER THE CALL (15 minutes)**

1. **Update Lambda environment variables:**
   ```bash
   PLAID_ENV=production
   PLAID_CLIENT_ID=<from-call>
   PLAID_SECRET=<from-call>
   ```

2. **Test in Sandbox first** (with Production credentials)

3. **Deploy to Production** when ready

4. **Wait 2-4 weeks** for major banks (OAuth approval)

5. **Soft launch** with available banks immediately

---

## 💡 **KEY INSIGHTS**

### **Good News:**
✅ OAuth handled on this call (not a separate blocker)  
✅ Can soft launch immediately with some banks  
✅ Production credentials available today  
✅ Full integration already built  

### **Main Concern:**
💰 $1,000/month pricing - negotiate for Launch tier!

### **Timeline:**
```
TODAY: Get credentials, submit OAuth
THIS WEEK: Deploy to Production, soft launch
WEEK 2-4: Major banks approved (Chase, Wells, BofA)
WEEK 4+: Full launch with all banks
```

---

## 🎯 **SUCCESS = Walking Away With:**

1. ✅ **Pricing:** $500/month or less (or startup credits)
2. ✅ **OAuth:** Submitted, 2-4 week timeline confirmed
3. ✅ **Credentials:** Production Client ID and Secret
4. ✅ **Support:** Contact for Production issues
5. ✅ **Clarity:** Know which banks available now vs later

---

## 📞 **OPENING STATEMENT**

> "Hi! Thanks for the call. I'm excited to get Plaid integrated with our savings app. We've already built our Sandbox integration with Lambda endpoints, so we're ready to move to Production.
>
> Before we dive in, I want to clarify pricing - I see $1,000/month for support. Do you have a Launch tier for early-stage startups? We'd like to align costs with our growth curve.
>
> Also, I understand OAuth registration is part of this call, so I have our app details ready to provide."

**This sets the right tone:** Professional, prepared, but cost-conscious

---

## ⏰ **TIME CHECK**

**Call starting soon!** 

**Have open:**
- ✅ This document (PLAID_CALL_FOCUS.md)
- ✅ Plaid Dashboard (to navigate together)
- ✅ Notepad (to write down credentials)

**Ready to ask:**
1. Pricing / Launch tier options
2. OAuth timeline after submission
3. Which banks available immediately

---

**You've got this!** 🚀

**Remember:** They WANT your business. Don't be afraid to negotiate pricing! 💪
