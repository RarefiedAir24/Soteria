# Notification Not Received - Troubleshooting Guide

**Issue**: 2:50pm alarm not received (it's now 2:52-2:53pm)

---

## 🔍 Immediate Checks

### 1. Check Notification Permissions
**Settings** → **Notifications** → **Soteria**
- ✅ Allow Notifications: **ON**
- ✅ Time Sensitive Notifications: **ON**
- ✅ Lock Screen: **ON**
- ✅ Banners: **ON**
- ✅ Sounds: **ON**

### 2. Check Background App Refresh
**Settings** → **General** → **Background App Refresh**
- ✅ Ensure **Soteria** is enabled
- ✅ Background App Refresh is ON globally

### 3. Check Do Not Disturb / Focus
- **Settings** → **Focus** → Check if any Focus mode is active
- Time-sensitive notifications should bypass, but verify

### 4. Check Notification Center
- Swipe down from top to check Notification Center
- Notification might have arrived but wasn't visible

---

## 🐛 Common Issues

### Issue 1: Notification Not Scheduled
**Check**: Is the alarm actually scheduled in the app?
- Open Soteria app
- Go to Protection Hours / Quiet Hours settings
- Verify the 2:50pm schedule is active and saved

### Issue 2: Wrong Day of Week
**Check**: Is the schedule set for today?
- Protection Hours schedules are day-specific
- If set for Monday but today is Tuesday, it won't fire

### Issue 3: Notification Permissions Not Granted
**Check**: First-time setup
- App may need notification permissions
- Check Settings → Notifications → Soteria

### Issue 4: App Not Running in Background
**Check**: Background App Refresh
- iOS may have killed the app
- Restart the app to reschedule notifications

---

## 🔧 Quick Fixes

### Fix 1: Reschedule Notifications
1. **Open Soteria app**
2. **Go to Protection Hours settings**
3. **Edit the 2:50pm schedule**
4. **Save** (this reschedules notifications)

### Fix 2: Check Notification Logs
1. **Open Soteria app**
2. **Check console/logs** for notification scheduling errors
3. Look for: "Failed to schedule notification"

### Fix 3: Restart App
1. **Force close Soteria app**
2. **Reopen the app**
3. This reschedules all notifications

### Fix 4: Verify Schedule is Active
1. **Check if schedule is enabled**
2. **Check if today is in the schedule's days**
3. **Verify time is correct** (2:50pm = 14:50)

---

## 📋 Debug Steps

### Step 1: Verify Schedule Exists
- Open app → Protection Hours
- Confirm 2:50pm schedule is visible and enabled

### Step 2: Check Notification Center
- Swipe down from top
- Check if notification arrived but wasn't visible

### Step 3: Check System Logs
- Settings → Privacy & Security → Analytics & Improvements
- Look for notification-related errors

### Step 4: Test with Immediate Notification
- Try scheduling a notification for 1 minute from now
- See if it fires (tests if notifications work at all)

---

## ⚠️ Known Issues

### Issue: Notifications Don't Fire After App Reinstall
**Fix**: Re-enable notifications in app settings

### Issue: Notifications Stop After iOS Update
**Fix**: Re-grant notification permissions

### Issue: Notifications Don't Fire on First Schedule
**Fix**: Save schedule, close app, reopen app

---

## 🎯 Next Steps

1. **Check notification permissions** (most common issue)
2. **Verify schedule is active** for today
3. **Reschedule the notification** (edit and save)
4. **Test with immediate notification** (1 minute from now)

---

**Most likely cause**: Notification permissions not granted or schedule not active for today.

