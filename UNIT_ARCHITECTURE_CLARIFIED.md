# Unit Architecture - Clarified: One Account Per User

## Architecture Overview

### ✅ **Simplified Approach: 1 User = 1 Unit Account**

```
User
  └── 1 Unit Account (FDIC-insured)
      └── All Goals Share This Account
          ├── Transaction 1: $50 → tagged goal_id="hawaii"
          ├── Transaction 2: $100 → tagged goal_id="hawaii"
          ├── Transaction 3: $200 → tagged goal_id="emergency"
          └── Transaction 4: $150 → tagged goal_id="car"
```

---

## How It Works

### 1. **Account Creation**
- **When**: User creates their FIRST goal
- **What**: Create ONE Unit deposit account
- **Result**: User has 1 Unit account for all goals

### 2. **Goal Tracking**
- **Method**: Tag transactions with `goal_id`
- **When**: Every deposit/transfer to Unit account
- **How**: Include `goal_id` in transaction tags

### 3. **Balance Calculation**
- **Per-Goal Balance**: Sum all transactions tagged with that `goal_id`
- **Total Account Balance**: Sum of all transactions
- **Query**: Filter transactions by `goal_id` tag

---

## Implementation Example

### Create Account (First Goal)
```swift
// User creates first goal → Create Unit account
POST /accounts
{
  "data": {
    "type": "depositAccount",
    "attributes": {
      "depositProduct": "savings",
      "tags": {
        "user_id": "user-123"
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
}
```

### Make Deposit to Goal
```swift
// User deposits $50 to "Hawaii" goal
POST /payments
{
  "data": {
    "type": "achCredit",
    "attributes": {
      "amount": 50.00,
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
          "id": "unit_account_id" // User's single account
        }
      }
    }
  }
}
```

### Calculate Goal Balance
```swift
// Get all transactions for "Hawaii" goal
GET /transactions?filter[tags][goal_id]=hawaii-trip-123

// Sum the amounts
let goalBalance = transactions
  .filter { $0.tags["goal_id"] == "hawaii-trip-123" }
  .reduce(0) { $0 + $1.amount }

// Display: "$150 / $2000 (7.5%)"
```

---

## Benefits

✅ **Simpler**: One account per user, not per goal
✅ **Lower Cost**: Fewer accounts = lower fees
✅ **Easier Management**: Less account complexity
✅ **Still Trackable**: Can track per-goal via transaction tags
✅ **FDIC Insured**: All funds in one protected account

---

## Multi-User Goals

For shared goals:
- Each user has their own Unit account
- Each user's deposits tagged with shared `goal_id`
- Aggregate balances across all users' accounts
- Query: Get all transactions with shared `goal_id` across all users

---

## Key Questions for Unit

1. **Transaction Tagging**: Can we tag payments/transactions with custom metadata (goal_id)?
2. **Transaction Filtering**: Can we query/filter transactions by tags?
3. **Tag Support**: What's the format for transaction tags?
4. **Multi-User**: How to aggregate balances across multiple users for shared goals?

---

## Summary

**Architecture**: 1 Unit account per user, all goals share it
**Tracking**: Transaction tags with goal_id
**Balance**: Sum transactions per goal_id
**Simple, cost-effective, and still fully functional!**

