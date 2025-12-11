# Behavioral Tracking Implementation Summary

## ✅ Enhanced Unblock Event Tracking

The unblock event tracking system has been significantly enhanced to capture comprehensive behavioral data for pattern analysis.

## What We Track

### Core Unblock Data
- ✅ **Timestamp** - Exact time of unblock request
- ✅ **Purchase Type** - "planned" or "impulse"
- ✅ **Category** - For planned purchases (gift_shopping, necessity, replacement, etc.)
- ✅ **Mood** - For impulse purchases (lonely, bored, stressed, depressed, etc.)
- ✅ **Mood Notes** - Free text notes for mood (especially for "other")
- ✅ **App Index** - Which app was selected (0-based index)
- ✅ **App Name** - User-defined app name for easier analysis
- ✅ **Duration** - How long apps were unblocked (default: 15 minutes)

### Contextual Data
- ✅ **Time of Day** - Hour (0-23) and category (Night/Morning/Afternoon/Evening)
- ✅ **Day of Week** - Day name (Monday, Tuesday, etc.)
- ✅ **Quiet Hours Status** - Was this during active quiet hours?
- ✅ **Quiet Hours Schedule** - Which schedule was active (if any)
- ✅ **Time Since Last Unblock** - Seconds since previous unblock (frequency tracking)
- ✅ **Unblock Count Today** - How many times unblocked today
- ✅ **Unblock Count This Week** - How many times unblocked this week

### Usage Tracking
- ✅ **Was App Used** - Did user actually open/use the app after unblock?
- ✅ **App Usage Duration** - How long was app used after unblock? (in seconds)

## Behavioral Patterns Analyzed

The system now provides comprehensive behavioral pattern analysis:

### Time Patterns
- **Most Common Time of Day** - When do unblocks typically occur?
- **Most Common Day of Week** - Which days see more unblocks?

### Context Patterns
- **Quiet Hours Percentage** - What % of unblocks happen during quiet hours?
- **Average Time Between Unblocks** - Frequency of unblock requests
- **Average Unblocks Per Day** - Daily unblock frequency

### Usage Patterns
- **App Usage Rate** - What % of unblocks result in actual app usage?
- **Average Usage Duration** - How long are apps typically used after unblock?

## Data Structure

```swift
struct UnblockEvent: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let purchaseType: String? // "planned" or "impulse"
    let category: String? // For planned purchases
    let mood: String? // For impulse purchases
    let moodNotes: String? // Free text notes
    let selectedAppsCount: Int
    let appIndex: Int?
    let appName: String?
    let durationMinutes: Int
    let wasDuringQuietHours: Bool
    let quietHoursScheduleName: String?
    let timeOfDay: Int // 0-23
    let dayOfWeek: Int // 1-7
    let timeSinceLastUnblock: TimeInterval?
    let unblockCountToday: Int
    let unblockCountThisWeek: Int
    let wasAppUsed: Bool?
    let appUsageDuration: TimeInterval?
}
```

## How It Works

### 1. When User Unblocks an App

When `temporarilyUnblock()` is called:
1. Calculates behavioral metrics (time since last, counts, etc.)
2. Checks if during quiet hours
3. Gets app name
4. Creates comprehensive `UnblockEvent` with all data
5. Saves to UserDefaults and syncs to AWS (if enabled)

### 2. When App Usage Ends

When `endAppUsageSession()` is called:
1. Calculates usage duration
2. Finds the most recent unblock event for that app
3. Updates the event with:
   - `wasAppUsed = true`
   - `appUsageDuration = duration`
4. Saves updated event

### 3. Behavioral Analysis

The `getBehavioralPatterns()` function analyzes all unblock events to provide:
- Time patterns (most common time/day)
- Context patterns (quiet hours percentage)
- Usage patterns (usage rate, average duration)
- Frequency patterns (average time between, per day)

## Metrics Dashboard

The Metrics Dashboard now displays:

### Unblock Metrics
- Total unblocks
- Planned vs Impulse breakdown
- Most requested app

### Behavioral Patterns
- Most common time of day
- Most common day of week
- Quiet hours percentage
- App usage rate (apps actually used vs just unblocked)
- Average time between unblocks
- Average usage duration
- Average unblocks per day

## Use Cases

This comprehensive tracking enables:

1. **Pattern Recognition**
   - Identify when users are most vulnerable
   - Recognize recurring behavioral triggers
   - Understand time-based patterns

2. **Intervention Timing**
   - Know when to show proactive prompts
   - Understand which quiet hours are most effective
   - Identify high-risk time periods

3. **Personalization**
   - Customize prompts based on historical patterns
   - Adjust quiet hours based on actual usage
   - Provide personalized insights

4. **Progress Tracking**
   - See if unblock frequency decreases over time
   - Track if usage duration decreases (less time shopping)
   - Monitor improvement in impulse control

## Data Storage

- **UserDefaults** - Local storage (always)
- **AWS DynamoDB** - Cloud sync (when enabled)
- **Table:** `soteria-unblock-events`

## Future Enhancements

Potential additions:
- **Location data** - Where unblocks occur (if permission granted)
- **Device context** - Battery level, time since last charge
- **App sequence** - Pattern of which apps are unblocked together
- **Purchase outcomes** - Did unblock lead to actual purchase?
- **Regret correlation** - Link unblocks to regret entries

## Example Insights

With this data, you can answer questions like:
- "Do I unblock more often when I'm stressed?"
- "What time of day am I most vulnerable?"
- "Do I actually use apps after unblocking, or just unblock and forget?"
- "Are my quiet hours effective at reducing unblocks?"
- "Is my impulse shopping getting better over time?"

All of this data is now being tracked and can be analyzed to provide meaningful behavioral insights!

