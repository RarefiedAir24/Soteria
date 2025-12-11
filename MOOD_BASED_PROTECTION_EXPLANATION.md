# Mood-Based Protection: How It Currently Works

## Current Implementation

### How Mood is Tracked
**Mood tracking is MANUAL, not automatic.** Users must manually enter their mood through:

1. **MoodCheckInView** - Dedicated mood check-in screen (accessible from Settings)
2. **PauseView** - When user is blocked and prompted for purchase intent, they also select their mood
3. **Anywhere `moodService.addMoodEntry()` is called** - Updates the `currentMood` property

### The Flow

```
User manually enters mood
    ↓
MoodTrackingService.addMoodEntry() called
    ↓
currentMood is updated to the latest entry
    ↓
(If Premium) QuietHoursService checks every 5 minutes:
    - Reads moodService.currentMood
    - Gets mood.regretRisk (0.0-1.0)
    - If risk >= 0.8, auto-activates Quiet Hours for 2 hours
```

### Mood Risk Levels

Each mood has a predefined risk level:
- **Very Happy**: 0.3 (low risk)
- **Happy**: 0.2 (low risk)
- **Neutral**: 0.4 (moderate risk)
- **Stressed**: 0.8 (high risk) ⚠️ Triggers auto-activation
- **Anxious**: 0.9 (very high risk) ⚠️ Triggers auto-activation
- **Sad**: 0.7 (moderate-high risk)

### The Problem

**Mood is NOT automatically monitored.** The system:
- ✅ Checks the last manually entered mood every 5 minutes
- ❌ Does NOT automatically detect mood changes
- ❌ Does NOT use any sensors or passive tracking
- ❌ Relies entirely on user self-reporting

**If a user hasn't entered a mood recently:**
- `currentMood` could be stale (from hours or days ago)
- Auto-activation might trigger based on an old mood
- Or might never trigger if user never enters mood

## What This Means

### Current Reality
- **Manual mood entry required** for mood-based protection to work
- **Premium feature** that checks the last entered mood periodically
- **Not truly "monitoring"** - more like "checking last known state"

### User Experience
1. User enters mood (manually) → `currentMood` updated
2. If mood is high-risk (stressed/anxious), system checks every 5 min
3. If risk >= 0.8, Quiet Hours auto-activate for 2 hours
4. User is protected during vulnerable moments (if they've entered mood)

## Potential Improvements

### Option 1: Make Mood Entry More Prominent
- Push notifications to check in
- Quick mood entry from HomeView
- Remind users to update mood regularly

### Option 2: Use Behavioral Patterns as Proxy
- Track unblock frequency as mood indicator
- High unblock rate → potential stress/anxiety
- Use RegretRiskEngine patterns instead of explicit mood

### Option 3: Hybrid Approach
- Manual mood entry (primary)
- Behavioral patterns (secondary indicator)
- Combine both for more accurate risk assessment

### Option 4: Clarify the Feature
- Rename to "Mood-Based Protection (Manual Entry)"
- Set expectations that users need to enter mood
- Make it clear it's not automatic mood detection

## Recommendation

**For now, clarify the feature description:**
- "Mood-Based Auto-Activation" should be "Mood-Based Protection (Requires Manual Entry)"
- Add prompts/reminders to enter mood regularly
- Consider using behavioral patterns (unblock frequency, time of day) as a fallback indicator

The feature works, but it's **reactive to user input**, not **proactive mood detection**.

