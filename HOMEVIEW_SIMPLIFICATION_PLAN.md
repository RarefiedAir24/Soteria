# 🏠 HomeView Simplification Plan

## Current Problems

1. **20+ @State properties** - Expensive struct initialization
2. **All cards referenced immediately** - May trigger evaluation during struct creation
3. **Complex computed properties** - Evaluated during body evaluation
4. **Single point of failure** - If one card blocks, everything blocks

## Solution: Progressive Card Loading

### Phase 1: Minimal Dashboard (Loads in < 1 second)
Show only:
- Header (user name, avatar)
- Total Saved (from SavingsService - fast)
- Current Streak (from StreakService - fast)
- Active Goal preview (from GoalsService - fast)

### Phase 2: Progressive Enhancement
Load other cards independently:
- Risk Card (loads after 2 seconds)
- Quiet Mode Card (loads after 3 seconds)
- Protection Moments (loads after 4 seconds)
- Mood Insights (loads after 5 seconds)
- Recent Interactions (loads after 6 seconds)
- Behavioral Insights (loads after 7 seconds)
- Regret Summary (loads after 8 seconds)

### Implementation Strategy

1. **Reduce @State properties**
   - Keep only essential: `homeDataService`, `shouldShowContent`
   - Move card-specific state into independent card views

2. **Create independent card components**
   - Each card is a separate view with its own @State
   - Each card loads its own data independently
   - Cards show loading state until data is ready

3. **Show minimal content first**
   - Header + 3 essential metrics
   - Other cards appear progressively

4. **Remove HomeViewDataService dependency**
   - Access services directly in each card
   - No initialization chain

## Benefits

- ✅ HomeView loads in < 1 second
- ✅ User sees useful content immediately
- ✅ Progressive enhancement feels natural
- ✅ No blocking if one card is slow
- ✅ Better user experience

