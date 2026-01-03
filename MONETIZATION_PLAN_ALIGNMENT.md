# Soteria Monetization Plan - Code Alignment Analysis

## ✅ Implemented Features

### 1. Subscription Infrastructure
- **Status**: ✅ Complete
- **Location**: `SubscriptionService.swift`
- **Notes**: 
  - Monthly and yearly products configured
  - ⚠️ **Product IDs need updating**: Currently `com.soteria.premium.monthly` and `com.soteria.premium.yearly`
  - Spec requires: $4.99/month, $39.99/year (product IDs should match App Store Connect)

### 2. Quiet Hours Limits
- **Status**: ✅ Complete
- **Location**: `QuietHoursView.swift`, `QuietHoursService.swift`
- **Implementation**:
  - Free: 1 schedule limit (enforced at line 97, 139 in `QuietHoursView.swift`)
  - Premium: Unlimited schedules
  - Paywall triggered when trying to create 2nd schedule

### 3. App Monitoring Limits
- **Status**: ✅ Complete
- **Location**: `SettingsView.swift` (line 464)
- **Implementation**:
  - Free: 1 app limit (`maxApps: subscriptionService.isPremium ? nil : 1`)
  - Premium: Unlimited apps
  - Paywall triggered when trying to add 2nd app

### 4. AI Features (Partial)
- **Status**: ⚠️ Partially Implemented
- **Location**: `BehavioralAIService.swift`
- **Implementation**:
  - ✅ AI service exists with timing recommendations, amount suggestions, copy variants
  - ❌ **NOT GATED**: AI features are available to all users (should be premium-only)
  - ❌ **Missing**: Guardrails for free tier (AI should only suggest, not block)

## ❌ Missing Features

### 1. Decision Windows Daily Limit
- **Status**: ❌ **NOT IMPLEMENTED**
- **Required**:
  - Free: Max 1 Decision Window per day
  - Premium: Up to 3 Decision Windows per day
- **Current State**: No limit enforcement in `DecisionWindowsService.swift` or `DecisionWindowsView.swift`
- **Action Needed**: Add daily limit check before allowing window creation

### 2. Power Actions (Premium-Only)
- **Status**: ❌ **NOT IMPLEMENTED**
- **Required Actions**:
  - `SAVE_AND_HOLD`: Save now, tagged as "Today's Protection" (label only)
  - `SPLIT_DECISION`: "I'll probably spend later — save $X anyway" (immediate manual save)
  - `SAVE_LATER_COMMITMENT`: User sets reminder for later same day (no auto-transfer)
- **Current State**: Only base actions exist (`microSave`, `spendGate`, `pauseIntention`)
- **Action Needed**: 
  - Add new `CommitmentType` cases
  - Add UI in `DecisionWindowPromptView.swift`
  - Gate behind `subscriptionService.isPremium`

### 3. Product IDs & Pricing
- **Status**: ⚠️ **NEEDS VERIFICATION**
- **Current**: Generic product IDs
- **Required**: Match App Store Connect product IDs for $4.99/month and $39.99/year
- **Action Needed**: Update `SubscriptionService.swift` product IDs

### 4. Paywall Copy
- **Status**: ⚠️ **NEEDS UPDATE**
- **Current**: Generic premium features list
- **Required**: Match spec copy:
  - Title: "More moments of protection"
  - Body: "Soteria Plus gives you more chances to pause — with smarter timing and stronger save options."
  - Bullets: Unlimited Quiet Hours, Up to 3 Decision Windows per day, Smarter save suggestions, Enhanced decision actions
- **Action Needed**: Update `PaywallView.swift`

### 5. AI Features Gating
- **Status**: ❌ **NOT GATED**
- **Required**: AI features should be premium-only
- **Current**: `BehavioralAIService` is accessible to all users
- **Action Needed**: 
  - Gate `generateTimingRecommendation` behind premium check
  - Gate `generateAmountSuggestion` behind premium check
  - Gate `selectCopyVariant` behind premium check
  - Show locked preview for free users

### 6. Upgrade Trigger Points
- **Status**: ⚠️ **PARTIALLY IMPLEMENTED**
- **Required Triggers**:
  - ✅ User tries to add 2nd Decision Window (needs daily limit check first)
  - ✅ User tries to add 2nd Quiet Hours target app
  - ❌ User taps a Power Action (not implemented)
  - ❌ User receives an AI timing suggestion (locked preview not implemented)
- **Action Needed**: Add remaining triggers

## 📋 Implementation Checklist

### Priority 1: Critical Missing Features
- [ ] Add Decision Windows daily limit (free: 1, premium: 3)
- [ ] Implement Power Actions (SAVE_AND_HOLD, SPLIT_DECISION, SAVE_LATER_COMMITMENT)
- [ ] Gate AI features behind premium subscription
- [ ] Update PaywallView copy to match spec

### Priority 2: Configuration Updates
- [ ] Verify/update product IDs in SubscriptionService
- [ ] Add upgrade trigger for Power Actions
- [ ] Add locked preview for AI timing suggestions

### Priority 3: Testing & Validation
- [ ] Test free tier limits are enforced
- [ ] Test premium unlocks work immediately after purchase
- [ ] Verify no notifications increase with premium
- [ ] Confirm all money movement remains user-initiated

## 🎯 Acceptance Criteria Status

| Criteria | Status | Notes |
|----------|--------|-------|
| Free users cannot exceed limits | ⚠️ Partial | Decision Windows limit missing |
| Plus unlocks apply immediately after purchase | ✅ Yes | SubscriptionService handles this |
| No notifications increase with Plus | ✅ Yes | Notifications are not gated |
| All money movement remains user-initiated | ✅ Yes | No auto-transfers implemented |
| AI suggestions never block actions | ✅ Yes | AI only suggests |
| App remains fully usable without subscription | ✅ Yes | Free tier is functional |

