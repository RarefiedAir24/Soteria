# StoreKit Configuration Setup Guide

## Issue
Products are not loading because they don't exist in App Store Connect yet.

**Error:** `⚠️ [SubscriptionService] No products loaded - check product IDs`

## Solution: Use StoreKit Configuration for Local Testing

A `Products.storekit` file has been created for local testing. This allows you to test subscriptions without configuring products in App Store Connect.

### Step 1: Add StoreKit Configuration to Xcode

1. **Open Xcode**
2. **Select your project** (soteria.xcodeproj)
3. **Right-click on `soteria` folder** in Project Navigator
4. **Select "Add Files to 'soteria'..."**
5. **Navigate to and select:** `soteria/Products.storekit`
6. **Make sure "Copy items if needed" is checked**
7. **Click "Add"**

### Step 2: Configure Scheme to Use StoreKit Configuration

1. **In Xcode, go to:** Product → Scheme → Edit Scheme...
2. **Select "Run"** in the left sidebar
3. **Click "Options" tab**
4. **Find "StoreKit Configuration"** dropdown
5. **Select:** `Products.storekit`
6. **Click "Close"**

### Step 3: Test

1. **Run the app** (⌘R)
2. **Navigate to Settings → Upgrade**
3. **Products should now load!** ✅

## Product IDs Configured

- **Monthly:** `com.soteria.premium.monthly` - $9.99/month
- **Yearly:** `com.soteria.premium.yearly` - $99.99/year

## For Production (App Store Connect)

When ready for production, you'll need to:

1. **Create products in App Store Connect:**
   - Go to: https://appstoreconnect.apple.com
   - Navigate to: Your App → Features → In-App Purchases
   - Create two Auto-Renewable Subscriptions:
     - `com.soteria.premium.monthly`
     - `com.soteria.premium.yearly`

2. **Configure subscription groups:**
   - Create a subscription group called "Premium"
   - Add both products to this group

3. **Submit for review:**
   - Products must be approved before they work in production

## Testing Purchases Locally

With StoreKit Configuration enabled:

1. **Purchases are simulated** - no real charges
2. **Transactions complete instantly** - no waiting
3. **Subscription status updates immediately**
4. **Perfect for development and testing**

## Troubleshooting

### Products still not loading?

1. **Verify StoreKit Configuration is selected in scheme**
2. **Check console logs for errors:**
   ```
   🟡 [SubscriptionService] Loading products: [...]
   ✅ [SubscriptionService] Loaded X products
   ```

3. **Make sure Products.storekit is in the project:**
   - Should appear in Project Navigator
   - Should be included in target membership

### Products load but purchase fails?

- This is normal in StoreKit Configuration
- Purchases are simulated but may show errors
- Check that subscription status updates correctly

## Notes

- **StoreKit Configuration only works in DEBUG builds**
- **For TestFlight/App Store, you need real App Store Connect products**
- **The Products.storekit file is for local testing only**

