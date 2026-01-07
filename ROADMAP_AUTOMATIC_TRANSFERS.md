# Automatic Transfers Feature - Roadmap Consideration

## Overview
Feature to enable automatic transfers from checking to savings accounts when users choose to save, without requiring explicit confirmation for each transfer.

## Current State
- ✅ All transfers are **user-initiated** (user must confirm before money moves)
- ✅ Plaid Transfer API integration is complete
- ✅ Backend Lambda functions support transfers
- ✅ User can initiate transfers via decision windows and deposit flows

## Proposed Feature: Automatic Transfers (Opt-In)

### Core Concept
Allow users to opt-in to automatic transfers, where money moves to savings automatically when they choose to save, without requiring confirmation for each transfer.

### User Experience

#### Setup Flow
1. User connects checking + savings accounts via Plaid
2. Settings → Savings Settings → New toggle: "Enable Automatic Transfers"
3. User sees explanation:
   - "When enabled, transfers will happen automatically when you choose to save"
   - "You can disable this at any time"
   - "Transfers will only occur when you explicitly choose to save"
4. Optional: Set transfer limits (max per transfer, max per day/week)

#### During Use
- User chooses to save in decision window → Transfer happens automatically (no confirmation prompt)
- User makes deposit → Transfer happens automatically (if enabled)
- User still has full control - they're choosing to save, just not confirming the transfer

### Technical Requirements

#### Frontend (iOS)
1. **Settings UI**
   - Toggle switch: "Enable Automatic Transfers"
   - Transfer limits configuration (optional)
   - Safety settings (max per day/week)

2. **PlaidService Updates**
   - New property: `automaticTransfersEnabled: Bool`
   - Persist setting in UserDefaults/AWS
   - Modify `initiateTransfer()` to check setting

3. **Decision Window Flow**
   - If automatic transfers enabled: Transfer immediately on "Save" choice
   - If disabled: Show confirmation prompt (current behavior)

4. **Notifications**
   - Send notification when automatic transfer completes
   - Show transfer details in notification
   - Add to transfer history

#### Backend (Lambda)
1. **No changes required** - existing transfer endpoint works
2. **Optional enhancements:**
   - Transfer limits validation
   - Rate limiting per user
   - Transfer failure notifications

### Safety Features

#### Required
- ✅ User must explicitly opt-in (toggle in settings)
- ✅ Transfers only happen when user chooses to save (not truly automatic)
- ✅ Clear notification when transfer occurs
- ✅ Easy way to disable (same toggle)

#### Recommended
- Transfer limits (max amount per transfer)
- Daily/weekly transfer caps
- Balance checks before transfer
- Error handling and retry logic
- Transfer history/audit log

### Implementation Phases

#### Phase 1: Basic Opt-In (MVP)
- Add toggle in Settings
- Modify decision window to skip confirmation if enabled
- Add notification on transfer
- Store setting in UserDefaults

**Timeline:** 1-2 weeks
**Risk:** Low (opt-in, easy to disable)

#### Phase 2: Enhanced Safety
- Transfer limits configuration
- Daily/weekly caps
- Enhanced error handling
- Transfer history UI

**Timeline:** 1 week
**Risk:** Low

#### Phase 3: Advanced Features
- Smart transfer amounts (AI suggestions)
- Scheduled transfers (optional)
- Transfer analytics

**Timeline:** 2-3 weeks
**Risk:** Medium

### User Control & Transparency

#### Always User-Controlled
- ✅ User must opt-in (not default)
- ✅ User chooses when to save (transfer only happens on save choice)
- ✅ User can disable anytime
- ✅ User sees all transfers in history
- ✅ User receives notifications

#### Transparency
- Clear explanation of what "automatic" means
- Notification for every transfer
- Transfer history always visible
- Easy way to review and cancel if needed

### Considerations

#### Pros
- ✅ Reduces friction (no confirmation needed)
- ✅ Can increase savings consistency
- ✅ Still user-initiated (they choose to save)
- ✅ Maintains user control (opt-in, can disable)

#### Cons
- ⚠️ Less explicit confirmation (money moves without "are you sure?")
- ⚠️ Higher risk if errors occur
- ⚠️ May conflict with app's emphasis on intentional saving
- ⚠️ Regulatory/compliance considerations

#### Regulatory/Compliance
- Ensure users understand what's happening
- Clear terms and conditions
- Proper error handling
- Audit trail of all transfers
- User consent documentation

### Alternative Approaches

#### Option 1: "Quick Save" Mode
- User can enable "Quick Save" mode
- When enabled, saves happen with minimal confirmation
- Still requires one tap, but faster flow

#### Option 2: Scheduled Transfers
- User sets up recurring transfers (weekly/monthly)
- Separate from decision window transfers
- More traditional savings automation

#### Option 3: Hybrid Approach
- Default: User-initiated (current)
- Opt-in: Automatic transfers
- Best of both worlds

### Success Metrics

#### Adoption
- % of users who enable automatic transfers
- Transfer frequency (with vs without)
- User retention impact

#### Safety
- Transfer failure rate
- User complaints/issues
- Support tickets related to transfers

#### Engagement
- Savings amount (with vs without)
- Goal completion rate
- User satisfaction

### Decision Criteria

#### Should We Build This?

**Build if:**
- Users request this feature
- Data shows low transfer completion rate with current flow
- Can maintain safety and user control
- Regulatory/compliance team approves

**Don't build if:**
- Current user-initiated flow works well
- Safety concerns outweigh benefits
- Regulatory/compliance issues
- Low user demand

### Timeline Recommendation

**Status:** 📋 **Consider for Future**
**Priority:** Medium
**Suggested Timeline:** Q2-Q3 2025 (after initial launch and user feedback)

**Rationale:**
- Current user-initiated flow is working
- Better to gather user feedback first
- Can validate demand before building
- Allows time for regulatory review

### Related Features

- Smart transfer amounts (AI suggestions)
- Transfer scheduling
- Savings goals automation
- Transfer analytics dashboard

---

## Notes

- This feature maintains user control (opt-in, can disable)
- Transfers still require user to choose to save (not truly automatic)
- Focus on safety, transparency, and user control
- Consider regulatory implications before implementation

