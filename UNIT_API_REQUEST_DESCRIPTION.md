# Unit API Access Request Description

## Copy/Paste Description for Unit

---

### Short Version (For Forms)

```
We're building a goal-based savings app (Soteria) that helps users save for specific goals (trips, purchases, emergencies). Each user gets ONE dedicated, FDIC-insured account (separate from their personal accounts). All goals share this same account - we track which goal each deposit is for by tagging transactions with goal_id. Users transfer funds from their existing bank accounts (via Plaid) into their Unit account. We also need to support multi-user shared goals where multiple users contribute to the same goal. We're a startup without a legal team, so we need a solution that handles all compliance, licensing, and insurance requirements.
```

---

### Detailed Version (For Support/Email)

```
We're building Soteria, a goal-based savings application that helps users save for specific financial goals (trips, purchases, emergency funds, etc.).

Our Use Case:
- Users create savings goals with target amounts and dates
- Each user gets ONE dedicated, FDIC-insured account (separate from their personal accounts)
- ALL goals share the same account - goals are tracked via transaction metadata/tags
- Users transfer funds from their existing bank accounts (connected via Plaid) into their Unit account
- When depositing, we tag the transaction with the goal_id to track which goal the deposit is for
- We need to support multi-user shared goals where multiple users can contribute to the same goal
- Users should be able to track progress per goal by summing transactions tagged with each goal_id

Technical Requirements:
- API access to create ONE deposit account per user (when they create first goal)
- Ability to tag transactions with goal_id when deposits are made
- ACH transfer capabilities (from external accounts to Unit account)
- Query transactions by goal_id to calculate per-goal balances
- Real-time balance queries for the account
- Webhook support for account events and transactions

Constraints:
- We're a startup without a legal team
- We need Unit to handle all compliance, KYC/AML, licensing, and FDIC insurance
- We're using Custom Build API (not Ready-to-Launch) for goal-specific features

We've signed up for sandbox access and are ready to start integration. We'd like to understand:
1. Can we create sub-accounts or separate accounts per goal?
2. How do we handle multi-user shared goals?
3. What's the timeline for production access?
4. What user data do we need to collect for KYC?
```

---

### Professional Email Version

```
Subject: API Access Request - Goal-Based Savings Accounts

Hi Unit Team,

We're building Soteria, a goal-based savings application, and we're interested in using Unit's Custom Build API to create dedicated savings accounts for our users' financial goals.

Use Case:
Our app allows users to create savings goals (e.g., "Trip to Hawaii - $2,000 by June 2025"). Each goal needs its own FDIC-insured account that's separate from the user's personal checking/savings accounts. Users will transfer funds from their existing bank accounts (connected via Plaid) into these goal-specific accounts via ACH transfers.

Key Requirements:
- Programmatic account creation for each savings goal
- ACH transfer capabilities (external accounts → Unit goal accounts)
- Real-time balance tracking per goal
- Support for multi-user shared goals (multiple contributors to one goal)
- Webhook support for account events

We're a startup without a legal team, so we need a solution where Unit handles all compliance, KYC/AML, licensing, and FDIC insurance requirements.

We've already signed up for sandbox access and selected the Custom Build path. We'd appreciate guidance on:
1. Can we tag transactions with custom metadata (goal_id) when creating payments/deposits?
2. Can we query/filter transactions by tags to calculate per-goal balances?
3. Multi-user goal implementation options (multiple users contributing to shared goal)
4. Timeline for production access
5. Required user data for KYC/AML

Thank you for your time. We're excited to integrate with Unit!

Best regards,
[Your Name]
Soteria Team
```

---

### One-Liner (For Quick Forms)

```
Goal-based savings app: 1 Unit account per user (all goals share same account), track goals via transaction tags. ACH transfers from user's existing banks. Need Custom Build API access. No legal team - require full compliance handling by Unit.
```

---

## Which to Use?

- **Short Version**: For quick forms or initial contact
- **Detailed Version**: For support tickets or detailed requests
- **Email Version**: For professional outreach to Unit sales/support
- **One-Liner**: For very short form fields

---

## Key Points to Emphasize

1. ✅ Goal-based savings (not generic banking)
2. ✅ Dedicated accounts per goal
3. ✅ ACH transfers from external accounts
4. ✅ Multi-user shared goals
5. ✅ No legal team - need compliance handled
6. ✅ Custom Build API (not Ready-to-Launch)

