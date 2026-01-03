# Unit API Research - Goal Savings Integration

## API Documentation Review
**Source**: https://www.unit.co/docs/api/

---

## Key Findings

### ✅ **Custom Build Path Confirmed**
- Full API access available
- Sandbox environment: https://api.s.unit.sh/
- Live environment: https://api.unit.co/
- Dashboard: https://app.s.unit.sh/ (sandbox) or https://app.unit.co/ (live)

### ✅ **Account Creation Available**
- **Deposit Accounts** endpoint exists
- Can create accounts programmatically
- Tags system for metadata (perfect for goals!)

### ✅ **SDKs Available**
- TypeScript/Node.js: https://github.com/unit-finance/unit-node-sdk
- Python: https://github.com/unit-finance/unit-python-sdk
- Ruby: https://github.com/unit-finance/unit-ruby-sdk
- Java: https://github.com/unit-finance/unit-openapi-java-sdk

### ✅ **Testing Tools**
- Postman Collection available
- Sandbox with simulations
- Immediate access after signup

---

## Relevant API Endpoints for Goals

### 1. **Accounts** (Deposit Accounts)
```
POST /accounts
GET /accounts/{id}
```
- Create deposit accounts for users
- Each account is FDIC-insured
- Can use **tags** to mark accounts as goals

### 2. **Tags System** (Perfect for Goals!)
```json
{
  "tags": {
    "purpose": "goal",
    "goal_id": "trip-to-hawaii-123",
    "goal_name": "Trip to Hawaii",
    "target_amount": "2000.00"
  }
}
```
- Attach metadata to accounts
- Search accounts by tags
- Update tags as goals progress

### 3. **Transactions**
```
GET /accounts/{id}/transactions
```
- Track deposits to goals
- Monitor goal progress
- Transaction history

### 4. **Payments**
```
POST /payments
```
- ACH transfers from user's bank → Unit goal account
- External payments
- Internal transfers

---

## Architecture for Goal-Based Accounts

### ✅ **Recommended: One Account Per User (All Goals Share Same Account)**

```
User → 1 Unit Account
  └── All goals tracked via transactions/tags
      ├── Transaction 1 → Goal "Hawaii" ($50)
      ├── Transaction 2 → Goal "Hawaii" ($100)
      ├── Transaction 3 → Goal "Emergency" ($200)
      └── Transaction 4 → Goal "Car" ($150)
```

**Architecture:**
- **1 Unit account per user** (created when user creates first goal)
- **All goals share the same account**
- **Goals tracked via transaction metadata/tags**
- **Balance tracking**: Sum transactions per goal to show progress

**Implementation:**
- Create 1 deposit account when user creates first goal
- Tag transactions with `goal_id` when deposits are made
- Query transactions by `goal_id` to calculate per-goal balances
- Total account balance = sum of all goal balances

**Pros:**
- ✅ Simpler (one account per user)
- ✅ Lower cost (fewer accounts)
- ✅ Easier account management
- ✅ All funds in one FDIC-insured account
- ✅ Can still track per-goal via transaction tags

**How It Works:**
1. User creates first goal → Create Unit account
2. User makes deposit → Transfer to Unit account, tag transaction with `goal_id`
3. Show goal progress → Sum transactions tagged with that `goal_id`
4. User creates more goals → Use same account, tag new transactions

---

## Getting Started Steps

### 1. Sign Up for Sandbox
- **Link**: https://app.s.unit.sh/
- **What you get**: Immediate access, API tokens, test environment
- **Time**: Instant

### 2. Get API Token
- Go to Dashboard → Developer → API Tokens
- Create token with appropriate scopes
- Use for authentication

### 3. Test Account Creation
```bash
# Example API call
POST https://api.s.unit.sh/accounts
Authorization: Bearer YOUR_TOKEN
Content-Type: application/vnd.api+json

{
  "data": {
    "type": "depositAccount",
    "attributes": {
      "depositProduct": "checking",
      "tags": {
        "goal_id": "hawaii-trip-123",
        "goal_name": "Trip to Hawaii",
        "purpose": "goal"
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

### 4. Explore Accounts Endpoint
- Check if sub-accounts are supported
- Verify tags work for goal tracking
- Test balance queries

---

## Key Questions to Answer

1. **Sub-Accounts**: Does Unit support creating sub-accounts under a main account?
   - Check: `/accounts` endpoint documentation
   - Look for: "sub-account", "child account", "nested account"

2. **Goal Tagging**: Can we use tags to organize goals?
   - ✅ Confirmed: Tags are supported on deposit accounts
   - Can search by tags: `?filter[tags][goal_id]=hawaii-trip-123`

3. **Multi-User Goals**: How to handle shared goals?
   - Check: Joint account support
   - Or: Multiple customers on one account

4. **Transfers**: How to transfer from Plaid → Unit?
   - Check: `/payments` endpoint
   - Look for: ACH transfer, external payment

---

## Next Steps

1. ✅ **Sign up**: https://app.s.unit.sh/
2. ✅ **Get API token**: Dashboard → Developer → API Tokens
3. ✅ **Import Postman collection**: Test endpoints immediately
4. ✅ **Read Accounts docs**: https://www.unit.co/docs/api/accounts
5. ✅ **Test account creation**: Create test goal account
6. ✅ **Test tags**: Verify goal tagging works
7. ✅ **Contact Unit**: Ask about sub-accounts for goals

---

## Resources

- **API Docs**: https://www.unit.co/docs/api/
- **Sandbox Dashboard**: https://app.s.unit.sh/
- **Postman Collection**: Available in docs
- **SDKs**: GitHub links in docs
- **OpenAPI Spec**: Available for code generation

---

## Integration Timeline

- **Week 1**: Sandbox exploration, API testing
- **Week 2**: Account creation implementation
- **Week 3**: Transfer integration (Plaid → Unit)
- **Week 4**: Goal tagging and tracking
- **Week 5+**: Production approval

**Total: ~4-6 weeks**

