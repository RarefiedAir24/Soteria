# Notification to Smart Suggestions Flow
## How Smart Suggestions Appear When User Taps Decision Window Notification

---

## Complete User Journey

### Step 1: Notification Sent

**When**: Decision Window time arrives (e.g., 8:00 AM on weekdays)

**What Happens**:
1. `DecisionWindowsService.checkActiveWindows()` runs every minute
2. Detects window is active (within 5-minute window)
3. Calls `sendDecisionWindowNotification(for: window)`
4. Notification sent with `userInfo: ["type": "decision_window", "windowId": window.id]`

### Step 2: User Taps Notification

**What Happens**:
1. iOS calls `NotificationDelegate.userNotificationCenter(didReceive:)`
2. Sets flags in UserDefaults:
   - `shouldShowDecisionWindowPrompt = true`
   - `activeDecisionWindowId = window.id`
3. Posts `NotificationCenter` notification: `DecisionWindowActive` with window object
4. App opens (if closed) or comes to foreground

### Step 3: DecisionWindowPromptView Appears

**What Happens**:
1. `HomeView` receives `DecisionWindowActive` notification
2. Sets `activeDecisionWindow = window`
3. Sets `showDecisionWindowPrompt = true`
4. `DecisionWindowPromptView` sheet appears with the window

### Step 4: Smart Suggestions Load (NEW - Premium Only)

**What Happens** (in `DecisionWindowPromptView.onAppear`):
1. Check if user is premium
2. Check if user has active goal
3. If both true:
   - Call `SmartSavingsService.getSmartSuggestions(for: activeGoal)`
   - Service calculates:
     - Nearest milestone
     - Round-up amount
     - Auto-adjust amount (if behind schedule)
   - Returns array of `SmartSuggestion` objects
4. Pre-fill amount field with top suggestion
5. Display smart suggestion card in UI

### Step 5: User Sees Smart Suggestions

**UI Shows**:
```
┌─────────────────────────────────┐
│ Decision Window: Morning Save   │
├─────────────────────────────────┤
│                                 │
│ 🎯 Smart Suggestion             │
│ Save $12.50 to reach            │
│ $500 milestone                  │
│ (You're at $487.50)             │
│                                 │
│ This moves you 3.2 days closer  │
│                                 │
│ 💡 Or round up:                 │
│ Save $2.50 to reach $490        │
│                                 │
│ How much to save today?         │
│ $ [12.50] ← Pre-filled          │
│                                 │
│ [ $12.50 ] [ $2.50 ] [ $5 ]    │
│                                 │
│ [ Save $12.50 ]                │
└─────────────────────────────────┘
```

### Step 6: User Confirms Save

**What Happens**:
1. User clicks "Save $12.50" button (or edits amount)
2. `saveCommitment()` function called
3. Creates `DecisionWindowCommitment` with amount
4. **User-initiated save** executes:
   - If Plaid: Opens transfer screen (user confirms)
   - If no Plaid: Records manual deposit (tracking)
5. Amount saved/tracked

---

## Code Flow Diagram

```
Decision Window Time Arrives
        │
        ├─→ DecisionWindowsService.checkActiveWindows()
        │   └─→ sendDecisionWindowNotification()
        │       └─→ UNUserNotificationCenter.add()
        │
        └─→ Notification Sent to User
                │
                └─→ User Taps Notification
                        │
                        ├─→ NotificationDelegate.didReceive()
                        │   └─→ Sets UserDefaults flags
                        │   └─→ Posts "DecisionWindowActive"
                        │
                        └─→ App Opens / Foreground
                                │
                                └─→ HomeView receives notification
                                        │
                                        └─→ Sets showDecisionWindowPrompt = true
                                                │
                                                └─→ DecisionWindowPromptView appears
                                                        │
                                                        ├─→ onAppear triggers
                                                        │   │
                                                        │   ├─→ Check if premium
                                                        │   ├─→ Check if has active goal
                                                        │   └─→ If both: Load smart suggestions
                                                        │       │
                                                        │       └─→ SmartSavingsService.getSmartSuggestions()
                                                        │           ├─→ Find nearest milestone
                                                        │           ├─→ Calculate round-up
                                                        │           ├─→ Check auto-adjust
                                                        │           └─→ Return suggestions
                                                        │
                                                        └─→ UI displays smart suggestions
                                                                │
                                                                └─→ User confirms save
                                                                        │
                                                                        └─→ User-initiated save executes
```

---

## Integration Points

### 1. Notification Tap Handler

**Location**: `SoteriaApp.swift` → `NotificationDelegate`

**Current**: Handles notification tap, sets flags

**Enhancement**: No changes needed - Smart Suggestions load in `DecisionWindowPromptView.onAppear`

### 2. DecisionWindowPromptView

**Location**: `DecisionWindowPromptView.swift`

**Current**: Shows manual entry + AI suggestions

**Enhancement**: 
- Add `SmartSavingsService` call in `onAppear`
- Display smart suggestion card
- Pre-fill amount field

### 3. SmartSavingsService

**Location**: `soteria/Services/SmartSavingsService.swift` (NEW)

**Purpose**: Calculate optimal amounts when view appears

**Triggers**: 
- ✅ When `DecisionWindowPromptView` appears (via notification tap)
- ✅ When `DecisionWindowPromptView` appears (in-app)
- ✅ When user has active goal
- ✅ When user is premium

---

## Example: Complete Flow

### Scenario: User has $487.50 of $500 goal

**8:00 AM - Notification Sent**:
- Decision Window notification: "Time to save - open Soteria"

**8:01 AM - User Taps Notification**:
- App opens
- `DecisionWindowPromptView` appears

**8:01 AM - Smart Suggestions Load**:
- `SmartSavingsService` calculates:
  - Nearest milestone: $500
  - Amount needed: $12.50
  - Impact: 3.2 days closer
- UI shows smart suggestion card

**8:02 AM - User Sees**:
- "Save $12.50 to reach $500 milestone"
- Amount field pre-filled with $12.50
- Impact: "3.2 days closer"

**8:02 AM - User Clicks "Save $12.50"**:
- User-initiated save executes
- If Plaid: Transfer screen opens (user confirms)
- Amount saved

**Result**: User reaches milestone with optimal amount suggestion

---

## Key Points

1. ✅ **Smart Suggestions appear automatically** when `DecisionWindowPromptView` opens
2. ✅ **Works via notification tap** - no special handling needed
3. ✅ **Premium-only** - Free users see manual entry only
4. ✅ **Goal-aware** - Only shows if user has active goal
5. ✅ **User-controlled** - All saves remain user-initiated

---

## Technical Implementation

### No Changes Needed To:
- ✅ Notification sending logic
- ✅ Notification tap handling
- ✅ DecisionWindowPromptView initialization
- ✅ Save execution flow

### Only Add:
- ✅ `SmartSavingsService` call in `DecisionWindowPromptView.onAppear`
- ✅ Smart suggestion UI card
- ✅ Pre-fill amount field with suggestion

**Result**: Seamless integration - Smart Suggestions appear automatically when user taps notification.

