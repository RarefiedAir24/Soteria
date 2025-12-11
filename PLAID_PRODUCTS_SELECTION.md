# Plaid Products Selection for Soteria

## Products to Select in Plaid Application

### ✅ Required Products (Select These)

#### Payments Category:

1. **Auth** ✅
   - **Why:** Required for authenticating and connecting bank accounts
   - **Use:** Account connection flow (checking + savings)
   - **Status:** Standard product

2. **Balance** ✅
   - **Why:** Read real-time account balances to show savings progress
   - **Use:** Display account balances in the app
   - **Status:** Standard product

3. **Transfer** ✅ (CUSTOM PLAN - Request Separately)
   - **Why:** Move money from checking to savings accounts
   - **Use:** Automatic transfers when users choose protection
   - **Status:** Custom plan product - request after initial approval
   - **Note:** You'll need to request this separately from Plaid support

### ❌ Do NOT Select (Not Needed)

#### Payments Category:
- ❌ **Identity** - Not needed for MVP
- ❌ **Identity Match** - Not needed
- ❌ **Payment Initiation** - Not available in US
- ❌ **Signal Transaction Scores** - Not needed

#### Credit Underwriting:
- ❌ **Assets** - Not doing lending
- ❌ **Income** - Not doing lending
- ❌ **Statements** - Not needed

#### Financial Management:
- ❌ **Transactions** - Not doing budgeting/transaction analysis
- ❌ **Recurring Transactions** - Not needed
- ❌ **Enrich** - Not needed
- ❌ **Investments** - Not needed
- ❌ **Liabilities** - Not needed

#### Fraud & Compliance:
- ❌ **Identity Verification** - Not needed for MVP
- ❌ **Monitor** - Not needed for MVP

#### Plaid Check:
- ❌ All Plaid Check products - Not doing lending

## Application Process

### Step 1: Initial Application
Select these products:
- ✅ **Auth**
- ✅ **Balance**

### Step 2: After Approval
Request **Transfer** product separately:
- Contact Plaid support or your account manager
- Explain your use case: "We need Transfer API to move money from checking to savings accounts when users choose protection"
- This is a custom plan product, so it requires additional approval

## Code Configuration

Your code is now configured to use:
```swift
"products": ["auth", "balance"]
```

Once Transfer is approved, you can add it:
```swift
"products": ["auth", "balance", "transfer"]
```

## Why Not Transactions?

You might see `transactions` in some old code examples, but you don't need it because:
- You're not doing budgeting or spending analysis
- You're not categorizing transactions
- You only need to read balances and initiate transfers
- Transactions adds unnecessary cost and complexity

## Summary

**For Plaid Application:**
- Select: **Auth** and **Balance**
- Request separately: **Transfer** (after initial approval)

**For Demo:**
- Auth + Balance are sufficient to show account connection and balance reading
- Transfer can be mentioned but may not work in sandbox for same-bank transfers

