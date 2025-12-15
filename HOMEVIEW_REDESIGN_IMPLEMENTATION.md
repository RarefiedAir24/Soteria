# 🏠 HomeView Redesign Implementation Plan

## Goal
Simplify HomeView to load in < 2 seconds while maintaining REVER theme and current layout.

## Key Changes

### 1. Reduce @State Properties (20+ → 8)
**Keep only:**
- `totalSaved`, `streak`, `soteriaMomentsCount` (essential metrics)
- `activeGoal` (essential goal info)
- `avatarImage`, `userName`, `userEmail` (header)
- Progressive loading flags: `showRiskCard`, `showQuietModeCard`, etc.

**Remove:**
- All `cached*` properties (load directly from services when needed)
- `homeDataService` (access services directly)
- `behavioralPatterns`, `unblockMetrics` (load in cards themselves)

### 2. Show Essential Content First
**Immediate (loads in < 1 second):**
- Header (avatar, user name)
- Protection Moments card (total saved, streak, active goal)

**Progressive (loads after delays):**
- Risk card (2 seconds)
- Quiet Mode card (3 seconds)
- Mood card (4 seconds)
- Interactions card (5 seconds)
- Insights card (6 seconds)

### 3. Direct Service Access
- Remove `HomeViewDataService` dependency
- Access services directly: `SavingsService.shared`, `StreakService.shared`, etc.
- Each card loads its own data independently

### 4. Maintain REVER Theme
- Keep all `.reverCard()`, `.reverH3()`, `.reverBody()` styling
- Keep Color.mistGray, Color.cloudWhite backgrounds
- Keep spacing: `.spacingCard`, `.spacingSection`
- Keep same card layouts and visual design

## Implementation Steps

1. **Simplify @State properties** - Reduce to 8 essential ones
2. **Create essential metrics section** - Shows immediately
3. **Make cards independent** - Each loads its own data
4. **Add progressive loading** - Cards appear one by one
5. **Test and verify** - Ensure REVER theme is maintained

## Expected Results

- ✅ HomeView loads in < 2 seconds
- ✅ User sees essential metrics immediately
- ✅ Other cards load progressively
- ✅ REVER theme fully maintained
- ✅ Same visual layout and design

