# 🔔 Decision Notifications Card - Enhanced Preview

## ✅ **ENHANCEMENT: Quick Glance at Active Notifications**

### **Problem:**
The Decision Notifications card on the home screen didn't show any information about whether notifications were active or what they were. Users had to tap in to see anything.

### **Solution:**
Enhanced the card to show a quick glance of active notifications directly on the home screen.

---

## 🎨 **NEW CARD DESIGN**

### **When NO Active Notifications:**
```
┌─────────────────────────────────────┐
│ 🔔 Decision Notifications        → │
│    Set up time-based savings prompts│
└─────────────────────────────────────┘
```
Same as before - simple call to action.

---

### **When ACTIVE Notifications (1-2):**
```
┌─────────────────────────────────────┐
│ 🔔 Decision Notifications        → │
│    2 active reminders ✅            │
│ ────────────────────────────────    │
│ 7:00 AM    Morning Planning      ● │
│ Daily      Next: Tomorrow           │
│ ────────────────────────────────    │
│ 9:00 PM    Evening Review         ● │
│ 5 days     Next: Today              │
└─────────────────────────────────────┘
```

**Shows:**
- ✅ Count of active reminders (green text)
- ✅ Time for each notification
- ✅ Name of each notification
- ✅ Frequency (Daily, 3 days, etc.)
- ✅ Next occurrence (Today, Tomorrow, Monday, etc.)
- ✅ Green dot indicator (active status)

---

### **When ACTIVE Notifications (3+):**
```
┌─────────────────────────────────────┐
│ 🔔 Decision Notifications        → │
│    5 active reminders ✅            │
│ ────────────────────────────────    │
│ 7:00 AM    Morning Planning      ● │
│ Daily      Next: Tomorrow           │
│ ────────────────────────────────    │
│ 9:00 PM    Evening Review         ● │
│ 5 days     Next: Today              │
│ ────────────────────────────────    │
│           +3 more                   │
└─────────────────────────────────────┘
```

**Shows:**
- First 2 active notifications
- "+X more" indicator for additional notifications
- Tap to see all

---

## 💻 **IMPLEMENTATION**

### **1. Dynamic Status Text:**
```swift
let activeWindows = DecisionWindowsService.shared.windows.filter { $0.isEnabled }
if activeWindows.isEmpty {
    Text("Set up time-based savings prompts")
        .foregroundColor(.softGraphite)
} else {
    Text("\(activeWindows.count) active reminder\(activeWindows.count == 1 ? "" : "s")")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.green)  // ← Green for active
}
```

### **2. Preview of Next 2 Active Notifications:**
```swift
ForEach(activeWindows.prefix(2)) { window in
    HStack(spacing: 12) {
        // Time indicator
        VStack(spacing: 2) {
            Text(formatTime(window.time))  // "7:00 AM"
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.reverBlue)
            
            Text(window.notificationDays.count == 7 ? "Daily" : "\(window.notificationDays.count) days")
                .font(.system(size: 10))
                .foregroundColor(.softGraphite)
        }
        .frame(width: 60)
        
        // Window name + next occurrence
        VStack(alignment: .leading, spacing: 2) {
            Text(window.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            
            Text("Next: \(formatNextOccurrence(nextOccurrence))")
                .font(.system(size: 12))
                .foregroundColor(.softGraphite)
        }
        
        Spacer()
        
        // Active indicator
        Circle()
            .fill(Color.green)
            .frame(width: 8, height: 8)
    }
}
```

### **3. Helper Functions:**

**Format Time:**
```swift
private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
}
// Returns: "7:00 AM", "9:30 PM", etc.
```

**Get Next Occurrence:**
```swift
private func getNextOccurrence(for window: DecisionWindow) -> Date? {
    // Looks ahead 7 days to find next day this window triggers
    // Returns the next date/time when notification will fire
}
```

**Format Next Occurrence:**
```swift
private func formatNextOccurrence(_ date: Date) -> String {
    if calendar.isDateInToday(date) {
        return "Today"
    } else if calendar.isDateInTomorrow(date) {
        return "Tomorrow"
    } else {
        return "Monday" // Day name
    }
}
// Returns: "Today", "Tomorrow", or day name
```

---

## 🎯 **USER BENEFITS**

### **Quick Glance Value:**
1. ✅ **See active status at a glance** - Green text shows notifications are working
2. ✅ **Preview next 2 reminders** - No need to tap in to see what's active
3. ✅ **See when they'll trigger** - "Next: Today" or "Next: Tomorrow"
4. ✅ **Understand frequency** - "Daily", "5 days", etc.
5. ✅ **One tap for full details** - Card still clickable for full management

### **Smart Display Logic:**
- **0 active:** Shows setup prompt
- **1-2 active:** Shows all with full details
- **3+ active:** Shows first 2 + count of remaining
- **Always tappable:** Opens full Decision Notifications view

---

## 📊 **VISUAL HIERARCHY**

```
Priority 1 (Most Prominent):
  - Notification time (7:00 AM) - Large, bold, blue
  - Active reminder count (green)

Priority 2 (Supporting Info):
  - Window name (Medium weight)
  - Green active dot

Priority 3 (Contextual):
  - Frequency (Daily, 5 days)
  - Next occurrence (Tomorrow, Today)
```

---

## 🧪 **TESTING CHECKLIST**

### **No Active Notifications:**
- [ ] Card shows "Set up time-based savings prompts"
- [ ] Text is gray (not green)
- [ ] No preview section shown

### **1-2 Active Notifications:**
- [ ] Shows "\(X) active reminder(s)" in green
- [ ] Shows time, name, frequency, next occurrence
- [ ] Green dot visible
- [ ] No "+X more" text

### **3+ Active Notifications:**
- [ ] Shows first 2 notifications
- [ ] Shows "+X more" text
- [ ] Count is accurate

### **Tap Behavior:**
- [ ] Tapping card opens full Decision Notifications view
- [ ] Can manage all notifications there

---

## 🎨 **DESIGN NOTES**

### **Color Palette:**
- **Active status:** Green (#00C853 or system green)
- **Time:** Rever Blue (#007AFF)
- **Names:** Midnight Slate (dark)
- **Details:** Soft Graphite (medium gray)
- **Active dot:** Green circle

### **Typography:**
- **Time:** 16pt, bold, rounded
- **Count:** 14pt, semibold
- **Names:** 14pt, medium
- **Details:** 10-12pt, regular

### **Spacing:**
- 12pt between header and preview
- 8pt between notification rows
- 4pt internal spacing

---

## ✅ **VERIFICATION**

**Linter Check:** ✅ **No errors found**

**File Updated:**
- ✅ `HomeView.swift` - Enhanced `savingsReminderCard`
- ✅ Added 3 helper functions
- ✅ ~150 lines added

---

**Decision Notifications card now provides actionable information at a glance!** 🔔✨

Users can see:
- How many notifications are active
- What time they trigger
- When the next one will fire
- All without tapping into the full view
