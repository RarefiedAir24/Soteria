# Unit Custom Build - Goal Savings Integration Guide

## Why Custom Build for Soteria

✅ **Goal-Based Accounts**: Create sub-accounts/purses for each goal
✅ **Full API Control**: Integrate with Plaid and your existing architecture
✅ **Custom Workflows**: Match your goal creation, deposits, multi-user flows
✅ **Flexible Design**: Build exactly what you need

---

## Getting Started

### 1. Sign Up for Sandbox
- **Link**: https://app.unit.co
- **What you get**: Free sandbox environment, API keys, test accounts
- **Time**: Immediate access

### 2. Review API Documentation
- **Link**: https://www.unit.co/docs/api
- **Focus on**:
  - Account creation
  - Sub-accounts/purses
  - Transfers
  - Balance queries

---

## Key API Endpoints to Explore

### Account Creation
```
POST /accounts
```
- Create ONE deposit account per user (when user creates first goal)
- Required: Name, SSN, Address, DOB
- Returns: Account ID, Account Number, Routing Number
- **All goals share this same account**

### Transaction Tagging (Goals)
```
POST /payments (or transactions)
{
  "tags": {
    "goal_id": "hawaii-trip-123",
    "goal_name": "Trip to Hawaii"
  }
}
```
- Tag transactions with goal_id when deposits are made
- Query transactions by goal_id to calculate per-goal balances
- All goals share the same account, tracked via transaction tags

### Transfers
```
POST /transfers
```
- ACH transfers from user's bank (Plaid) → Unit goal account
- External transfers
- Internal transfers between goals

### Balance Queries
```
GET /accounts/{accountId}
GET /accounts/{accountId}/balance
```
- Real-time balance for goals
- Transaction history

---

## Integration Architecture

```
┌─────────────────┐
│   Soteria App   │
│  (Your Code)    │
└────────┬────────┘
         │
         ├─── Plaid API (Read balances, connect banks)
         │
         └─── Unit API (Create accounts, transfers)
              │
              ▼
         ┌─────────────────┐
         │  Unit Platform  │
         │  (Handles all   │
         │   compliance)   │
         └────────┬────────┘
                  │
                  ▼
         ┌─────────────────┐
         │  Bank Partner    │
         │  (FDIC Insured)  │
         └─────────────────┘
```

---

## Implementation Flow

### Step 1: User Creates First Goal
```swift
// User creates "Trip to Hawaii" goal
// If this is user's first goal, create Unit account
// If account already exists, skip this step
POST /accounts
{
  "type": "depositAccount",
  "attributes": {
    "depositProduct": "savings",
    "tags": {
      "user_id": "user-123",
      "first_goal": "hawaii-trip"
    }
  },
  "relationships": {
    "customer": {
      "data": {
        "type": "customer",
        "id": "customer-id"
      }
    }
  }
}
```

### Step 2: User Makes Deposit to Goal
```swift
// User deposits $50 to "Hawaii" goal
// Your app:
// 1. Reads balance via Plaid
// 2. Initiates transfer via Unit
// 3. Tags transaction with goal_id
POST /payments
{
  "type": "achCredit",
  "attributes": {
    "amount": 50.00,
    "direction": "Credit",
    "description": "Deposit to Hawaii goal",
    "tags": {
      "goal_id": "hawaii-trip-123",
      "goal_name": "Trip to Hawaii"
    }
  },
  "relationships": {
    "account": {
      "data": {
        "type": "account",
        "id": "unit_account_id" // User's single Unit account
      }
    },
    "counterparty": {
      "data": {
        "type": "counterparty",
        "id": "plaid_counterparty_id" // User's bank via Plaid
      }
    }
  }
}
```

### Step 3: Show Goal Progress
```swift
// Get all transactions for this goal
GET /transactions?filter[tags][goal_id]=hawaii-trip-123
// Returns: Array of transactions tagged with this goal_id

// Calculate goal balance
let goalBalance = transactions
  .filter { $0.tags["goal_id"] == "hawaii-trip-123" }
  .reduce(0) { $0 + $1.amount }

// Display: "$50 / $2000 (2.5%)"
```

---

## What to Ask Unit Support

1. **Sub-Accounts/Purses**: "Do you support creating sub-accounts or purses for goal-based savings?"
2. **API Access**: "How quickly can we get Custom Build API access?"
3. **Sandbox**: "Is sandbox free and unlimited for testing?"
4. **Compliance**: "You handle all KYC/AML, correct? What data do we need to collect?"
5. **Pricing**: "What are the fees for account creation and ACH transfers?"
6. **Timeline**: "How long from sandbox to production for Custom Build?"

---

## Next Steps

1. ✅ Sign up at https://app.unit.co
2. ✅ Explore sandbox API
3. ✅ Test account creation
4. ✅ Test sub-account/purse creation
5. ✅ Test transfers
6. ✅ Review pricing
7. ✅ Contact Unit support with questions

---

## Timeline Estimate

- **Week 1**: Sandbox exploration, API testing
- **Week 2-3**: Integration development
- **Week 4**: Testing and refinement
- **Week 5+**: Production approval and launch

**Total: ~4-6 weeks for Custom Build**

---

## Resources

- **API Docs**: https://www.unit.co/docs/api
- **Sandbox**: https://app.unit.co
- **Support**: Available through dashboard
- **Community**: Check for developer forums/slack

