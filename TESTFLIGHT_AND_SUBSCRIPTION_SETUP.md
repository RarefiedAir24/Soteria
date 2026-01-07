# TestFlight & Subscription Setup Guide

**Date**: January 7, 2026  
**Status**: Ready for TestFlight Build

---

## ✅ Why TestFlight Now

1. **Easier Testing**: TestFlight allows real-world testing of flows and user experience
2. **Subscription Testing**: Can test subscription flows in TestFlight with sandbox accounts
3. **Plaid Sandbox**: Works perfectly for TestFlight testing
4. **Iterative Improvements**: Catch issues early before App Store release

---

## 📋 Pre-TestFlight Checklist

### 1. App Store Connect - Subscription Products ⚠️ **REQUIRED**

Before TestFlight, you need to configure subscriptions in App Store Connect:

#### Step 1: Create Subscription Group
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → **Features** → **In-App Purchases**
3. Click **"+"** → **Create Subscription Group**
4. Name it: `Soteria Premium` (or similar)

#### Step 2: Create Monthly Subscription
1. In your subscription group, click **"+"** → **Create Auto-Renewable Subscription**
2. **Product ID**: `com.soteria.premium.monthly`
3. **Reference Name**: `Soteria Premium Monthly`
4. **Subscription Duration**: 1 Month
5. **Price**: Set your monthly price (e.g., $4.99/month)
6. **Display Name**: `Soteria Premium Monthly`
7. **Description**: Describe the monthly subscription benefits

#### Step 3: Create Annual Subscription
1. In the same subscription group, click **"+"** → **Create Auto-Renewable Subscription**
2. **Product ID**: `com.soteria.premium.yearly`
3. **Reference Name**: `Soteria Premium Annual`
4. **Subscription Duration**: 1 Year
5. **Price**: Set your annual price (e.g., $49.99/year)
6. **Display Name**: `Soteria Premium Annual`
7. **Description**: Describe the annual subscription benefits

#### Step 4: Configure Subscription Benefits
- Add subscription benefits/features
- Set up promotional offers (optional)
- Configure subscription pricing for different countries

#### Step 5: Submit for Review
- Subscriptions need to be submitted for review (can take 24-48 hours)
- You can test in TestFlight with sandbox accounts while waiting

---

## 🔧 Current Subscription Configuration

### Product IDs (in code):
- **Monthly**: `com.soteria.premium.monthly`
- **Annual**: `com.soteria.premium.yearly`

### Location in Code:
- `soteria/Services/SubscriptionService.swift` (lines 40-41)

---

## 🧪 Testing Subscriptions in TestFlight

### Sandbox Testing Accounts
1. Create sandbox test accounts in App Store Connect:
   - **Users and Access** → **Sandbox Testers**
   - Create test accounts (use different emails)
2. Sign out of App Store on test device
3. When prompted during purchase, use sandbox test account
4. Subscriptions will work in sandbox mode

### Test Subscription Flow
1. User taps "Upgrade" or subscription prompt
2. App shows subscription options (monthly/annual)
3. User selects subscription
4. Sandbox purchase flow appears
5. Use sandbox test account to complete purchase
6. Verify subscription activates in app

---

## 📱 TestFlight Build Process

### 1. Update Version Numbers
- **Version**: `1.0` (or increment if major release)
- **Build**: Increment from `1` to `2` (or next number)

### 2. Archive
- **Product** → **Archive**
- Wait for archive to complete

### 3. Distribute
- **Distribute App** → **App Store Connect**
- **Upload** (not export)
- Wait for processing

### 4. Configure in App Store Connect
- Go to **TestFlight** tab
- Add testers (internal or external)
- Add build notes
- Submit for review (if needed)

---

## ✅ What Works in TestFlight (Sandbox)

- ✅ Plaid connection (sandbox mode)
- ✅ Subscription purchases (sandbox accounts)
- ✅ All app features
- ✅ Apple Wallet passes (if certificates uploaded)
- ✅ All user flows

---

## ⚠️ What Needs Production Access

- ❌ Real bank connections (Plaid production)
- ❌ Real subscription purchases (App Store production)
- ❌ Production Apple Wallet passes (if needed)

**Note**: All of these can be tested in sandbox mode for TestFlight!

---

## 🚀 Recommended Approach

### Phase 1: TestFlight with Sandbox (Now)
1. ✅ Configure subscriptions in App Store Connect
2. ✅ Build and upload to TestFlight
3. ✅ Test all flows with sandbox accounts
4. ✅ Iterate and fix issues

### Phase 2: Production (Later)
1. Get Plaid production access
2. Switch Lambda to production
3. Submit app for App Store review
4. Launch with production subscriptions

---

## 📝 Subscription Setup Checklist

### App Store Connect:
- [ ] Create subscription group
- [ ] Create monthly subscription (`com.soteria.premium.monthly`)
- [ ] Create annual subscription (`com.soteria.premium.yearly`)
- [ ] Set pricing for both subscriptions
- [ ] Add subscription descriptions
- [ ] Submit subscriptions for review
- [ ] Create sandbox test accounts

### Code Verification:
- [x] Product IDs match: `com.soteria.premium.monthly` and `com.soteria.premium.yearly`
- [x] SubscriptionService configured correctly
- [x] Paywall views configured

---

## 🎯 Next Steps

1. **Configure subscriptions in App Store Connect** (30 minutes)
2. **Build and upload to TestFlight** (15 minutes)
3. **Test subscription flow with sandbox account** (10 minutes)
4. **Test Plaid connection with sandbox** (10 minutes)
5. **Iterate based on feedback**

---

**Status**: ✅ Ready to proceed with TestFlight  
**Recommendation**: Configure subscriptions first, then build

