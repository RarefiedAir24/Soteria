# 🔴 MainActor Operations Report - What's Blocking MainActor

## Critical Finding: 67-Second Blocking Gap

**Timeline:** 13.095s (UI appearance) → 80.087s (next log) = **67 seconds of MainActor blocking**

## MainActor Operations Identified

### 1. DeviceActivityService - ⚠️ **CRITICAL BLOCKER** (34 MainActor.run calls!)

**Location:** `soteria/Services/DeviceActivityService.swift`

#### Known Blocking Operations:
- **Line 38-44**: `await MainActor.run { self.selectedApps.applicationTokens.count }`
  - **Impact:** ⚠️ **20+ SECOND BLOCKER** - Accessing `applicationTokens` is extremely slow
  - **Timing:** Runs in `didSet` when `selectedApps` changes
  - **Status:** This is the #1 suspect for the 67-second gap

- **Line 51-53**: `await MainActor.run { self.saveSelection() }`
  - **Impact:** Blocks MainActor to save selection
  - **Timing:** Runs in `didSet` when `selectedApps` changes

- **Line 59-61**: `await MainActor.run { self.updateAppNamesMapping() }`
  - **Impact:** Blocks MainActor to update app names
  - **Timing:** Runs in `selectedApps.didSet`

- **Line 298**: `Task(priority: .utility) { @MainActor [weak self] in`
  - **Impact:** Large MainActor task that loads critical data
  - **Timing:** Runs during initialization (but should be deferred)

- **Line 374-376**: `await MainActor.run { self.isMonitoring }`
  - **Impact:** Blocks MainActor to read monitoring state
  - **Timing:** Runs during initialization

- **Line 432-434**: `await MainActor.run { self.selectedApps.applicationTokens.count }`
  - **Impact:** ⚠️ **20+ SECOND BLOCKER** - Same as above
  - **Timing:** Runs in `refreshAppCount()`

- **Line 1064-1067**: `await MainActor.run { Array(self.selectedApps.applicationTokens) }`
  - **Impact:** ⚠️ **20+ SECOND BLOCKER** - Creating array from tokens
  - **Timing:** Runs in `getApplicationTokens()`

**Total Blocking Potential:** 60+ seconds from DeviceActivityService alone

### 2. AuthService - ⚠️ **PARTIALLY FIXED**

**Location:** `soteria/Services/AuthService.swift`

- **Line 69-71**: `await MainActor.run { SubscriptionService.shared.setPremiumForTesting(email: email) }`
  - **Impact:** Blocks MainActor to set premium status
  - **Timing:** Runs during init if user has cached tokens
  - **Status:** Still using MainActor.run (should be DispatchQueue.main.async)

### 3. GoalsService - ⚠️

**Location:** `soteria/Services/GoalsService.swift`

- **Line 179-182**: `await MainActor.run { self.loadGoals() }`
  - **Impact:** Blocks MainActor to load goals
  - **Timing:** Runs 30 seconds after init (deferred)

### 4. QuietHoursService - ⚠️

**Location:** `soteria/Services/QuietHoursService.swift`

- **Line 123-127**: `await MainActor.run { self.schedules = decoded }`
  - **Impact:** Blocks MainActor to set schedules
  - **Timing:** Runs when schedules are loaded

- **Multiple `Task { @MainActor in` blocks** (lines 147, 154, 188, 198, 208, 218, 312, 339)
  - **Impact:** Multiple MainActor tasks for status checks
  - **Timing:** Various triggers

### 5. PlaidService - ⚠️

**Location:** `soteria/Services/PlaidService.swift`

- **Line 263-268**: `await MainActor.run { self.connectedAccounts[index].balance = balance }`
  - **Impact:** Blocks MainActor to update balances
  - **Timing:** Runs when balances are fetched

- **Line 276-281**: `await MainActor.run { self.savingsAccount?.balance = balance }`
  - **Impact:** Blocks MainActor to update savings balance
  - **Timing:** Runs when savings balance is fetched

### 6. RootView.checkForPurchaseIntentPrompt() - ⚠️

**Location:** `soteria/SoteriaApp.swift`

- **Line 684-689**: `await MainActor.run { QuietHoursService.shared }` and `DeviceActivityService.shared`
  - **Impact:** Blocks MainActor to access services
  - **Timing:** Called from various places (not during startup, but could be triggered)

- **Line 712-779**: Large `await MainActor.run` block
  - **Impact:** Blocks MainActor for extensive service access
  - **Timing:** Runs when checking for purchase intent prompt

## Root Cause Analysis

### The 67-Second Gap Explained

**Most Likely Culprit: DeviceActivityService.selectedApps.applicationTokens**

1. When `DeviceActivityService` is accessed (even lazily), it might trigger initialization
2. If `selectedApps` has been set previously, the `didSet` fires
3. `didSet` contains `await MainActor.run { self.selectedApps.applicationTokens.count }`
4. **This operation is known to take 20+ seconds**
5. Multiple such operations queue up on MainActor
6. Result: 67-second blocking gap

### Why TextFields Are Frozen

- MainActor is completely saturated by queued `MainActor.run` operations
- Even simple operations like TextField input can't execute
- Keyboard appears (UI is rendered) but input can't be processed
- System logs show "perform input operation requires a valid sessionID" - MainActor is blocked

## Solution

### Immediate Fixes Needed:

1. **DeviceActivityService.selectedApps.didSet** - Remove ALL `MainActor.run` calls
   - Use `DispatchQueue.main.async` instead
   - Defer `applicationTokens.count` access to 60+ seconds after startup
   - Never access `applicationTokens` during startup

2. **AuthService Line 69** - Replace `MainActor.run` with `DispatchQueue.main.async`

3. **Defer ALL DeviceActivityService operations** - Don't access it until 60+ seconds after startup

4. **Add guards** - Prevent service access during first 60 seconds of app launch

