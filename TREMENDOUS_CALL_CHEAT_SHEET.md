# 🎯 Tremendous Call Cheat Sheet - Wednesday, Jan 14

**Quick reference for your call with Tremendous**

---

## 📱 About Soteria

**Elevator Pitch:**
> "Soteria is a savings app that gamifies saving money. Users earn loyalty points when they save (10 points per $1 saved). We want to let Premium users redeem those points for real gift cards via Tremendous. We have 1,000+ beta users, launching gift card redemption in Q1 2026."

**Our Point Economics:**
- User saves $1 → Earns 10 points
- 500 points = $1 gift card value
- User must save $50 to earn a $1 gift card (2% reward rate)

**Monthly Caps (Fraud Prevention):**
- Premium users ($7.99/mo): $250/month redemption cap
- Tier 2 users ($14.99/mo): $500/month redemption cap

**Gift Cards We Want:**
- Amazon ($5, $10, $25, $50, $100)
- Visa Prepaid ($5, $10, $25, $50, $100)
- Target ($5, $10, $25, $50, $100)
- Walmart ($5, $10, $25, $50, $100)
- Starbucks ($5, $10, $25)

---

## ❓ Top 10 Questions for Tremendous

### 🔧 Technical Questions

**1. Product IDs**
```
❓ What are the exact product IDs for our cards?
   - Is it "AMAZON" or "AMAZON_GIFT_CARD"?
   - Can we programmatically list products by denomination?
   - Do denominations matter for product ID, or just brand?
   
💡 Why: Need to map our GiftCard.tremendousCampaignId
```

**2. Funding & Billing**
```
❓ What's the best funding method for startups?
   - Pre-funded balance vs. invoice vs. credit card?
   - Minimum balance requirements?
   - How do we get notified when balance is low?
   
💡 Why: Need to set up production billing
```

**3. API Rate Limits**
```
❓ What are your rate limits?
   - Per second? Per minute?
   - What happens if we exceed?
   - Retry-After headers?
   
💡 Why: Planning for scale (1,000+ users)
```

**4. Error Handling**
```
❓ What error codes should we handle?
   - Insufficient balance?
   - Invalid product?
   - Email delivery failure?
   
💡 Why: Building robust error handling
```

**5. Webhooks**
```
❓ What webhook events do you send?
   - Reward delivered?
   - Reward redeemed by user?
   - Delivery failed?
   
💡 Why: Need delivery confirmation
```

---

### 💰 Business Questions

**6. Pricing Confirmation**
```
❓ Confirm: Face value only, no fees?
   - $5 gift card costs us exactly $5?
   - No transaction fees?
   - No monthly minimums or setup fees?
   
💡 Why: Economics must work with $7.99/mo subscription
```

**7. Volume Discounts**
```
❓ Are volume discounts available?
   - At what volume?
   - How much discount?
   
💡 Why: Planning for growth
```

**8. Production Access**
```
❓ What's required for production approval?
   - KYC/compliance documents?
   - Business verification?
   - Timeline estimate?
   
💡 Why: Want to launch ASAP
```

**9. Fraud Prevention**
```
❓ What fraud prevention do you recommend?
   - Velocity limits?
   - Email verification?
   - IP blocking?
   
💡 Why: Our users could game the system
```

**10. Support & SLA**
```
❓ What support do we get?
   - Response time for issues?
   - API uptime SLA?
   - Dedicated account manager?
   
💡 Why: Mission-critical for user trust
```

---

## 🎯 What We Need from the Call

### Must-Haves
- ✅ Sandbox API key location (if we couldn't find it)
- ✅ Exact product ID list for our 5 brands
- ✅ Funding setup instructions
- ✅ Production access requirements & timeline

### Nice-to-Haves
- 📚 Sample code / SDK for Node.js
- 📋 Best practices guide
- 🤝 Introduction to support team
- 📊 Dashboard tour

---

## 📝 Notes to Share with Tremendous

**Our Tech Stack:**
- Frontend: iOS app (Swift/SwiftUI)
- Backend: AWS Lambda (Node.js) + API Gateway
- Auth: AWS Cognito (JWT tokens)
- Database: DynamoDB
- Already built: Full loyalty points system + UI

**Our Integration Plan:**
```
User redeems → iOS app → API Gateway (JWT auth) 
→ Lambda validates → Tremendous API → Email to user
```

**Timeline:**
- Now: Sandbox testing
- Jan 15-24: Backend development
- Jan 27-31: Production deployment
- Feb 1: Launch! 🚀

**Current Status:**
- ✅ Loyalty system built
- ✅ Gift card UI designed
- ✅ Premium gating implemented
- ⏳ Backend Lambda in progress
- ⏳ Waiting for Tremendous sandbox testing

---

## 🚀 After the Call Action Items

- [ ] Update `PRODUCT_MAP` in Lambda with correct product IDs
- [ ] Set up production funding source
- [ ] Request production API access
- [ ] Test sandbox with real API calls
- [ ] Schedule follow-up if needed

---

## 💡 Pro Tips for the Call

1. **Have your sandbox account open** - screen share if needed
2. **Take notes** - especially product IDs and setup instructions
3. **Ask for documentation links** - don't rely on memory
4. **Get a direct contact** - for urgent issues post-launch
5. **Mention timeline** - creates urgency for production access

---

## 📞 Call Details

**Date:** Wednesday, January 14, 2026  
**Time:** [ADD YOUR TIME]  
**Platform:** [Zoom? Phone? Teams?]  
**Attendees:**  
- Soteria: [Your name]
- Tremendous: [Their team]

**Backup Contact:**
- Tremendous Support: support@tremendous.com
- Tremendous Sales: sales@tremendous.com

---

## 🎉 Good Luck!

You're well-prepared. Your loyalty system is already built, your UI is beautiful, and you have a clear integration plan. This call is just about confirming technical details!

**Remember:**
- You're a customer they want to work with
- Your questions show you've done your homework
- Don't hesitate to ask for clarification

**You've got this!** 💪
