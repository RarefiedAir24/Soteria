# 2-Minute Interval Implementation

## Overview

Implemented 2-minute monitoring intervals to enable notifications on every app launch. DeviceActivity events reset every 2 minutes, allowing banners to appear each time a targeted app is opened (after the 1-second rate limit).

## Problem Solved

**Before**: DeviceActivity events fired once per monitoring interval (could be hours). Once an event fired, it wouldn't fire again until the interval reset the next day.

**After**: Events reset every 2 minutes. Notifications can appear on every app launch (subject to 1-second rate limiting to prevent spam).

## Implementation Details

### 1. Helper Function: `createTwoMinuteIntervalSchedules()`

- Breaks Quiet Hours schedules into 2-minute chunks
- Handles both same-day and overnight schedules (e.g., 8pm-8am)
- Returns an array of `DeviceActivitySchedule` objects

**Example**:
- Original schedule: 8:00 PM - 10:00 PM (2 hours)
- Result: 60 x 2-minute intervals (8:00-8:02, 8:02-8:04, ..., 9:58-10:00)

### 2. Multiple Activity Names

- Each 2-minute interval gets its own `DeviceActivityName`
- Format: `soteria.monitoring.interval0`, `soteria.monitoring.interval1`, etc.
- All intervals use the same events (one per app)
- Events reset when each interval starts

### 3. Tracking and Cleanup

- `intervalActivityNames` array tracks all interval activity names
- All `stopMonitoring()` calls updated to stop interval activities
- Proper cleanup when monitoring stops or restarts

## How It Works

1. **Schedule Creation**: Quiet Hours schedule (e.g., 8pm-10pm) is split into 2-minute intervals
2. **Registration**: Each interval is registered as a separate activity with the same events
3. **Event Reset**: Every 2 minutes, `intervalDidStart` fires for the next interval, resetting events
4. **Notification**: When a targeted app opens, events can fire again (if 1+ second has passed since last notification)

## Rate Limiting

- **1-second rate limit** still applies (prevents spam from rapid open/close)
- **2-minute event reset** allows notifications on every legitimate app launch
- Combined: Notifications appear on every app launch (after 1-second cooldown)

## Extension Behavior

The `DeviceActivityMonitorExtension` automatically handles multiple activity names:
- Receives `intervalDidStart` for each interval (every 2 minutes)
- Each call resets event state, allowing events to fire again
- `eventDidReachThreshold` fires when apps open during any active interval

## Performance Considerations

- **Schedule Count**: A 2-hour Quiet Hours window = 60 schedules
- **Overhead**: Minimal - DeviceActivity is designed for this
- **Battery**: Negligible impact (monitoring is passive)
- **Extension Calls**: `intervalDidStart` fires every 2 minutes (acceptable frequency)

## Testing

1. Set up Quiet Hours (e.g., 8pm-10pm)
2. Select a targeted app (e.g., Amazon)
3. Open the app → Banner appears ✅
4. Close and reopen within 2 minutes → Banner appears again ✅ (if 1+ second has passed)
5. Close and reopen after 2 minutes → Banner appears ✅ (event reset)

## Files Modified

- `soteria/Services/DeviceActivityService.swift`
  - Added `createTwoMinuteIntervalSchedules()` helper function
  - Modified `updateMonitoringSchedule()` to use 2-minute intervals
  - Added `intervalActivityNames` tracking
  - Updated all `stopMonitoring()` calls to clean up intervals

## Notes

- Works with existing rate limiting (1 second)
- Compatible with all-day monitoring (no Quiet Hours)
- Handles overnight schedules correctly
- Extension requires no changes (handles multiple activity names automatically)

