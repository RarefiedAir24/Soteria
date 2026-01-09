# Goal Notifications vs Decision Notifications

## Overview

**They are DIFFERENT notification systems** that serve different purposes, but both use the same underlying iOS `UNUserNotificationCenter` API.

---

## 🔔 Goal Notifications (`GoalNotificationService`)

### Purpose
- **Progress updates** for savings goals
- **Milestone notifications** (25%, 50%, 75% progress)
- **Achievement notifications** (when goal is reached)

### Features
- ✅ **Multiple times per day** (up to 5 times) - **NEW FEATURE**
- ✅ Frequency options: Daily, Weekly, Twice Weekly, Never
- ✅ Customizable notification time(s)
- ✅ Tied to specific savings goals
- ✅ Shows progress percentage and remaining amount

### Notification Identifiers
- `goal_progress_{goalId}_{timeIndex}` - Daily progress
- `goal_progress_{goalId}_weekly_{timeIndex}` - Weekly progress
- `goal_progress_{goalId}_twice_{timeIndex}_{weekday}` - Twice weekly
- `goal_milestone_{goalId}_{percentage}` - Milestone reached
- `goal_achievement_{goalId}` - Goal achieved

### Service
- **File**: `soteria/Services/GoalNotificationService.swift`
- **Class**: `GoalNotificationService` (singleton)
- **Trigger**: Based on goal progress and frequency settings

### Example Notification
```
Title: "Vacation Fund Progress"
Body: "You're 45% toward Vacation Fund. $550.00 to go!"
```

---

## ⏰ Decision Notifications (`DecisionWindowsService`)

### Purpose
- **Time-based prompts** to make savings decisions
- **Reminders** to pause and think before spending
- **Manual entry prompts** for cash/external transfers

### Features
- ✅ **Single time per day** (one time per decision window)
- ✅ Multiple days of week (e.g., Monday-Friday)
- ✅ Custom prompt messages
- ✅ Time-sensitive alerts (iOS 15+)
- ✅ "Just Remind Me" mode (simple reminders)

### Notification Identifiers
- `decision_window_{windowId}_{day}` - Regular decision prompts
- `decision_window_reminder_{windowId}_{day}` - Reminder-only windows

### Service
- **File**: `soteria/Services/DecisionWindowsService.swift`
- **Class**: `DecisionWindowsService` (singleton)
- **Trigger**: Based on time of day and days of week

### Example Notification
```
Title: "Before today continues..."
Body: "Do you want to protect anything?"
```

---

## 🔄 Key Differences

| Feature | Goal Notifications | Decision Notifications |
|---------|-------------------|----------------------|
| **Purpose** | Progress updates | Savings prompts |
| **Times per day** | Up to 5 times | 1 time per window |
| **Frequency** | Daily/Weekly/Twice Weekly | Custom days of week |
| **Content** | Progress %, remaining $ | Custom prompt message |
| **Tied to** | Specific savings goal | Time-based window |
| **Service** | `GoalNotificationService` | `DecisionWindowsService` |
| **User-facing name** | "Goal Notifications" | "Decision Notifications" |

---

## 🔧 Technical Implementation

### Both Use:
- ✅ **iOS `UNUserNotificationCenter`** - Same underlying API
- ✅ **`UNCalendarNotificationTrigger`** - For scheduled notifications
- ✅ **`UNMutableNotificationContent`** - For notification content
- ✅ **Same permission system** - Both request notification permissions

### Separate Services:
- ✅ **Different service classes** - No shared code
- ✅ **Different notification identifiers** - No conflicts
- ✅ **Different scheduling logic** - Independent systems
- ✅ **Different cancellation methods** - Separate cleanup

---

## 📱 User Experience

### Goal Notifications
- User sees: "Your goal is 45% complete"
- Purpose: Track progress, stay motivated
- Frequency: Based on user preference (daily/weekly)
- Multiple times: Can receive updates at 9 AM, 12 PM, 6 PM, etc.

### Decision Notifications
- User sees: "Before today continues - do you want to protect anything?"
- Purpose: Prompt for savings action
- Frequency: Based on time window (e.g., 2:50 PM daily)
- Single time: One notification per decision window per day

---

## ✅ Summary

**They are DIFFERENT systems** that:
- ✅ Serve different purposes (progress vs. prompts)
- ✅ Use separate service classes
- ✅ Have different notification identifiers
- ✅ Are configured independently
- ✅ But use the same iOS notification infrastructure

**No conflicts** - They work independently and don't interfere with each other.

---

## 🎯 Current Status

- ✅ **Goal Notifications**: Support multiple times (up to 5) - **JUST IMPLEMENTED**
- ✅ **Decision Notifications**: Single time per window (as designed)
- ✅ Both systems working independently
- ✅ No conflicts or interference

---

**Answer**: They are **different notification systems** with different purposes, but both use the same iOS notification infrastructure.

