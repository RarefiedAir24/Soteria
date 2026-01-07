# Add Plaid LinkKit to Soteria

## The Issue

LinkKit is not available, causing the error:
```
⚠️ [PlaidLinkViewController] LinkKit not available
```

## The Fix: Add Plaid LinkKit via Swift Package Manager

### Step 1: Open Xcode Workspace

1. **Open** `soteria.xcworkspace` in Xcode (NOT `.xcodeproj`)

### Step 2: Add Plaid LinkKit Package

1. **Select the project** (blue icon at top of navigator)
2. **Select the project** (not target) in the editor
3. Go to **"Package Dependencies"** tab
4. Click the **"+"** button (bottom left)
5. In the search/URL field, enter:
   ```
   https://github.com/plaid/plaid-link-ios
   ```
6. Click **"Add Package"**
7. Wait for it to fetch package information
8. Select version: **Up to Next Major Version** with **4.0.0** or latest
9. In the package products list, check:
   - ✅ **LinkKit**
10. Make sure **"Add to Target: soteria"** is selected
11. Click **"Add Package"**

### Step 3: Verify Package is Added

1. In **Package Dependencies** tab, you should see:
   - `plaid-link-ios` with a checkmark ✅
   - LinkKit listed under products

2. **Select the `soteria` target** (not project)
3. Go to **"General"** tab
4. Scroll to **"Frameworks, Libraries, and Embedded Content"**
5. You should see **LinkKit** listed
6. If it's missing, click **"+"** and add it

### Step 4: Clean and Build

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)

### Step 5: Test

1. Run the app
2. Try connecting a bank account
3. LinkKit should now be available and the Plaid Link UI should appear

## Alternative: Check if Already Added

If LinkKit package is already listed but not working:

1. **File** → **Packages** → **Reset Package Caches**
2. **File** → **Packages** → **Resolve Package Versions**
3. Clean and rebuild

## Verification

After adding LinkKit:
- ✅ No "LinkKit not available" warnings
- ✅ `#if canImport(LinkKit)` evaluates to true
- ✅ Plaid Link UI appears when connecting accounts
- ✅ Bank connection flow works

