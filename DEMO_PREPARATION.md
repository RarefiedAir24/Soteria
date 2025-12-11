# Demo Preparation for Plaid - Next Week

## What to Show

### 1. Account Connection Flow ✅
- **Show**: User taps "Connect Accounts" in Settings
- **Demonstrate**: Plaid Link UI opens
- **Use**: Sandbox credentials (`user_good` / `pass_good`)
- **Result**: Accounts connected, displayed in app

### 2. Balance Reading ✅
- **Show**: Connected accounts with balances
- **Demonstrate**: Real-time balance display
- **Explain**: Read-only access, no modification

### 3. Protection Flow (Virtual Savings Mode) ✅
- **Show**: User unblocks app → chooses to save
- **Demonstrate**: "Save $10?" prompt
- **Result**: Virtual savings tracked (since we can't do same-bank transfers in demo)
- **Explain**: This is for users without savings accounts OR same-bank scenario

### 4. UI/UX Flow ✅
- **Show**: Complete user journey
- **Demonstrate**: Settings → Savings Settings → Connect Accounts
- **Show**: PauseView → Unblock → Save Money prompt
- **Result**: Smooth, intuitive experience

## What to Explain

### 1. The Limitation We Learned
- **Issue**: Plaid can't transfer between accounts at same bank
- **Impact**: If user's checking and savings are at same institution, transfer won't work
- **Solution**: We'll handle this gracefully (see below)

### 2. Our Solution Strategy

**For Same-Bank Scenario:**
- Detect if accounts are at same institution
- Show message: "Your accounts are at the same bank. Set up an external transfer or use virtual savings mode."
- Option A: Guide user to set up external transfer (one-time)
- Option B: Use virtual savings mode (track amounts, no actual transfer)

**For Different Banks:**
- Use Plaid Transfer API (this works!)
- Show successful transfer flow

**For No Savings Account:**
- Virtual savings mode (already implemented)
- Guide user to create savings account
- Or partner with BaaS provider for account creation

### 3. Architecture
- **Backend**: AWS Lambda + API Gateway
- **Storage**: DynamoDB (encrypted access tokens)
- **Security**: Firebase Auth, encrypted tokens, read-only balances
- **Compliance**: We never hold money, only facilitate transfers

### 4. User Experience
- **Seamless**: Account connection via Plaid Link
- **Transparent**: Users see balances, transfer history
- **Flexible**: Works with or without savings accounts
- **Safe**: All transfers require user confirmation

## What Needs to Be Working

### Must Have (Critical):
- [ ] Plaid Link integration working (sandbox)
- [ ] Account connection flow complete
- [ ] Balance reading functional
- [ ] UI polished and ready
- [ ] Virtual savings mode working

### Nice to Have (If Time):
- [ ] Transfer flow (for different banks scenario)
- [ ] Error handling for same-bank detection
- [ ] Transfer history display

## Demo Script

### Opening (2 min)
1. "Soteria is a behavioral finance app that helps users save money"
2. "We use Plaid for secure account connection and transfers"
3. "Let me show you how it works"

### Account Connection (3 min)
1. Open app → Settings → Savings Settings
2. Tap "Connect Accounts"
3. Plaid Link opens
4. Use sandbox credentials
5. Show connected accounts with balances

### Protection Flow (3 min)
1. Show PauseView (when app is blocked)
2. User chooses to unblock
3. "Save $10?" prompt appears
4. Show virtual savings tracking
5. Explain: "For same-bank or no-savings scenarios, we track amounts virtually"

### Q&A Prep (2 min)
- Be ready to discuss:
  - Same-bank transfer limitation
  - Account creation strategy
  - Compliance and security
  - Pricing and production access

## Technical Setup Checklist

### Before Demo:
- [ ] Sandbox credentials configured in Lambda
- [ ] Lambda functions deployed
- [ ] API Gateway URL updated in PlaidService.swift
- [ ] DynamoDB tables created
- [ ] App builds and runs without errors
- [ ] Plaid Link SDK installed (pod install)
- [ ] Test account connection works
- [ ] Test balance reading works

### Demo Environment:
- [ ] Use sandbox environment
- [ ] Have test credentials ready (`user_good` / `pass_good`)
- [ ] App running on device or simulator
- [ ] Internet connection stable
- [ ] Screen sharing ready (if remote)

## Key Talking Points

### What We're Building:
- "Behavioral finance app that turns moments of self-control into savings"
- "Users connect accounts, and when they choose protection, we transfer money to savings"
- "We never hold money - it stays in user's bank accounts"

### How We Use Plaid:
- "Plaid Link for secure account connection"
- "Transfer API for moving money between accounts (different banks)"
- "Balance API for showing savings progress"
- "Accounts API for detecting account types"

### Handling Limitations:
- "We learned Plaid can't do same-bank transfers"
- "We handle this with virtual savings mode or by guiding users to set up external transfers"
- "For account creation, we're exploring BaaS partnerships or guiding users to create accounts at their banks"

### Security & Compliance:
- "Access tokens stored encrypted in AWS DynamoDB"
- "We only read balances, never modify accounts"
- "All transfers require explicit user confirmation"
- "We follow Plaid's security best practices"

## Questions They Might Ask

### Technical:
- "How do you detect same-bank accounts?"
- "What happens if transfer fails?"
- "How do you handle insufficient funds?"
- "What's your error handling strategy?"

### Business:
- "What's your monetization model?"
- "How many users do you expect?"
- "What's your go-to-market strategy?"

### Compliance:
- "Are you a money transmitter?"
- "What licenses do you need?"
- "How do you handle user data?"

## Post-Demo Follow-Up

### What to Ask:
- "What's the timeline for Transfer API production access?"
- "Do you have recommended BaaS partners for account creation?"
- "What's the best practice for handling same-bank transfers?"
- "Can we get pricing information?"
- "What's the approval process for production?"

## Demo Day Checklist

### Morning Of:
- [ ] Test all flows one more time
- [ ] Have backup plan if something breaks
- [ ] Prepare screen recording (backup)
- [ ] Have questions ready
- [ ] Review talking points

### During Demo:
- [ ] Stay calm if something doesn't work
- [ ] Explain what you're showing
- [ ] Be honest about limitations
- [ ] Show enthusiasm for the product
- [ ] Ask questions when appropriate

### After Demo:
- [ ] Send thank you email
- [ ] Follow up on any questions
- [ ] Document any new information
- [ ] Update implementation plan based on feedback

