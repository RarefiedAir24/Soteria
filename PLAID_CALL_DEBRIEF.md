# Plaid Call - Debrief & Next Steps

**Date:** Today  
**Status:** Initial discussion complete, contract signing required

---

## 📝 **What You Learned**

### **Process Timeline:**
```
1. Sign contract (THIS WEEK)
   ↓
2. Onboarding call (NEXT WEEK)
   ↓
3. Go live (MARCH)
   ↓
4. First bill (APRIL) - $1,000
```

### **Key Points:**
✅ **No onboarding until contract signed** - Need to review and sign agreement first  
✅ **Billing starts at launch** - First $1,000 bill in April (not immediate)  
✅ **Target launch: March** - ~6-8 weeks from now  
✅ **Unit costs unknown** - Still need to discuss Unit pricing  

---

## 🚨 **CRITICAL: Total Cost Analysis Needed**

### **Known Costs:**
```
Plaid: $1,000/month = $12,000/year
Unit:  $???/month = $???/year
──────────────────────────────────
TOTAL: $1,000+ /month minimum
```

**You need Unit pricing BEFORE signing anything!**

---

## 🎯 **IMMEDIATE ACTION ITEMS**

### **URGENT (This Week):**

#### **1. Review Plaid Contract** 🔍
- [ ] **Read the entire contract** - Don't sign blindly
- [ ] **Look for:**
  - Monthly commitment ($1,000/month confirmed?)
  - Annual commitment (can you cancel monthly?)
  - Rate limits (API calls per month)
  - Overage fees (what if exceed limits?)
  - Contract length (month-to-month or annual?)
  - Cancellation terms (can you cancel if it doesn't work out?)
  - Price increases (can they raise prices?)
  - Support SLA (what response times are guaranteed?)

#### **2. Talk to Unit IMMEDIATELY** 📞
- [ ] **Schedule call with Unit rep**
- [ ] **Questions to ask:**
  - What's your monthly pricing?
  - Any per-transaction fees?
  - Per-account fees?
  - Minimum commitments?
  - When does billing start?
  - Any setup or onboarding fees?
  - What's included in base price?

#### **3. Calculate Total Cost of Integration** 💰

**Need to know TOTAL monthly cost:**
```
Plaid:    $1,000/month
Unit:     $___/month (GET THIS!)
AWS:      $50-200/month (estimate)
Other:    $___/month
─────────────────────────
TOTAL:    $1,050+ /month minimum

Per Year: $12,600+ /year
```

**Ask yourself:** Can we afford this? Will users pay enough?

#### **4. Unit Economics Check** 📊

**Example calculation:**
```
Total costs: $1,500/month (Plaid + Unit + AWS)
Users needed: ?
Revenue per user: $?

If $10/month per user:
→ Need 150 paying users just to break even

If $5/month per user:
→ Need 300 paying users just to break even
```

**Critical question:** Is this financially viable?

---

## 📋 **CONTRACT REVIEW CHECKLIST**

### **Before Signing, Verify:**

**Pricing:**
- [ ] Monthly fee clearly stated: $______/month
- [ ] No hidden fees or overages
- [ ] Billing starts: ______ (April confirmed?)
- [ ] Can I see a sample invoice?

**Commitment:**
- [ ] Contract length: ☐ Month-to-month ☐ Annual ☐ Other: ______
- [ ] Can I cancel? Notice period: ______
- [ ] Early termination fee? Amount: ______
- [ ] Auto-renewal terms: ______

**Limits:**
- [ ] API calls per month: ______
- [ ] Linked accounts limit: ______
- [ ] What happens if exceed: ______
- [ ] Can I upgrade/downgrade: ______

**Support:**
- [ ] Response time SLA: ______
- [ ] Support channels: ☐ Email ☐ Slack ☐ Phone
- [ ] Dedicated contact? ☐ Yes ☐ No
- [ ] After-hours support? ☐ Yes ☐ No

**Legal:**
- [ ] Liability caps: ______
- [ ] Data ownership: ______
- [ ] Security requirements: ______
- [ ] Compliance obligations: ______

**Red Flags to Watch For:**
- 🚩 Annual commitment without trial period
- 🚩 Hefty early termination fees
- 🚩 Auto-renewal without notification
- 🚩 Unlimited price increase clause
- 🚩 No SLA guarantees

---

## 🔄 **UNIT PRICING DISCUSSION - PREP**

### **Questions for Unit:**

**Base Pricing:**
1. "What's your monthly platform fee?"
2. "Are there different tiers (Launch, Scale, Enterprise)?"
3. "Do you have startup pricing or credits?"
4. "When does billing start?"

**Per-Transaction Fees:**
5. "What are your ACH transfer fees?"
6. "Incoming vs outgoing transfer costs?"
7. "Any monthly minimums?"
8. "Volume discounts available?"

**Account Fees:**
9. "Cost per deposit account?"
10. "Cost per customer/application?"
11. "Monthly account maintenance fees?"
12. "Dormant account fees?"

**Other Fees:**
13. "Card issuance fees?" (if applicable)
14. "Statement/report fees?"
15. "API call fees?"
16. "Support fees?"

**Plaid Integration:**
17. "Any discounts for Plaid+Unit partnership?"
18. "Additional fees for Plaid processor tokens?"

---

## 💰 **TYPICAL UNIT PRICING (Industry Estimate)**

**Based on similar platforms:**
```
Platform Fee:     $500-2,000/month
Per Account:      $1-5/month per active account
ACH Transfers:    $0.20-0.50 per transaction
Account Opening:  $2-10 per account opened
Plaid Integration: Usually included (no extra fee)

Example Monthly Cost (100 users):
├─ Platform fee:      $1,000
├─ 100 accounts:      $300 (at $3/account)
├─ 200 ACH transfers: $60 (at $0.30/transfer)
└─ TOTAL:             $1,360/month for Unit

COMBINED (Plaid + Unit):
$1,000 (Plaid) + $1,360 (Unit) = $2,360/month
```

**This is just an estimate - GET REAL NUMBERS FROM UNIT!**

---

## 🎯 **DECISION MATRIX**

### **Should You Sign with Plaid?**

| Total Monthly Cost | Viable? | Action |
|-------------------|---------|--------|
| **$1,000-1,500** (Plaid + low Unit fees) | ✅ Maybe | Proceed if unit economics work |
| **$1,500-2,500** (Plaid + moderate Unit fees) | ⚠️ Tight | Need strong pricing model |
| **$2,500+** (Plaid + high Unit fees) | 🚩 High risk | Consider alternatives |

### **Unit Economics Must Work:**
```
Monthly Costs: $______
÷ Expected Users: ______
= Cost per user: $______

Your pricing: $______/user
- Cost per user: $______
= Profit per user: $______

Break-even users: ______
Target users month 1: ______
Time to profitability: ______ months
```

**If profit per user is negative or break-even is >1 year away, RECONSIDER!**

---

## ⚠️ **ALTERNATIVE CONSIDERATIONS**

### **If Total Costs Too High, Consider:**

**Option 1: Defer Plaid**
- Start with manual ACH (Unit direct)
- Users enter account/routing numbers
- Add Plaid later when you have revenue
- **Saves:** $1,000/month initially

**Option 2: Alternative to Plaid**
- Yodlee (similar pricing)
- MX (similar pricing)
- Finicity (may be cheaper)
- Teller (newer, potentially cheaper)
- **Research:** Get quotes before committing

**Option 3: Different Unit Alternative**
- Synapse (similar to Unit)
- Treasury Prime (similar to Unit)
- Column (newer, potentially simpler)
- **Research:** Compare all-in costs

**Option 4: Delay Launch**
- Build more features first
- Wait until more funding secured
- Launch when costs are more manageable
- **Risk:** Lose momentum

---

## 📅 **REVISED TIMELINE**

### **This Week (Before Signing):**
- [ ] **Day 1-2:** Get Unit pricing (URGENT!)
- [ ] **Day 3:** Review Plaid contract thoroughly
- [ ] **Day 4:** Calculate total costs + unit economics
- [ ] **Day 5:** Make go/no-go decision
- [ ] **Day 6-7:** Sign contract (if proceeding) OR negotiate alternatives

### **Next Week (After Signing):**
- [ ] Plaid onboarding call
- [ ] Complete OAuth registration
- [ ] Get Production credentials
- [ ] Set up billing

### **February:**
- [ ] Deploy to Production
- [ ] Internal testing
- [ ] Beta user testing
- [ ] Fix any issues

### **March:**
- [ ] Public launch
- [ ] Marketing push
- [ ] User onboarding

### **April:**
- [ ] First Plaid bill ($1,000)
- [ ] First Unit bill ($???)
- [ ] Evaluate actual costs vs projections

---

## 🚨 **RED FLAGS / WARNING SIGNS**

### **Don't Sign If:**
- ❌ Haven't talked to Unit about pricing yet
- ❌ Unit economics don't work (can't break even)
- ❌ Contract has annual commitment with no trial
- ❌ Can't afford 3-6 months of costs before revenue
- ❌ Have doubts about product-market fit

### **Proceed If:**
- ✅ Understand total costs (Plaid + Unit + AWS)
- ✅ Unit economics work (reasonable path to profitability)
- ✅ Contract is month-to-month or has reasonable cancellation
- ✅ Have runway to cover 3-6 months of costs
- ✅ Confident in product and market

---

## 📞 **EMAIL TO SEND TODAY**

### **To Unit Rep:**

```
Subject: Urgent: Pricing Discussion Needed Before Plaid Contract

Hi [Unit Rep],

We just spoke with Plaid about integrating their service with Unit 
for our savings app. They've proposed $1,000/month and we're ready 
to sign, but we need to understand our total integration costs first.

Can we schedule a call THIS WEEK to discuss Unit pricing? Specifically:

1. Monthly platform fees
2. Per-account fees
3. ACH transfer fees
4. Any other costs we should be aware of

We're targeting a March launch and need to finalize our vendor 
agreements this week. 

Are you available for a 30-minute call in the next 2 days?

Thanks!
[Your Name]
```

---

## 💡 **KEY INSIGHTS**

### **Good News:**
✅ **Billing delayed until April** - Gives you time to launch and get users  
✅ **Launch timeline clear** - March target is achievable  
✅ **Not paying immediately** - Can deploy and test before first bill  

### **Concerns:**
💰 **$1,000/month is significant** - Need to ensure unit economics work  
❓ **Unit costs unknown** - Could be another $500-2,000/month  
📄 **Contract not reviewed** - Need to read fine print before signing  

### **Critical Path:**
```
1. GET UNIT PRICING (this week!)
2. Calculate total monthly cost
3. Verify unit economics work
4. Review Plaid contract thoroughly
5. THEN decide whether to sign
```

---

## 🎯 **SUCCESS CRITERIA**

### **Before Signing Plaid Contract, Confirm:**

- [ ] ✅ Know exact Unit monthly cost
- [ ] ✅ Total cost (Plaid + Unit) is affordable
- [ ] ✅ Unit economics show path to profitability
- [ ] ✅ Contract terms are reasonable (month-to-month preferred)
- [ ] ✅ Understand all fees and limits
- [ ] ✅ Have 3-6 months runway to cover costs
- [ ] ✅ Confident in March launch timeline

**If you can't check all boxes, DON'T SIGN YET!**

---

## 🚀 **NEXT STEPS (Priority Order)**

### **#1 - URGENT (Today/Tomorrow):**
📞 **Schedule Unit pricing call** - Can't proceed without this

### **#2 - IMPORTANT (This Week):**
📄 **Request Plaid contract** - Need to review before signing  
💰 **Calculate total costs** - Plaid + Unit + AWS  
📊 **Validate unit economics** - Does the math work?

### **#3 - DECISION (End of Week):**
✅ **Sign Plaid contract** - If economics work  
OR  
⏸️ **Delay signing** - If costs too high or need more info  
OR  
🔄 **Negotiate alternatives** - Different pricing/vendors

---

## 📝 **QUESTIONS YOU STILL NEED ANSWERED**

**For Plaid (before signing):**
1. Can I see the actual contract?
2. Is it month-to-month or annual commitment?
3. What's the cancellation policy?
4. Are there API rate limits?
5. What happens if we exceed limits?

**For Unit (URGENT):**
1. What's your monthly platform fee?
2. What are per-account fees?
3. What are ACH transfer fees?
4. Any setup or minimum fees?
5. When does billing start?

**For Yourself:**
1. Can we afford $1,000-2,500/month for 3-6 months?
2. What do we need to charge users to be profitable?
3. How many users do we need to break even?
4. Is March launch realistic?
5. Do we have the runway for this?

---

## 🎯 **BOTTOM LINE**

**Don't sign anything until you:**
1. ✅ Get Unit pricing
2. ✅ Calculate total costs
3. ✅ Verify unit economics
4. ✅ Review contract thoroughly

**Timeline is OK:**
- This week: Due diligence
- Next week: Onboarding (if signed)
- March: Launch
- April: First bill

**This is a $15,000-30,000/year commitment!** Take time to get it right! 💰

---

**URGENT ACTION:** Contact Unit TODAY for pricing discussion! 📞
