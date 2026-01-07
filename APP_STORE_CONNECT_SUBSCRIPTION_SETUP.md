# App Store Connect Subscription Setup - Step by Step

**App**: Soteria Savings  
**Date**: January 7, 2026  
**Status**: Ready to Create Subscriptions

---

## ✅ Your App Code is Ready

Your app is already configured with:
- **Product IDs**: `com.soteria.premium.monthly` and `com.soteria.premium.yearly`
- **Paywall View**: Displays both subscription options
- **Subscription Service**: Handles purchases and validation

**Next**: Create matching subscriptions in App Store Connect

---

## 🚀 Step-by-Step Instructions

### Step 1: Navigate to In-App Purchases

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **"My Apps"**
3. Select **"Soteria Savings"**
4. Click **"Features"** tab (top navigation bar)
5. Click **"In-App Purchases"** (left sidebar)

---

### Step 2: Create Subscription Group

1. Click the **"+"** button (top left, next to "In-App Purchases")
2. Select **"Create Subscription Group"**
3. **Group Name**: `Soteria Premium`
   - This groups your monthly and annual subscriptions together
4. **Description** (optional): `Premium subscription tier for Soteria Savings`
5. Click **"Create"**

**Result**: You'll see an empty subscription group named "Soteria Premium"

---

### Step 3: Create Monthly Subscription

1. In your "Soteria Premium" group, click **"+"** → **"Create Auto-Renewable Subscription"**

2. **Product Information**:
   - **Product ID**: `com.soteria.premium.monthly` ⚠️ **MUST MATCH EXACTLY**
   - **Reference Name**: `Soteria Premium Monthly` (internal name, can be different)
   - **Subscription Duration**: Select **"1 Month"**

3. **Subscription Pricing**:
   - Click **"Add Subscription Pricing"**
   - **Base Territory**: Select **"United States"**
   - **Price**: Enter `4.99` (or select from dropdown)
   - Click **"Next"** → **"Save"**

4. **Localization** (English - U.S.):
   - Click **"Add Localization"** if not already there
   - **Display Name**: `Soteria Premium Monthly`
   - **Description**: 
     ```
     Unlock premium features including:
     • Premium member card with custom themes
     • Goal-based savings tracking
     • Decision windows and protection hours
     • Shared goals with friends and family
     • Apple Wallet integration
     • Priority support
     ```

5. Click **"Save"** (top right)

**Result**: Monthly subscription created (status: "Ready to Submit")

---

### Step 4: Create Annual Subscription

1. In the same "Soteria Premium" group, click **"+"** → **"Create Auto-Renewable Subscription"**

2. **Product Information**:
   - **Product ID**: `com.soteria.premium.yearly` ⚠️ **MUST MATCH EXACTLY**
   - **Reference Name**: `Soteria Premium Annual`
   - **Subscription Duration**: Select **"1 Year"**

3. **Subscription Pricing**:
   - Click **"Add Subscription Pricing"**
   - **Base Territory**: Select **"United States"**
   - **Price**: Enter `39.99` (or select from dropdown)
   - Click **"Next"** → **"Save"**

4. **Localization** (English - U.S.):
   - Click **"Add Localization"** if not already there
   - **Display Name**: `Soteria Premium Annual`
   - **Description**: 
     ```
     Best value! Get all premium features for a full year:
     • Premium member card with custom themes
     • Goal-based savings tracking
     • Decision windows and protection hours
     • Shared goals with friends and family
     • Apple Wallet integration
     • Priority support
     
     Save 33% compared to monthly billing!
     ```

5. Click **"Save"** (top right)

**Result**: Annual subscription created (status: "Ready to Submit")

---

### Step 5: Set Subscription Group Order (Important!)

1. In your "Soteria Premium" subscription group, you'll see both subscriptions listed
2. **Drag to reorder** (if needed):
   - **Annual** should be **first** (best value, users see it first)
   - **Monthly** should be **second**
3. This order will appear in your app's paywall

**Why**: Users typically see the best value first, which increases annual subscriptions

---

### Step 6: Add Subscription Benefits (Optional but Recommended)

For each subscription (monthly and annual):

1. Click on the subscription to open its details
2. Scroll down to **"Subscription Benefits"** section
3. Click **"+"** to add benefits:
   - **Premium Member Card**
   - **Custom Card Themes**
   - **Goal-Based Savings**
   - **Decision Windows**
   - **Protection Hours**
   - **Shared Goals**
   - **Apple Wallet Integration**
   - **Priority Support**

**Note**: Benefits are optional but help users understand what they're getting

---

### Step 7: Submit Subscriptions for Review

1. Both subscriptions should show status: **"Ready to Submit"**
2. Select both subscriptions (checkboxes)
3. Click **"Submit for Review"** button
4. **Review Time**: Typically 24-48 hours
5. **Good News**: You can test in TestFlight with sandbox accounts while waiting!

---

## ✅ Verification Checklist

After creating subscriptions, verify:

- [ ] Subscription group created: `Soteria Premium`
- [ ] Monthly subscription created: `com.soteria.premium.monthly`
- [ ] Annual subscription created: `com.soteria.premium.yearly`
- [ ] Monthly price set: $4.99
- [ ] Annual price set: $39.99
- [ ] Display names added (English - U.S.)
- [ ] Descriptions added
- [ ] Subscription order set (Annual first, Monthly second)
- [ ] Subscriptions submitted for review
- [ ] Product IDs match exactly with code

---

## 🧪 Testing Subscriptions (After Creation)

### Create Sandbox Test Accounts

1. In App Store Connect, go to **"Users and Access"** (top right)
2. Click **"Sandbox Testers"** tab
3. Click **"+"** to add testers
4. Create test accounts:
   - Use different emails than your real account
   - Example: `test1@example.com`, `test2@example.com`
5. **Note**: These are for testing only - no real charges

### Test in TestFlight (After Build Upload)

1. **Sign out of App Store** on your test device:
   - Settings → [Your Name] → Media & Purchases → Sign Out
2. **Install app** from TestFlight
3. **Navigate to subscription/paywall** screen (Settings → Upgrade)
4. **When prompted**, sign in with sandbox test account
5. **Complete purchase** (no real charge - sandbox mode)
6. **Verify subscription activates** in app

---

## 📱 What Happens Next

### After Subscriptions Are Created:

1. ✅ **Subscriptions exist** in App Store Connect
2. **Build and upload** to TestFlight
3. **Test subscription flow** with sandbox accounts
4. **Verify subscription UI** shows both options correctly
5. **Test purchase flow** end-to-end
6. **Iterate based on testing**

### After Subscriptions Are Approved (24-48 hours):

1. Subscriptions work in production
2. Can test with real purchases (if desired)
3. Ready for App Store submission

---

## ⚠️ Important Notes

### Product IDs Must Match Exactly
- **Code uses**: `com.soteria.premium.monthly` and `com.soteria.premium.yearly`
- **App Store Connect must use**: Same exact IDs
- **Why**: App looks for these specific IDs to load products

### Review Time
- Subscriptions typically approved in **24-48 hours**
- Can test in **sandbox mode** while waiting (no review needed)
- Sandbox testing works immediately after creation

### Pricing
- Can adjust pricing later (requires new version)
- Initial pricing: **$4.99/month**, **$39.99/year**
- Annual saves ~33% vs monthly

### Sandbox Testing
- Works immediately (no review needed)
- Perfect for TestFlight testing
- No real charges

---

## 🎯 Current Status

- ✅ **App created**: "Soteria Savings" in App Store Connect
- ✅ **Code ready**: Product IDs configured, PaywallView ready
- ⏳ **Next**: Create subscriptions (follow steps above)
- ⏳ **Then**: Build and upload to TestFlight
- ⏳ **Then**: Test subscription flow

---

**Ready to proceed?** Follow the steps above to create your subscriptions!

