# High-Value Feature Recommendation: Real-Time Goal Impact Intervention

## Executive Summary

**Recommended Feature**: **"Real-Time Goal Impact Calculator with Emotional Anchoring"** - A moment-of-decision intervention that shows users the tangible, emotional cost of their impulse purchase in real-time, combining goal visualization, delay calculations, and past regret reminders.

**Why This Feature**: Transforms the current "friction" (easily bypassed) into a powerful behavioral intervention that actually changes decisions at the moment of impulse.

---

## Current State Assessment

### What Soteria Already Has (Strengths)
✅ **Savings Goals** - Visual goals with photos, progress tracking, money tree
✅ **Decision Windows (Decision Notifications)** - Scheduled notifications that prompt users to save before spending
✅ **Behavioral Tracking** - Mood, regret logging, risk assessment
✅ **Micro-Commitments** - Small savings commitments
✅ **Streaks** - Gamification through streaks
✅ **Basic Goal Anchoring** - DecisionWindowPromptView already shows goal info (but minimal)

### What's Missing (Gaps Identified)
❌ **Emotional Connection at Decision Moment** - Goal anchoring exists but is minimal (basic card only)
❌ **Tangible Cost Visualization** - No calculation of "saving $X = Y days closer to goal"
❌ **Past Regret Reminders** - Regrets are logged but not shown during Decision Windows
❌ **Real-Time Impact** - No immediate feedback on how saving affects goals
❌ **Future Self Visualization** - Goals have photos but aren't prominently displayed in DecisionWindowPromptView

### Competitive Landscape Analysis

**Traditional Savings Apps** (Mint, YNAB, Qapital, Digit, Acorns):
- Focus: Budgeting, expense tracking, automatic transfers
- Missing: Behavioral intervention, app blocking, moment-of-decision prompts
- Gap: None address the emotional/psychological aspect of impulse spending

**What Makes This Unique**:
- No competitor shows real-time goal delay calculations
- No competitor combines emotional (photos) + logical (math) + behavioral (regrets) in one intervention
- No competitor uses past regrets as prevention (only as logging)
- No competitor shows goal photos at the moment of decision

---

## Recommended Feature: Real-Time Goal Impact Intervention

### Core Concept

When a Decision Window notification triggers and DecisionWindowPromptView appears, enhance the existing goal anchoring section with:

1. **Their Active Goal Photo** (prominent, full-width display)
2. **Impact Calculation**: "Saving $X now = Y days closer to [Goal Name]"
3. **Countdown Timer**: Shows how close they are to goal (e.g., "47 days away")
4. **Past Regret Reminder**: "You regretted not saving $45 on Jan 15 - that would have been 2 days closer"
5. **Visual Progress Bar**: Shows current progress and how this save moves the needle
6. **Emotional Messaging**: "Your [goal name] is worth more than this impulse"
7. **Dynamic Amount Suggestions**: AI suggests amounts based on goal progress (e.g., "Save $25 to be 1 day closer")

### User Flow

```
Decision Window notification triggers (scheduled time)
    ↓
User taps notification → DecisionWindowPromptView appears
    ↓
ENHANCED: Goal Impact Section shows (replaces/enhances existing goalAnchoringCard):
    - Goal photo (prominent, full-width)
    - "Saving $25 now = 1 day closer to your Hawaii trip"
    - "You're 47 days away from your goal"
    - "You regretted not saving $45 on Jan 15 - that would have been 2 days closer"
    - Progress bar: "$1,200 of $3,000 saved" → "$1,225 of $3,000 saved" (animated)
    - "Your Hawaii trip is worth more than this impulse"
    - Quick-save buttons: $10 (0.4 days), $25 (1 day), $50 (2 days)
    ↓
User sees emotional + logical + behavioral data
    ↓
Decision: Choose micro-save amount OR skip
    ↓
If user saves: Record as "Goal-Anchored Save" (shows emotional connection worked)
If user skips: Record as "Goal-Anchored Skip" (track for insights)
```

### Technical Implementation

#### 1. Goal Impact Calculator Service

```swift
class GoalImpactService {
    func calculateImpact(purchaseAmount: Double, goal: SavingsGoal) -> GoalImpact {
        let remainingAmount = goal.remainingAmount
        let daysUntilGoal = goal.daysUntilTarget ?? 30
        let dailyRequired = remainingAmount / Double(daysUntilGoal)
        let daysDelayed = purchaseAmount / dailyRequired
        
        return GoalImpact(
            purchaseAmount: purchaseAmount,
            daysDelayed: daysDelayed,
            currentProgress: goal.progress,
            daysUntilGoal: daysUntilGoal,
            remainingAmount: remainingAmount
        )
    }
    
    func getSimilarRegrets(amount: Double, goal: SavingsGoal) -> [RegretPurchase] {
        // Find regrets within 20% of purchase amount
        // That occurred when user was working toward similar goals
        // Return most recent 1-2 regrets
    }
}
```

#### 2. Enhanced DecisionWindowPromptView

Enhance existing `goalAnchoringCard` (line 89-92):
- Replace minimal goal card with full-featured goal impact section
- Show goal photo prominently (full-width)
- Add impact calculations
- Add past regret reminders
- Add dynamic amount suggestions based on goal progress
- Only shows if user has active goal with photo
- Falls back to current minimal card if no goal/photo

#### 3. Goal-Anchored Save Tracking

New commitment type:
- `goalAnchoredSave` - User chose to save after seeing goal impact
- Track separately from regular micro-saves
- Show in metrics: "X goal-anchored saves this week"
- More valuable than regular saves (shows emotional connection worked)
- Track which amounts were chosen (e.g., did they pick the "1 day closer" amount?)

### Why This Feature is High-Value

#### 1. **Solves the Core Problem**
- **Current**: "Friction, not prevention" - user can easily skip purchase intent questions
- **With This**: Emotional + logical + behavioral data = actual decision change
- **Result**: User sees what they're giving up, not just generic purchase intent questions

#### 2. **Unique Competitive Advantage**
- No other app shows real-time goal delay calculations
- No other app combines emotional (photos) + logical (math) + behavioral (regrets)
- No other app uses past regrets as prevention (only as logging)
- Creates a "moment of truth" that competitors can't replicate

#### 3. **Behavioral Science Backed**
- **Future Self Visualization**: Goal photos make future feel real
- **Loss Aversion**: Shows what they're losing (days from goal)
- **Regret Aversion**: Past regrets prevent future ones
- **Tangible Cost**: Math makes abstract goal concrete
- **Emotional Anchoring**: Goal photo creates emotional connection

#### 4. **Measurable Impact**
- Track: Goal-anchored protections vs regular protections
- Track: Conversion rate (unblock → protection) with goal impact vs without
- Track: Goal achievement rate for users with goal impact enabled
- Expected: 2-3x higher protection rate when goal impact is shown

#### 5. **Premium Feature Potential**
- Free: Basic goal impact (calculation only)
- Premium: Full feature (photos, regrets, advanced messaging)
- Premium: Multiple goals (show impact on all active goals)
- Premium: Custom messaging per goal

### Implementation Priority

**Phase 1 (MVP)** - 2-3 weeks
- Goal impact calculation (saving $X = Y days closer)
- Enhance DecisionWindowPromptView goalAnchoringCard
- Prominent goal photo display
- Track goal-anchored saves

**Phase 2 (Enhanced)** - 1-2 weeks
- Past regret reminders
- Multiple goals support
- Advanced messaging
- Metrics dashboard integration

**Phase 3 (Premium)** - 1 week
- Custom messaging per goal
- Goal impact analytics
- Comparison views (impact on all goals)

### Success Metrics

- **Save Rate**: % of Decision Window prompts that result in saves (with vs without enhanced goal impact)
- **Goal Achievement**: % of goals achieved for users with goal impact enabled
- **Engagement**: Frequency of goal-anchored saves
- **User Feedback**: Qualitative feedback on decision-changing moments

### Why This Beats Other Options

**vs. Commitment Device (Auto-Transfer)**:
- ✅ No bank connection required (works for all users)
- ✅ Emotional impact > financial consequence (for many users)
- ✅ Doesn't require Plaid integration
- ✅ Works immediately (no setup)

**vs. Social Accountability**:
- ✅ No need for partner coordination
- ✅ Works for users who prefer privacy
- ✅ Immediate impact (no waiting for partner response)
- ✅ Lower implementation complexity

**vs. Future Self Visualization Alone**:
- ✅ Combines multiple behavioral techniques (not just visualization)
- ✅ Includes tangible math (not just emotional)
- ✅ Uses past data (regrets) for prevention
- ✅ More comprehensive intervention

---

## Conclusion

This feature transforms Soteria from a "friction tool" into a "decision-changing intervention" by combining:
- **Emotional** (goal photos, future self)
- **Logical** (impact calculations, days delayed)
- **Behavioral** (past regrets, progress tracking)

It's unique in the market, solves the core problem identified in your value proposition analysis, and creates measurable value that users will pay for.

**Next Steps**: 
1. Validate with user research (show mockups, measure interest)
2. Build MVP (Phase 1)
3. A/B test (goal impact vs current view)
4. Measure impact and iterate

