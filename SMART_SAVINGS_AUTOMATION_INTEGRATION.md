# Smart Savings Suggestions - Integration Guide
## How It Works with Existing App

**Important Clarification**: "Smart Suggestions" means **intelligent recommendations**, not automatic transfers. All saves are **user-initiated and confirmed**. Even with Plaid connected, users must manually confirm before any money moves. The "smart" part is in calculating optimal amounts, not in executing transfers.

---

## Overview

**Smart Savings Automation** enhances the existing Decision Window experience by adding intelligent, goal-aware amount suggestions. It builds on your current infrastructure without requiring major rewrites.

---

## Current Flow (What You Have Now)

### When User Opens Decision Window (via notification tap):

1. **Decision Window notification** is sent at scheduled time
2. User **taps notification** → App opens
3. **DecisionWindowPromptView** appears (via `DecisionWindowActive` notification)
4. User sees "Lock a Micro-Save" option
5. **BehavioralAIService** generates amount suggestions (premium only)
6. User manually enters amount OR taps AI suggestion buttons
7. User clicks "Save" button
8. Amount is saved via `PlaidService.recordManualDeposit()` (user-initiated)

### Current AI Suggestions:
- Based on: Recent success/failure, savings patterns, goal context
- Returns: Array of suggested amounts (e.g., [1, 2, 3, 5])
- Default: One amount pre-selected
- **Limitation**: Generic amounts, not goal-specific

---

## Enhanced Flow (With Smart Savings Suggestions)

### When User Opens Decision Window (via notification tap or in-app):

1. **DecisionWindowPromptView** appears (triggered by notification tap or in-app)
2. User sees "Lock a Micro-Save" option
3. **SmartSavingsService** (NEW) calculates optimal amount:
   - Checks active goal progress
   - Finds nearest milestone (e.g., $500, $1000, 25%, 50%)
   - Calculates amount needed to reach milestone
   - Considers deadline urgency
   - Factors in savings velocity
4. **Enhanced UI** shows:
   - **Primary suggestion**: "Save $12.50 to reach $500 milestone"
   - **Round-up option**: "Or save $2.50 to reach $490"
   - **Impact preview**: "This moves you 3.2 days closer"
   - **One-tap confirmation** button with suggested amount (pre-filled)
5. User taps suggested amount OR manually enters
6. User clicks "Save" button to confirm
7. Amount is saved via existing flow (user-initiated, same as before)

**Note**: This works when:
- ✅ User taps Decision Window notification (opens `DecisionWindowPromptView`)
- ✅ User opens app and Decision Window is active (in-app prompt)
- ✅ User manually opens Decision Window from settings

---

## Technical Integration Points

### 1. New Service: `SmartSavingsService`

**Location**: `soteria/Services/SmartSavingsService.swift`

**Purpose**: Calculates optimal save amounts based on goals and milestones

**Dependencies**:
- `GoalsService` - Get active goals
- `GoalImpactService` - Calculate impact
- `PremiumAnalyticsService` - Get savings velocity
- `BehavioralAIService` - Get user patterns

**Key Functions**:
```swift
// Calculate optimal amount to reach next milestone
func calculateOptimalAmount(for goal: SavingsGoal) -> SmartSuggestion?

// Find nearest milestone
func findNearestMilestone(for goal: SavingsGoal) -> Milestone?

// Calculate round-up amount
func calculateRoundUpAmount(current: Double, target: Double) -> Double?

// Get smart suggestions with reasoning
func getSmartSuggestions(for goal: SavingsGoal) -> [SmartSuggestion]
```

### 2. Enhanced `BehavioralAIService`

**Current**: Returns generic amounts [1, 2, 3, 5]

**Enhanced**: Integrates with `SmartSavingsService` to return goal-aware amounts

**Change**: Minimal - just call `SmartSavingsService` before generating suggestions

```swift
// In BehavioralAIService.generateAmountSuggestion()
func generateAmountSuggestion(for windowId: String) -> AmountSuggestion? {
    // ... existing code ...
    
    // NEW: Get smart suggestions if premium and has active goal
    if subscriptionService.isPremium,
       let activeGoal = goalsService.activeGoal {
        let smartSuggestions = SmartSavingsService.shared.getSmartSuggestions(for: activeGoal)
        // Merge smart suggestions with behavioral suggestions
        suggestedAmounts = mergeSuggestions(smartSuggestions, behavioralAmounts)
    }
    
    // ... rest of existing code ...
}
```

### 3. Enhanced `DecisionWindowPromptView`

**Current UI**:
```
┌─────────────────────────────┐
│ Lock a Micro-Save          │
│                             │
│ How much to save today?    │
│ $ [____]                    │
│                             │
│ [ $1 ] [ $2 ] [ $3 ] [ $5 ] │ ← AI suggestions
│                             │
│ [ Save $X today ]           │
└─────────────────────────────┘
```

**Enhanced UI (Premium)**:
```
┌─────────────────────────────┐
│ Lock a Micro-Save          │
│                             │
│ 🎯 Smart Suggestion         │
│ Save $12.50 to reach        │
│ $500 milestone              │
│ (You're at $487.50)         │
│                             │
│ 💡 Or round up:             │
│ Save $2.50 to reach $490    │
│                             │
│ How much to save today?     │
│ $ [12.50] ← Pre-filled      │
│                             │
│ [ $12.50 ] [ $2.50 ] [ $5 ] │ ← Smart + AI suggestions
│                             │
│ This moves you 3.2 days     │
│ closer to your goal         │
│                             │
│ [ Save $12.50 ] ← One-tap   │
└─────────────────────────────┘
```

**Code Changes**:
- Add `@State private var smartSuggestion: SmartSuggestion?`
- Call `SmartSavingsService` in `onAppear`
- Display smart suggestion card above amount field
- Pre-fill amount field with smart suggestion
- Show impact calculation

### 4. Integration with `GoalImpactService`

**Current**: `GoalImpactService` calculates impact for any amount

**Enhanced**: `SmartSavingsService` uses `GoalImpactService` to:
- Calculate impact for suggested amounts
- Show "days closer" for each suggestion
- Display progress bar updates

**No changes needed** - just call existing functions:
```swift
let impact = goalImpactService.calculateImpact(amount: suggestedAmount, goal: goal)
// impact.daysCloser = 3.2 days
// impact.projectedProgress = 0.975 (97.5%)
```

---

## User Experience Flow

### Scenario 1: User Has Active Goal

**Current**:
1. Decision Window opens
2. AI suggests: [ $1, $2, $3, $5 ]
3. User picks $3
4. Saves $3

**With Smart Automation**:
1. Decision Window opens
2. **Smart suggestion**: "Save $12.50 to reach $500 milestone"
3. **Round-up option**: "Or save $2.50 to reach $490"
4. **Impact shown**: "3.2 days closer"
5. Amount field pre-filled with $12.50
6. User taps "Save $12.50" button (confirms the save)
7. User-initiated save executes (same flow as before - no auto-transfer)
8. Saves $12.50

**Result**: User saves 4x more ($12.50 vs $3) with same effort

### Scenario 2: Goal Deadline Approaching

**Current**:
1. Goal deadline in 5 days
2. User needs $50 more
3. AI suggests: [ $1, $2, $3, $5 ]
4. User saves $5
5. **Problem**: Won't reach goal in time

**With Smart Automation**:
1. Goal deadline in 5 days
2. User needs $50 more
3. **Smart suggestion**: "Save $10/day to reach goal on time"
4. **Warning**: "You're behind schedule - increase saves"
5. **Auto-adjust**: Suggests $10 instead of $3 (amount field pre-filled)
6. User confirms and saves $10 (user-initiated, not automatic)
7. **Result**: On track to reach goal

---

## Code Structure

### New Files Needed

1. **`SmartSavingsService.swift`**
   - Core automation logic
   - Milestone detection
   - Optimal amount calculation

2. **`MilestoneDetector.swift`** (optional, can be in SmartSavingsService)
   - Finds milestones (25%, 50%, 75%, round numbers)
   - Calculates amounts needed

3. **Enhanced `DecisionWindowPromptView.swift`**
   - UI for smart suggestions
   - Integration with existing flow

### Modified Files

1. **`BehavioralAIService.swift`**
   - Add call to `SmartSavingsService`
   - Merge smart + behavioral suggestions

2. **`DecisionWindowPromptView.swift`**
   - Add smart suggestion UI
   - Pre-fill amount field
   - Show impact calculations

### No Changes Needed

- ✅ `GoalsService` - Already has goal data
- ✅ `GoalImpactService` - Already calculates impact
- ✅ `PlaidService` - Already handles saves
- ✅ `PremiumAnalyticsService` - Already tracks velocity

---

## Implementation Example

### Step 1: Create SmartSavingsService

```swift
// soteria/Services/SmartSavingsService.swift

import Foundation

struct SmartSuggestion {
    let amount: Double
    let reason: String
    let milestone: Milestone?
    let impact: GoalImpact?
    let priority: Int // 1 = highest priority
}

struct Milestone {
    let targetAmount: Double
    let type: MilestoneType
    let label: String
    
    enum MilestoneType {
        case percentage(Int) // 25%, 50%, 75%
        case roundNumber // $100, $500, $1000
        case goalTarget // Final goal amount
    }
}

class SmartSavingsService {
    static let shared = SmartSavingsService()
    
    private let goalsService = GoalsService.shared
    private let goalImpactService = GoalImpactService.shared
    private let premiumAnalytics = PremiumAnalyticsService.shared
    
    private init() {}
    
    /// Get smart suggestions for active goal
    func getSmartSuggestions(for goal: SavingsGoal) -> [SmartSuggestion] {
        guard SubscriptionService.shared.isPremium else {
            return [] // Free users don't get smart suggestions
        }
        
        var suggestions: [SmartSuggestion] = []
        
        // 1. Find nearest milestone
        if let milestone = findNearestMilestone(for: goal) {
            let amountNeeded = milestone.targetAmount - goal.currentAmount
            if amountNeeded > 0 && amountNeeded <= 100 { // Reasonable amount
                let impact = goalImpactService.calculateImpact(amount: amountNeeded, goal: goal)
                suggestions.append(SmartSuggestion(
                    amount: amountNeeded,
                    reason: "Reach \(milestone.label)",
                    milestone: milestone,
                    impact: impact,
                    priority: 1
                ))
            }
        }
        
        // 2. Calculate round-up to next $10/$50/$100
        if let roundUp = calculateRoundUpAmount(current: goal.currentAmount, target: goal.targetAmount) {
            let impact = goalImpactService.calculateImpact(amount: roundUp, goal: goal)
            suggestions.append(SmartSuggestion(
                amount: roundUp,
                reason: "Round up to \(Int(goal.currentAmount + roundUp))",
                milestone: nil,
                impact: impact,
                priority: 2
            ))
        }
        
        // 3. Auto-adjust based on deadline
        if let adjustedAmount = calculateAdjustedAmount(for: goal) {
            let impact = goalImpactService.calculateImpact(amount: adjustedAmount, goal: goal)
            suggestions.append(SmartSuggestion(
                amount: adjustedAmount,
                reason: "Stay on track for deadline",
                milestone: nil,
                impact: impact,
                priority: 3
            ))
        }
        
        return suggestions.sorted { $0.priority < $1.priority }
    }
    
    private func findNearestMilestone(for goal: SavingsGoal) -> Milestone? {
        let current = goal.currentAmount
        let target = goal.targetAmount
        
        // Check percentage milestones
        let milestones: [Milestone] = [
            Milestone(targetAmount: target * 0.25, type: .percentage(25), label: "25% milestone"),
            Milestone(targetAmount: target * 0.50, type: .percentage(50), label: "50% milestone"),
            Milestone(targetAmount: target * 0.75, type: .percentage(75), label: "75% milestone"),
        ]
        
        // Check round number milestones
        let roundNumbers: [Double] = [50, 100, 250, 500, 1000, 2500, 5000]
        for roundNum in roundNumbers {
            if roundNum > current && roundNum <= target {
                milestones.append(Milestone(
                    targetAmount: roundNum,
                    type: .roundNumber,
                    label: "$\(Int(roundNum)) milestone"
                ))
            }
        }
        
        // Find nearest milestone
        return milestones
            .filter { $0.targetAmount > current && $0.targetAmount <= target }
            .min { abs($0.targetAmount - current) < abs($1.targetAmount - current) }
    }
    
    private func calculateRoundUpAmount(current: Double, target: Double) -> Double? {
        // Round up to next $10
        let nextTen = ceil(current / 10) * 10
        if nextTen > current && nextTen <= target {
            return nextTen - current
        }
        
        // Round up to next $50
        let nextFifty = ceil(current / 50) * 50
        if nextFifty > current && nextFifty <= target {
            return nextFifty - current
        }
        
        return nil
    }
    
    private func calculateAdjustedAmount(for goal: SavingsGoal) -> Double? {
        guard let targetDate = goal.targetDate else { return nil }
        
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        guard daysRemaining > 0 else { return nil }
        
        let remaining = goal.remainingAmount
        let dailyNeeded = remaining / Double(daysRemaining)
        
        // Get current velocity
        let velocity = premiumAnalytics.calculateSavingsVelocity(for: goal)
        
        // If behind schedule, suggest higher amount
        if velocity.averageDailySavings < dailyNeeded {
            let catchUpAmount = dailyNeeded * 1.2 // 20% buffer
            return min(catchUpAmount, remaining) // Don't exceed goal
        }
        
        return nil
    }
}
```

### Step 2: Enhance DecisionWindowPromptView

```swift
// In DecisionWindowPromptView.swift

@ObservedObject private var smartSavingsService = SmartSavingsService.shared
@State private var smartSuggestions: [SmartSuggestion] = []

// In onAppear:
.onAppear {
    // ... existing code ...
    
    // Get smart suggestions if premium
    if subscriptionService.isPremium,
       let activeGoal = goalsService.activeGoal {
        smartSuggestions = smartSavingsService.getSmartSuggestions(for: activeGoal)
        
        // Pre-fill with top suggestion
        if let topSuggestion = smartSuggestions.first {
            microSaveAmount = String(format: "%.2f", topSuggestion.amount)
        }
    }
}

// In UI (Micro-Save section):
if !smartSuggestions.isEmpty {
    // Smart Suggestion Card
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.orange)
            Text("Smart Suggestion")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.reverBlue)
        }
        
        if let topSuggestion = smartSuggestions.first {
            Text("Save $\(String(format: "%.2f", topSuggestion.amount))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.midnightSlate)
            
            Text(topSuggestion.reason)
                .font(.system(size: 12))
                .foregroundColor(.softGraphite)
            
            if let impact = topSuggestion.impact {
                Text("This moves you \(impact.formattedDaysCloser) closer")
                    .font(.system(size: 12))
                    .foregroundColor(.reverBlue)
            }
        }
    }
    .padding(12)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.orange.opacity(0.1))
    )
}
```

---

## Integration Benefits

### 1. Minimal Code Changes
- ✅ Builds on existing services
- ✅ No breaking changes
- ✅ Backward compatible (free users unaffected)

### 2. Leverages Existing Infrastructure
- ✅ Uses `GoalImpactService` for impact calculations
- ✅ Uses `BehavioralAIService` for user patterns
- ✅ Uses `PremiumAnalyticsService` for velocity
- ✅ Uses `GoalsService` for goal data

### 3. Clear Premium Differentiation
- ✅ Free: Manual entry only
- ✅ Premium: Smart suggestions + manual entry
- ✅ Easy to gate behind subscription

### 4. Incremental Implementation
- ✅ Phase 1: Milestone detection (Week 1)
- ✅ Phase 2: Round-up calculations (Week 1)
- ✅ Phase 3: Auto-adjust logic (Week 2)
- ✅ Phase 4: UI integration (Week 2)

---

## User Flow Diagram

```
Decision Window Opens
        │
        ├─→ Free User
        │   └─→ Manual entry only
        │
        └─→ Premium User
            │
            ├─→ Has Active Goal?
            │   │
            │   ├─→ YES
            │   │   │
            │   │   ├─→ SmartSavingsService calculates:
            │   │   │   • Nearest milestone
            │   │   │   • Round-up amount
            │   │   │   • Auto-adjust amount
            │   │   │
            │   │   └─→ UI shows:
            │   │       • Primary suggestion card
            │   │       • Round-up option
            │   │       • Impact preview
            │   │       • Pre-filled amount
            │   │       • One-tap save button
            │   │
            │   └─→ NO
            │       └─→ Falls back to BehavioralAIService
            │           (existing AI suggestions)
            │
            └─→ User confirms save amount
                └─→ User-initiated save (same flow as before)
                    └─→ PlaidService.recordManualDeposit (if Plaid)
                    └─→ OR manual tracking (if no Plaid)
                    └─→ **No automatic transfers** - user always confirms
```

---

## Example Integration Code

### Complete Example: Enhanced DecisionWindowPromptView

```swift
// In DecisionWindowPromptView.swift

struct DecisionWindowPromptView: View {
    // ... existing properties ...
    
    @ObservedObject private var smartSavingsService = SmartSavingsService.shared
    @State private var smartSuggestions: [SmartSuggestion] = []
    @State private var selectedSmartSuggestion: SmartSuggestion? = nil
    
    var body: some View {
        // ... existing code ...
        
        // In Micro-Save section:
        if selectedOption == .microSave {
            VStack(alignment: .leading, spacing: 12) {
                // SMART SUGGESTION CARD (Premium only)
                if subscriptionService.isPremium,
                   !smartSuggestions.isEmpty,
                   let topSuggestion = smartSuggestions.first {
                    smartSuggestionCard(suggestion: topSuggestion)
                }
                
                // Existing AI suggestion header
                if let suggestion = amountSuggestion {
                    // ... existing code ...
                }
                
                // Amount input field
                HStack {
                    Text("$")
                    TextField("0.00", text: $microSaveAmount)
                }
                
                // Smart suggestion buttons + AI suggestion buttons
                if !smartSuggestions.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(smartSuggestions.prefix(3), id: \.amount) { suggestion in
                            smartSuggestionButton(suggestion: suggestion)
                        }
                    }
                }
                
                // Existing AI suggestion buttons
                if let suggestion = amountSuggestion {
                    // ... existing code ...
                }
            }
        }
    }
    
    @ViewBuilder
    private func smartSuggestionCard(suggestion: SmartSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                Text("Smart Suggestion")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.reverBlue)
            }
            
            Text("Save $\(String(format: "%.2f", suggestion.amount))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.midnightSlate)
            
            Text(suggestion.reason)
                .font(.system(size: 13))
                .foregroundColor(.softGraphite)
            
            if let impact = suggestion.impact {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 12))
                    Text("Moves you \(impact.formattedDaysCloser) closer")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.reverBlue)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .onTapGesture {
            microSaveAmount = String(format: "%.2f", suggestion.amount)
            selectedSmartSuggestion = suggestion
        }
    }
    
    @ViewBuilder
    private func smartSuggestionButton(suggestion: SmartSuggestion) -> some View {
        Button(action: {
            microSaveAmount = String(format: "%.2f", suggestion.amount)
            selectedSmartSuggestion = suggestion
        }) {
            VStack(spacing: 4) {
                Text("$\(String(format: "%.0f", suggestion.amount))")
                    .font(.system(size: 14, weight: .semibold))
                if let milestone = suggestion.milestone {
                    Text(milestone.label)
                        .font(.system(size: 10))
                        .lineLimit(1)
                }
            }
            .foregroundColor(selectedSmartSuggestion?.amount == suggestion.amount ? .white : .reverBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedSmartSuggestion?.amount == suggestion.amount
                    ? Color.reverBlue
                    : Color.reverBlue.opacity(0.1)
            )
            .cornerRadius(8)
        }
    }
    
    // In onAppear:
    .onAppear {
        // ... existing code ...
        
        // Load smart suggestions
        if subscriptionService.isPremium,
           let activeGoal = goalsService.activeGoal {
            smartSuggestions = smartSavingsService.getSmartSuggestions(for: activeGoal)
            
            // Pre-fill with top suggestion
            if let topSuggestion = smartSuggestions.first {
                microSaveAmount = String(format: "%.2f", topSuggestion.amount)
                selectedSmartSuggestion = topSuggestion
            }
        }
    }
}
```

---

## Key Integration Points Summary

| Component | Current Role | Enhanced Role |
|-----------|-------------|---------------|
| **BehavioralAIService** | Generates generic amounts | Merges smart + behavioral suggestions |
| **GoalImpactService** | Calculates impact for any amount | Used by SmartSavingsService for impact |
| **DecisionWindowPromptView** | Shows manual entry + AI buttons | Shows smart suggestions + manual entry |
| **GoalsService** | Provides goal data | Used by SmartSavingsService |
| **PremiumAnalyticsService** | Tracks velocity | Used for auto-adjust calculations |

---

## Benefits of This Integration

1. **No Breaking Changes** - Free users unaffected
2. **Incremental** - Can be built feature by feature
3. **Leverages Existing** - Uses current services
4. **Clear Value** - Obvious premium benefit
5. **Easy to Test** - Can test with one goal at a time

---

## Next Steps

1. Create `SmartSavingsService.swift` with milestone detection
2. Add smart suggestion UI to `DecisionWindowPromptView`
3. Integrate with existing `BehavioralAIService`
4. Test with real goals and milestones
5. Add to paywall as premium feature

This integration is **low-risk, high-value** and builds naturally on your existing architecture.

