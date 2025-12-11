# Plaid Integration Architecture for Soteria

## Overview

Soteria will use Plaid to:
1. Connect user's checking and savings accounts
2. Initiate automatic transfers (checking → savings) when users unblock
3. Read balances to show savings progress
4. Handle users with only checking accounts (virtual savings mode)

## Key Principle

**We never hold or control user money. We only facilitate transfers between the user's own accounts.**

## Architecture Diagram

```
iOS App (Soteria)
    ↓
PlaidService.swift
    ↓
AWS API Gateway (soteria-api)
    ↓
AWS Lambda Functions
    ↓
Plaid API
    ↓
User's Bank Accounts
```

## Data Flow

### Account Connection Flow
```
1. User taps "Connect Accounts" in Settings
2. iOS → PlaidService → AWS API Gateway → Lambda → Plaid Link Token
3. Plaid Link UI opens (Plaid SDK)
4. User connects checking + savings accounts
5. Plaid returns public_token
6. iOS → AWS → Lambda → Plaid (exchange public_token for access_token)
7. Lambda stores access_token in DynamoDB (encrypted)
8. Lambda returns account info (account_id, type, balance)
9. iOS stores account_id and type (NOT access_token)
10. Done - accounts connected
```

### Transfer Flow (When User Unblocks)
```
1. User unblocks app → chooses to save money
2. iOS → PlaidService → Check balance (via AWS Lambda)
3. If sufficient funds:
   - iOS → AWS → Lambda → Plaid Transfer API
   - Transfer: checking → savings ($10)
4. Lambda returns transfer_id and status
5. iOS updates UI: "Saved $10! Your Soteria Savings: $150"
6. User sees balance in Soteria AND their bank app
```

### Balance Reading Flow
```
1. User opens app → wants to see savings progress
2. iOS → PlaidService → AWS Lambda → Plaid Balance API
3. Lambda reads balance (read-only)
4. Returns balance to iOS
5. iOS displays: "Your Soteria Savings: $150"
```

## Security Model

### What We Store:
- ✅ Account IDs (for reference)
- ✅ Account types (checking/savings)
- ✅ Transfer history (for UI)
- ❌ Access tokens (stored in AWS DynamoDB, encrypted)
- ❌ Full account numbers (never stored)
- ❌ Bank credentials (handled by Plaid)

### What We Can Do:
- ✅ Initiate transfers (with user confirmation)
- ✅ Read balances (read-only)
- ✅ Check account types
- ❌ Withdraw money
- ❌ Move money without user action
- ❌ Access accounts directly

## Account Types & Modes

### Mode 1: Automatic Transfers (User has Savings Account)
- User connects checking + savings
- Transfers happen automatically on unblock
- Real money movement
- Balance shown in app

### Mode 2: Virtual Savings (User has Only Checking)
- User connects only checking account
- Track "protected" amounts (no transfer)
- Show progress: "You've protected $150 this month"
- Option to create savings account later

### Mode 3: Manual Mode
- No accounts connected
- Just track protection moments
- No financial features
- Can upgrade later

## AWS Resources Needed

### Lambda Functions:
1. `soteria-plaid-create-link-token` - Create Plaid Link token
2. `soteria-plaid-exchange-token` - Exchange public token for access token
3. `soteria-plaid-get-accounts` - Get user's accounts
4. `soteria-plaid-check-balance` - Read account balance
5. `soteria-plaid-initiate-transfer` - Start transfer
6. `soteria-plaid-transfer-status` - Check transfer status
7. `soteria-plaid-webhook` - Handle Plaid webhooks

### DynamoDB Tables:
1. `soteria-plaid-access-tokens` - Store access tokens (encrypted)
2. `soteria-plaid-transfers` - Track transfer history

### API Gateway:
- Endpoint: `/soteria/plaid/*`
- All endpoints require Firebase Auth

## iOS Services

### PlaidService.swift
- Handle Plaid Link integration
- Manage account connections
- Initiate transfers
- Read balances
- Handle errors

### SavingsService.swift (Update)
- Track virtual savings (if no savings account)
- Track real savings (if has savings account)
- Show progress
- Handle mode switching

## User Experience

### Onboarding:
1. "Connect your accounts to enable automatic savings"
2. Plaid Link opens
3. User connects checking + savings (or just checking)
4. If no savings: "Enable Virtual Savings Mode"
5. If has savings: "Automatic transfers enabled!"

### During Unblock:
1. User unblocks → "Save $10 to your savings?"
2. If automatic mode: Transfer happens → "✅ Saved $10!"
3. If virtual mode: Track amount → "Protected $10 (create savings account to enable transfers)"

### Settings:
- View connected accounts
- Change protection amount ($5, $10, $25, custom)
- Switch between modes
- Disconnect accounts
- View transfer history

