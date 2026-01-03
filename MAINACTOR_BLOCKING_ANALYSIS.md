# 🔴 MainActor Blocking Analysis

## Critical Finding: Multiple MainActor.run Calls Blocking Sign-In

### Blocking Operations Identified

#### 1. AuthService.init() - Multiple MainActor.run Calls ⚠️ CRITICAL
**Location:** `soteria/Services/AuthService.swift`

- **Line 100**: `await MainActor.run { self.cognitoService.$isAuthenticated... }`
  - **Impact:** Blocks MainActor to set up Combine subscription
  - **Timing:** Runs 0.1s after init (Task.detached delay)
  
- **Line 117**: `await MainActor.run { self.isCheckingAuth = true }`
  - **Impact:** Blocks MainActor to set checking state
  - **Timing:** Runs immediately in background task
  
- **Line 128**: `try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds`
  - **Impact:** 2-second delay before auth check
  - **Timing:** Blocks background task for 2 seconds
  
- **Line 154**: `await MainActor.run { self.updateAuthState() }`
  - **Impact:** Blocks MainActor to update auth state
  - **Timing:** After auth check completes (2+ seconds)
  
- **Line 166, 178**: Multiple `await MainActor.run` calls for error handling
  - **Impact:** Blocks MainActor during error handling

**Total Blocking Time:** ~2+ seconds of MainActor blocking during startup

#### 2. CognitoAuthService - MainActor.run in signUp ⚠️
**Location:** `soteria/Services/CognitoAuthService.swift`

- **Line 92**: `await MainActor.run { self.accessToken = ... }`
  - **Impact:** Blocks MainActor during sign-up
  - **Timing:** Only during sign-up (not startup)

#### 3. RootView.checkForPurchaseIntentPrompt() - Multiple MainActor.run ⚠️
**Location:** `soteria/SoteriaApp.swift`

- **Line 685-690**: `await MainActor.run { QuietHoursService.shared }`
- **Line 713-780**: Large `MainActor.run` block accessing services
  - **Impact:** Blocks MainActor for service access
  - **Timing:** Called from various places (not during startup, but could be triggered)

#### 4. SoteriaApp.init() - UI Appearance Config ⚠️
**Location:** `soteria/SoteriaApp.swift`

- **Line 30**: `await MainActor.run { ... }` for UI appearance
  - **Impact:** Blocks MainActor during app init
  - **Timing:** 0.5s delay, then MainActor.run

## Root Cause

**MainActor is saturated by multiple queued `MainActor.run` calls from AuthService initialization:**

1. AuthService.init() creates multiple `Task.detached` operations
2. Each task uses `await MainActor.run` to update state
3. These MainActor.run calls queue up and block MainActor
4. When AuthView appears, MainActor is still processing these queued operations
5. TextFields can't receive input because MainActor is blocked

## Solution

1. **Remove MainActor.run from AuthService init tasks** - Use `DispatchQueue.main.async` instead
2. **Remove 2-second delay** - Check auth immediately or defer longer
3. **Batch MainActor updates** - Combine multiple state updates into single MainActor.run
4. **Defer non-critical operations** - Move auth verification to 30+ seconds after startup

