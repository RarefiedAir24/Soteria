# Notification/Alarm Delivery Timing on iPhone

**Question**: For a 2:50pm alarm, when should I expect to receive it?

---

## ⏰ Expected Delivery Time

### For a 2:50pm Alarm:

**Expected Time**: **2:50:00 PM** (exactly 2:50pm)

**Tolerance**: Usually within **0-30 seconds** of the scheduled time

---

## 📱 How iOS Notifications Work

### Scheduling:
- Uses `UNCalendarNotificationTrigger` with `DateComponents`
- Hour: `14` (2:50pm in 24-hour format)
- Minute: `50`
- Repeats: `true` (if recurring)

### Delivery:
- iOS schedules the notification at the exact time
- Notification fires at **2:50:00 PM**
- May arrive **0-30 seconds** after due to:
  - System processing
  - Battery optimization
  - Other system tasks

---

## ⚠️ Factors That Affect Delivery

### 1. **Time-Sensitive Notifications** ✅
Your app uses `.timeSensitive` interruption level:
- ✅ Shows even when Do Not Disturb is on
- ✅ Bypasses Focus modes
- ✅ Higher priority delivery
- ✅ More reliable timing

### 2. **Battery Optimization**
- Low Power Mode: May delay notifications slightly
- Background App Refresh: Should be enabled for best results

### 3. **System Load**
- Heavy system load: May delay by a few seconds
- Normal conditions: Usually on time

### 4. **Device State**
- Locked: Notification shows on lock screen
- Unlocked: Notification banner appears
- App in foreground: May show in-app notification

---

## ✅ Expected Behavior

### For 2:50pm Alarm:

**Best Case**: 
- Notification arrives at **2:50:00 PM** (exactly on time)

**Typical Case**:
- Notification arrives between **2:50:00 PM - 2:50:30 PM**
- Usually within 5-10 seconds

**Worst Case**:
- Notification may be delayed up to **1-2 minutes** if:
  - Device is in Low Power Mode
  - Heavy system load
  - Battery is very low

---

## 🔍 How to Verify

### Check Notification Settings:
1. **Settings** → **Notifications** → **Soteria**
2. Ensure:
   - ✅ Allow Notifications: ON
   - ✅ Time Sensitive Notifications: ON
   - ✅ Lock Screen: ON
   - ✅ Banners: ON

### Check Background App Refresh:
1. **Settings** → **General** → **Background App Refresh**
2. Ensure **Soteria** is enabled

### Check Do Not Disturb:
- Time-sensitive notifications should still show
- But verify Do Not Disturb isn't blocking all notifications

---

## 📋 Summary

**For a 2:50pm alarm**:
- **Expected**: 2:50:00 PM
- **Typical Range**: 2:50:00 PM - 2:50:30 PM
- **Maximum Delay**: Up to 2 minutes (rare)

**Your app uses time-sensitive notifications**, so delivery should be very reliable and on-time!

---

## ⚠️ If Notification Doesn't Arrive

1. **Check notification permissions**: Settings → Notifications → Soteria
2. **Check Background App Refresh**: Settings → General → Background App Refresh
3. **Check Do Not Disturb**: May need to allow time-sensitive notifications
4. **Restart device**: Sometimes helps with notification delivery
5. **Check if alarm is actually scheduled**: Verify in app settings

---

**Bottom Line**: Expect the notification at **2:50pm**, usually within 0-30 seconds of that time!

