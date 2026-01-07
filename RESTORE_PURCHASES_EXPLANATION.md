# Restore Purchases - Apple Requirements & Behavior

**Date**: January 7, 2026  
**Status**: Implementation Complete ✅

---

## 🍎 Apple's Requirement

**Apple REQUIRES** apps with auto-renewable subscriptions to provide a "Restore Purchases" feature. This is **mandatory** for App Store approval.

**Why**: Users need a way to restore their subscriptions when:
- Getting a new device
- Reinstalling the app
- Switching between devices (iPhone → iPad)
- Encountering access issues

---

## ✅ What "Restore Purchases" DOES

### 1. **Restores Active Subscriptions** ✅
- If user has an **active** subscription on their Apple ID
- Gets a new device → Can restore it
- Reinstalls app → Can restore it
- Switches devices → Can restore it

### 2. **Works Across Devices** ✅
- Same Apple ID on multiple devices
- Subscription is tied to Apple ID, not device
- Restore works on any device with same Apple ID

---

## ❌ What "Restore Purchases" DOES NOT Do

### 1. **Cannot Restore Cancelled Subscriptions** ❌
- If subscription was **cancelled** → Cannot restore
- If subscription **expired** → Cannot restore
- If subscription was **refunded** → Cannot restore

### 2. **Cannot Restore Free Trials** ❌
- Free trials that ended → Cannot restore
- Must purchase to continue

### 3. **Cannot Restore Non-Active Subscriptions** ❌
- Only **currently active** subscriptions can be restored
- Past subscriptions (even if paid) cannot be restored if expired

---

## 🔧 How It Works (Technical)

### Current Implementation

```swift
func restorePurchases() async {
    try await AppStore.sync()  // Syncs with App Store
    await updateSubscriptionStatus()  // Checks for active subscriptions
}
```

**What happens**:
1. `AppStore.sync()` contacts Apple's servers
2. Checks for **active subscriptions** on user's Apple ID
3. If found → Restores subscription status
4. If not found → User remains free tier

**Key Point**: Only **active** subscriptions are restored. Apple's servers check:
- Is subscription currently active? ✅ → Restore
- Is subscription expired/cancelled? ❌ → No restore

---

## 📱 User Scenarios

### Scenario 1: New Device ✅
- **User**: Has active Monthly subscription on iPhone
- **Action**: Gets new iPhone, installs app
- **Result**: Taps "Restore Purchases" → Subscription restored ✅

### Scenario 2: Reinstall App ✅
- **User**: Has active Annual subscription
- **Action**: Deletes app, reinstalls later
- **Result**: Taps "Restore Purchases" → Subscription restored ✅

### Scenario 3: Cancelled Subscription ❌
- **User**: Had Monthly subscription, cancelled it
- **Action**: Taps "Restore Purchases"
- **Result**: Nothing happens (no active subscription to restore) ❌

### Scenario 4: Expired Subscription ❌
- **User**: Had Annual subscription, it expired
- **Action**: Taps "Restore Purchases"
- **Result**: Nothing happens (subscription is expired) ❌

### Scenario 5: Multiple Devices ✅
- **User**: Has active subscription on iPhone
- **Action**: Installs app on iPad (same Apple ID)
- **Result**: Taps "Restore Purchases" → Subscription works on iPad ✅

---

## ✅ Current Implementation Status

### What's Implemented:
- ✅ "Restore Purchases" button in PaywallView
- ✅ `restorePurchases()` function using `AppStore.sync()`
- ✅ Automatic subscription status update after restore
- ✅ Celebration shown if subscription is restored (user wasn't premium before)

### Location:
- **PaywallView**: "Restore Purchases" button at bottom
- **SettingsView**: Can be added if needed (currently in PaywallView only)

---

## 📋 Apple Review Checklist

For App Store submission, ensure:

- [x] "Restore Purchases" button is visible and accessible
- [x] Button is clearly labeled (not hidden)
- [x] Works for active subscriptions
- [x] Handles case when no subscriptions to restore (gracefully)
- [x] Provides feedback to user (loading state, success/error)

**Current Status**: ✅ All requirements met

---

## 🎯 Best Practices

### 1. **Clear Messaging**
- If restore finds subscription → Show success
- If restore finds nothing → Show message: "No active subscriptions found"
- Current implementation: Shows celebration if subscription restored

### 2. **User Feedback**
- Show loading indicator during restore
- Provide clear success/error messages
- Current implementation: Has loading state ✅

### 3. **Placement**
- Should be easily accessible
- Common locations: Settings, Paywall, Account section
- Current implementation: PaywallView ✅

---

## ⚠️ Important Notes

1. **Cannot Bypass Cancellation**: If user cancels, they cannot restore. They must purchase again.

2. **Subscription Status**: Apple checks subscription status in real-time. If expired, it won't restore.

3. **Family Sharing**: If subscription is part of Family Sharing, restore works for family members too.

4. **Sandbox Testing**: In TestFlight/sandbox, restore works the same way (only active subscriptions).

---

## 🔍 Testing Restore Purchases

### In Sandbox/TestFlight:
1. Purchase subscription with sandbox account
2. Sign out of App Store
3. Delete app (or use different device)
4. Reinstall app
5. Tap "Restore Purchases"
6. Sign in with same sandbox account
7. Subscription should restore ✅

### What to Test:
- ✅ Active subscription restores
- ✅ Cancelled subscription does NOT restore
- ✅ Expired subscription does NOT restore
- ✅ Works across devices (same Apple ID)
- ✅ Loading state shows during restore
- ✅ User feedback is clear

---

**Status**: ✅ Implementation complete and ready for App Store submission

