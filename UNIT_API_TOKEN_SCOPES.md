# Unit API Token Scopes - Goal Savings Setup

## Required Scopes for Goal-Based Savings

### ✅ **Essential (Select These)**

#### **Application**
- **Read** ✅
- **Write** ✅
- **Why**: Create applications for new customers/users

#### **Customers**
- **Read** ✅
- **Write** ✅
- **Why**: Create and manage customer accounts (users)

#### **Accounts**
- **Read** ✅
- **Write** ✅
- **Why**: Create goal accounts, read balances, update account info

#### **Transactions**
- **Read** ✅
- **Why**: See deposits/withdrawals to goal accounts, track goal progress

#### **Payments**
- **Read** ✅
- **Write** ✅
- **Why**: Initiate transfers from user's bank (Plaid) → Unit goal accounts

#### **Payments ACH**
- **Read** ✅
- **Write** ✅
- **Why**: ACH transfers (primary method for goal deposits)

#### **Payments Linked Accounts**
- **Read** ✅
- **Write** ✅
- **Why**: Link external accounts (user's bank via Plaid) for transfers

#### **Webhooks**
- **Read** ✅
- **Why**: Receive notifications about account events, transfers, etc.

#### **Events**
- **Read** ✅
- **Why**: Track account events, transfer status updates

---

## Optional (Add Later If Needed)

### **Statements**
- **Read** ✅ (Optional)
- **Why**: Generate account statements for users (nice to have)

### **Account Holds**
- **Read** ✅ (Optional)
- **Write** ✅ (Optional)
- **Why**: If you need to hold funds (probably not needed for goals)

### **Counterparties**
- **Read** ✅ (Optional)
- **Write** ✅ (Optional)
- **Why**: Manage payees/recipients (may need for transfers)

---

## NOT Needed (Don't Select)

❌ **Cards** - You're not issuing cards for goals
❌ **Cards Sensitive** - Not issuing cards
❌ **Repayments** - Not doing loans
❌ **Credit Decisions** - Not doing lending
❌ **Lending Program** - Not doing lending
❌ **Credit Application** - Not doing lending
❌ **Disputes** - Probably not needed initially
❌ **Chargebacks** - Probably not needed initially
❌ **Rewards** - Not doing rewards program
❌ **Check Payments** - Not using checks
❌ **Tax Profiles** - Not needed for basic goals
❌ **Forms** - Not needed initially
❌ **Forms Sensitive** - Not needed
❌ **Wire Drawdowns** - Not using wire transfers
❌ **Cash Deposits** - Not using cash deposits
❌ **Check Deposits** - Not using check deposits initially
❌ **Received Payments** - May not need initially
❌ **Authorization Requests** - May not need
❌ **Batch Releases** - May not need
❌ **Migrations** - Not needed
❌ **Card Fraud Case** - Not issuing cards
❌ **Customer Tags** - May not need (but harmless if selected)
❌ **Customer Token** - May not need (but harmless if selected)
❌ **Payments Wire** - Not using wire transfers
❌ **Payments ACH Debit** - May not need (you're doing credits TO goals)

---

## Recommended Selection

### Minimum Viable Setup:
```
✅ Application (Read, Write)
✅ Customers (Read, Write)
✅ Accounts (Read, Write)
✅ Transactions (Read)
✅ Payments (Read, Write)
✅ Payments ACH (Read, Write)
✅ Payments Linked Accounts (Read, Write)
✅ Webhooks (Read)
✅ Events (Read)
```

### With Optional Features:
```
✅ Application (Read, Write)
✅ Customers (Read, Write)
✅ Accounts (Read, Write)
✅ Transactions (Read)
✅ Payments (Read, Write)
✅ Payments ACH (Read, Write)
✅ Payments Linked Accounts (Read, Write)
✅ Webhooks (Read)
✅ Events (Read)
✅ Statements (Read) - Optional
✅ Counterparties (Read, Write) - Optional
```

---

## Security Best Practice

**Start with minimum required scopes**, then add more as needed. This follows the principle of least privilege.

You can always create additional tokens with more scopes later if you need new features.

---

## Summary

**Select these 9 scopes:**
1. Application (Read, Write)
2. Customers (Read, Write)
3. Accounts (Read, Write)
4. Transactions (Read)
5. Payments (Read, Write)
6. Payments ACH (Read, Write)
7. Payments Linked Accounts (Read, Write)
8. Webhooks (Read)
9. Events (Read)

**That's all you need to get started with goal-based savings accounts!**

