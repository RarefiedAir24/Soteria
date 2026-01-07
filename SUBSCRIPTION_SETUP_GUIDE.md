# Subscription Setup Guide for App Store Connect

**Date**: January 7, 2026  
**App**: Soteria Savings  
**Status**: Ready to Create Subscriptions

---

## 📋 Subscription Product IDs

Your app code is configured with:
- **Monthly**: `com.soteria.premium.monthly`
- **Annual**: `com.soteria.premium.yearly`

**Pricing** (from StoreKit config):
- **Monthly**: $4.99/month
- **Annual**: $39.99/year (saves ~33% vs monthly)

---

## 🚀 Step-by-Step: Create Subscriptions in App Store Connect

### Step 1: Navigate to In-App Purchases

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **"My Apps"**
3. Select **"Soteria Savings"**
4. Click **"Features"** tab (top navigation)
5. Click **"In-App Purchases"** (left sidebar)

### Step 2: Create Subscription Group

1. Click **"+"** button (top left)
2. Select **"Create Subscription Group"**
3. **Group Name**: `Soteria Premium`
4. **Description** (optional): "Premium subscription tier for Soteria Savings"
5. Click **"Create"**

### Step 3: Create Monthly Subscription

1. In your subscription group, click **"+"** → **"Create Auto-Renewable Subscription"**

2. **Product Information**:
   - **Product ID**: `com.soteria.premium.monthly` ⚠️ **MUST MATCH EXACTLY**
   - **Reference Name**: `Soteria Premium Monthly` (internal name, can be different)
   - **Subscription Duration**: `1 Month`

3. **Subscription Pricing**:
   - Click **"Add Subscription Pricing"**
   - **Base Territory**: United States
   - **Price**: `$4.99`
   - Click **"Next"** → **"Save"**

4. **Localization** (English - U.S.):
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

### Step 4: Create Annual Subscription

1. In the same subscription group, click **"+"** → **"Create Auto-Renewable Subscription"**

2. **Product Information**:
   - **Product ID**: `com.soteria.premium.yearly` ⚠️ **MUST MATCH EXACTLY**
   - **Reference Name**: `Soteria Premium Annual`
   - **Subscription Duration**: `1 Year`

3. **Subscription Pricing**:
   - Click **"Add Subscription Pricing"**
   - **Base Territory**: United States
   - **Price**: `$39.99`
   - Click **"Next"** → **"Save"**

4. **Localization** (English - U.S.):
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

### Step 5: Set Subscription Group Order

1. In your subscription group, you'll see both subscriptions
2. **Drag to reorder** (if needed):
   - Annual should be **first** (best value)
   - Monthly should be **second**
3. This order will appear in your app's paywall

### Step 6: Add Subscription Benefits (Optional but Recommended)

For each subscription:

1. Click on the subscription
2. Scroll to **"Subscription Benefits"** section
3. Click **"+"** to add benefits:
   - **Premium Member Card**
   - **Custom Card Themes**
   - **Goal-Based Savings**
   - **Decision Windows**
   - **Protection Hours**
   - **Shared Goals**
   - **Apple Wallet Integration**
   - **Priority Support**

### Step 7: Submit Subscriptions for Review

1. Both subscriptions should show status: **"Ready to Submit"**
2. Click **"Submit for Review"** button
3. **Note**: Subscriptions can take 24-48 hours to be approved
4. **Good news**: You can test in TestFlight with sandbox accounts while waiting!

---

## ✅ Verification Checklist

After creating subscriptions:

- [ ] Subscription group created: `Soteria Premium`
- [ ] Monthly subscription created: `com.soteria.premium.monthly`
- [ ] Annual subscription created: `com.soteria.premium.yearly`
- [ ] Monthly price set: $4.99
- [ ] Annual price set: $39.99
- [ ] Display names and descriptions added
- [ ] Subscriptions submitted for review
- [ ] Product IDs match exactly with code

---

## 🧪 Testing Subscriptions

### Create Sandbox Test Accounts

1. In App Store Connect, go to **"Users and Access"**
2. Click **"Sandbox Testers"** tab
3. Click **"+"** to add testers
4. Create test accounts (use different emails than your real account)
5. **Note**: These are for testing only - no real charges

### Test in TestFlight

1. Sign out of App Store on your test device
2. Install app from TestFlight
3. Navigate to subscription/paywall screen
4. When prompted, sign in with sandbox test account
5. Complete purchase (no real charge)
6. Verify subscription activates in app

---

## 📱 Next Steps After Subscriptions Created

1. ✅ **Subscriptions created** (you're here)
2. **Build and upload to TestFlight**
3. **Test subscription flow** with sandbox accounts
4. **Verify subscription UI** shows both options correctly
5. **Test purchase flow** end-to-end
6. **Iterate based on testing**

---

## ⚠️ Important Notes

1. **Product IDs Must Match Exactly**: 
   - Code uses: `com.soteria.premium.monthly` and `com.soteria.premium.yearly`
   - App Store Connect must use the same IDs

2. **Review Time**: 
   - Subscriptions typically approved in 24-48 hours
   - Can test in sandbox while waiting

3. **Pricing**:
   - Can adjust pricing later (requires new version)
   - Initial pricing: $4.99/month, $39.99/year

4. **Sandbox Testing**:
   - Works immediately (no review needed)
   - Perfect for TestFlight testing

---

**Status**: Ready to create subscriptions  
**Next**: Follow steps above, then build TestFlight build

