# Plaid Call Notes - Key Findings

## Date: Today's Call with Sophia

### ✅ What We Learned

1. **Demo Scheduled**: Next week - need to prepare demo
2. **Transfer Limitation**: Plaid **cannot transfer between accounts at the same bank** (checking → savings at same institution)
3. **Account Creation**: Plaid **does not create accounts** - we need a separate solution
4. **Solution Needed**: We'll need to bundle another service with Plaid

### ❌ Limitations

- **Same-Bank Transfers**: If user's checking and savings are at the same bank, Plaid Transfer API won't work
- **Account Creation**: No built-in account creation capability
- **Workaround Required**: Need alternative solution for these cases

### 🔄 Updated Architecture Options

## Option 1: Plaid + Bank API (Same-Bank Transfers)

**For same-bank transfers:**
- Use bank's own API (if available)
- Or use ACH via different service
- Or guide users to set up external transfers

**Pros:**
- Direct integration with bank
- Can handle same-bank transfers

**Cons:**
- Each bank has different API
- Complex integration
- May require bank partnerships

## Option 2: Plaid + Banking-as-a-Service (BaaS)

**For account creation:**
- Partner with Unit, Synapse, or similar
- Create "Soteria Savings" account via BaaS
- Use Plaid for existing account connections

**Pros:**
- Can create accounts programmatically
- Handles compliance/regulatory
- Single integration point

**Cons:**
- Additional cost
- Users get new account (not at their existing bank)
- May require additional compliance

## Option 3: Plaid + Manual Account Creation Flow

**For users without savings:**
- Guide users to create savings account at their bank
- Provide instructions/links
- Use Plaid to connect new account once created

**Pros:**
- Simple implementation
- No additional services needed
- Users keep accounts at their preferred bank

**Cons:**
- Requires user action
- Not seamless
- May have drop-off

## Option 4: Plaid + Virtual Savings Only

**Simplified approach:**
- Use Plaid only for account connection and balance reading
- Track "protected" amounts virtually
- Don't do actual transfers
- Focus on behavioral tracking

**Pros:**
- Simplest implementation
- No transfer limitations
- Lower compliance burden

**Cons:**
- No actual money movement
- Less compelling value proposition
- Users may want real savings

## Option 5: Plaid + External Transfer Service

**For same-bank transfers:**
- Use service like Modern Treasury, Stripe, or Dwolla
- Handle ACH transfers separately
- Use Plaid for account connection

**Pros:**
- Can handle same-bank transfers
- Professional payment infrastructure
- Good for scale

**Cons:**
- Additional integration
- Additional cost
- More complexity

### 🎯 Recommended Approach

**Hybrid Solution:**

1. **For Different Banks**: Use Plaid Transfer API (checking at Bank A → savings at Bank B)
2. **For Same Bank**: 
   - Option A: Guide users to set up external transfer (one-time setup)
   - Option B: Use bank's API if available
   - Option C: Use external ACH service (Modern Treasury, etc.)
3. **For No Savings Account**:
   - Guide users to create account at their bank
   - Or partner with BaaS for account creation
   - Or use virtual savings mode (track amounts, no transfers)

### 📋 Demo Preparation (Next Week)

**What to Show:**
1. Account connection flow (Plaid Link)
2. Balance reading
3. Transfer initiation (for different banks)
4. Virtual savings mode (for users without savings)
5. UI/UX of the protection flow

**What to Explain:**
1. How we handle same-bank limitation
2. Account creation strategy
3. User experience for different scenarios
4. Security and compliance approach

### ❓ Questions for Follow-Up

1. Can Plaid detect if accounts are at the same bank before attempting transfer?
2. What's the recommended approach for same-bank transfers?
3. Do you have partner BaaS providers you recommend?
4. Can we use Plaid Balance API to verify account types before transfer?
5. What's the best practice for handling users without savings accounts?

### 🔄 Next Steps

1. **Prepare Demo** - Show working sandbox integration
2. **Decide on Same-Bank Solution** - Choose approach for same-bank transfers
3. **Decide on Account Creation** - Choose approach for users without savings
4. **Update Architecture** - Revise implementation plan
5. **Update UI/UX** - Handle different scenarios gracefully

