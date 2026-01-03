# Clean Rebuild Plan - Fix MainActor Blocking Once and For All

## Problem Summary
- MainActor is intermittently blocked, causing:
  - Delayed button taps (only work after rapid repeated presses)
  - Keyboard not appearing
  - View updates not reflecting state changes
  - App freezes after simple state changes

## Root Causes Identified
1. **Service initialization during app startup** - Even lazy singletons can block when accessed
2. **StartupDiagnostics logging** - Accessing `.shared` during service init blocks MainActor
3. **SwiftUI view evaluation** - Conditional rendering and state changes trigger blocking operations
4. **Synchronous UserDefaults reads** - Happening during service initialization

## Clean Rebuild Strategy

### Phase 1: Minimal App Structure
1. **SoteriaApp.swift** - Only WindowGroup, no service initialization
2. **RootView** - Simple view router, no service access
3. **AuthView** - Minimal sign-in, no service access until user actually signs in
4. **Test View** - Absolute minimum to verify keyboard works

### Phase 2: Lazy Service Architecture
1. **No `.shared` access at file level** - All services created on-demand
2. **No service init in app startup** - Services only created when user action requires them
3. **No StartupDiagnostics during init** - All logging deferred to background
4. **No UserDefaults reads in init()** - All data loading deferred

### Phase 3: Non-Blocking Patterns
1. **All async work off MainActor** - Use `Task.detached` for everything
2. **State updates via DispatchQueue.main.async** - Never `await MainActor.run`
3. **View updates only after data loaded** - Show loading states, update when ready
4. **No synchronous property access** - All service properties accessed asynchronously

## Implementation Steps

### Step 1: Create Minimal Test App
- Single view with TextField and Button
- No services, no logging, no state management
- Verify keyboard works

### Step 2: Add Auth Service (Lazy)
- Only create AuthService when user taps "Sign In"
- No initialization in init()
- All work deferred to background

### Step 3: Add Other Services (On-Demand)
- Only create services when actually needed
- Never access `.shared` during view creation
- All initialization deferred

### Step 4: Add Logging (Deferred)
- All StartupDiagnostics calls deferred to 60+ seconds
- Or completely removed for production

## Files to Rebuild
1. `SoteriaApp.swift` - Minimal app structure
2. `RootView` - Simple router
3. `AuthView` - Minimal sign-in
4. All Services - Lazy initialization, no blocking work

## Success Criteria
- App launches in < 1 second
- Button taps respond immediately
- Keyboard appears when TextField tapped
- View updates reflect state changes immediately
- No MainActor blocking detected

