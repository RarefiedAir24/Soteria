# Total Cost Analysis - Plaid + Unit Integration

**Status:** 🚨 **INCOMPLETE** - Need Unit pricing!  
**Decision Needed By:** End of this week (before signing Plaid)

---

## 💰 **MONTHLY COST BREAKDOWN**

### **Known Costs:**
```
┌─────────────────────────────────────────┐
│ PLAID                                   │
│ Monthly Fee:              $1,000        │
│ Per-transaction:          $0 (included) │
│ ─────────────────────────────────────   │
│ PLAID TOTAL:              $1,000/month  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ UNIT (ESTIMATED - GET REAL NUMBERS!)   │
│ Platform Fee:             $___/month    │
│ Per Account:              $___/account  │
│ ACH Transfer:             $___/transfer │
│ Other Fees:               $___          │
│ ─────────────────────────────────────   │
│ UNIT TOTAL:               $???/month    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ AWS (ESTIMATE)                          │
│ Lambda:                   $20/month     │
│ API Gateway:              $20/month     │
│ DynamoDB:                 $30/month     │
│ CloudWatch:               $10/month     │
│ Other:                    $20/month     │
│ ─────────────────────────────────────   │
│ AWS TOTAL:                $100/month    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ OTHER                                   │
│ Domain/hosting:           $10/month     │
│ Email service:            $20/month     │
│ Misc services:            $20/month     │
│ ─────────────────────────────────────   │
│ OTHER TOTAL:              $50/month     │
└─────────────────────────────────────────┘

═════════════════════════════════════════
 GRAND TOTAL:               $1,150+ /month
                            (Unit TBD!)
═════════════════════════════════════════
```

---

## 📊 **SCENARIO PLANNING**

### **Scenario 1: Low Unit Costs** ✅ BEST CASE
```
Plaid:     $1,000/month
Unit:      $500/month (platform + low volume)
AWS:       $100/month
Other:     $50/month
──────────────────────────
TOTAL:     $1,650/month
ANNUAL:    $19,800/year
```

**Viability:** ✅ Manageable for seed-stage startup

### **Scenario 2: Moderate Unit Costs** ⚠️ TYPICAL
```
Plaid:     $1,000/month
Unit:      $1,200/month (platform + moderate volume)
AWS:       $100/month
Other:     $50/month
──────────────────────────
TOTAL:     $2,350/month
ANNUAL:    $28,200/year
```

**Viability:** ⚠️ Tight - need strong revenue model

### **Scenario 3: High Unit Costs** 🚩 WORST CASE
```
Plaid:     $1,000/month
Unit:      $2,000/month (platform + high volume)
AWS:       $150/month
Other:     $50/month
──────────────────────────
TOTAL:     $3,200/month
ANNUAL:    $38,400/year
```

**Viability:** 🚩 Very expensive - need significant revenue

---

## 🎯 **UNIT ECONOMICS**

### **Model 1: $10/month Subscription**

```
┌─────────────────────────────────────────────────────────┐
│ REVENUE PER USER:           $10/month                   │
│ VARIABLE COST PER USER:     $2/month (est.)             │
│ CONTRIBUTION MARGIN:        $8/month                    │
└─────────────────────────────────────────────────────────┘

Break-even Analysis:

Scenario 1 ($1,650/month total cost):
$1,650 ÷ $8 = 207 paying users needed to break even

Scenario 2 ($2,350/month total cost):
$2,350 ÷ $8 = 294 paying users needed to break even

Scenario 3 ($3,200/month total cost):
$3,200 ÷ $8 = 400 paying users needed to break even
```

### **Model 2: $5/month Subscription**

```
┌─────────────────────────────────────────────────────────┐
│ REVENUE PER USER:           $5/month                    │
│ VARIABLE COST PER USER:     $2/month (est.)             │
│ CONTRIBUTION MARGIN:        $3/month                    │
└─────────────────────────────────────────────────────────┘

Break-even Analysis:

Scenario 1 ($1,650/month total cost):
$1,650 ÷ $3 = 550 paying users needed to break even

Scenario 2 ($2,350/month total cost):
$2,350 ÷ $3 = 784 paying users needed to break even

Scenario 3 ($3,200/month total cost):
$3,200 ÷ $3 = 1,067 paying users needed to break even
```

### **Model 3: Freemium with Premium Upsell**

```
┌─────────────────────────────────────────────────────────┐
│ FREE USERS:                 90% (no revenue)            │
│ PREMIUM USERS:              10% at $15/month            │
│ AVG REVENUE PER USER:       $1.50/month                 │
│ VARIABLE COST PER USER:     $2/month (all users)        │
│ CONTRIBUTION MARGIN:        -$0.50/month (NEGATIVE!)    │
└─────────────────────────────────────────────────────────┘

🚩 This model doesn't work! Need higher conversion or pricing.
```

---

## 🚨 **REALITY CHECK**

### **Can You Achieve These User Numbers?**

| Pricing Model | Scenario | Users Needed | Realistic? |
|--------------|----------|--------------|------------|
| $10/month | Best case | 207 users | ✅ Maybe by month 3-4 |
| $10/month | Typical | 294 users | ⚠️ Challenging but possible |
| $10/month | Worst case | 400 users | 🚩 Hard to hit |
| $5/month | Best case | 550 users | ⚠️ Challenging |
| $5/month | Typical | 784 users | 🚩 Very difficult |
| $5/month | Worst case | 1,067 users | ❌ Unrealistic in first 6 months |

### **Timeline to Break-Even:**

**Assumptions:**
- Launch in March with 10 paying users
- 20% month-over-month growth
- $10/month pricing

```
Month 1 (March):    10 users    → -$1,550 loss
Month 2 (April):    12 users    → -$1,530 loss
Month 3 (May):      14 users    → -$1,510 loss
Month 4 (June):     17 users    → -$1,485 loss
...
Month 12:           ~100 users  → Still not break-even

With aggressive 50% MoM growth:
Month 6:            ~75 users   → Still losing money
Month 9:            ~250 users  → Near break-even
Month 12:           ~800 users  → Profitable
```

**Reality:** It will take 6-12 months to break even, costing $10,000-20,000 in the meantime.

---

## 💰 **CASH RUNWAY NEEDED**

### **6-Month Launch Cost:**

```
Pre-Launch (3 months):
$1,650 x 3 = $4,950 (best case)
OR
$2,350 x 3 = $7,050 (typical)

Post-Launch (3 months with some revenue):
Month 1: $1,650 - $100 (10 users) = $1,550 loss
Month 2: $1,650 - $120 (12 users) = $1,530 loss
Month 3: $1,650 - $140 (14 users) = $1,510 loss
Total: $4,590 loss

──────────────────────────────────────
6-MONTH TOTAL: $9,540 - $11,640 needed
──────────────────────────────────────
```

**Question:** Do you have $10,000-12,000 runway for this integration?

---

## 🎯 **DECISION CRITERIA**

### **Proceed with Plaid/Unit if:**
- ✅ Total monthly cost < $2,000/month
- ✅ Can charge $10+/month per user
- ✅ Have $10,000+ runway for 6-12 months
- ✅ Confident in getting 200-300 users by month 4-6
- ✅ Clear path to profitability

### **Reconsider if:**
- ❌ Total monthly cost > $2,500/month
- ❌ Can only charge $5/month per user
- ❌ Have < $10,000 runway
- ❌ Uncertain about user acquisition
- ❌ No clear path to profitability

### **Defer integration if:**
- ❌ Total monthly cost > $3,000/month
- ❌ Freemium model (negative unit economics)
- ❌ Have < $5,000 runway
- ❌ Haven't validated product-market fit
- ❌ Can't justify the investment

---

## 📝 **WHAT YOU NEED TO CALCULATE THIS WEEK**

### **From Unit (URGENT!):**
1. Monthly platform fee: $______
2. Per-account fee: $______ x _____ accounts = $______
3. ACH transfer fee: $______ x _____ transfers = $______
4. Setup/onboarding fees: $______
5. Other fees: $______

**UNIT TOTAL: $______/month**

### **From Your Business Model:**
1. Pricing per user: $______/month
2. Expected conversion rate: ______%
3. Expected user growth: ______% MoM
4. Month 1 paying users: ______
5. Month 6 paying users: ______

### **Financial Position:**
1. Current runway: $______
2. Burn rate (other expenses): $______/month
3. Available for integration: $______
4. Can sustain losses for: ______ months

---

## 🚀 **ALTERNATIVES TO CONSIDER**

### **If Costs Too High:**

**Option 1: Manual ACH (Unit Direct)**
```
Cost Savings: -$1,000/month (no Plaid)
User Experience: Worse (manual entry)
Time to Market: Same
Recommendation: ✅ Consider for MVP
```

**Option 2: Cheaper Plaid Alternative**
```
Research: Teller.io, Finicity, MX
Potential Savings: $200-500/month
Trade-off: Less mature, fewer banks
Recommendation: ⚠️ Worth exploring
```

**Option 3: Different Banking Platform**
```
Research: Treasury Prime, Column, Synapse
Potential Savings: Varies
Trade-off: Different features
Recommendation: ⚠️ Compare before committing
```

**Option 4: Phase 2 Feature**
```
Launch: Simple savings tracking first
Add Later: Bank integration when have revenue
Savings: $15,000-25,000 in year 1
Trade-off: Less compelling MVP
Recommendation: ⚠️ Conservative approach
```

---

## ✅ **ACTION PLAN FOR THIS WEEK**

### **Monday/Tuesday:**
- [ ] Call Unit, get detailed pricing
- [ ] Request Plaid contract to review
- [ ] Research alternatives (Teller, others)

### **Wednesday:**
- [ ] Calculate real total monthly cost
- [ ] Model break-even scenarios
- [ ] Assess runway vs requirements

### **Thursday:**
- [ ] Review Plaid contract terms
- [ ] Compare alternatives
- [ ] Make go/no-go decision

### **Friday:**
- [ ] If GO: Sign Plaid contract
- [ ] If NO-GO: Inform Plaid, pursue alternatives
- [ ] If DEFER: Let both know timeline

---

## 🎯 **BOTTOM LINE**

**The Math Has to Work!**

You're committing to:
- $12,000-28,000/year in integration costs
- 6-12 months to profitability
- Need for 200-400 paying users

**Before signing, confirm:**
1. ✅ Know exact Unit costs
2. ✅ Total cost is affordable
3. ✅ Unit economics are positive
4. ✅ Have runway to reach break-even
5. ✅ Confident in user acquisition

**If any of these are uncertain, WAIT!**

---

**🚨 URGENT: Get Unit pricing THIS WEEK before signing anything with Plaid!**
