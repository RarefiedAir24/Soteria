# Unit Integration Guide - No Legal Team Required

## Overview
This guide explains how to integrate Unit for goal-based savings accounts **without needing a legal team, banking license, or insurance**.

## Key Principle
**Unit handles ALL compliance, licensing, and insurance. You just integrate via API.**

---

## What Unit Handles (You Don't Need to Worry About)

✅ **Banking License** - Unit's bank partner has the license
✅ **FDIC Insurance** - Unit's bank partner carries FDIC insurance
✅ **KYC/AML Compliance** - Unit runs all verification checks
✅ **Regulatory Reporting** - Unit handles all regulatory requirements
✅ **Legal Liability** - Unit assumes regulatory burden
✅ **Compliance Team** - Unit has the compliance team

---

## What You Need to Do (Simple)

### 1. Collect Basic User Information
Standard signup data you probably already collect:
- Full name
- Email address
- Phone number
- Date of birth
- Social Security Number (SSN)
- Physical address

### 2. Integrate Unit API
- Create ONE account per user via API (when first goal is created)
- Tag transactions with goal_id when deposits are made
- Initiate transfers via API
- Query transactions by goal_id to calculate per-goal balances

### 3. Handle User Experience
- Show account details to users
- Display balances
- Handle transfers
- Show goal progress

**That's it! No legal team needed.**

---

## Integration Architecture

```
┌─────────────────┐
│   Your App      │
│  (Soteria)      │
└────────┬────────┘
         │
         │ API Calls
         │ (No legal complexity)
         │
         ▼
┌─────────────────┐
│   Unit API        │
│  (Handles ALL      │
│   compliance)      │
└────────┬───────────┘
         │
         │ Licensed Bank Partner
         │ (FDIC Insured)
         │
         ▼
┌─────────────────┐
│  User's Goal    │
│  Account        │
│  (FDIC Insured) │
└─────────────────┘
```

---

## Typical Integration Flow

### Step 1: User Creates First Goal
```
User → Your App → "Create Goal: Trip to Hawaii"
```

### Step 2: Create Unit Account (if first goal)
```
Your App → Unit API → Create Account
Unit handles: KYC, AML, compliance
Returns: Account ID, Account Number, Routing Number
Note: This is the ONLY account for this user - all goals share it
```

### Step 3: User Makes Deposit to Goal
```
User → Your App → "Deposit $50 to Hawaii goal"
Your App → Plaid → Read user's bank balance
Your App → Unit API → Initiate ACH transfer
  - Tag transaction with: goal_id="hawaii-trip-123"
Unit handles: Transfer, compliance, reporting
```

### Step 4: Show Goal Progress
```
Your App → Unit API → Get Transactions
  - Filter by: tags[goal_id]="hawaii-trip-123"
  - Sum transaction amounts
Display: "$50 / $2000 (2.5%)"
```

### Step 5: User Creates More Goals
```
User → "Create Goal: Emergency Fund"
- Uses same Unit account (no new account needed)
- Future deposits tagged with new goal_id
- Calculate balance per goal by filtering transactions
```

---

## Code Example (Conceptual)

```swift
// UnitService.swift (Conceptual)

class UnitService {
    private let apiKey: String
    private let baseURL = "https://api.unit.co"
    
    // Create account for user (Unit handles ALL compliance)
    func createAccount(userInfo: UserInfo) async throws -> UnitAccount {
        // Unit handles:
        // - KYC verification
        // - AML checks
        // - Regulatory compliance
        // - Account creation
        
        let response = try await api.post("/accounts", body: [
            "type": "deposit",
            "attributes": [
                "fullName": userInfo.fullName,
                "ssn": userInfo.ssn,
                "address": userInfo.address,
                "dateOfBirth": userInfo.dateOfBirth
            ]
        ])
        
        return UnitAccount(
            id: response.id,
            accountNumber: response.accountNumber,
            routingNumber: response.routingNumber
        )
    }
    
    // Create goal sub-account
    func createGoalAccount(userAccountId: String, goalName: String) async throws -> GoalAccount {
        // Unit creates sub-account for goal
        // Still FDIC-insured
        // Still compliant
        
        let response = try await api.post("/accounts/\(userAccountId)/sub-accounts", body: [
            "type": "goal",
            "attributes": [
                "name": goalName
            ]
        ])
        
        return GoalAccount(id: response.id)
    }
    
    // Transfer from user's bank to goal account
    func transferToGoal(
        fromPlaidAccount: String,
        toGoalAccount: String,
        amount: Double
    ) async throws -> Transfer {
        // Unit handles:
        // - ACH transfer
        // - Compliance
        // - Reporting
        
        let response = try await api.post("/transfers", body: [
            "type": "ach",
            "attributes": [
                "amount": amount,
                "fromAccount": fromPlaidAccount,
                "toAccount": toGoalAccount
            ]
        ])
        
        return Transfer(id: response.id, status: response.status)
    }
}
```

---

## User Experience Flow

### 1. User Signs Up
```
"Create your Soteria account"
↓
Collect: Name, Email, SSN, Address
↓
Unit verifies (happens in background)
↓
Account created (FDIC-insured)
```

### 2. User Creates Goal
```
"Save for: Trip to Hawaii"
↓
Unit creates goal sub-account
↓
Show: "Your goal account: ****1234"
```

### 3. User Makes Deposit
```
"Deposit $50 to Hawaii goal"
↓
Connect bank via Plaid (read balance)
↓
Transfer $50: Your Bank → Goal Account
↓
Unit handles transfer + compliance
↓
Show: "$50 / $2000 saved"
```

---

## Compliance Made Simple

### What Unit Does:
- ✅ Verifies user identity (KYC)
- ✅ Checks for money laundering (AML)
- ✅ Reports to regulators
- ✅ Maintains compliance records
- ✅ Handles all regulatory requirements

### What You Do:
- ✅ Collect user info (standard signup)
- ✅ Pass to Unit via API
- ✅ Display account info to user
- ✅ Handle user experience

### What You DON'T Do:
- ❌ Run compliance checks
- ❌ ❌ File regulatory reports
- ❌ Maintain compliance records
- ❌ Handle regulatory requirements
- ❌ Worry about legal liability

---

## Security

Unit provides:
- ✅ **SOC 2 Type II** certified
- ✅ **Bank-level encryption**
- ✅ **FDIC insurance** (up to $250k per account)
- ✅ **PCI DSS** compliance
- ✅ **Regular security audits**

You get enterprise-grade security without building it yourself.

---

## Pricing (Typical)

- **Account Creation**: $0.10 - $0.50 per account/month
- **ACH Transfers**: $0.25 - $1.00 per transfer
- **No Setup Fees**: Usually waived for startups
- **No Minimum Volume**: Typically none for startups

**Total Cost**: ~$0.50 - $2.00 per active user per month

---

## Getting Started

### 1. Contact Unit
- Email: sales@unit.co
- Website: https://www.unit.co
- Request: "API access for goal-based savings"

### 2. Onboarding (2-4 weeks)
- Week 1: API access, documentation review
- Week 2: Integration development
- Week 3: Testing in sandbox
- Week 4: Production approval

### 3. Integration
- Add Unit SDK or REST API
- Implement account creation
- Implement goal sub-accounts
- Implement transfers
- Update UI

### 4. Launch
- Go live with Unit handling all compliance
- Monitor via Unit dashboard
- Support users (Unit provides compliance support)

---

## Support

Unit provides:
- ✅ Technical support (API questions)
- ✅ Compliance support (regulatory questions)
- ✅ Integration support (help with setup)
- ✅ Documentation (comprehensive guides)

**You don't need a legal team - Unit's compliance team helps you.**

---

## Summary

**Unit = Zero Legal Burden**

- They handle: Compliance, licensing, insurance, regulatory requirements
- You handle: User experience, API integration, basic data collection
- Result: Goal-based savings accounts without legal complexity

**Perfect for startups without legal teams.**

