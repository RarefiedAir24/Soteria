# TestFlight First Build Guide

**Date**: January 7, 2026  
**Status**: Ready for First TestFlight Build

---

## 📋 Correct Order of Operations

### Step 1: Create App in App Store Connect ⚠️ **FIRST**

Before you can create subscriptions or upload builds, you need to create the app:

1. **Go to [App Store Connect](https://appstoreconnect.apple.com)**
2. **Click "My Apps"** → **"+"** button
3. **Select "New App"**
4. **Fill in App Information**:
   - **Platform**: iOS
   - **Name**: `Soteria` (or your preferred name)
   - **Primary Language**: English
   - **Bundle ID**: `io.montebay.soteria` (must match Xcode)
   - **SKU**: `soteria-001` (or any unique identifier)
   - **User Access**: Full Access (or as needed)
5. **Click "Create"**

### Step 2: Upload First Build to TestFlight

After app is created:

1. **Build and Archive** in Xcode
2. **Distribute App** → **App Store Connect**
3. **Upload** the build
4. **Wait for processing** (usually 10-30 minutes)

### Step 3: Create Subscriptions (After First Build)

Once the app exists and first build is uploaded:

1. **Go to App Store Connect** → Your App
2. **Features** → **In-App Purchases**
3. **Create Subscription Group**: "Soteria Premium"
4. **Create Monthly Subscription**: `com.soteria.premium.monthly`
5. **Create Annual Subscription**: `com.soteria.premium.yearly`
6. **Submit subscriptions for review**

### Step 4: Test in TestFlight

1. **Add testers** in TestFlight
2. **Test subscription flow** with sandbox accounts
3. **Test Plaid connection** with sandbox
4. **Iterate and improve**

---

## ✅ Current Configuration

### Bundle ID
- **Bundle Identifier**: `io.montebay.soteria`
- **Location**: Xcode → General tab

### Version Numbers
- **Marketing Version**: `1.0`
- **Build Number**: `1`

### Subscription Product IDs (Ready for App Store Connect)
- **Monthly**: `com.soteria.premium.monthly`
- **Annual**: `com.soteria.premium.yearly`

---

## 🚀 Immediate Next Steps

### 1. Create App in App Store Connect (5 minutes)
- Follow Step 1 above
- App will be created but not submitted for review yet

### 2. Build and Upload First TestFlight Build (15 minutes)
- Update build number if needed (currently `1`)
- Archive in Xcode
- Upload to App Store Connect
- Wait for processing

### 3. Create Subscriptions (After Build Processes)
- Once build is processed, create subscriptions
- Can test subscriptions in TestFlight with sandbox accounts

---

## 📝 App Store Connect App Creation Checklist

- [ ] Log into App Store Connect with organization account
- [ ] Click "My Apps" → "+" → "New App"
- [ ] Select Platform: iOS
- [ ] Enter App Name: `Soteria`
- [ ] Select Primary Language: English
- [ ] Select Bundle ID: `io.montebay.soteria`
- [ ] Enter SKU: `soteria-001` (or unique identifier)
- [ ] Select User Access level
- [ ] Click "Create"
- [ ] Verify app appears in "My Apps"

---

## ⚠️ Important Notes

1. **App Must Exist First**: Cannot create subscriptions without app
2. **First Build Required**: Need at least one build uploaded before full TestFlight setup
3. **Subscriptions Can Wait**: You can test everything else in TestFlight first
4. **Sandbox Testing**: Subscriptions work in sandbox mode for TestFlight

---

## 🎯 Recommended Timeline

**Today**:
1. Create app in App Store Connect
2. Build and upload first TestFlight build
3. Test non-subscription features

**After Build Processes** (tomorrow or later):
1. Create subscriptions in App Store Connect
2. Test subscription flow in TestFlight
3. Iterate based on feedback

---

**Status**: ✅ Ready to create app and upload first build  
**Next Action**: Create app in App Store Connect, then build and upload

