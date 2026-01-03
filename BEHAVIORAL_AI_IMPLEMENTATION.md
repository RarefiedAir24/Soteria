# Behavioral AI Implementation Summary

## Overview
Implemented Phase 1 (MVP) of the Quiet Behavioral Intelligence system for Soteria. The AI improves savings outcomes by:
- Adapting Decision Window timing based on engagement patterns
- Suggesting micro-save amounts likely to succeed
- Personalizing notification copy variants

**Core Principle**: AI thinks quietly, speaks rarely, and only acts with permission.

## Files Created

### Models
1. **`soteria/Models/DecisionWindowEvent.swift`**
   - Tracks window engagement (opened, completed actions)
   - Records suggested/chosen amounts
   - Privacy-first: Only aggregates stored

2. **`soteria/Models/AIRecommendation.swift`**
   - `TimingRecommendation`: Suggests better window times
   - `AmountSuggestion`: Suggests micro-save amounts
   - `CopyVariantRecommendation`: Selects best notification copy
   - `WeeklyReflection`: Phase 2 feature (structure ready)

### Services
3. **`soteria/Services/BehavioralAIService.swift`**
   - Core AI service managing all recommendations
   - Event tracking and analysis
   - Recommendation generation with guardrails
   - Privacy-first: Only stores last 100 events

### Views
4. **`soteria/Views/TimingRecommendationCard.swift`**
   - UI component for displaying timing recommendations
   - Shows in Decision Windows settings

## Files Modified

### Services
1. **`soteria/Services/DecisionWindowsService.swift`**
   - Integrated copy variant selection into notification generation
   - Added transfer tracking for AI analysis

2. **`soteria/Views/DecisionWindowPromptView.swift`**
   - Added event tracking (window opened, actions completed)
   - Integrated AI amount suggestions with quick-select buttons
   - Pre-fills amounts based on AI recommendations

3. **`soteria/Views/DecisionWindowsView.swift`**
   - Added timing recommendation cards
   - Integrated recommendation generation and display
   - Added handlers for accepting/dismissing recommendations

## Features Implemented

### 1. Adaptive Decision Window Timing ✅
- Analyzes engagement patterns by time of day
- Suggests moving windows to times with higher engagement
- Guardrails: Max 1 suggestion per 7 days
- Only suggests if difference is meaningful (≥30 minutes)

### 2. Micro-Save Amount Suggestions ✅
- Analyzes recent transfer success/failure rates
- Suggests discrete amounts: $1, $2, $3, $5, $10
- Adapts based on performance:
  - Recent failures → Lower amounts
  - Good follow-through → Moderate amounts
  - Low engagement → Very low amounts
- Displays quick-select buttons in Decision Window prompt

### 3. Copy/Tone Personalization ✅
- Selects from approved copy variants
- Uses engagement data to choose best variant
- Variants:
  - `A_MOMENT_FOR_TODAY` (default)
  - `SAVE_FIRST`
  - `TAKE_A_PAUSE`
  - `PROTECT_YOUR_MONEY`
  - `BEFORE_DAY_ENDS`

## Event Tracking

### Decision Window Events
- **Window Opened**: Tracked when user opens Decision Window prompt
- **Action Completed**: Tracked when user:
  - Saves first (micro-save)
  - Protects (spend gate)
  - Sets reminder (pause intention)
  - Dismisses ("Not today")

### Transfer Events
- **Transfer Results**: Tracked when:
  - Micro-save executed
  - Spend gate triggered
- Records: amount, source, result (success/failure)

## Privacy & Guardrails

### Privacy First
- Only stores last 100 events (auto-pruned)
- No raw transaction data
- No merchant names
- No location tracking
- No social/app usage beyond existing Quiet Hours selection

### Guardrails
- **Timing Suggestions**: Max 1 per 7 days
- **Weekly Reflections**: Max 1 per week (Phase 2)
- **Amount Suggestions**: Never exceed user-set maximum
- **Language**: Neutral, optional, non-judgmental
- **No Shaming**: Never uses "overspending," "bad habit," "failed"
- **No Urgency**: Never uses "last chance," "don't miss"
- **No Financial Advice**: Never suggests reducing spending categories

## User Experience

### Timing Recommendations
- Displayed as cards in Decision Windows settings
- Shows: "Small tweak? You tend to respond more around 4:30 PM..."
- Actions: "Update time" or "Not now"

### Amount Suggestions
- Shown in Decision Window prompt when micro-save selected
- Header: "Pick a small save"
- Helper: "Keep it easy today. You can always change this."
- Quick-select buttons for suggested amounts

### Copy Variants
- Automatically selected based on engagement
- Used in notification titles/bodies
- No user-facing selection (automatic optimization)

## Data Flow

1. **User Opens Decision Window**
   → `BehavioralAIService.recordWindowOpened()`
   → Event stored locally

2. **User Completes Action**
   → `BehavioralAIService.recordWindowAction()`
   → Event stored with action type, amounts

3. **Transfer Executed**
   → `BehavioralAIService.recordTransfer()`
   → Transfer event stored with result

4. **AI Analysis** (runs on-demand)
   → Analyzes events for patterns
   → Generates recommendations
   → Stores recommendations

5. **Recommendations Displayed**
   → Timing: In Decision Windows settings
   → Amount: In Decision Window prompt
   → Copy: In notifications (automatic)

## Next Steps (Phase 2)

1. **Weekly Reflection Summary**
   - 1x/week insight
   - Normalizes behavior
   - Suggests one small change
   - Opt-in required

2. **Future-Self Anchoring** (Phase 3)
   - User-authored messages
   - AI can help draft
   - User owns final

## Testing Checklist

- [ ] Decision Window events tracked correctly
- [ ] Transfer events tracked correctly
- [ ] Timing recommendations generated after sufficient data
- [ ] Amount suggestions adapt to success/failure
- [ ] Copy variants selected appropriately
- [ ] Guardrails enforced (max suggestions per week)
- [ ] Privacy maintained (only last 100 events)
- [ ] Recommendations display correctly in UI
- [ ] User can accept/dismiss timing recommendations
- [ ] Amount suggestions pre-fill correctly

## Notes

- All recommendations are optional and can be dismissed
- AI fails gracefully: Uses defaults if model unavailable
- No real-time spending interception
- No "always-on chat assistant" requirement
- All notification text uses approved variants only
- Localization ready (uses translation keys)

