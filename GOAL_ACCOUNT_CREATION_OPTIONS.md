# Goal-Oriented Account Creation Options

## Problem Statement
Plaid can connect to existing accounts but **cannot create new accounts**. For goal savings, we need a way to create dedicated, separate accounts that act as "protected piggy banks" for each goal.

## Critical Requirements
- ✅ **NO legal team required** - Provider handles all compliance
- ✅ **NO banking licenses needed** - Provider is the licensed entity
- ✅ **NO insurance required** - Provider carries FDIC insurance
- ✅ **NO legal liability** - Provider assumes regulatory burden
- ✅ **Secure** - Enterprise-grade security
- ✅ **Simple integration** - API-based, no legal complexity

## Solution: Banking-as-a-Service (BaaS) Providers

These providers can programmatically create FDIC-insured bank accounts for your users, separate from their personal checking/savings accounts. **The key benefit: They handle ALL compliance, licensing, and insurance - you just integrate via API.**

---

## Top US-Based BaaS Providers

### 1. **Unit** ⭐⭐⭐ (BEST FOR NO LEGAL TEAM)
**Website**: https://www.unit.co

**What They Offer:**
- Create FDIC-insured deposit accounts programmatically
- Virtual cards and physical cards
- ACH transfers, wire transfers
- Real-time balance updates
- Goal-based sub-accounts (perfect for your use case!)

**Compliance & Legal Burden:**
- ✅ **Unit handles ALL KYC/AML compliance** - You just collect basic user info
- ✅ **Unit is the licensed bank** - You don't need any licenses
- ✅ **Unit carries FDIC insurance** - You don't need insurance
- ✅ **Unit handles all regulatory requirements** - Zero legal burden on you
- ✅ **Simple API integration** - No legal team needed
- ✅ **They provide compliance support** - Help with any questions

**Pros:**
- ✅ **ZERO legal burden** - They handle everything
- ✅ Excellent developer experience and documentation
- ✅ Fast onboarding (2-4 weeks, minimal legal review)
- ✅ Modern API design
- ✅ Built-in support for goal-based accounts
- ✅ Competitive pricing
- ✅ Perfect for startups without legal teams
- ✅ Strong customer support
- ✅ Clear compliance documentation

**Cons:**
- ⚠️ Relatively newer (founded 2019) but well-funded and growing
- ⚠️ May have minimum volume requirements
- ⚠️ You still need to collect user info (name, SSN, etc.) but Unit handles verification

**Pricing:**
- Typically $0.10-$0.50 per account per month
- Transaction fees vary by type
- Setup fees may apply

**Best For:**
- Startups building goal-based savings features
- Need quick integration
- Want modern API experience

---

### 2. **Treasury Prime**
**Website**: https://treasuryprime.com

**What They Offer:**
- FDIC-insured account creation
- ACH, wire, and card capabilities
- Multi-account management
- Strong compliance framework

**Compliance & Legal Burden:**
- ✅ **They handle compliance** - But may require more legal review
- ✅ **Bank partner handles licensing** - You don't need licenses
- ✅ **FDIC insurance provided** - By bank partner
- ⚠️ **May require more legal documentation** - More complex than Unit

**Pros:**
- ✅ Established player in embedded finance
- ✅ Good for B2B and B2C
- ✅ Strong compliance and regulatory support
- ✅ Flexible account structures

**Cons:**
- ⚠️ Can be more complex to integrate
- ⚠️ Longer onboarding process (may need legal review)
- ⚠️ May be more expensive
- ⚠️ May require more legal documentation upfront

**Best For:**
- More established companies
- Need extensive compliance support
- Complex account structures

---

### 3. **Synapse**
**Website**: https://synapsefi.com

**What They Offer:**
- Account creation and management
- Payment processing
- Card issuance
- Multi-account support

**Pros:**
- ✅ Very established (founded 2014)
- ✅ Large customer base
- ✅ Comprehensive platform
- ✅ Good documentation

**Cons:**
- ⚠️ Can be complex
- ⚠️ Longer integration time
- ⚠️ May have higher minimums

**Best For:**
- Companies needing comprehensive banking infrastructure
- Established fintechs
- Complex use cases

---

### 4. **Stripe Treasury** (If Using Stripe)
**Website**: https://stripe.com/docs/treasury

**What They Offer:**
- Financial accounts via Stripe
- ACH transfers
- Balance management
- Integration with Stripe ecosystem

**Pros:**
- ✅ Seamless if already using Stripe
- ✅ Familiar API patterns
- ✅ Good documentation
- ✅ Unified billing

**Cons:**
- ⚠️ Requires Stripe account
- ⚠️ Less flexible than dedicated BaaS
- ⚠️ May have limitations for goal-specific features

**Best For:**
- Already using Stripe for payments
- Want unified platform
- Simpler use cases

---

### 5. **Modern Treasury**
**Website**: https://www.moderntreasury.com

**What They Offer:**
- Payment operations platform
- Account creation capabilities
- Strong reconciliation features
- API-first design

**Pros:**
- ✅ Excellent for payment operations
- ✅ Strong reconciliation tools
- ✅ Good API design
- ✅ Strong enterprise features

**Cons:**
- ⚠️ More enterprise-focused
- ⚠️ May be overkill for simple goal accounts
- ⚠️ Higher pricing

**Best For:**
- Enterprise customers
- Complex payment operations
- Need strong reconciliation

---

## Recommended Approach for Soteria

### **Option A: Unit (Recommended)**
**Why:**
1. Built-in support for goal-based accounts
2. Fast integration (2-4 weeks)
3. Modern, developer-friendly API
4. Competitive pricing
5. Good for startups
6. Strong documentation

**Implementation:**
- Create one Unit account per user
- Create sub-accounts or "purses" for each goal
- Each goal gets its own account number
- Funds are FDIC-insured
- Can transfer from user's Plaid-connected account to Unit goal account

**Architecture:**
```
User's Bank (Plaid) → Unit Goal Account (via ACH)
```

---

### **Option B: Hybrid Approach**
**Use Both Plaid + Unit:**

1. **Plaid**: Connect to user's existing accounts (read balances, initiate transfers)
2. **Unit**: Create dedicated goal accounts
3. **Flow**:
   - User connects bank via Plaid
   - User creates goal → Unit creates dedicated account
   - User makes deposit → Transfer from Plaid account to Unit goal account
   - Funds are protected in separate FDIC-insured account

**Benefits:**
- ✅ Users keep their existing bank accounts
- ✅ Goal funds are in separate, protected accounts
- ✅ Can still use Plaid for balance reading
- ✅ Clear separation of goal funds

---

## Implementation Considerations

### 1. **Account Structure**
- **One Unit account per user** (all goals share the same account)
- **Goals tracked via transaction tags** (tag each deposit with goal_id)
- **Per-goal balance** = sum of transactions tagged with that goal_id

**Recommendation**: One account per user, track goals via transaction metadata/tags.

### 2. **User Experience**
- Seamless account creation (happens in background)
- Clear messaging: "Your goal funds are protected in a separate FDIC-insured account"
- Show account details (account number, routing number) for transparency

### 3. **Compliance (HANDLED BY PROVIDER)**
- ✅ **KYC (Know Your Customer)**: Provider handles verification, you just collect basic info
- ✅ **AML (Anti-Money Laundering)**: Provider runs all checks
- ✅ **Banking License**: Provider has the license, not you
- ✅ **FDIC Insurance**: Provider carries insurance, not you
- ✅ **Regulatory Compliance**: Provider handles all regulatory requirements
- ✅ **Legal Liability**: Provider assumes liability, not you

**What You Need to Do:**
- Collect user information (name, email, SSN, address) - Standard signup data
- Pass data to provider via API
- Provider handles all verification, compliance, and legal requirements

**What You DON'T Need:**
- ❌ Banking license
- ❌ Insurance
- ❌ Legal team
- ❌ Compliance team
- ❌ Regulatory filings

### 4. **Costs**
- Account creation fees
- Monthly account fees
- Transaction fees (ACH transfers)
- Factor into pricing model

### 5. **Multi-User Goals**
- For shared goals, you could:
  - Create a joint account (if Unit supports)
  - OR create separate goal accounts and aggregate balances
  - OR use a single account with multiple contributors

---

## Next Steps

1. **Contact Unit** (or preferred provider)
   - Request demo/API access
   - Understand pricing
   - Review compliance requirements
   - Get integration timeline

2. **Architecture Design**
   - Decide on account structure (one per user vs one per goal)
   - Design transfer flow (Plaid → Unit)
   - Plan for multi-user goals

3. **Integration Plan**
   - Add Unit SDK/service
   - Create account creation flow
   - Update deposit flows to use Unit accounts
   - Update UI to show account details

4. **Testing**
   - Test account creation
   - Test transfers
   - Test multi-user scenarios
   - Compliance testing

---

## Comparison Table

| Provider | Setup Time | Pricing | Developer Experience | Goal Support | Best For |
|----------|------------|---------|---------------------|--------------|----------|
| **Unit** | 2-4 weeks | $$ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Startups, goal-based apps |
| **Treasury Prime** | 4-8 weeks | $$$ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Established companies |
| **Synapse** | 6-12 weeks | $$$ | ⭐⭐⭐ | ⭐⭐⭐ | Complex use cases |
| **Stripe Treasury** | 2-4 weeks | $$ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Stripe users |
| **Modern Treasury** | 4-8 weeks | $$$$ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Enterprise |

---

## Recommendation

### **Unit is the CLEAR WINNER for No Legal Team**

**Why Unit is Perfect for You:**
1. ✅ **ZERO legal burden** - They handle ALL compliance, licensing, insurance
2. ✅ **No legal team needed** - Simple API integration, they provide compliance support
3. ✅ **Fastest setup** - 2-4 weeks, minimal legal review
4. ✅ **Best for startups** - Designed for companies without legal teams
5. ✅ **Clear documentation** - They explain what you need vs what they handle
6. ✅ **Goal-based accounts** - Built-in support for your exact use case
7. ✅ **FDIC-insured** - They carry the insurance, not you
8. ✅ **Secure** - Enterprise-grade security, SOC 2 compliant

**What You Actually Need:**
- Basic user info collection (name, SSN, address) - Standard signup data
- API integration (technical, not legal)
- That's it!

**What You DON'T Need:**
- ❌ Banking license
- ❌ Insurance
- ❌ Legal team
- ❌ Compliance team
- ❌ Regulatory expertise

You can always migrate to another provider later if needed, but Unit is the best starting point for Soteria's goal savings feature when you don't have a legal team.

---

## Questions to Ask Providers (CRITICAL FOR NO LEGAL TEAM)

### Compliance & Legal Questions:
1. **Do you handle ALL KYC/AML compliance?** (Answer should be YES)
2. **Do we need any banking licenses?** (Answer should be NO)
3. **Do we need to carry any insurance?** (Answer should be NO)
4. **Do you handle all regulatory requirements?** (Answer should be YES)
5. **What legal documentation do we need to provide?** (Should be minimal - basic business info)
6. **Do you provide compliance support?** (Answer should be YES)
7. **What's our legal liability?** (Should be minimal - you're just integrating)

### Technical Questions:
8. Can you create sub-accounts or "purses" for goal-based savings?
9. What are the monthly fees per account?
10. What are ACH transfer fees?
11. How long does account creation take?
12. Do you support joint accounts for multi-user goals?
13. What's the minimum volume requirement?
14. What's the integration timeline?
15. Do you have iOS SDK or REST API only?
16. What's your uptime SLA?

### For Unit Specifically:
17. **What user information do we need to collect?** (Name, SSN, address, etc.)
18. **How do you handle KYC verification?** (Automated vs manual)
19. **What happens if a user fails KYC?** (Do they get notified, can they retry?)
20. **Do you handle all regulatory reporting?** (YES - they should)

